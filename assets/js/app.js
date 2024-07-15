// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const debounce = (callback, wait) => {
  let timeoutId = null;
  return (...args) => {
    window.clearTimeout(timeoutId);
    timeoutId = window.setTimeout(() => {
      callback(...args);
    }, wait);
  };
}

const hooks = {}
hooks.root = {
  mounted() {
    let startMs, endMs
    let currentPlayId = 0
    let currentTrackUrl
    let deviceId

    const checkForOutOfBoundsTrack = (position) => {
      if (startMs > position) {
        this.player.seek(startMs)
        return true
      } else if (endMs < position) {
        this.player.pause().then(() => {
          this.player.seek(startMs)
        })
        return true
      }
    }

    const script = document.createElement("script");
    script.src = "https://sdk.scdn.co/spotify-player.js";
    script.async = true;
    document.body.appendChild(script);

    window.onSpotifyWebPlaybackSDKReady = () => {
      const token = this.el.dataset.token;
      const player = new Spotify.Player({
        name: 'Snippit',
        getOAuthToken: cb => { cb(token); },
        volume: 0.5
      })

      player.addListener('ready', ({ device_id }) => {
        deviceId = device_id
        console.log('player ready!!')
        this.pushEvent('player_ready', deviceId)
      })

      const onStateChange = (state) => {
        const { paused, position, loading, track_window } = state
        const player_url = track_window.current_track.uri
        checkForOutOfBoundsTrack(position)
        updatePlayId({ paused, position })
        console.log('player_state_changed', state)
        this.pushEvent('player_state_changed', { paused, position, loading, player_url })
      }

      const _onStateChange = debounce(onStateChange, 5)

      player.addListener('player_state_changed', _onStateChange)
      player.connect()

      this.player = player

      this.player.on('authentication_error', ({ message }) => {
        console.error('Failed to authenticate', message);
      });

      player.on('playback_error', ({ message }) => {
        console.error('Failed to perform playback', message);
      });
    }

    this.handleEvent('initialize_audio', ({ start_ms, end_ms, spotify_url }) => {
      currentTrackUrl = spotify_url
      startMs = start_ms
      endMs = end_ms
      this.player.pause().then(() => {
        this.player.seek(start_ms)
      })
    })

    const updatePlayId = ({ paused, position }) => {
      if (paused) {
        currentPlayId = null
        return
      }
      const playId = Math.random()
      currentPlayId = playId
      setTimeout(() => {
        if (currentPlayId && currentPlayId === playId) {
          this.player.pause().then(() => {
            this.player.seek(startMs)
          })
        }
      }, endMs - position - 10)
      // leave 10ms as buffer to prevent next song in queue from playing
    }

    const updatePositionAndPlayIdIfInBounds = () => {
      this.player.getCurrentState().then(state => {
        const outOfBounds = checkForOutOfBoundsTrack(state.position)
        if (!outOfBounds) {
          const trackEl = document.getElementById("track")
          if (trackEl) {
            this.pushEventTo(trackEl, 'position_updated', state.position)
          }
        }
        updatePlayId(state)
      })
    }

    this.handleEvent('bounds_changed', ({ start_ms, end_ms }) => {
      startMs = start_ms
      endMs = end_ms
      updatePositionAndPlayIdIfInBounds()
    })

    this.handleEvent('toggle_play', () => {
      this.player.togglePlay()
    })
  
    this.handleEvent('pause', () => {
      this.player.pause()
    })

    this.handleEvent('reset', () => {
      this.player.pause().then(() => {
        this.player.seek(startMs)
      })
    })

    this.handleEvent('restart', () => {
      this.player.seek(startMs).then(() => {
        this.player.resume()
      })
    })

    this.handleEvent('backward', () => {
      this.player.seek(startMs)
    })

    this.handleEvent('seek', ({ ms }) => {
      this.player.seek(ms)
    })

  },
  destroyed() {
    this.player.disconnect()
  }
}

hooks.track = {
  mounted() {
    const rect = this.el.getBoundingClientRect()
    const width = rect.width
    const [bound1El, bound2El] = this.el.querySelectorAll('.bound-marker')
    const trackEl = this.el.querySelector('#track-marker')

    this.pushEventTo(this.el, 'width_computed', width)
    let durationMs
    const state = {
      bound1: {
        el: bound1El, isDragging: false
      },
      bound2: {
        el: bound2El, isDragging: false
      },
      track: {
        el: trackEl, isDragging: false
      }
    }

    const markers = ['bound1', 'bound2', 'track']
    markers.forEach(marker => {
      state[marker].el.addEventListener('mousedown', () => {
        state[marker].isDragging = true
      })
    })

    window.addEventListener('mousemove', (e) => {
      markers.forEach(marker => {
        if (state[marker].isDragging) {
          let x = e.clientX - rect.left
          if (x < 0) {
            x = 0
          } else if (x > width) {
            x = width
          }
          applyXTransformToMarker(marker, x)
        }
      })
    })

    function getTranslateX(el) {
      const style = el.style;
      const matrix = new WebKitCSSMatrix(style.transform);
      return matrix.m41
    }

    function getTranslateY(el) {
      const style = el.style;
      const matrix = new WebKitCSSMatrix(style.transform);
      return matrix.m42
    }

    function applyXTransformToMarker(markerName, x) {
      const y = getTranslateY(state[markerName].el)
      state[markerName].el.style.transform = `translateX(${x}px) translateY(${y}px)`
    }

    function getMsFromMarkerName(name) {
      return Math.round((getTranslateX(state[name].el) / width) * durationMs)
    }

    window.addEventListener('mouseup', () => {
      markers.forEach(marker => {
        if (state[marker].isDragging) {
          state[marker].isDragging = false
          const ms = getMsFromMarkerName(marker)
          if (marker === 'track') {
            this.pushEventTo(this.el, 'track_marker_changed', ms)
          } else {
            const otherBound = marker === 'bound1' ? 'bound2' : 'bound1'
            const otherMs = getMsFromMarkerName(otherBound)
            const startMs = Math.min(ms, otherMs)
            const endMs = Math.max(ms, otherMs)
            this.pushEventTo(this.el, 'bound_markers_changed', { start_ms: startMs, end_ms: endMs })
          }
        }
      })
    })

    this.handleEvent('initialize_audio', ({ end_ms, spotify_url }) => {
      this.spotifyUrl = spotify_url
      console.log(this.spotifyUrl)
      durationMs = end_ms
    })

    let isPlaying, prevTimestamp, currentPlayId
    function maybeMoveTrackMarker(timestamp, playId, init = false) {
      if (!isPlaying || (playId !== currentPlayId)) {
        return
      }
      if (init) {
        prevTimestamp = timestamp
      }
      const elapsed = timestamp - prevTimestamp
      const pxPerMs = width / durationMs
      const newTranslateX = (getMsFromMarkerName('track') + elapsed) * pxPerMs
      applyXTransformToMarker('track', newTranslateX)
      requestAnimationFrame(timestamp => maybeMoveTrackMarker(timestamp, playId))
      prevTimestamp = timestamp
    }
    this.handleEvent('player_state_changed', ({ playing }) => {
      isPlaying = playing
      currentPlayId = Math.random()
      requestAnimationFrame(timestamp => maybeMoveTrackMarker(timestamp, currentPlayId, true))
    })
  },
  destroyed() {
    this.pushEventTo(
      document.getElementById('add_snippet'),
      'track_removed',
      { spotify_url: this.spotifyUrl }
    )
  }
}

hooks.collections = {
  addListeners() {
    this.el
      .querySelectorAll(".collection-link")
      .forEach(linkEl => {
        linkEl.addEventListener("mouseenter", this.mouseenter)
        linkEl.addEventListener("mouseleave", this.mouseleave)
    })
  },
  mouseenter(el) {
    const buttons = el.target.querySelector(".collection-buttons")
    buttons && buttons.classList.remove("opacity-0", "pointer-events-none")
  },
  mouseleave(el) {
    const buttons = el.target.querySelector(".collection-buttons")
    buttons && buttons.classList.add("opacity-0", "pointer-events-none")
  },
  mounted() {
    this.addListeners()
  },
  updated() {
    this.addListeners()
  }
}

hooks.snippets = {
  addListeners() {
    this.el
      .querySelectorAll(".snippet")
      .forEach(linkEl => {
        linkEl.addEventListener("mouseenter", this.mouseenter)
        linkEl.addEventListener("mouseleave", this.mouseleave)
    })
  },
  mouseenter(el) {
    const buttons = el.target.querySelector(".snippet-buttons")
    buttons && buttons.classList.remove("opacity-0", "pointer-events-none")
  },
  mouseleave(el) {
    const buttons = el.target.querySelector(".snippet-buttons")
    buttons && buttons.classList.add("opacity-0", "pointer-events-none")
  },
  mounted() {
    this.addListeners()
  },
  updated() {
    this.addListeners()
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks
})

window.addEventListener('phx:show_modal', e => {
  const modal = document.getElementById(e.detail.id)
  if (modal) {
    liveSocket.execJS(modal, modal.getAttribute('data-show'))
  }
})

window.addEventListener('phx:hide_modal', e => {
  const modal = document.getElementById(e.detail.id)
  if (modal) {
    liveSocket.execJS(modal, modal.getAttribute('data-remove'))
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

