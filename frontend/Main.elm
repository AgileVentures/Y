port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


port payAndDonate :
    { percent : String
    , donee : String
    , ether : String
    }
    -> Cmd msg


port txID : (String -> msg) -> Sub msg


type Msg
    = PayAndDonate
    | Ether String
    | Donee String
    | TxID String


type alias Model =
    { percent : String
    , donee : String
    , ether : String
    , txID : String
    , payee : String
    }


init : { percent : String, payee : String, ether : String } -> ( Model, Cmd Msg )
init { percent, payee, ether } =
    ( { percent = percent
      , donee = ""
      , ether = ether
      , txID = ""
      , payee = payee
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Ether ether ->
            ( { model | ether = ether }, Cmd.none )

        Donee donee ->
            ( { model | donee = donee }, Cmd.none )

        PayAndDonate ->
            ( model
            , payAndDonate
                { percent = model.percent
                , donee = model.donee
                , ether = model.ether
                }
            )

        TxID txID ->
            ( { model | txID = txID }, Cmd.none )


view model =
    case model.txID of
        "" ->
            div []
                [ div [] []
                , Html.form [ onSubmit PayAndDonate ]
                    [ p []
                        [ text ("Pay " ++ model.payee ++ " " ++ model.ether ++ " Ether")
                        , label []
                            [ text (", donating " ++ model.percent ++ "% to ")
                            , input [ placeholder "Ethereum address", pattern "0x[a-fA-F0-9]{40}", title "0x followed by 40 characters from a to F, 0 to 9", required True, onInput Donee ] []
                            ]
                        , text ". "
                        , input [ type_ "submit" ] []
                        ]
                    ]
                ]

        _ ->
            div [] [ text ("Paid. Transaction ID: " ++ model.txID) ]


subscriptions model =
    txID TxID
