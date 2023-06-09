// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IFlashProtocol {
    event StrategyRegistered(
        address indexed _strategyAddress,
        address indexed _principalTokenAddress,
        address indexed _fTokenAddress
    );
    event Staked(uint256 _stakeId);
    event Unstaked(uint256 _stakeId, uint256 _tokensReturned, uint256 _fTokensBurned, bool _stakeFinished);
    event NFTIssued(uint256 _stakeId, uint256 nftId);

    struct StakeStruct {
        address stakerAddress; // Address of staker
        address strategyAddress; // Address of strategy being used
        uint256 stakeStartTs; // Unix timestamp of when stake started
        uint256 stakeDuration; // Time in seconds from start time until stake ends
        uint256 stakedAmount; // The amount of tokens staked
        bool active; // Stake has been removed/unstaked
        uint256 nftId; // NFT id if set
        uint256 fTokensToUser; // How many fERC20 tokens were minted
        uint256 fTokensFee; // How many fERC20 tokens were taken as fee
        uint256 totalFTokenBurned;
        uint256 totalStakedWithdrawn;
    }

    function flashNFTAddress() external view returns (address);

    function flashStake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _minimumReceived,
        address _yieldTo,
        bool _mintNFT
    ) external;

    function getStakeInfo(uint256 _id, bool _isNFT) external view returns (StakeStruct memory _stake);

    function issueNFT(uint256 _stakeId) external returns (uint256 _nftId);

    function owner() external view returns (address);

    function registerStrategy(
        address _strategyAddress,
        address _principalTokenAddress,
        string calldata _fTokenName,
        string calldata _fTokenSymbol
    ) external;

    function renounceOwnership() external;

    function setMintFeeInfo(address _feeRecipient, uint96 _feePercentageBasis) external;

    function stake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo,
        bool _issueNFT
    ) external returns (StakeStruct memory _stake);

    function transferOwnership(address newOwner) external;

    function unstake(
        uint256 _id,
        bool _isNFT,
        uint256 _fTokenToBurn
    ) external returns (uint256 _principalReturned, uint256 _fTokensBurned);
}