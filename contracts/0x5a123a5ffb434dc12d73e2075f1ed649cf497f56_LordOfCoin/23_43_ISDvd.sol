// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISDvd is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function setMinter(address account, bool value) external;

    function setNoFeeAddress(address account, bool value) external;

    function setPairAddress(address _pairAddress) external;

    function snapshot() external returns (uint256);

    function syncPairTokenTotalSupply() external returns (bool isPairTokenBurned);

}