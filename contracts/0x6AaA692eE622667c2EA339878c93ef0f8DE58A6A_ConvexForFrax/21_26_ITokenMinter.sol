// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

// Not a complete interface, but should have what we need
interface ITokenMinter {
    function minted(address arg0, address arg1) external view returns (uint256);

    function mint(address gauge_addr) external;
}
/* solhint-enable */