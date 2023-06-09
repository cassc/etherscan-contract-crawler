// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IXEqbToken {
    function convert(uint256 amount) external;

    function convertTo(uint256 amount, address to) external;

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event Convert(address indexed from, address to, uint256 amount);
    event UpdateRedeemSettings(
        uint256 minRedeemRatio,
        uint256 maxRedeemRatio,
        uint256 minRedeemDuration,
        uint256 maxRedeemDuration
    );
    event SetTransferWhitelist(address account, bool add);
    event Redeem(
        address indexed userAddress,
        uint256 xEqbAmount,
        uint256 eqbAmount,
        uint256 duration
    );
    event FinalizeRedeem(
        address indexed userAddress,
        address indexed receiverAddress,
        uint256 xEqbAmount,
        uint256 eqbAmount
    );
    event CancelRedeem(address indexed userAddress, uint256 xEqbAmount);
    event Lock(
        address indexed _userAddress,
        uint256 _xEqbAmount,
        uint256 _eqbAmount,
        uint256 _weeks
    );
}