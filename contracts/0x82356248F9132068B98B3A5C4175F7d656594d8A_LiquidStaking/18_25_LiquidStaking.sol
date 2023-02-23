// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "src/interfaces/INodeOperatorsRegistry.sol";
import "src/interfaces/ILiquidStaking.sol";
import "src/interfaces/INETH.sol";
import "src/interfaces/IVNFT.sol";
import "src/interfaces/IDepositContract.sol";
import "src/interfaces/IBeaconOracle.sol";
import "src/interfaces/IELVault.sol";
import {ERC721A__IERC721ReceiverUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";

/**
 * @title NodeDao LiquidStaking Contract
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
contract LiquidStaking is
    ILiquidStaking,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC721A__IERC721ReceiverUpgradeable
{
    IDepositContract public depositContract;

    INodeOperatorsRegistry public nodeOperatorRegistryContract;

    INETH public nETHContract;

    IVNFT public vNFTContract;

    IBeaconOracle public beaconOracleContract;

    bytes public liquidStakingWithdrawalCredentials;

    // deposit fee rate
    uint256 public depositFeeRate;
    uint256 internal constant totalBasisPoints = 10000;

    uint256 internal constant DEPOSIT_SIZE = 32 ether;
    // After the Shanghai upgrade, the rewards will be distributed linearly,
    // and the rewards will not exceed 16ETH, so the maximum value of a node is set to 48ETH
    uint256 internal constant MAX_NODE_VALUE = 48 ether;

    // operator's internal stake pool, key is operator_id
    mapping(uint256 => uint256) public operatorPoolBalances;

    // unused funds in the current liquidStaking pool
    uint256 internal operatorPoolBalancesSum;

    // dao address
    address public dao;
    // dao treasury address
    address public daoVaultAddress;

    modifier onlyDao() {
        require(msg.sender == dao, "PERMISSION_DENIED");
        _;
    }

    /**
     * @notice initialize LiquidStaking Contract
     * @param _dao Dao contract address
     * @param _daoVaultAddress Dao Vault Address
     * @param _withdrawalCreds Withdrawal Credentials, Withdrawal vault contract address
     * @param _nodeOperatorRegistryContractAddress Node Operator Registry Contract Address
     * @param _nETHContractAddress NETH contract address, The liquidity token for the eth stake
     * @param _nVNFTContractAddress VNFT contract address, The NFT representing the validator
     * @param _beaconOracleContractAddress Beacon Oracle Contract Address, where balances and VNFT values are tracked
     * @param _depositContractAddress eth2 Deposit Contract Address
     */
    function initialize(
        address _dao,
        address _daoVaultAddress,
        bytes memory _withdrawalCreds,
        address _nodeOperatorRegistryContractAddress,
        address _nETHContractAddress,
        address _nVNFTContractAddress,
        address _beaconOracleContractAddress,
        address _depositContractAddress
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        dao = _dao;
        daoVaultAddress = _daoVaultAddress;

        liquidStakingWithdrawalCredentials = _withdrawalCreds;

        depositContract = IDepositContract(_depositContractAddress);
        nodeOperatorRegistryContract = INodeOperatorsRegistry(_nodeOperatorRegistryContractAddress);

        nETHContract = INETH(_nETHContractAddress);

        vNFTContract = IVNFT(_nVNFTContractAddress);

        beaconOracleContract = IBeaconOracle(_beaconOracleContractAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice For operators added to the blacklist by dao, for example,
     * because the operator has been inactive for a long time,
     * and has been punished on a large scale, etc.
     *
     * The Dao has the right to distribute the available balance on this operator to other active operators,
     * and the allocation share will be determined through proposals
     * @param _assignOperatorId blacklist or quit operator id
     * @param _operatorIds The operator id of the allocation share
     * @param _amounts The size of the allocated share
     */
    function assignBlacklistOrQuitOperator(
        uint256 _assignOperatorId,
        uint256[] calldata _operatorIds,
        uint256[] calldata _amounts
    ) external onlyOwner {
        // assignOperatorId must be a blacklist operator
        require(
            !nodeOperatorRegistryContract.isTrustedOperator(_assignOperatorId)
                || nodeOperatorRegistryContract.isQuitOperator(_assignOperatorId),
            "This operator is trusted"
        );
        require(_operatorIds.length == _amounts.length, "Invalid length");

        // Update operator available funds
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            uint256 operatorId = _operatorIds[i];
            require(nodeOperatorRegistryContract.isTrustedOperator(operatorId), "Operator must be trusted");
            uint256 amount = _amounts[i];
            totalAmount += amount;
            operatorPoolBalances[operatorId] += amount;
        }

        require(operatorPoolBalances[_assignOperatorId] >= totalAmount, "Insufficient balance of blacklist operator");
        operatorPoolBalances[_assignOperatorId] -= totalAmount;
        emit BlacklistOperatorAssigned(_assignOperatorId, totalAmount);
    }

    /**
     * @notice slash operator
     * @param _operatorId operator id
     * @param _amount slash amount
     */
    function slashOperator(uint256 _operatorId, uint256 _amount) external onlyOwner {
        nodeOperatorRegistryContract.slash(_amount, _operatorId);
        operatorPoolBalances[_operatorId] += _amount;
        operatorPoolBalancesSum += _amount;
        emit OperatorSlashed(_operatorId, _amount);
    }

    /**
     * @notice stake eth to designated operator, stake ETH to get nETH
     * @param _operatorId operator id
     */
    function stakeETH(uint256 _operatorId) external payable nonReentrant whenNotPaused {
        require(msg.value >= 1000 gwei, "Stake amount must be minimum 1000 gwei");

        // operatorId must be a trusted operator
        require(nodeOperatorRegistryContract.isTrustedOperator(_operatorId), "The operator is not trusted");

        // Must meet the basic mortgage funds before being allowed to be entrusted
        require(nodeOperatorRegistryContract.isConformBasicPledge(_operatorId), "Insufficient pledge balance");

        // When the deposit rate is not 0, charge the fee
        uint256 depositFeeAmount;
        uint256 depositPoolAmount;
        if (depositFeeRate == 0) {
            depositPoolAmount = msg.value;
        } else {
            depositFeeAmount = msg.value * depositFeeRate / totalBasisPoints;
            depositPoolAmount = msg.value - depositFeeAmount;
            require(daoVaultAddress != address(0), "DaoVaultAddress address invalid");
            payable(daoVaultAddress).transfer(depositFeeAmount);
            emit Transferred(daoVaultAddress, depositFeeAmount);
        }

        // 1. Convert depositAmount according to the exchange rate of nETH
        // 2. Mint nETH
        uint256 amountOut = getNethOut(depositPoolAmount);
        nETHContract.whiteListMint(amountOut, msg.sender);

        operatorPoolBalances[_operatorId] += depositPoolAmount;
        operatorPoolBalancesSum += depositPoolAmount;

        emit EthStake(msg.sender, msg.value, amountOut);
    }

    /**
     * @notice unstakeNFT Support after Shanghai upgrade
     * @param _tokenId token Id
     */
    function unstakeNFT(uint256 _tokenId) public nonReentrant whenNotPaused returns (bool) {
        return true;
    }

    /**
     * @notice Stake 32 multiples of eth to get the corresponding number of vNFTs
     * @param _operatorId operator id
     */
    function stakeNFT(uint256 _operatorId) external payable nonReentrant whenNotPaused {
        // operatorId must be a trusted operator
        require(nodeOperatorRegistryContract.isTrustedOperator(_operatorId), "The operator is not trusted");
        require(msg.value % DEPOSIT_SIZE == 0, "Incorrect Ether amount");

        // Must meet the basic mortgage funds before being allowed to be entrusted
        require(nodeOperatorRegistryContract.isConformBasicPledge(_operatorId), "Insufficient pledge balance");

        uint256 amountOut = getNethOut(msg.value);

        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(_operatorId);
        IELVault(vaultContractAddress).settle();

        nETHContract.whiteListMint(amountOut, address(this));

        uint256 mintNftsCount = msg.value / DEPOSIT_SIZE;
        for (uint256 i = 0; i < mintNftsCount; ++i) {
            uint256 tokenId = vNFTContract.whiteListMint(bytes(""), msg.sender, _operatorId);
            IELVault(vaultContractAddress).setUserNft(tokenId, block.number);
        }

        operatorPoolBalances[_operatorId] += msg.value;
        operatorPoolBalancesSum += msg.value;

        emit NftStake(msg.sender, mintNftsCount);
    }

    /**
     * @notice registers validators
     * @param _pubkeys validator pubkeys
     * @param _signatures validator signatures
     * @param _depositDataRoots validator depositDataRoots
     */
    function registerValidator(
        bytes[] calldata _pubkeys,
        bytes[] calldata _signatures,
        bytes32[] calldata _depositDataRoots
    ) external nonReentrant whenNotPaused {
        require(
            _pubkeys.length == _signatures.length && _pubkeys.length == _depositDataRoots.length,
            "parameter must have the same length"
        );

        // must be a trusted operator
        uint256 operatorId = nodeOperatorRegistryContract.isTrustedOperatorOfControllerAddress(msg.sender);
        require(operatorId != 0, "The sender must be controlAddress of the trusted operator");
        require(operatorPoolBalances[operatorId] / DEPOSIT_SIZE >= _pubkeys.length, "Insufficient balance");

        reinvestRewardsOfOperator(operatorId);

        for (uint256 i = 0; i < _pubkeys.length; ++i) {
            _stakeAndMint(operatorId, _pubkeys[i], _signatures[i], _depositDataRoots[i]);
        }

        uint256 stakeAmount = DEPOSIT_SIZE * _pubkeys.length;
        operatorPoolBalances[operatorId] -= stakeAmount;
        operatorPoolBalancesSum -= stakeAmount;
        beaconOracleContract.addPendingBalances(stakeAmount);
    }

    function _stakeAndMint(
        uint256 _operatorId,
        bytes calldata _pubkey,
        bytes calldata _signature,
        bytes32 _depositDataRoot
    ) internal {
        depositContract.deposit{value: 32 ether}(
            _pubkey, liquidStakingWithdrawalCredentials, _signature, _depositDataRoot
        );

        uint256 tokenId = vNFTContract.whiteListMint(_pubkey, address(this), _operatorId);

        emit ValidatorRegistered(_operatorId, tokenId);
    }

    /**
     * @notice nETH swap vNFT
     * @param _tokenId vNFT tokenId
     * @param _proof Merkle tree proof from the oracle for this validator
     * @param _value value from the oracle for this validator
     */
    function wrapNFT(uint256 _tokenId, bytes32[] calldata _proof, uint256 _value) external nonReentrant whenNotPaused {
        require(_value >= DEPOSIT_SIZE, "Value check failed");

        uint256 operatorId = vNFTContract.operatorOf(_tokenId);

        reinvestRewardsOfOperator(operatorId);

        uint256 amountOut = getNethOut(_value);

        bytes memory pubkey = vNFTContract.validatorOf(_tokenId);
        bool success = beaconOracleContract.verifyNftValue(_proof, pubkey, _value, _tokenId);
        require(success, "vNFT value verification failed");

        // this might need to use transfer instead
        success = nETHContract.transferFrom(msg.sender, address(this), amountOut);
        require(success, "Failed to transfer neth");

        vNFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);

        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(operatorId);
        IELVault(vaultContractAddress).setUserNft(_tokenId, block.number);

        emit NftWrap(_tokenId, operatorId, _value, amountOut);
    }

    /**
     * @notice vNFT swap nETH
     * @param _tokenId vNFT tokenId
     * @param _proof Merkle tree proof from the oracle for this validator
     * @param _value value from the oracle for this validator
     */
    function unwrapNFT(uint256 _tokenId, bytes32[] calldata _proof, uint256 _value)
        external
        nonReentrant
        whenNotPaused
    {
        require(_value <= MAX_NODE_VALUE, "Value check failed");

        uint256 operatorId = vNFTContract.operatorOf(_tokenId);

        bool trusted;
        address vaultContractAddress;
        // The nft under the trusted operator can be wrapped
        (trusted,,,, vaultContractAddress) = nodeOperatorRegistryContract.getNodeOperator(operatorId, false);
        require(trusted, "PERMISSION_DENIED");

        // Check the value of the validator
        bytes memory pubkey = vNFTContract.validatorOf(_tokenId);
        bool success = beaconOracleContract.verifyNftValue(_proof, pubkey, _value, _tokenId);
        require(success, "vNFT value verification failed");

        uint256 amountOut = getNethOut(_value);

        // Settle this nft reward to the user
        claimRewardsOfUser(_tokenId);
        // Complete the exchange of nETH and vNFT
        vNFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        success = nETHContract.transfer(msg.sender, amountOut);
        require(success, "Failed to transfer neth");

        // Change the gas height of this nft
        IELVault(vaultContractAddress).setUserNft(_tokenId, 0);

        emit NftUnwrap(_tokenId, operatorId, _value, amountOut);
    }

    /**
     * @notice How much nETH can be obtained by trading vNFT
     * @param _tokenId vNFT tokenId
     * @param _proof Merkle tree proof from the oracle for this validator
     * @param _value value from the oracle for this validator
     */
    function getNFTOut(uint256 _tokenId, bytes32[] calldata _proof, uint256 _value) external view returns (uint256) {
        uint256 operatorId = vNFTContract.operatorOf(_tokenId);

        bool trusted;
        address vaultContractAddress;
        (trusted,,,, vaultContractAddress) = nodeOperatorRegistryContract.getNodeOperator(operatorId, false);
        require(trusted, "PERMISSION_DENIED");

        bytes memory pubkey = vNFTContract.validatorOf(_tokenId);
        bool success = beaconOracleContract.verifyNftValue(_proof, pubkey, _value, _tokenId);
        require(success, "vNFT value verification failed");

        return getNethOut(_value);
    }

    /**
     * @notice Batch Reinvestment Rewards
     * @param _operatorIds The operatorIds of the re-investment
     */
    function batchReinvestRewardsOfOperator(uint256[] calldata _operatorIds) public whenNotPaused {
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            reinvestRewardsOfOperator(_operatorIds[i]);
        }
    }

    function reinvestRewardsOfOperator(uint256 _operatorId) internal {
        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(_operatorId);
        IELVault(vaultContractAddress).settle();

        // Change the gas height of liquidStaking nft
        uint256 nftRewards = IELVault(vaultContractAddress).reinvestmentOfLiquidStaking();
        IELVault(vaultContractAddress).setLiquidStakingGasHeight(block.number);

        if (nftRewards == 0) {
            return;
        }

        // update available funds
        operatorPoolBalances[_operatorId] += nftRewards;
        operatorPoolBalancesSum += nftRewards;

        emit OperatorReinvestRewards(_operatorId, nftRewards);
    }

    /**
     * @notice Users claim vNFT rewards
     * @dev There is no need to judge whether this nft belongs to the liquidStaking,
     *      because the liquidStaking cannot directly reward
     * @param _tokenId vNFT tokenId
     */
    function claimRewardsOfUser(uint256 _tokenId) public whenNotPaused {
        uint256 operatorId = vNFTContract.operatorOf(_tokenId);
        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(operatorId);
        IELVault(vaultContractAddress).settle();

        uint256 nftRewards = IELVault(vaultContractAddress).claimRewardsOfUser(_tokenId);

        emit UserClaimRewards(operatorId, _tokenId, nftRewards);
    }

    /**
     * @notice Get the total amount of ETH in the protocol
     */
    function getTotalEthValue() public view returns (uint256) {
        return operatorPoolBalancesSum + beaconOracleContract.getBeaconBalances()
            + beaconOracleContract.getPendingBalances();
    }

    /**
     * @notice nETH to ETH exchange rate
     * @param _nethAmountIn nETH amount
     */
    function getEthOut(uint256 _nethAmountIn) public view returns (uint256) {
        uint256 totalEth = getTotalEthValue();
        uint256 nethSupply = nETHContract.totalSupply();
        if (nethSupply == 0) {
            return _nethAmountIn;
        }

        return _nethAmountIn * (totalEth) / (nethSupply);
    }

    /**
     * @notice ETH to nETH exchange rate
     * @param _ethAmountIn ETH amount
     */
    function getNethOut(uint256 _ethAmountIn) public view returns (uint256) {
        uint256 totalEth = getTotalEthValue();
        uint256 nethSupply = nETHContract.totalSupply();
        if (nethSupply == 0) {
            return _ethAmountIn;
        }
        require(totalEth > 0, "totalEth is zero");
        return _ethAmountIn * (nethSupply) / (totalEth);
    }

    /**
     * @notice nETH to ETH exchange rate
     */
    function getExchangeRate() external view returns (uint256) {
        return getEthOut(1 ether);
    }

    /**
     * @notice set dao address
     * @param _dao new dao address
     */
    function setDaoAddress(address _dao) external onlyOwner {
        require(_dao != address(0), "Dao address invalid");
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    /**
     * @notice set dao vault address
     * @param _daoVaultAddress new dao vault address
     */
    function setDaoVaultAddress(address _daoVaultAddress) external onlyDao {
        require(_daoVaultAddress != address(0), "dao vault address invalid");
        emit DaoVaultAddressChanged(daoVaultAddress, _daoVaultAddress);
        daoVaultAddress = _daoVaultAddress;
    }

    /**
     * @notice Set staking fee rate
     * @param _feeRate new stake fee rate
     */
    function setDepositFeeRate(uint256 _feeRate) external onlyDao {
        require(_feeRate <= 1000, "Rate too high");
        emit DepositFeeRateSet(depositFeeRate, _feeRate);
        depositFeeRate = _feeRate;
    }

    /**
     * @notice Set LiquidStaking contract withdrawalCredentials
     * @param _liquidStakingWithdrawalCredentials new withdrawalCredentials
     */
    function setLiquidStakingWithdrawalCredentials(bytes calldata _liquidStakingWithdrawalCredentials)
        external
        onlyOwner
    {
        emit LiquidStakingWithdrawalCredentialsSet(
            liquidStakingWithdrawalCredentials, _liquidStakingWithdrawalCredentials
            );
        liquidStakingWithdrawalCredentials = _liquidStakingWithdrawalCredentials;
    }

    /**
     * @notice Set new beaconOracleContract address
     * @param _beaconOracleContractAddress new withdrawalCredentials
     */
    function setBeaconOracleContract(address _beaconOracleContractAddress) external onlyDao {
        emit BeaconOracleContractSet(address(beaconOracleContract), _beaconOracleContractAddress);
        beaconOracleContract = IBeaconOracle(_beaconOracleContractAddress);
    }

    /**
     * @notice Set new nodeOperatorRegistryContract address
     * @param _nodeOperatorRegistryContract new withdrawalCredentials
     */
    function setNodeOperatorRegistryContract(address _nodeOperatorRegistryContract) external onlyDao {
        emit NodeOperatorRegistryContractSet(address(nodeOperatorRegistryContract), _nodeOperatorRegistryContract);
        nodeOperatorRegistryContract = INodeOperatorsRegistry(_nodeOperatorRegistryContract);
    }

    /**
     * @notice vNFT receiving function
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @notice Receive Rewards
     * @param _rewards rewards amount
     */
    function receiveRewards(uint256 _rewards) external payable {
        emit RewardsReceive(_rewards);
    }

    /**
     * @notice Receive slash fund
     * @param _amount amount
     */
    function slashReceive(uint256 _amount) external payable {
        emit SlashReceive(_amount);
    }

    /**
     * @notice The protocol has been Paused
     */
    function isPaused() public view returns (bool) {
        return paused();
    }

    /**
     * @notice In the event of an emergency, stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice restart protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }
}