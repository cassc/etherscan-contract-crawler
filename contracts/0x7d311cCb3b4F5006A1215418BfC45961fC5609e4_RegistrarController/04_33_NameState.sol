pragma solidity >=0.8.4;

library NameState {
    enum State {
        UNKNOWN,
        INVALID_NAME,
        WHITELIST_NAME,
        RESERVATION_NAME,
        NOT_AVAILABLE_NAME,
        AVAILABLE_NAME
    }
}