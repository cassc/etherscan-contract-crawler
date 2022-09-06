// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity ^0.8.0;

interface IKaijuMartRedeemable is IERC165 {
    function kmartRedeem(uint256 lotId, uint32 amount, address to) external;
}