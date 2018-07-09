port module Main exposing (..)

import Payment exposing (Payment)
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


port paying : (() -> msg) -> Sub msg


port paid : (() -> msg) -> Sub msg


type Msg
    = PayAndDonate
    | Ether String
    | Donee String
    | Paying ()
    | Paid ()


type alias Model =
    { percent : String
    , donee : String
    , ether : String
    , payment : Payment.Payment
    , payee : String
    }


init : { percent : String, payee : String, ether : String } -> ( Model, Cmd Msg )
init { percent, payee, ether } =
    ( { percent = percent
      , donee = ""
      , ether = ether
      , payment = Payment.Unpaid
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
              -- refactor: "Paying" after MetaMask window submitted, not before (needs web3.js v1 for PromiEvents);
            , payAndDonate
                { percent = model.percent
                , donee = model.donee
                , ether = model.ether
                }
            )

        Paying _ ->
            ( { model | payment = Payment.Paying }, Cmd.none )

        Paid _ ->
            ( { model | payment = Payment.Paid }, Cmd.none )


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
        , case model.payment of
            Payment.Unpaid ->
                Html.form [ onSubmit PayAndDonate ]
                    [ p []
                        [ text ("Pay " ++ model.payee ++ " " ++ model.ether ++ " Ether")
                        , label []
                            [ text (", donating " ++ model.percent ++ "% to ")
                            , input
                                [ placeholder "Ethereum address"
                                , pattern "0x[a-fA-F0-9]{40}"
                                , title "0x followed by 40 characters from a to F, 0 to 9"
                                , required True
                                , onInput Donee
                                ]
                                []
                            ]
                        , text ". "
                        , input [ type_ "submit" ] []
                        ]
                    ]

            Payment.Paying ->
                p [] [ text "Paying." ]

            Payment.Paid ->
                p [] [ text "Paid." ]
        ]


subscriptions model =
    Sub.batch [ paying Paying, paid Paid ]
