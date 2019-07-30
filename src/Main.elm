module Main exposing (main)

import Browser
import Browser.Events
import Json.Decode as Decode
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias Model =
    { ball : Ball
    , rightPaddle : Paddle
    , leftPaddle : Paddle
    }


type alias Ball =
    { x : Int
    , y : Int
    , radius : Int
    , horizSpeed : Int
    }


type Paddle
    = RightPaddle PaddleInfo
    | LeftPaddle PaddleInfo


type alias PaddleInfo =
    { x : Int
    , y : Int
    , width : Int
    , height : Int
    }


type Msg
    = OnAnimationFrame Float
    | KeyDown String


type alias Flags =
    ()


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { ball = initBall
      , rightPaddle = RightPaddle <| initPaddle 480
      , leftPaddle = LeftPaddle <| initPaddle 10
      }
    , Cmd.none
    )


initBall : Ball
initBall =
    { x = 250
    , y = 250
    , radius = 10
    , horizSpeed = 4
    }


initPaddle : Int -> PaddleInfo
initPaddle initialX =
    { x = initialX
    , y = 225
    , width = 10
    , height = 50
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnAnimationFrame timeDelta ->
            let
                ball =
                    model.ball

                shouldBounce =
                    shouldBallBounce model.rightPaddle model.ball
                        || shouldBallBounce model.leftPaddle model.ball

                horizSpeed =
                    if shouldBounce then
                        ball.horizSpeed * -1

                    else
                        ball.horizSpeed

                updatedBall =
                    { ball
                        | x = ball.x + horizSpeed
                        , horizSpeed = horizSpeed
                    }
            in
            ( { model | ball = updatedBall }, Cmd.none )

        KeyDown keyString ->
            let
                _ =
                    Debug.log "key pressed" keyString
            in
            ( model, Cmd.none )


shouldBallBounce : Paddle -> Ball -> Bool
shouldBallBounce paddle ball =
    case paddle of
        LeftPaddle { x, y, width, height } ->
            (ball.x - ball.radius <= x + width)
                && (ball.y >= y)
                && (ball.y <= y + height)

        RightPaddle { x, y, height } ->
            (ball.x + ball.radius >= x)
                && (ball.y >= y)
                && (ball.y <= y + height)


view : Model -> Svg.Svg Msg
view { ball, rightPaddle, leftPaddle } =
    svg
        [ width "500"
        , height "500"
        , viewBox "0 0 500 500"
        , Svg.Attributes.style "background: #efefef"
        ]
        [ viewBall ball
        , viewPaddle rightPaddle
        , viewPaddle leftPaddle
        ]


viewBall : Ball -> Svg.Svg Msg
viewBall { x, y, radius } =
    circle
        [ cx <| String.fromInt x
        , cy <| String.fromInt y
        , r <| String.fromInt radius
        ]
        []


viewPaddle : Paddle -> Svg.Svg Msg
viewPaddle paddle =
    let
        paddleInfo =
            case paddle of
                LeftPaddle info ->
                    info

                RightPaddle info ->
                    info
    in
    rect
        [ x <| String.fromInt paddleInfo.x
        , y <| String.fromInt paddleInfo.y
        , width <| String.fromInt paddleInfo.width
        , height <| String.fromInt paddleInfo.height
        ]
        []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta OnAnimationFrame
        , Browser.Events.onKeyDown (Decode.map KeyDown keyDecoder)
        ]


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string
