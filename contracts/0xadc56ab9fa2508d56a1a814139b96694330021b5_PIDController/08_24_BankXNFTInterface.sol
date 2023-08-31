// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface BankXInterface {

    function balanceOf(address account) external view returns (uint256);

    function pool_mint(address _entity, uint _amount) external;

    function pool_burn_from(address _entity, uint _amount) external;

    function genesis_supply() external returns (uint);

    function totalSupply() external view returns (uint);

    function updateTVLReached() external;

}