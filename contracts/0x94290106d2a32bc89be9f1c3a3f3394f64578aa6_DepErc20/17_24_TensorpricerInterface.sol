// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract TensorpricerInterface {
    /// @notice Indicator that this is a Tensorpricer contract (for inspection)
    bool public constant isTensorpricer = true;

    uint public fxMult = 100;   // tmp variable

    /*** Supported functions ***/
    function mintAllowed(address levToken, address minter) virtual external returns (uint);

    function redeemAllowed(address levToken, address redeemer, uint redeemTokens) virtual external returns (uint);

    function transferAllowed(address levToken, address src, address dst, uint transferTokens) virtual external returns (uint);

    function getFx(string memory fxname) virtual external view returns (uint);

    function _setMintPausedLev(address levToken, bool state) virtual public returns (bool);

    function _setRedeemPausedLev(address levToken, bool state) virtual public returns (bool);

    function setFxMult(uint mult) virtual external; // tmp function to be removed after testing
}