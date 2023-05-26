// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAcorneCommon {
    struct Acorne {
        string name;
        string description;
        uint256 commission;
    }

    struct Commission {
        uint256 value;
        uint256 lastClaimedAt;
        address lastClaimedAddress;
    }

    struct MintState {
        bool isPublicOpen;
        uint256 liveAt;
        uint256 expiresAt;
        bytes32 frgMerkleRoot;
        bytes32 ethMerkleRoot;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        bool hasMinted;
    }

    event Claim(uint256 tokenId, address owner, uint256 amount);

    event CommissionAdded(uint256 tokenId, uint256 value);

    event CommissionRemoved(uint256 tokenId, uint256 value);

    event CommissionVerified(uint256 tokenId, uint256 value);

    event CommissionManuallySet(address sender, uint256 tokenId, uint256 value);

    event DepositERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    );

    event Deposit(address from, address to, uint256 amount);

    event Withdraw(address from, address to, uint256 amount);
}