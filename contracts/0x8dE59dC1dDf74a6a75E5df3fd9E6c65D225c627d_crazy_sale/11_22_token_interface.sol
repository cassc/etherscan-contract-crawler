pragma solidity ^0.8.0;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


interface token_interface {

    struct TKS { // Token Kitchen Sink
        uint256     _mintPosition;
        uint256     _ts1;
        string      _pre_reveal_uri;
        bool        _lockTillSaleEnd;
        bool        _secondReceived;
    }

    function setAllowed(address _addr, bool _state) external;

    function permitted(address) external view returns (bool);

    function mintCards(uint256 numberOfCards, address recipient) external;

    function tellEverything() external view returns (TKS memory);

}