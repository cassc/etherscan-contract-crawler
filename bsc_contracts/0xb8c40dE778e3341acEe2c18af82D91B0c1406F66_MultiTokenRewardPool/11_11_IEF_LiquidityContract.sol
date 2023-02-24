// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEF_LiquidityContract {

    function giveRole(address wallet, uint256 _roleId) external;

    function revokeRole(address wallet, uint256 _roleId) external ;

    function renounceOwnership() external ;

    function transferOut(
        address _token,
        address _to,
        uint256 _value
    ) external ;
    function exchangeCoin(
        address token_0,
        address token_1,
        uint256 _amount
    ) external ;

    function setReserverConstant(uint256 _reserver_constant) external ;

    function setTaxId(uint256 _tax_Id) external;
    function getReserves()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    ;
     function getExchangeDetails()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    ;
}