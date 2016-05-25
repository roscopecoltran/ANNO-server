require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common


require! {
    \./../models/Object : my-object
    \./Breadcrumb
}

module.exports = class Guider extends React.Component
    ->
        super ...
        @state =
            *   displayType: \grid # grid list block
                ajaxing: false
                select-all-state: false
                # modal type, edit or add
                modalType: \add

        store.connect-to-component this, [
            \currentItem
        ]

    componentDidMount: ->
        self = this
        #dialog = $ \#addModal .dialog do
        #    auto-open: false
        #    modal: true
        dialog = $ \#addModal
        dialog.modal detachable:false

        del-dialog = $ \#delModal
        del-dialog.modal do
            detachable:false
            on-approve: ~>
                {selects} = store.get-state!
                actions.deleteItems selects


        $ \#addItemBtn .click ~>
            @set-state modalType:\add
            dialog.modal \show

        $ \#editItemBtn .click ~>
            {selects} = store.get-state!
            ids = Object.keys(selects)
            if ids.length == 0
                item = @state.currentItem
            else if ids.length != 1
                toastr.error "Please select only one item."
                return
            else
                item = store.get-state!.items[ids[0]]
            for k,v of item
                # attribute selector
                dom = addItemForm.find "input[name='#{k}']"
                dom.val(v)

            @set-state modalType:\edit
            @edit-id = item._id
            dialog.modal \show

        $ \#delItemBtn .click ->
            del-dialog.modal \show

        $ \#selectAllBtn .click ->
            self.set-state select-all-state: !self.state.select-all-state
            if self.state.select-all-state
                actions.selectShowed!
            else
                actions.resetSelects!

        addItemForm = $ \#addItemForm
        addItemForm.submit (e) ~>
            e.prevent-default!
            inputs = addItemForm.find \input
            values = {}
            for input in inputs
                values[input.name] = $(input).val!

            if self.state.modalType == \edit
                id = @edit-id
                unless id? then return
                values._id = id
            else
                fid = store.get-state!.fatherId
                if fid then values.parent = fid
            self.set-state ajaxing: true
            $.ajax do
                method: \POST
                url: \/api/new-object
                data: values
                error: ->
                    toastr.error it.response-text
                success: ->
                    toastr.success it
                    dialog.modal \hide
                    addItemForm[0].reset!
                    actions.fetchContent!
                complete: ->
                    self.set-state ajaxing: false

    render: ->
        mainDescription = @state.currentItem?.description
        unless mainDescription? then mainDescription=\Home
        self = this
        displayBar = [ \grid \list \block ].map (it) ->
            ``<a
            className={"ui "+ (it==self.state.displayType?"active":"") +" item"}
            onClick={function(){self.setState({displayType:it})}}
            key={it}
            ><i className={it+" layout icon"}></i></a>
            ``
        availItems = []
        for key of my-object.tree
            if my-object.tree[key] == String
                availItems.push ``<div className="field" key={key}>
                  <label>{key}</label>
                  <input type="text" name={key} placeholder={key}/>
                </div>
                ``

        delModal = ``<div className="ui modal" id="delModal">
            <i className="close icon"></i>
            <div className="header">
                Delete Item
            </div>
            <div className="content">
                Are you sure you delete those items?
            </div>
            <div className="actions">
                <div className="ui approve button">OK</div>
                <div className="ui cancel button">Cancel</div>
            </div>
        </div>
        ``

        ``<div>
        {delModal}
        <div className="ui modal" id="addModal">
            <i className="close icon"></i>
            <div className="header">
                New Item
            </div>
            <div className="content">
                <form className={self.state.ajaxing?"ui loading form":"ui form"} id="addItemForm">

                    {availItems}

                    <button className="ui button" type="submit">Submit</button>
                </form>
            </div>
        </div>

            <div className="ui container">

                <div className="ui right floated small menu">
                    {displayBar}
                </div>

                <div className="ui right floated small menu">
                    <a className="ui item" id="selectAllBtn"><i className=
                    {self.state.selectAllState?"check circle icon":"check circle outline icon"}></i></a>
                    <a className="ui item" id="addItemBtn"><i className="green add circle icon"></i></a>
                    <a className="ui item" id="delItemBtn"><i className="red minus circle icon"></i></a>
                    <a className="ui item" id="editItemBtn"><i className="edit icon"></i></a>
                </div>

                <Breadcrumb/>

            </div>
            <div className="ui fitted hidden clearing divider"></div>
            <div className="ui vertical segment">
                <big>{mainDescription}</big>
            </div>
        </div>
        ``