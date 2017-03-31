require! {
    \./app/models : {User}
    \./config
    \express
    \morgan
    \body-parser
    \compression
    \validator

    \express-session : \session
    \passport
    \passport-local
}

app = express!
    ..use morgan \dev
    ..use compression!
    # parse json in body
    ..use body-parser.json limit:\5mb
    # parse urlencoded in body
    # set limit to fix bug
    # <http://stackoverflow.com/questions/19917401/node-js-express-request-entity-too-large>
    ..use body-parser.urlencoded extended:false, limit:\5mb
    ..use session secret:config.secret, resave: true, saveUninitialized: true
    ..use passport.initialize!
    ..use passport.session!

passport.serialize-user (user, done) ->
    done null, user.id
passport.deserialize-user (id, done) ->
    User.find-by-id id, (err,user) -> done err,user

passport.use \local-signup, new passport-local.Strategy do
    *   username-field: \email
        password-field: \password
        pass-req-to-callback: true
    (req, email, password, done) ->
        # User.findOne wont fire unless data is sent back
        <- process.next-tick
        User.find-one 'local.email':email, (err, user) ->
            if err then return done err
            if user then
                return done null, false, message:"The email exist!"
            if typeof req.body.name != \string
                return done null, false, message:"Invalid name."
            user = new User do
                local:
                    email: email
                    password: password
                profile:
                    name: req.body.name
            user.local.password = user.generate-hash password
            user.save ->
                if err then throw err
                else
                    done null, user

passport.use \local-login, new passport-local.Strategy do
    *   username-field: \email
        password-field: \password
        pass-req-to-callback: true
    (req, email, password, done) ->
        (err, user) <- User.find-one 'local.email':email, _
        if err then return done err
        if !user then
            return done null, false, message:'User not found.'
        if !user.valid-password password then
            return done null, false, message:'Invalid user or password.'
        return done null, user

module.exports = app
