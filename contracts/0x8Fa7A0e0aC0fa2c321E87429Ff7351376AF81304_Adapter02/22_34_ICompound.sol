// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ICToken is IERC20 {
    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);
}

abstract contract ICEther is ICToken {
    function mint() external payable virtual;
}

abstract contract ICERC20 is ICToken {
    function mint(uint256 mintAmount) external virtual returns (uint256);

    function underlying() external view virtual returns (address token);
}