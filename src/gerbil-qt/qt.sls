#!chezscheme
;;; qt.sls -- Stub for (gerbil-qt qt)
;;; TODO: Wire up to gherkin-qt when available

(library (gerbil-qt qt)
  (export
    qt-action-create
    qt-action-set-shortcut
    qt-action-set-tooltip
    qt-app-create
    qt-app-destroy
    qt-app-exec
    qt-app-set-style-sheet
    qt-check-box-checked
    qt-check-box-create
    qt-combo-box-add-item
    qt-combo-box-clear
    qt-combo-box-count
    qt-combo-box-create
    qt-combo-box-current-text
    qt-combo-box-set-current-index
    qt-date-edit-create
    qt-date-edit-date-string
    qt-date-edit-set-calendar-popup
    qt-date-edit-set-display-format
    qt-dialog-accept
    qt-dialog-create
    qt-dialog-exec
    qt-dialog-reject
    qt-dialog-set-title
    qt-disconnect-all
    qt-file-dialog-open-directory
    qt-form-layout-add-row
    qt-form-layout-add-spanning-widget
    qt-form-layout-create
    qt-hbox-layout-create
    qt-label-create
    qt-layout-add-stretch
    qt-layout-add-widget
    qt-line-edit-create
    qt-line-edit-set-placeholder
    qt-line-edit-set-text
    qt-line-edit-text
    qt-list-widget-add-item
    qt-list-widget-create
    qt-list-widget-current-row
    qt-list-widget-item-data
    qt-list-widget-set-item-data
    qt-main-window-add-toolbar
    qt-main-window-create
    qt-main-window-menu-bar
    qt-main-window-set-central-widget
    qt-main-window-set-status-bar-text
    qt-main-window-set-title
    qt-menu-add-action
    qt-menu-add-separator
    qt-menu-bar-add-menu
    qt-message-box-critical
    qt-message-box-information
    qt-message-box-warning
    qt-on-clicked
    qt-on-return-pressed
    qt-on-triggered
    qt-on-view-clicked
    qt-on-view-double-clicked
    qt-plain-text-edit-create
    qt-plain-text-edit-set-read-only
    qt-plain-text-edit-set-text
    qt-push-button-create
    qt-sort-filter-proxy-create
    qt-sort-filter-proxy-set-source-model
    qt-spin-box-create
    qt-spin-box-set-prefix
    qt-spin-box-set-range
    qt-spin-box-set-value
    qt-spin-box-value
    qt-splitter-add-widget
    qt-splitter-create
    qt-splitter-set-sizes
    qt-standard-item-create
    qt-standard-model-create
    qt-standard-model-set-horizontal-header
    qt-standard-model-set-item
    qt-standard-model-set-row-count
    qt-table-view-create
    qt-table-view-hide-column
    qt-table-view-set-column-width
    qt-tab-widget-add-tab
    qt-tab-widget-create
    qt-tab-widget-set-current-index
    qt-text-browser-create
    qt-text-browser-set-html
    qt-toolbar-add-action
    qt-toolbar-add-separator
    qt-toolbar-add-widget
    qt-toolbar-create
    qt-toolbar-set-movable
    qt-vbox-layout-create
    qt-view-last-clicked-row
    qt-view-set-alternating-row-colors
    qt-view-set-edit-triggers
    qt-view-set-model
    qt-view-set-selection-behavior
    qt-view-set-selection-mode
    qt-view-set-sorting-enabled
    qt-widget-close
    qt-widget-create
    qt-widget-resize
    qt-widget-set-cursor
    qt-widget-set-minimum-width
    qt-widget-set-tooltip
    qt-widget-show
    qt-widget-unset-cursor
  )
  (import (chezscheme))

  (define (qt-action-create . args) (error 'qt-action-create "gerbil-qt not yet implemented"))
  (define (qt-action-set-shortcut . args) (error 'qt-action-set-shortcut "gerbil-qt not yet implemented"))
  (define (qt-action-set-tooltip . args) (error 'qt-action-set-tooltip "gerbil-qt not yet implemented"))
  (define (qt-app-create . args) (error 'qt-app-create "gerbil-qt not yet implemented"))
  (define (qt-app-destroy . args) (error 'qt-app-destroy "gerbil-qt not yet implemented"))
  (define (qt-app-exec . args) (error 'qt-app-exec "gerbil-qt not yet implemented"))
  (define (qt-app-set-style-sheet . args) (error 'qt-app-set-style-sheet "gerbil-qt not yet implemented"))
  (define (qt-check-box-checked . args) (error 'qt-check-box-checked "gerbil-qt not yet implemented"))
  (define (qt-check-box-create . args) (error 'qt-check-box-create "gerbil-qt not yet implemented"))
  (define (qt-combo-box-add-item . args) (error 'qt-combo-box-add-item "gerbil-qt not yet implemented"))
  (define (qt-combo-box-clear . args) (error 'qt-combo-box-clear "gerbil-qt not yet implemented"))
  (define (qt-combo-box-count . args) (error 'qt-combo-box-count "gerbil-qt not yet implemented"))
  (define (qt-combo-box-create . args) (error 'qt-combo-box-create "gerbil-qt not yet implemented"))
  (define (qt-combo-box-current-text . args) (error 'qt-combo-box-current-text "gerbil-qt not yet implemented"))
  (define (qt-combo-box-set-current-index . args) (error 'qt-combo-box-set-current-index "gerbil-qt not yet implemented"))
  (define (qt-date-edit-create . args) (error 'qt-date-edit-create "gerbil-qt not yet implemented"))
  (define (qt-date-edit-date-string . args) (error 'qt-date-edit-date-string "gerbil-qt not yet implemented"))
  (define (qt-date-edit-set-calendar-popup . args) (error 'qt-date-edit-set-calendar-popup "gerbil-qt not yet implemented"))
  (define (qt-date-edit-set-display-format . args) (error 'qt-date-edit-set-display-format "gerbil-qt not yet implemented"))
  (define (qt-dialog-accept . args) (error 'qt-dialog-accept "gerbil-qt not yet implemented"))
  (define (qt-dialog-create . args) (error 'qt-dialog-create "gerbil-qt not yet implemented"))
  (define (qt-dialog-exec . args) (error 'qt-dialog-exec "gerbil-qt not yet implemented"))
  (define (qt-dialog-reject . args) (error 'qt-dialog-reject "gerbil-qt not yet implemented"))
  (define (qt-dialog-set-title . args) (error 'qt-dialog-set-title "gerbil-qt not yet implemented"))
  (define (qt-disconnect-all . args) (error 'qt-disconnect-all "gerbil-qt not yet implemented"))
  (define (qt-file-dialog-open-directory . args) (error 'qt-file-dialog-open-directory "gerbil-qt not yet implemented"))
  (define (qt-form-layout-add-row . args) (error 'qt-form-layout-add-row "gerbil-qt not yet implemented"))
  (define (qt-form-layout-add-spanning-widget . args) (error 'qt-form-layout-add-spanning-widget "gerbil-qt not yet implemented"))
  (define (qt-form-layout-create . args) (error 'qt-form-layout-create "gerbil-qt not yet implemented"))
  (define (qt-hbox-layout-create . args) (error 'qt-hbox-layout-create "gerbil-qt not yet implemented"))
  (define (qt-label-create . args) (error 'qt-label-create "gerbil-qt not yet implemented"))
  (define (qt-layout-add-stretch . args) (error 'qt-layout-add-stretch "gerbil-qt not yet implemented"))
  (define (qt-layout-add-widget . args) (error 'qt-layout-add-widget "gerbil-qt not yet implemented"))
  (define (qt-line-edit-create . args) (error 'qt-line-edit-create "gerbil-qt not yet implemented"))
  (define (qt-line-edit-set-placeholder . args) (error 'qt-line-edit-set-placeholder "gerbil-qt not yet implemented"))
  (define (qt-line-edit-set-text . args) (error 'qt-line-edit-set-text "gerbil-qt not yet implemented"))
  (define (qt-line-edit-text . args) (error 'qt-line-edit-text "gerbil-qt not yet implemented"))
  (define (qt-list-widget-add-item . args) (error 'qt-list-widget-add-item "gerbil-qt not yet implemented"))
  (define (qt-list-widget-create . args) (error 'qt-list-widget-create "gerbil-qt not yet implemented"))
  (define (qt-list-widget-current-row . args) (error 'qt-list-widget-current-row "gerbil-qt not yet implemented"))
  (define (qt-list-widget-item-data . args) (error 'qt-list-widget-item-data "gerbil-qt not yet implemented"))
  (define (qt-list-widget-set-item-data . args) (error 'qt-list-widget-set-item-data "gerbil-qt not yet implemented"))
  (define (qt-main-window-add-toolbar . args) (error 'qt-main-window-add-toolbar "gerbil-qt not yet implemented"))
  (define (qt-main-window-create . args) (error 'qt-main-window-create "gerbil-qt not yet implemented"))
  (define (qt-main-window-menu-bar . args) (error 'qt-main-window-menu-bar "gerbil-qt not yet implemented"))
  (define (qt-main-window-set-central-widget . args) (error 'qt-main-window-set-central-widget "gerbil-qt not yet implemented"))
  (define (qt-main-window-set-status-bar-text . args) (error 'qt-main-window-set-status-bar-text "gerbil-qt not yet implemented"))
  (define (qt-main-window-set-title . args) (error 'qt-main-window-set-title "gerbil-qt not yet implemented"))
  (define (qt-menu-add-action . args) (error 'qt-menu-add-action "gerbil-qt not yet implemented"))
  (define (qt-menu-add-separator . args) (error 'qt-menu-add-separator "gerbil-qt not yet implemented"))
  (define (qt-menu-bar-add-menu . args) (error 'qt-menu-bar-add-menu "gerbil-qt not yet implemented"))
  (define (qt-message-box-critical . args) (error 'qt-message-box-critical "gerbil-qt not yet implemented"))
  (define (qt-message-box-information . args) (error 'qt-message-box-information "gerbil-qt not yet implemented"))
  (define (qt-message-box-warning . args) (error 'qt-message-box-warning "gerbil-qt not yet implemented"))
  (define (qt-on-clicked . args) (error 'qt-on-clicked "gerbil-qt not yet implemented"))
  (define (qt-on-return-pressed . args) (error 'qt-on-return-pressed "gerbil-qt not yet implemented"))
  (define (qt-on-triggered . args) (error 'qt-on-triggered "gerbil-qt not yet implemented"))
  (define (qt-on-view-clicked . args) (error 'qt-on-view-clicked "gerbil-qt not yet implemented"))
  (define (qt-on-view-double-clicked . args) (error 'qt-on-view-double-clicked "gerbil-qt not yet implemented"))
  (define (qt-plain-text-edit-create . args) (error 'qt-plain-text-edit-create "gerbil-qt not yet implemented"))
  (define (qt-plain-text-edit-set-read-only . args) (error 'qt-plain-text-edit-set-read-only "gerbil-qt not yet implemented"))
  (define (qt-plain-text-edit-set-text . args) (error 'qt-plain-text-edit-set-text "gerbil-qt not yet implemented"))
  (define (qt-push-button-create . args) (error 'qt-push-button-create "gerbil-qt not yet implemented"))
  (define (qt-sort-filter-proxy-create . args) (error 'qt-sort-filter-proxy-create "gerbil-qt not yet implemented"))
  (define (qt-sort-filter-proxy-set-source-model . args) (error 'qt-sort-filter-proxy-set-source-model "gerbil-qt not yet implemented"))
  (define (qt-spin-box-create . args) (error 'qt-spin-box-create "gerbil-qt not yet implemented"))
  (define (qt-spin-box-set-prefix . args) (error 'qt-spin-box-set-prefix "gerbil-qt not yet implemented"))
  (define (qt-spin-box-set-range . args) (error 'qt-spin-box-set-range "gerbil-qt not yet implemented"))
  (define (qt-spin-box-set-value . args) (error 'qt-spin-box-set-value "gerbil-qt not yet implemented"))
  (define (qt-spin-box-value . args) (error 'qt-spin-box-value "gerbil-qt not yet implemented"))
  (define (qt-splitter-add-widget . args) (error 'qt-splitter-add-widget "gerbil-qt not yet implemented"))
  (define (qt-splitter-create . args) (error 'qt-splitter-create "gerbil-qt not yet implemented"))
  (define (qt-splitter-set-sizes . args) (error 'qt-splitter-set-sizes "gerbil-qt not yet implemented"))
  (define (qt-standard-item-create . args) (error 'qt-standard-item-create "gerbil-qt not yet implemented"))
  (define (qt-standard-model-create . args) (error 'qt-standard-model-create "gerbil-qt not yet implemented"))
  (define (qt-standard-model-set-horizontal-header . args) (error 'qt-standard-model-set-horizontal-header "gerbil-qt not yet implemented"))
  (define (qt-standard-model-set-item . args) (error 'qt-standard-model-set-item "gerbil-qt not yet implemented"))
  (define (qt-standard-model-set-row-count . args) (error 'qt-standard-model-set-row-count "gerbil-qt not yet implemented"))
  (define (qt-table-view-create . args) (error 'qt-table-view-create "gerbil-qt not yet implemented"))
  (define (qt-table-view-hide-column . args) (error 'qt-table-view-hide-column "gerbil-qt not yet implemented"))
  (define (qt-table-view-set-column-width . args) (error 'qt-table-view-set-column-width "gerbil-qt not yet implemented"))
  (define (qt-tab-widget-add-tab . args) (error 'qt-tab-widget-add-tab "gerbil-qt not yet implemented"))
  (define (qt-tab-widget-create . args) (error 'qt-tab-widget-create "gerbil-qt not yet implemented"))
  (define (qt-tab-widget-set-current-index . args) (error 'qt-tab-widget-set-current-index "gerbil-qt not yet implemented"))
  (define (qt-text-browser-create . args) (error 'qt-text-browser-create "gerbil-qt not yet implemented"))
  (define (qt-text-browser-set-html . args) (error 'qt-text-browser-set-html "gerbil-qt not yet implemented"))
  (define (qt-toolbar-add-action . args) (error 'qt-toolbar-add-action "gerbil-qt not yet implemented"))
  (define (qt-toolbar-add-separator . args) (error 'qt-toolbar-add-separator "gerbil-qt not yet implemented"))
  (define (qt-toolbar-add-widget . args) (error 'qt-toolbar-add-widget "gerbil-qt not yet implemented"))
  (define (qt-toolbar-create . args) (error 'qt-toolbar-create "gerbil-qt not yet implemented"))
  (define (qt-toolbar-set-movable . args) (error 'qt-toolbar-set-movable "gerbil-qt not yet implemented"))
  (define (qt-vbox-layout-create . args) (error 'qt-vbox-layout-create "gerbil-qt not yet implemented"))
  (define (qt-view-last-clicked-row . args) (error 'qt-view-last-clicked-row "gerbil-qt not yet implemented"))
  (define (qt-view-set-alternating-row-colors . args) (error 'qt-view-set-alternating-row-colors "gerbil-qt not yet implemented"))
  (define (qt-view-set-edit-triggers . args) (error 'qt-view-set-edit-triggers "gerbil-qt not yet implemented"))
  (define (qt-view-set-model . args) (error 'qt-view-set-model "gerbil-qt not yet implemented"))
  (define (qt-view-set-selection-behavior . args) (error 'qt-view-set-selection-behavior "gerbil-qt not yet implemented"))
  (define (qt-view-set-selection-mode . args) (error 'qt-view-set-selection-mode "gerbil-qt not yet implemented"))
  (define (qt-view-set-sorting-enabled . args) (error 'qt-view-set-sorting-enabled "gerbil-qt not yet implemented"))
  (define (qt-widget-close . args) (error 'qt-widget-close "gerbil-qt not yet implemented"))
  (define (qt-widget-create . args) (error 'qt-widget-create "gerbil-qt not yet implemented"))
  (define (qt-widget-resize . args) (error 'qt-widget-resize "gerbil-qt not yet implemented"))
  (define (qt-widget-set-cursor . args) (error 'qt-widget-set-cursor "gerbil-qt not yet implemented"))
  (define (qt-widget-set-minimum-width . args) (error 'qt-widget-set-minimum-width "gerbil-qt not yet implemented"))
  (define (qt-widget-set-tooltip . args) (error 'qt-widget-set-tooltip "gerbil-qt not yet implemented"))
  (define (qt-widget-show . args) (error 'qt-widget-show "gerbil-qt not yet implemented"))
  (define (qt-widget-unset-cursor . args) (error 'qt-widget-unset-cursor "gerbil-qt not yet implemented"))
)
