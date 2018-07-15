port module Main exposing (..)

import Payment exposing (Payment)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (..)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- port getPercent :


port payAndDonate :
    { payee : String
    , percent : String
    , donee : String
    , ether : String
    }
    -> Cmd msg


port paying : (() -> msg) -> Sub msg


port paid : (() -> msg) -> Sub msg


type alias Model =
    { percent : {- Maybe -} String
    , donee : String
    , ether : String
    , payment : Payment.Payment
    , payee : { address : String {- , name : String -} }
    }


init :
    { percent : {- Maybe -} String
    , payee :
        { address : String {- , name : String -} }
        -- , ether : Maybe String
    }
    -> ( Model, Cmd Msg )
init { percent, payee {- , ether -} } =
    ( { percent = percent
      , donee = ""
      , ether = ""
      , payment = Payment.Unpaid
      , payee = payee
      }
    , Cmd.none
    )


type Msg
    = {- Payee String
         | GetPercent
         |
      -}
      PayAndDonate
    | Ether String
    | Donee String
    | Paying ()
    | Paid ()


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        {- Payee payee ->
               ( { model | payee = payee }, Cmd.none )

           GetPercent ->
               ( model, getPercent model.payee )
        -}
        Ether ether ->
            ( { model | ether = ether }, Cmd.none )

        Donee donee ->
            ( { model | donee = donee }, Cmd.none )

        PayAndDonate ->
            ( model
              -- refactor: "Paying" after MetaMask window submitted, not before (needs web3.js v1 for PromiEvents);
            , {- case model.percent of
                 Nothing ->
                     Cmd.none

                 Just percent ->
              -}
              payAndDonate
                { payee = model.payee.address
                , percent = model.percent
                , donee = model.donee
                , ether = model.ether
                }
            )

        Paying _ ->
            ( { model | payment = Payment.Paying }, Cmd.none )

        Paid _ ->
            ( { model | payment = Payment.Paid }, Cmd.none )


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
        , case model.payment of
            Payment.Unpaid ->
                {- case model.percent of
                   Nothing ->
                       Html.form [ onSubmit GetPercent ]
                           [ p []
                               [ label []
                                   [ text ("Pay ")
                                   , input
                                       [ placeholder "Ethereum address"
                                       , pattern "0x[a-fA-F0-9]{40}"
                                       , title "0x followed by 40 characters from a to F, 0 to 9"
                                       , required True
                                       , onInput Payee
                                       ]
                                       []
                                   ]
                                 -- , label [] [ input [] [], text " Ether" ]
                               ]
                           ]

                   Just percent ->
                -}
                Html.form [ onSubmit PayAndDonate ]
                    [ p []
                        [ text ("Pay " ++ model.payee.address ++ " ")
                        , label []
                            [ input [ onInput Ether, type_ "number", Attr.min "0", step "any" ] []
                            , text " Ether"
                            ]
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
                p [] [ text "Paying..." ]

            Payment.Paid ->
                p [] [ text "Paid." ]
        ]


subscriptions model =
    Sub.batch [ paying Paying, paid Paid ]
