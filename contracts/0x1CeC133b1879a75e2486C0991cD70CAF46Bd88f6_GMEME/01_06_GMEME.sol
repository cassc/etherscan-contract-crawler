// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/access/Ownable.sol";

contract GMEME is ERC20, Ownable {
    uint256 private constant TOTAL_SUPPLY = 1000000000 * 10**18;
    uint256 private constant TEAM_ALLOCATION = TOTAL_SUPPLY * 10 / 1000;
    uint256 private constant CEX_ALLOCATION = TOTAL_SUPPLY * 50 / 1000;
    uint256 private constant NFT_ALLOCATION = TOTAL_SUPPLY * 510 / 1000;

    constructor(
        address teamWallet,
        address cexWallet,
        address nftCommunityWallet
    ) ERC20("GMEME", "GMEME") {
        uint256 teamTokens = 10000000 * 10**decimals(); // 1% for the team
        uint256 cexTokens = 50000000 * 10**decimals(); // 5% for CEX listing
        uint256 nftCommunityTokens = 510000000 * 10**decimals(); // 51% for NFT community

        _mint(teamWallet, teamTokens);
        _mint(cexWallet, cexTokens);
        _mint(nftCommunityWallet, nftCommunityTokens);

        // The remaining 43% of the supply goes to the liquidity pool
        _mint(msg.sender, 430000000 * 10**decimals());
}

    function renounceOwnership() public virtual onlyOwner override {
        address currentOwner = owner();
        transferOwnership(address(0));
        emit OwnershipRenounced(currentOwner);
    }

    event OwnershipRenounced(address indexed previousOwner);
}