pragma solidity 0.8.8;

/**
 * @title Interface fro NodeDao LiquidStaking Contract
 *
 * NodeDao is a DAO that provides decentralized solutions for Ethereum liquidity,
 * jointly initiated by ChainUp Cloud, XHash, AntAlpha, ImToken, and Bitrise.
 *
 * The NodeDAO protocol is a smart contract for next-generation liquid staking derivatives,
 * which includes all the concepts of traditional liquid staking, re-staking, distributed validators, and validator NFTs in a single protocol.
 *
 * Our vision is to use our innovative liquidity solution to provide more options for the Ethereum liquidity market,
 * thereby making Ethereum staking more decentralized.
 */
interface ILiquidStaking {
    /**
     * @notice Receive Rewards
     * @param _rewards rewards amount
     */
    function receiveRewards(uint256 _rewards) external payable;

    /**
     * @notice Update the status of the corresponding nft according to the report result of the oracle machine
     * @param _tokenIds token id
     * @param _exitBlockNumbers exit block number
     */
    function nftExitHandle(uint256[] memory _tokenIds, uint256[] memory _exitBlockNumbers) external;

    /**
     * @notice According to the settlement results of the vaultManager, the income of the re-investment execution layer
     * @param _operatorIds operator id
     * @param _amounts reinvest amounts
     */
    function reinvestElRewards(uint256[] memory _operatorIds, uint256[] memory _amounts) external;

    /**
     * @notice According to the reported results of the oracle machine, the income of the consensus layer is re-invested
     * @param _operatorIds operator id
     * @param _amounts reinvest amounts
     * @param _totalAmount totalAmount
     */
    function reinvestClRewards(uint256[] memory _operatorIds, uint256[] memory _amounts, uint256 _totalAmount)
        external;

    /**
     * @notice nETH to ETH exchange rate
     * @param _nethAmountIn nETH amount
     */
    function getEthOut(uint256 _nethAmountIn) external view returns (uint256);

    /**
     * @notice ETH to nETH exchange rate
     * @param _ethAmountIn ETH amount
     */
    function getNethOut(uint256 _ethAmountIn) external view returns (uint256);

    /**
     * @notice When withdrawing a large amount, update the user's unstake quota
     * @param _operatorId operator id
     * @param _from user address
     * @param _amount unstakeETH amount
     */
    function largeWithdrawalUnstake(uint256 _operatorId, address _from, uint256 _amount) external;

    /**
     * @notice large withdrawals, when users claim eth, will trigger the burning of locked Neth
     * @param _totalRequestNethAmount totalRequestNethAmount will burn
     * @param _to burn neth address
     */
    function LargeWithdrawalRequestBurnNeth(uint256 _totalRequestNethAmount, address _to) external;

    /**
     * @notice When unstakeNFT, if the funds pledged by the user have not been deposited, the user is allowed to withdraw directly
     * @param _operatorId operator id
     * @param _tokenId tokenId
     * @param _to receiving address
     */
    function fastUnstakeNFT(uint256 _operatorId, uint256 _tokenId, address _to) external;

    /**
     * @notice When the operator is punished due to an error in operation, the penalty funds are recharged to its own pledge pool
     * @param _operatorId operator id
     * @param _amount slash amount
     */
    function addPenaltyFundToStakePool(uint256 _operatorId, uint256 _amount) external payable;

    /**
     * @notice Users claim vNFT rewards
     * @dev There is no need to judge whether this nft belongs to the liquidStaking,
     *      because the liquidStaking cannot directly reward
     * @param _operatorId operator id
     * @param _tokenIds vNFT tokenIds
     * @param _totalNftRewards _totalNftRewards
     * @param _gasHeight update claim gasHeigt
     * @param _owner _owner
     */
    function claimRewardsOfUser(
        uint256 _operatorId,
        uint256[] memory _tokenIds,
        uint256 _totalNftRewards,
        uint256 _gasHeight,
        address _owner
    ) external;

    /**
     * @notice The operator claims the operation reward
     * @param _operatorId operator Id
     * @param _rewardAddresses reward address
     * @param _rewards _rewards
     */
    function claimRewardsOfOperator(uint256 _operatorId, address[] memory _rewardAddresses, uint256[] memory _rewards)
        external;

    /**
     * @notice The dao claims to belong to the dao reward
     * @param _operatorIds operators Id
     * @param _rewards rewards
     */
    function claimRewardsOfDao(uint256[] memory _operatorIds, uint256[] memory _rewards) external;

    /**
     * @notice nETH to ETH exchange rate
     */
    function getExchangeRate() external view returns (uint256);

    event OperatorAssigned(uint256 indexed _blacklistOperatorId, uint256 _operatorId, uint256 _totalAmount);
    event EthStake(uint256 indexed _operatorId, address indexed _from, uint256 _amount, uint256 _amountOut);
    event EthUnstake(
        uint256 indexed _operatorId, uint256 targetOperatorId, address ender, uint256 _amounts, uint256 amountOut
    );
    event NftStake(uint256 indexed _operatorId, address indexed _from, uint256 _count);
    event ValidatorRegistered(uint256 indexed _operatorId, uint256 _tokenId, bytes _pubkey);
    event UserClaimRewards(uint256 _operatorId, uint256[] _tokenIds, uint256 _rewards);
    event Transferred(address _to, uint256 _amount);
    event OperatorReinvestClRewards(uint256 _operatorId, uint256 _rewards);
    event OperatorReinvestElRewards(uint256 _operatorId, uint256 _rewards);
    event RewardsReceive(uint256 _rewards);
    event LiquidStakingWithdrawalCredentialsSet(
        bytes _oldLiquidStakingWithdrawalCredentials, bytes _liquidStakingWithdrawalCredentials
    );
    event WithdrawOracleContractSet(address _oldWithdrawOracleContractSet, address _withdrawOracleContractSetAddress);
    event NodeOperatorRegistryContractSet(
        address _oldNodeOperatorRegistryContract, address _nodeOperatorRegistryContract
    );
    event DaoAddressChanged(address _oldDao, address _dao);
    event DaoVaultAddressChanged(address _oldDaoVaultAddress, address _daoVaultAddress);
    event DepositFeeRateSet(uint256 _oldFeeRate, uint256 _feeRate);
    event OperatorClaimRewards(uint256 _operatorId, uint256 _rewards);
    event DaoClaimRewards(uint256 _operatorId, uint256 _rewards);
    event NftExitBlockNumberSet(uint256[] tokenIds, uint256[] exitBlockNumbers);
    event VaultManagerContractSet(address vaultManagerContractAddress, address _vaultManagerContract);
    event ConsensusVaultContractSet(address vaultManagerContractAddress, address _consensusVaultContract);
    event OperatorCanLoanAmountsSet(uint256 operatorCanLoanAmounts, uint256 _newCanloadAmounts);
    event WithdrawalRequestContractSet(address _withdrawalRequestContract, address _withdrawalRequestContractAddress);
    event OperatorSlashContractSet(address oldOperatorSlashContract, address _operatorSlashContract);
}