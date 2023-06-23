// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IDistributor is IERC165 {
    function distribute(IERC20 token, uint256 amount) external;
}