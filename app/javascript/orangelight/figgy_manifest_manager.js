
import loadResourcesByBibId from './load-resources-by-bib-id'
import loadResourcesByBibIds from './load-resources-by-bib-ids'

class FiggyViewer {
  // There may be more than one ARK minted which resolves to the same manifested resource
  constructor(idx, element, manifestUrl, arks) {
    this.idx = idx
    this.element = element
    this.manifestUrl = manifestUrl
    this.arks = arks
  }

  getAvailabilityElement() {
    let elements = document.querySelectorAll('#availability > div.location--panel.location--online > div > div.panel-body > div')
    if (elements.length < 1) {
      elements = document.querySelectorAll('#availability > div.location--panel.location--online > div > div.panel-body > div > ul > div.electronic-access')
    }
    // This assumes that the first element is the link
    const element = elements[0]
    return element
  }

  getArkLinkElement() {
    // If there is only one electronic access link, it's structure using a <div> rather than <ul>
    const availabilityElement = this.getAvailabilityElement()

    if (!availabilityElement) {
      return null
    }

    let elements = availabilityElement.querySelectorAll('div > a')
    if (elements.length < 1) {
      elements = availabilityElement.querySelectorAll('li > a')
    }

    // This assumes that there is a one-to-one mapping between the ARK electronic resource links in the DOM and the UniversalViewer instances
    return elements[this.idx]
  }

  buildViewerId() {
    return this.idx == 0 ? 'view' : `view_${this.idx}`
  }

  updateArkLinkElement() {
    const arkLinkElement = this.getArkLinkElement()
    if (!arkLinkElement) {
      return
    }

    arkLinkElement.href = '#' + this.buildViewerId()
    arkLinkElement.removeAttribute("target")
  }

  constructIFrame() {
    const iframeElement = document.createElement("iframe")
    iframeElement.setAttribute("allowFullScreen", "true")
    iframeElement.id = `iframe-${this.idx + 1}`

    // This needs to be retrieved using Global
    const figgyUrl = window.Global.figgy.url
    const src = `${figgyUrl}/uv/uv#?manifest=${this.manifestUrl}&config=${figgyUrl}/uv/uv_config.json`
    iframeElement.src = src

    return iframeElement
  }

  constructViewerElement() {
    const viewerElement = document.createElement("div")
    viewerElement.setAttribute("class", "intrinsic-container intrinsic-container-16x9")
    viewerElement.id = this.buildViewerId()

    const iFrameElement = this.constructIFrame()
    viewerElement.appendChild(iFrameElement)

    return viewerElement
  }

  async render() {
    const viewerElement = this.constructViewerElement()
    if (!viewerElement) {
      return null
    }

    if (this.arks.length > 0) {
      this.updateArkLinkElement()
    }

    this.element.appendChild(viewerElement)
  }
}

class FiggyViewerSet {
  constructor(element, query, variables, arks, jQuery) {
    this.element = element
    this.query = query
    this.variables = variables
    this.arks = arks
    this.jQuery = jQuery
  }

  async fetchResources() {
    const data = await this.query.call(this, this.variables)
    if (!data) {
      return null;
    }

    const resources = data.resourcesByBibid
    return resources
  }

  async getManifestUrls() {
    const resources = await this.fetchResources()
    if (!resources) {
      return []
    }

    // Filter only for resources with child resources (i. e. non-FileSets) as members
    // This is not performant, and should require a separate GraphQL query
    const filteredResources = resources.filter((resource) => {
      if (!resource['members'])
        return true
      return resource.members.filter((member) => {
        return member.__typename != "FileSet"
      }).length > 0
    })
    if (resources.length > 0 && filteredResources.length < 1)
      return resources.map((resource) => {
        return resource.manifestUrl
      })

    return filteredResources.map((resource) => {
      return resource.manifestUrl
    })
  }

  async render() {
    const manifestUrls = await this.getManifestUrls()

    manifestUrls.forEach((manifestUrl, idx) => {
      const viewer = new FiggyViewer(idx, this.element, manifestUrl, this.arks)
      viewer.render()
    })
  }
}

// Queries for resources using multiple bib. IDs
class FiggyThumbnailSet {
  constructor(elements, query, jQuery) {
    this.elements = elements
    this.$elements = jQuery(elements)
    this.query = query
    this.jQuery = jQuery
  }

  async fetchResources() {
    this.bibIds = this.$elements.map((idx, element) => this.jQuery(element).data('bib-id').toString())
    const variables = { bibIds: this.bibIds.toArray() }
    this.thumbnails = {}
    const data = await this.query.call(this, variables.bibIds)
    if (!data) {
      return null;
    }

    const resources = data.resourcesByBibids
    this.resources = resources

    // Cache the thumbnail URLs
    for (let resource of this.resources) {
      const bibId = resource.sourceMetadataIdentifier
      this.thumbnails[bibId] = resource.thumbnail
    }
    return this.resources
  }

  constructThumbnailElement(bibId) {
    const thumbnail = this.thumbnails[bibId]
    if (!thumbnail) {
      return null
    }

    const $element = this.jQuery(`<img alt="" src="${thumbnail.iiifServiceUrl}/square/225,/0/default.jpg">`)
    return $element
  }

  async render() {
    await this.fetchResources()
    this.$elements.map((idx, element) => {
      const $element = this.jQuery(element)
      const bibId = $element.data('bib-id')
      const $thumbnailElement = this.constructThumbnailElement(bibId)
      if (!$thumbnailElement) {
        return
      }
      $element.empty()
      $element.addClass('has-viewer-link')
      $element.wrap('<a href="#view"></a>').append('<span class="sr-only">Go to viewer</span>')
      $element.append($thumbnailElement)
    })
  }
}

class FiggyManifestManager {

  static buildThumbnailSet($elements) {
    return new FiggyThumbnailSet($elements, loadResourcesByBibIds, window.jQuery)
  }

  // Build multiple viewers
  static buildViewers(element) {
    const $element = window.jQuery(element)
    const bibId = $element.data('bib-id')
    const arks = $element.data('arks') || []

    return new FiggyViewerSet(element, loadResourcesByBibId, bibId.toString(), arks, window.jQuery)
  }
}

export default FiggyManifestManager
