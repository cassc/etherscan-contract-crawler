// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IMurakamiMoneyCatCoinBank is IERC721AUpgradeable {
    function mint(address to) external;

    event MoneyCatCoinBankBroken(uint256 indexed tokenId, address indexed user);
    event CoinAdded(
        uint256 indexed catTokenId,
        uint256 indexed coinTokenId,
        uint256 exp
    );
}