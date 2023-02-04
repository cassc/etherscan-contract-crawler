pragma solidity ^0.8.4;

interface IFlashProtocol {
    event NFTIssued(uint256 _stakeId, uint256 nftId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Staked(uint256 _stakeId);
    event StrategyRegistered(
        address indexed _strategyAddress,
        address indexed _principalTokenAddress,
        address indexed _fTokenAddress
    );
    event Unstaked(uint256 _stakeId, uint256 _tokensReturned, uint256 _fTokensBurned, bool _stakeFinished);

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
        string memory _fTokenName,
        string memory _fTokenSymbol
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

    struct StakeStruct {
        address stakerAddress;
        address strategyAddress;
        uint256 stakeStartTs;
        uint256 stakeDuration;
        uint256 stakedAmount;
        bool active;
        uint256 nftId;
        uint256 fTokensToUser;
        uint256 fTokensFee;
        uint256 totalFTokenBurned;
        uint256 totalStakedWithdrawn;
    }
}