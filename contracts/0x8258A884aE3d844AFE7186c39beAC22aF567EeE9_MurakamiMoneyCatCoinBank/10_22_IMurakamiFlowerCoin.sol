// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IMurakamiFlowerCoin is IERC721AUpgradeable {
    function getEXP(uint256 tokenId) external view returns (uint256);

    event LuckyCatCoinBankBroken(uint256 indexed tokenId, address indexed user);
}