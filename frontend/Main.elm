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
    { percent : String, donee : String, ether : String, txID : String }


init percent =
    ( { percent = percent
      , donee = ""
      , ether = ""
      , txID = ""
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
                [ div [] [ text (model.percent ++ "% donation") ]
                , Html.form [ onSubmit PayAndDonate ]
                    [ label []
                        [ text "Donate to"
                        , input [ placeholder "Ethereum address", onInput Donee ] []
                        ]
                    , label [] [ text "Pay", input [ onInput Ether ] [], text "Ether" ]
                    , button [{- type = submit? -}] [ text "Pay And Donate" ]
                    ]
                ]

        _ ->
            div [] [ text ("Paid. Transaction ID: " ++ model.txID) ]


subscriptions model =
    txID TxID
