pragma solidity ^0.8.15;

interface BBTy {
    enum GUARDMODE  { PAUSE, RUN, TURBO } 
    enum TOKENSTATE { OK, LOCKED, RECLIAMED }
    enum REPLYACT   { NONE, UNLOCK, LOCK, RECLAIM, JUDGE, GUARD, UNGUARD }
    enum TOKENOP    { GUARD, UNGUARD, LOCK, UNLOCK }
    enum SAFEIDX    { NONE, SAFE, UNSAFE }
}