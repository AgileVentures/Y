module Main exposing (..)

import Html exposing (text)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init percent =
    ( percent, Cmd.none )


update message model =
    ( model, Cmd.none )


view model =
    text model


subscriptions model =
    Sub.none
