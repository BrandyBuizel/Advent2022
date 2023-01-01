package data;

enum EventState
{
    NONE;
    INTRO(event:IntroState);
    OUTRO(event:OutroState);
}

enum IntroState
{
    START;
    END;
}

enum OutroState
{
    START;
    PAN;
    END;
}