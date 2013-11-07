Ember.Widgets.ModalComponent =
Ember.Component.extend Ember.Widgets.StyleBindingsMixin,
  layoutName: 'modal'
  classNames: ['modal']
  classNameBindings: ['isShowing:in', 'fade']
  modalPaneBackdrop: '<div class="modal-backdrop"></div>'
  bodyElementSelector: '.modal-backdrop'

  enforceModality: no
  backdrop:     yes
  isShowing:    no
  fade:         yes
  headerText:   "Modal Header"
  confirmText:  "Confirm"
  cancelText:   "Cancel"
  content:      ""
  contentViewClass: null

  confirm: Ember.K
  cancel: Ember.K

  defaultContentViewClass: Ember.View.extend
    template: Ember.Handlebars.compile("<p>{{content}}</p>")

  _contentViewClass: Ember.computed ->
    contentViewClass = @get 'contentViewClass'
    return @get('defaultContentViewClass') unless contentViewClass
    if typeof contentViewClass is 'string'
      Ember.get @get('contentViewClass')
    else contentViewClass
  .property 'contentViewClass'

  actions:
    sendCancel: ->
      cancel = @get 'cancel'
      # TODO: this is for backward compatibility only. If cancel is a function
      # we will invoke the callback
      if typeof(cancel) is 'function' then cancel() else @sendAction 'cancel'
      @hide()

    sendConfirm: ->
      confirm = @get 'confirm'
      # TODO: this is for backward compatibility only. If confirm is a function
      # we will invoke the callback
      if typeof(confirm) is 'function' then confirm() else @sendAction 'confirm'
      @hide()

  didInsertElement: ->
    @_super()
    # See force reflow at http://stackoverflow.com/questions/9016307/
    # force-reflow-in-css-transitions-in-bootstrap
    @$()[0].offsetWidth if @get('fade')
    # append backdrop
    @_appendBackdrop() if @get('backdrop')
    # show modal in next run loop so that it will fade in instead of appearing
    # abruptly on the screen
    Ember.run.next this, -> @set 'isShowing', yes
    # bootstrap modal adds this class to the body when the modal opens to
    # transfer scroll behavior to the modal
    $(document.body).addClass('modal-open')

  click: (event) ->
    return if event.target isnt event.currentTarget
    @hide() unless @get('enforceModality')

  hide: -> Ember.Widgets.ModalComponent.hideModal()

  _hide: ->
    @set 'isShowing', no
    # bootstrap modal removes this class from the body when the modal cloases
    # to transfer scroll behavior back to the app
    $(document.body).removeClass('modal-open')
    # fade out backdrop
    @_backdrop.removeClass('in')
    # remove backdrop and destroy modal only after transition is completed
    @$().one $.support.transition.end, =>
      @_backdrop.remove() if @_backdrop
      # We need to wrap this in a run-loop otherwise ember-testing will complain
      # about auto run being disabled when we are in testing mode.
      Ember.run this, @destroy

  _appendBackdrop: ->
    parentLayer = @$().parent()
    modalPaneBackdrop = @get 'modalPaneBackdrop'
    @_backdrop = jQuery(modalPaneBackdrop).addClass('fade') if @get('fade')
    @_backdrop.appendTo(parentLayer)
    # show backdrop in next run loop so that it can fade in
    Ember.run.next this, -> @_backdrop.addClass('in')

Ember.Widgets.ModalComponent.reopenClass
  rootElement: '.ember-application'
  poppedModal: null

  hideModal: ->
    if Addepar.Components.ModalComponent.poppedModal
      Addepar.Components.ModalComponent.poppedModal._hide()
      Addepar.Components.ModalComponent.poppedModal = null

  popup: (options = {}) ->
    rootElement = options.rootElement or @rootElement
    @hideModal()
    Addepar.Components.ModalComponent.poppedModal = this.create options
    modal = Addepar.Components.ModalComponent.poppedModal
    modal.container = modal.get('targetObject.container')
    modal.appendTo rootElement
    modal

Ember.Handlebars.helper('modal-component', Ember.Widgets.ModalComponent)
