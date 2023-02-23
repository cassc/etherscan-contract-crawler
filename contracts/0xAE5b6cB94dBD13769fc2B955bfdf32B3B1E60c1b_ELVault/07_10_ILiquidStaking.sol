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
     * @notice Receive slash fund
     * @param _amount amount
     */
    function slashReceive(uint256 _amount) external payable;

    event BlacklistOperatorAssigned(uint256 _blacklistOperatorId, uint256 _totalAmount);
    event OperatorSlashed(uint256 _operatorId, uint256 _amount);
    event EthStake(address indexed _from, uint256 _amount, uint256 _amountOut);
    event EthUnstake(address indexed _from, uint256 _amount, uint256 _amountOut);
    event NftStake(address indexed _from, uint256 _count);
    event ValidatorRegistered(uint256 _operatorId, uint256 _tokenId);
    event NftWrap(uint256 _tokenId, uint256 _operatorId, uint256 _value, uint256 _amountOut);
    event NftUnwrap(uint256 _tokenId, uint256 operatorId, uint256 _value, uint256 _amountOut);
    event UserClaimRewards(uint256 _operatorId, uint256 _tokenId, uint256 _rewards);
    event Transferred(address _to, uint256 _amount);
    event OperatorReinvestRewards(uint256 _operatorId, uint256 _rewards);
    event RewardsReceive(uint256 _rewards);
    event SlashReceive(uint256 _amount);
    event LiquidStakingWithdrawalCredentialsSet(
        bytes _oldLiquidStakingWithdrawalCredentials, bytes _liquidStakingWithdrawalCredentials
    );
    event BeaconOracleContractSet(address _oldBeaconOracleContract, address _beaconOracleContractAddress);
    event NodeOperatorRegistryContractSet(
        address _oldNodeOperatorRegistryContract, address _nodeOperatorRegistryContract
    );
    event DaoAddressChanged(address _oldDao, address _dao);
    event DaoVaultAddressChanged(address _oldDaoVaultAddress, address _daoVaultAddress);
    event DepositFeeRateSet(uint256 _oldFeeRate, uint256 _feeRate);
}