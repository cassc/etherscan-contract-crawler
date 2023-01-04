// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface CustomNFT is IERC721EnumerableUpgradeable {
    function receiveNFT(address _to, uint256 _id) external;
}