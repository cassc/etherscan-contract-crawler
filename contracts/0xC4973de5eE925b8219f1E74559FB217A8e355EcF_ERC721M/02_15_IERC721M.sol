//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721M {
    error CannotIncreaseMaxMintableSupply();
    error CannotUpdatePermanentBaseURI();
    error CosignerNotSet();
    error CrossmintAddressNotSet();
    error CrossmintOnly();
    error GlobalWalletLimitOverflow();
    error InvalidCosignSignature();
    error InvalidProof();
    error InvalidStage();
    error InvalidStageArgsLength();
    error NoSupplyLeft();
    error NotEnoughValue();
    error NotMintable();
    error StageSupplyExceeded();
    error WalletGlobalLimitExceeded();
    error WalletStageLimitExceeded();
    error WithdrawFailed();

    struct MintStageInfo {
        uint256 price;
        uint32 walletLimit; // 0 for unlimited
        bytes32 merkleRoot; // 0x0 for no presale enforced
        uint256 maxStageSupply; // 0 for unlimited
    }

    event UpdateStage(
        uint256 stage,
        uint256 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint256 maxStageSupply
    );

    event SetCosigner(address cosigner);
    event SetCrossmintAddress(address crossmintAddress);
    event SetMintable(bool mintable);
    event SetMaxMintableSupply(uint256 maxMintableSupply);
    event SetGlobalWalletLimit(uint256 globalWalletLimit);
    event SetActiveStage(uint256 activeStage);
    event SetBaseURI(string baseURI);
    event PermanentBaseURI(string baseURI);
}