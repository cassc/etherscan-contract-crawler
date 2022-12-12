// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @dev contract to manage NFT challenges
 */
import "./NFTChallenge.sol";
import "./ERC20Challenge.sol";

contract ExchangeChallenge is ERC20Challenge, NFTChallenge {
    constructor(address token) NFTChallenge(token) {}
}