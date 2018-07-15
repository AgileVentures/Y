port module Main exposing (..)

import Percent exposing (..)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (..)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { percent : String
    , status : Percent.Percent
    , address : String
    , host : String
    }


port setPercent : String -> Cmd msg


port settingPercent : (() -> msg) -> Sub msg


port percentSet : ({ address : String, host : String } -> msg) -> Sub msg


init : ( Model, Cmd Msg )
init =
    ( { percent = ""
      , status = Percent.Unset
      , address = ""
      , host = ""
      }
    , Cmd.none
    )


type Msg
    = Percent String
    | SetPercent
    | SettingPercent ()
    | PercentSet { address : String, host : String }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Percent percent ->
            ( { model | percent = percent }, Cmd.none )

        SetPercent ->
            ( model, setPercent model.percent )

        SettingPercent _ ->
            ( { model | status = Percent.Setting }, Cmd.none )

        PercentSet { address, host } ->
            ( { model | status = Percent.Set, address = address, host = host }, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "display", "flex" )
            , ( "justify-content", "center" )
            , ( "align-items", "center" )
            , ( "flex-direction", "column" )
            , ( "font-family", "sans-serif" )
            ]
        ]
        [ header [] [ h1 [] [ text "Y" ] ]
        , case model.status of
            Unset ->
                Html.form [ onSubmit SetPercent ]
                    [ p []
                        [ label []
                            [ text "Donate "
                            , input
                                [ type_ "number"
                                , Attr.min "0"
                                , Attr.max "100"
                                , Attr.step "any"
                                , onInput Percent
                                ]
                                []
                            , text " %. "
                            ]
                        , input [ type_ "submit" ] []
                        ]
                    ]

            Setting ->
                p [] [ text "Setting..." ]

            Set ->
                p []
                    [ p [] [ text "Set." ]
                    , p [] [ a [ href (model.host ++ "/pay/?payeeAddress=" ++ model.address) ] [ text "Payment link" ] ]
                    ]
        ]


subscriptions model =
    Sub.batch [ settingPercent SettingPercent, percentSet PercentSet ]
