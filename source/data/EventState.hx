package data;

enum EventState
{
    NONE;
    INTRO(event:IntroState);
}

enum IntroState
{
    START;
    END;
}