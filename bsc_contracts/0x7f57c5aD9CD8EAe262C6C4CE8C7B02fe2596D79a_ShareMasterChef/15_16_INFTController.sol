// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface INFTController {
    function getBoostRate(address token, uint tokenId) external view returns (uint boostRate);

    function isWhitelistedNFT(address token) external view returns (bool);
}