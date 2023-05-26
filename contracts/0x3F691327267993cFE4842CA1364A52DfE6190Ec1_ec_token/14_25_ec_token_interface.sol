pragma solidity ^0.8.0;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


interface ec_token_interface {

    struct TKS { // Token Kitchen Sink
        uint256     _mintPosition;
        uint256     _ts1;
        uint256     _ts2;
        bool        _randomReceived;
        bool        _secondReceived;
        uint256     _randomCL;
        uint256     _randomCL2;
        bool        _lockTillSaleEnd;
    }

    function setAllowed(address _addr, bool _state) external;

    function permitted(address) external view returns (bool);

    function mintCards(uint256 numberOfCards, address recipient) external;

    function tellEverything() external view returns (TKS memory);

}