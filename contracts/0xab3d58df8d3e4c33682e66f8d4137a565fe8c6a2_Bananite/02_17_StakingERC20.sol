//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainScoutsExtension.sol";
import "./IUtilityERC20.sol";
import "./ChainScoutMetadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./Rng.sol";

abstract contract StakingERC20 is
    ChainScoutsExtension,
    IUtilityERC20,
    ERC20Burnable
{
    Rng internal rng = RngLibrary.newRng();

    mapping(uint256 => uint256) public lastClaimTime;
    mapping(uint256 => address) public tokenIdOwners;
    mapping(address => mapping(uint256 => uint256)) public ownerTokenIds;
    mapping(address => uint256) public numberTokensStaked;

    function adminMint(address owner, uint256 amountWei)
        external
        override
        onlyAdmin
    {
        super._mint(owner, amountWei);
    }

    function adminSetTokenTimestamp(uint256 tokenId, uint256 timestamp)
        external
        override
        onlyAdmin
    {
        lastClaimTime[tokenId] = timestamp;
    }

    function burn(address owner, uint256 amountWei) external override {
        require(
            chainScouts.isAdmin(msg.sender) || msg.sender == owner,
            "must be admin or owner"
        );
        super._burn(owner, amountWei);
    }

    function calculateTokenRewards(Rng memory rn, uint256 tokenId)
        public
        view
        returns (uint256 rewards)
    {
        rewards = calculateTokenRewardsOverTime(
            rn,
            tokenId,
            block.timestamp > lastClaimTime[tokenId] &&
                lastClaimTime[tokenId] > 0
                ? block.timestamp - lastClaimTime[tokenId]
                : 0
        );
    }

    function calculateTokenRewardsOverTime(
        Rng memory,
        uint256,
        uint256 secondsElapsedSinceLastClaim
    ) public view virtual returns (uint256) {
        return (secondsElapsedSinceLastClaim * 1 ether) / 1 days;
    }

    function claimRewards() external virtual override whenEnabled {
        Rng memory rn = rng;
        uint count = 0;

        for (uint256 i = 0; i < numberTokensStaked[msg.sender]; ++i) {
            uint256 tid = ownerTokenIds[msg.sender][i];
            count += calculateTokenRewards(rn, tid);
            lastClaimTime[tid] = block.timestamp;
        }

        if (count > 0) {
            super._mint(msg.sender, count);
        }

        rng = rn;
    }

    function stake(uint256[] calldata tokenIds) public virtual override whenEnabled {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(
                chainScouts.canAccessToken(msg.sender, tokenId),
                "ChainScoutsExtension: you don't own the token"
            );
            require(
                tokenIdOwners[tokenId] == address(0),
                "StakingERC20: This token is already staked"
            );

            address owner = chainScouts.ownerOf(tokenId);

            lastClaimTime[tokenId] = block.timestamp;
            tokenIdOwners[tokenId] = owner;
            ownerTokenIds[owner][numberTokensStaked[owner]] = tokenId;
            numberTokensStaked[owner]++;
            chainScouts.adminTransfer(owner, address(this), tokenId);
        }
    }

    function unstake(uint256[] calldata tokenIds) public virtual whenEnabled {
        Rng memory rn = rng;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint tokenId = tokenIds[i];
            require(
                tokenIdOwners[tokenId] == msg.sender,
                "StakingERC20: You don't own this token"
            );

            uint256 rewards = calculateTokenRewards(rn, tokenId);
            if (rewards > 0) {
                super._mint(msg.sender, rewards);
            }

            tokenIdOwners[tokenId] = address(0);
            for (uint256 j = 0; j < numberTokensStaked[msg.sender]; ++j) {
                if (ownerTokenIds[msg.sender][j] == tokenId) {
                    uint256 lastIndex = numberTokensStaked[msg.sender] - 1;
                    ownerTokenIds[msg.sender][j] = ownerTokenIds[msg.sender][
                        lastIndex
                    ];
                    delete ownerTokenIds[msg.sender][lastIndex];
                    break;
                }
            }
            numberTokensStaked[msg.sender]--;
            chainScouts.adminTransfer(address(this), msg.sender, tokenId);
        }

        rng = rn;
    }
}