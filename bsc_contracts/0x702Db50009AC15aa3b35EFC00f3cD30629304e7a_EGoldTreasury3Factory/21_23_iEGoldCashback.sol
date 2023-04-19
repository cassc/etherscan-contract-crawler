//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iEGoldCashback is IERC20 {

    function addCashback( address _addr , uint256 _cashback ) external;

    function fetchCashback(  uint256 _addr ) external view returns ( uint256 );

    function burn(address _to, uint256 _value) external returns (bool);

}