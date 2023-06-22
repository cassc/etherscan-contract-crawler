//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface IERC721M is IERC721AQueryable {
    error CannotIncreaseMaxMintableSupply();
    error CannotUpdatePermanentBaseURI();
    error CosignerNotSet();
    error CrossmintAddressNotSet();
    error CrossmintOnly();
    error GlobalWalletLimitOverflow();
    error InsufficientStageTimeGap();
    error InvalidCosignSignature();
    error InvalidProof();
    error InvalidStage();
    error InvalidStageArgsLength();
    error InvalidStartAndEndTimestamp();
    error NoSupplyLeft();
    error NotEnoughValue();
    error NotMintable();
    error Mintable();
    error StageSupplyExceeded();
    error TimestampExpired();
    error WalletGlobalLimitExceeded();
    error WalletStageLimitExceeded();
    error WithdrawFailed();

    struct MintStageInfo {
        uint80 price;
        uint32 walletLimit; // 0 for unlimited
        bytes32 merkleRoot; // 0x0 for no presale enforced
        uint24 maxStageSupply; // 0 for unlimited
        uint64 startTimeUnixSeconds;
        uint64 endTimeUnixSeconds;
    }

    event UpdateStage(
        uint256 stage,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    );

    event SetCosigner(address cosigner);
    event SetCrossmintAddress(address crossmintAddress);
    event SetMintable(bool mintable);
    event SetMaxMintableSupply(uint256 maxMintableSupply);
    event SetGlobalWalletLimit(uint256 globalWalletLimit);
    event SetActiveStage(uint256 activeStage);
    event SetBaseURI(string baseURI);
    event SetTimestampExpirySeconds(uint64 expiry);
    event PermanentBaseURI(string baseURI);
    event Withdraw(uint256 value);

    function getCosigner() external view returns (address);

    function getCrossmintAddress() external view returns (address);

    function getNumberStages() external view returns (uint256);

    function getGlobalWalletLimit() external view returns (uint256);

    function getTimestampExpirySeconds() external view returns (uint64);

    function getMaxMintableSupply() external view returns (uint256);

    function getMintable() external view returns (bool);

    function totalMintedByAddress(address a) external view returns (uint256);

    function getTokenURISuffix() external view returns (string memory);

    function getStageInfo(uint256 index)
        external
        view
        returns (
            MintStageInfo memory,
            uint32,
            uint256
        );

    function getActiveStageFromTimestamp(uint64 timestamp)
        external
        view
        returns (uint256);

    function assertValidCosign(
        address minter,
        uint32 qty,
        uint64 timestamp,
        bytes memory signature
    ) external view;
}