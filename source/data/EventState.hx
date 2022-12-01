package data;

enum EventState
{
    NoEvent;
    Intro(event:IntroState);
    LuciaDay(event:LuciaDayState);
}

enum IntroState
{
    Started;
    Finished;
}

enum LuciaDayState
{
    Started;
    Finding;
    Present;
}