require! {
    \react : React
    \react-router : {Link}
    \react-dom : ReactDOM
    \react-timer-mixin : TimerMixin
    \../actions/mainAction : {actions, store}
}

# props
# data
# dataOwner:[ref,dataKey]
class MyComponent extends React.Component
    componentWillMount: ->
        if @props.dataOwner?
            [@dataOwner, @dataKey] = @props.dataOwner
            [a,b] = @dataKey.split \.
            if b
                value = @dataOwner.state[a][b]
            else
                value = @dataOwner.state[@dataKey]
            @set-state data:value
            @onChange = (data) ~>
                @state.data = data
                if b
                    @dataOwner.state?[a][b] = data
                    @dataOwner.forceUpdate!
                else
                if @dataOwner.state?[@dataKey] != data
                    @dataOwner.set-state "#{@dataKey}":data
        else if @props.data?
            @set-state @props{data}
            @onChange = @props.onChange

    set-data: ->
        @set-state data:it
        if this.onChange then this.onChange it

class MyIdInput extends MyComponent
    ->
        super ...
        @state =
            loading: false
            error: false
            done: false
            name: ""
            delete: false
        @errorStyle =
            backgroundColor: \#fff6f6
            borderColor: \#e0b4b4
            color: \#9f3a38
            boxShadow: \none
        @successStyle =
            backgroundColor: \#f6fff6
            borderColor: \#b4e0b9
            color: \#389f46
            boxShadow: \none

    componentDidMount: ->
        if @props.data == undefined
            @input.value = ""
        else
            @input.value = @props.data.to-string!
    componentDidUpdate: ->
        @componentDidMount!
        #@input.value = @props.data


    btnClick: ~>
        if @state.delete
            @set-state delete: false, done: false, name:""
            @input.value = ""
            @set-data undefined
            return
        @set-state loading:true
        @set-data @input.value
        $.ajax do
            method: \POST
            data: _id:@input.value
            url: \/api/find-one-name
            success: ~>
                @set-state error: false, done: true, name: it.name, delete: true, loading: false
            error: ~>
                toastr.error "Object not found."
                @set-state error:true, loading: false

    render: ->
        if @state.loading
            inputStyle = {}
        else if @state.error
            inputStyle = @errorStyle
        else if @state.done
            inputStyle = @successStyle
        else inputStyle = {}
        ``<div className={"ui right labeled left icon input"+(this.state.loading?" loading":"")}>
          <i className="file image outline icon"></i>
          <input type="text" ref={(v)=>this.input = v} placeholder="Enter ObjectID" style={inputStyle} />
          <a className="ui tag label" onClick={this.btnClick}>
             {this.state.delete?"(name:"+this.state.name+") Delete":"Add Image"}
          </a>
        </div>
        ``
# props
# text
class MyCheckbox extends MyComponent
    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @cb = jq.checkbox do
            onChecked: ~> @set-data true
            onUnchecked: ~> @set-data false
        @cb.checkbox if @state.data then "set checked" else "set unchecked"

    shouldComponentUpdate: (next-props, next-state)->
        if next-props.data == undefined then return false
        @cb.checkbox if next-props.data then "set checked" else "set unchecked"
        return false

    render: ->
        ``<div className="ui checkbox">
          <input type="checkbox" />
          <label>{this.props.text}</label>
        </div>``

# props
# options:[{value,text}]
# defaultText
class MyDropdown extends MyComponent
    componentDidMount: ->
        jq = $ ReactDOM.findDOMNode this
        @dd = jq.dropdown do
            onChange: @onChange
        @dd.dropdown 'set selected', @state.data

    shouldComponentUpdate: (next-props, next-state)->
        if next-props.data and @props.data != next-props.data
            @dd.dropdown 'set selected', next-props.data
        return false

    render: ->
        console.log \dd-render
        optList = for opt in @props.options
            opt.text ?= opt.value
            ``<div className="item" data-value={opt.value} key={opt.value}>{opt.text}</div>
            ``
        ``<div className="ui selection dropdown">
          <input type="hidden" name={this.props.name}/>
          <i className="dropdown icon"></i>
          <div className="default text">{this.props.defaultText}</div>
          <div className="menu">
            {optList}
          </div>
        </div>``

module.exports = {
    React, Link, ReactDOM, TimerMixin, actions, store
    MyComponent, MyCheckbox, MyDropdown, MyIdInput
}
