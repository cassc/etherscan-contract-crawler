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
import "src/interfaces/IWithdrawOracle.sol";
import "src/interfaces/IELVault.sol";
import {ERC721A__IERC721ReceiverUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import "src/interfaces/IConsensusVault.sol";
import "src/interfaces/IVaultManager.sol";
import "src/interfaces/IWithdrawalRequest.sol";
import "src/interfaces/IOperatorSlash.sol";

/**
 * @title NodeDao LiquidStaking Contract
 *
 * NodeDao is a DAO that provides decentralized solutions for Ethereum liquidity,
 * jointly initiated by ChainUp Cloud, XHash.
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

    IWithdrawOracle public withdrawOracleContract;

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

    // v2 storage

    address public vaultManagerContractAddress;
    IConsensusVault public consensusVaultContract;
    IWithdrawalRequest public withdrawalRequestContract;
    IOperatorSlash public operatorSlashContract;

    // operator's internal nft stake pool, key is operator_id
    mapping(uint256 => uint256) public operatorNftPoolBalances;

    struct StakeInfo {
        uint256 operatorId;
        uint256 quota;
    }

    // key is user address, value is StakeInfo
    mapping(address => StakeInfo[]) internal stakeRecords;

    // key is quit operatorId, value is asign operatorId
    mapping(uint256 => uint256) public reAssignRecords;

    uint256 public operatorCanLoanAmounts;

    // key is operatorId, value is loan amounts
    mapping(uint256 => uint256) public operatorLoanRecords;
    // key is operatorId, value is loan blockNumber
    mapping(uint256 => uint256) public operatorLoadBlockNumbers;

    error PermissionDenied();
    error RequireBlacklistOperator();
    error AssignMustSameOperator();
    error InvalidParameter();
    error RequireOperatorTrusted();
    error InvalidAmount();
    error InsufficientMargin();
    error InvalidDaoVaultAddr();
    error UnstakeEthNoQuota();
    error OperatorLoanFailed();
    error InvalidWithdrawalCredentials();
    error InsufficientFunds();
    error OperatorHasArrears();
    error TotalEthIsZero();

    modifier onlyDao() {
        if (msg.sender != dao) revert PermissionDenied();
        _;
    }

    modifier onlyVaultManager() {
        if (msg.sender != vaultManagerContractAddress) revert PermissionDenied();
        _;
    }

    modifier onlyWithdrawalRequest() {
        if (msg.sender != address(withdrawalRequestContract)) revert PermissionDenied();
        _;
    }

    modifier onlyOperatorSlash() {
        if (msg.sender != address(operatorSlashContract)) revert PermissionDenied();
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
     * @param _withdrawOracleContractAddress Beacon Oracle Contract Address, where balances and VNFT values are tracked
     * @param _depositContractAddress eth2 Deposit Contract Address
     */
    function initialize(
        address _dao,
        address _daoVaultAddress,
        bytes memory _withdrawalCreds,
        address _nodeOperatorRegistryContractAddress,
        address _nETHContractAddress,
        address _nVNFTContractAddress,
        address _withdrawOracleContractAddress,
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

        withdrawOracleContract = IWithdrawOracle(_withdrawOracleContractAddress);
    }

    /**
     * @notice initializeV2 LiquidStaking Contract
     * @param _operatorIds operator id
     * @param _users user Address
     * @param _nethAmounts Withdrawal Credentials, Withdrawal vault contract address
     * @param _consensusVaultContractAddress consensusVaultContract address
     * @param _vaultManagerContractAddress vaultManagerContract address
     * @param _withdrawalRequestContractAddress withdrawalRequestContract address
     * @param _operatorSlashContractAddress operatorSlashContract address
     * @param _withdrawOracleContractAddress withdrawOracleContract address
     */
    function initializeV2(
        uint256[] memory _operatorIds,
        address[] memory _users,
        uint256[] memory _nethAmounts,
        address _consensusVaultContractAddress,
        address _vaultManagerContractAddress,
        address _withdrawalRequestContractAddress,
        address _operatorSlashContractAddress,
        address _withdrawOracleContractAddress
    ) public reinitializer(2) onlyDao {
        // merge already stake data to StakeRecords
        if (_operatorIds.length != _users.length && _nethAmounts.length != _users.length) revert InvalidParameter();
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            if (!nodeOperatorRegistryContract.isTrustedOperator(_operatorIds[i])) revert RequireOperatorTrusted();
            _stakeRecords(_operatorIds[i], _users[i], _nethAmounts[i]);
        }

        if (
            _withdrawalRequestContractAddress == address(0) || _operatorSlashContractAddress == address(0)
                || _vaultManagerContractAddress == address(0) || _consensusVaultContractAddress == address(0)
        ) revert InvalidParameter();

        operatorCanLoanAmounts = 32 ether;

        emit WithdrawalRequestContractSet(address(withdrawalRequestContract), _withdrawalRequestContractAddress);
        withdrawalRequestContract = IWithdrawalRequest(_withdrawalRequestContractAddress);

        emit OperatorSlashContractSet(address(operatorSlashContract), _operatorSlashContractAddress);
        operatorSlashContract = IOperatorSlash(_operatorSlashContractAddress);

        emit VaultManagerContractSet(vaultManagerContractAddress, _vaultManagerContractAddress);
        vaultManagerContractAddress = _vaultManagerContractAddress;

        emit ConsensusVaultContractSet(address(consensusVaultContract), _consensusVaultContractAddress);
        consensusVaultContract = IConsensusVault(_consensusVaultContractAddress);

        emit WithdrawOracleContractSet(address(withdrawOracleContract), _withdrawOracleContractAddress);
        withdrawOracleContract = IWithdrawOracle(_withdrawOracleContractAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice For operators added to the blacklist by dao, for example,
     * because the operator has been inactive for a long time,
     * and has been punished on a large scale, etc.
     *
     * The Dao has the right to distribute the available balance on this operator to other active operators,
     * and the allocation share will be determined through proposals
     * @param _assignOperatorId blacklist operator id
     * @param _operatorId The operator id of the allocation share
     */
    function assignOperator(uint256 _assignOperatorId, uint256 _operatorId) external onlyOwner {
        // assignOperatorId must be a blacklist operator
        if (!nodeOperatorRegistryContract.isTrustedOperator(_operatorId)) revert RequireOperatorTrusted();

        uint256 assignOperatorBalances = _assignOperator(_assignOperatorId, _operatorId);
        if (nodeOperatorRegistryContract.isQuitOperator(_assignOperatorId)) {
            if (reAssignRecords[_assignOperatorId] != 0) {
                if (reAssignRecords[_assignOperatorId] != _operatorId) revert AssignMustSameOperator();
            }

            reAssignRecords[_assignOperatorId] = _operatorId;
        } else {
            if (!nodeOperatorRegistryContract.isBlacklistOperator(_assignOperatorId)) revert RequireBlacklistOperator();
        }

        emit OperatorAssigned(_assignOperatorId, _operatorId, assignOperatorBalances);
    }

    function _assignOperator(uint256 _assignOperatorId, uint256 _operatorId) internal returns (uint256) {
        uint256 assignOperatorBalances = operatorPoolBalances[_assignOperatorId];
        uint256 loanAmounts = operatorLoanRecords[_assignOperatorId];
        if (loanAmounts > 0) {
            if (loanAmounts > assignOperatorBalances) {
                operatorLoanRecords[_assignOperatorId] -= assignOperatorBalances;
                assignOperatorBalances = 0;
            } else {
                operatorLoanRecords[_assignOperatorId] = 0;
                assignOperatorBalances -= loanAmounts;
            }
        }

        operatorPoolBalances[_operatorId] += assignOperatorBalances;
        operatorPoolBalances[_assignOperatorId] = 0;

        return assignOperatorBalances;
    }

    /**
     * @notice stake eth to designated operator, stake ETH to get nETH
     * @param _operatorId operator id
     */
    function stakeETH(uint256 _operatorId) external payable nonReentrant whenNotPaused {
        if (msg.value < 1000 gwei) revert InvalidAmount();

        // operatorId must be a trusted operator
        if (!nodeOperatorRegistryContract.isTrustedOperator(_operatorId)) revert RequireOperatorTrusted();

        // Must meet the basic mortgage funds before being allowed to be entrusted
        if (!nodeOperatorRegistryContract.isConformBasicPledge(_operatorId)) revert InsufficientMargin();

        // When the deposit rate is not 0, charge the fee
        uint256 depositFeeAmount;
        uint256 depositPoolAmount;
        if (depositFeeRate == 0) {
            depositPoolAmount = msg.value;
        } else {
            depositFeeAmount = msg.value * depositFeeRate / totalBasisPoints;
            depositPoolAmount = msg.value - depositFeeAmount;
            if (daoVaultAddress == address(0)) revert InvalidDaoVaultAddr();
            payable(daoVaultAddress).transfer(depositFeeAmount);
            emit Transferred(daoVaultAddress, depositFeeAmount);
        }

        // 1. Convert depositAmount according to the exchange rate of nETH
        // 2. Mint nETH
        uint256 amountOut = _getNethOut(depositPoolAmount);
        nETHContract.whiteListMint(amountOut, msg.sender);

        _updateStakeFundLedger(_operatorId, depositPoolAmount);
        _stakeRecords(_operatorId, msg.sender, amountOut);

        emit EthStake(_operatorId, msg.sender, msg.value, amountOut);
    }

    function _updateStakeFundLedger(uint256 _operatorId, uint256 _amount) internal {
        operatorPoolBalancesSum += _amount;

        uint256 loanAmounts = operatorLoanRecords[_operatorId];
        if (loanAmounts > 0) {
            if (loanAmounts > _amount) {
                operatorLoanRecords[_operatorId] -= _amount;
                _amount = 0;
            } else {
                operatorLoanRecords[_operatorId] = 0;
                operatorLoadBlockNumbers[_operatorId] = 0;
                _amount = _amount - loanAmounts;
            }
        }

        if (_amount > 0) {
            operatorPoolBalances[_operatorId] += _amount;
        }
    }

    function _stakeRecords(uint256 _operatorId, address _from, uint256 _amount) internal {
        StakeInfo[] memory records = stakeRecords[_from];
        if (records.length == 0) {
            stakeRecords[_from].push(StakeInfo({operatorId: _operatorId, quota: _amount}));
        } else {
            for (uint256 i = 0; i < records.length; ++i) {
                if (records[i].operatorId == _operatorId) {
                    stakeRecords[_from][i].quota += _amount;
                    return;
                }
            }

            stakeRecords[_from].push(StakeInfo({operatorId: _operatorId, quota: _amount}));
        }
    }

    /**
     * @notice unstake neth to designated operator
     * @param _operatorId operator id
     * @param _amounts untake neth amount
     */
    function unstakeETH(uint256 _operatorId, uint256 _amounts) public nonReentrant whenNotPaused {
        uint256 amountOut = _getEthOut(_amounts);

        _unstake(_operatorId, msg.sender, _amounts);

        uint256 targetOperatorId = _updateUnstakeFundLedger(amountOut, _operatorId);

        nETHContract.whiteListBurn(_amounts, msg.sender);
        payable(msg.sender).transfer(amountOut);

        emit EthUnstake(_operatorId, targetOperatorId, msg.sender, _amounts, amountOut);
    }

    function _unstake(uint256 _operatorId, address _from, uint256 _amount) internal {
        StakeInfo[] memory records = stakeRecords[_from];
        if (records.length == 0) revert UnstakeEthNoQuota();

        for (uint256 i = 0; i < records.length; ++i) {
            if (records[i].operatorId == _operatorId) {
                if (stakeRecords[_from][i].quota < _amount) revert UnstakeEthNoQuota();
                stakeRecords[_from][i].quota -= _amount;
                return;
            }
        }

        revert UnstakeEthNoQuota();
    }

    function _updateUnstakeFundLedger(uint256 _ethOutAmount, uint256 _operatorId) internal returns (uint256) {
        uint256 targetOperatorId = _operatorId;
        bool isQuit = nodeOperatorRegistryContract.isQuitOperator(_operatorId);
        if (isQuit) {
            uint256 reAssignOperatorId = reAssignRecords[_operatorId];
            if (reAssignOperatorId != 0) {
                targetOperatorId = reAssignOperatorId;
            }
        }

        uint256 operatorBalances = operatorPoolBalances[targetOperatorId];
        if (operatorBalances >= _ethOutAmount) {
            operatorPoolBalances[targetOperatorId] -= _ethOutAmount;
        } else {
            if (isQuit && (targetOperatorId == _operatorId)) revert OperatorLoanFailed();
            uint256 newLoanAmounts = _ethOutAmount - operatorBalances;
            uint256 operatorLoanAmounts = operatorLoanRecords[targetOperatorId];
            if ((operatorCanLoanAmounts < operatorLoanAmounts + newLoanAmounts)) revert OperatorLoanFailed();
            operatorPoolBalances[targetOperatorId] = 0;
            operatorLoanRecords[targetOperatorId] += newLoanAmounts;
            if (operatorLoadBlockNumbers[targetOperatorId] != 0) {
                operatorLoadBlockNumbers[targetOperatorId] = block.number;
            }
        }

        operatorPoolBalancesSum -= _ethOutAmount;

        return targetOperatorId;
    }

    /**
     * @notice Stake 32 multiples of eth to get the corresponding number of vNFTs
     * @param _operatorId operator id
     */
    function stakeNFT(uint256 _operatorId, address withdrawalCredentialsAddress)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        if (withdrawalCredentialsAddress == address(0)) revert InvalidWithdrawalCredentials();
        if (withdrawalCredentialsAddress.balance < 1 wei) revert InvalidWithdrawalCredentials();

        // operatorId must be a trusted operator
        if (!nodeOperatorRegistryContract.isTrustedOperator(_operatorId)) revert RequireOperatorTrusted();
        if (msg.value == 0 || msg.value % DEPOSIT_SIZE != 0) revert InvalidAmount();

        // Must meet the basic mortgage funds before being allowed to be entrusted
        if (!nodeOperatorRegistryContract.isConformBasicPledge(_operatorId)) revert InsufficientMargin();

        bytes memory userWithdrawalCredentials =
            bytes.concat(hex"010000000000000000000000", abi.encodePacked(withdrawalCredentialsAddress));

        uint256 mintNftsCount = msg.value / DEPOSIT_SIZE;
        for (uint256 i = 0; i < mintNftsCount; ++i) {
            vNFTContract.whiteListMint(bytes(""), userWithdrawalCredentials, msg.sender, _operatorId);
        }

        operatorNftPoolBalances[_operatorId] += msg.value;

        emit NftStake(_operatorId, msg.sender, mintNftsCount);
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
        if (_pubkeys.length != _signatures.length || _pubkeys.length != _depositDataRoots.length) {
            revert InvalidParameter();
        }
        // must be a trusted operator
        uint256 operatorId = nodeOperatorRegistryContract.isTrustedOperatorOfControllerAddress(msg.sender);
        if (operatorId == 0) revert RequireOperatorTrusted();

        if ((operatorPoolBalances[operatorId] + operatorNftPoolBalances[operatorId]) / DEPOSIT_SIZE < _pubkeys.length) {
            revert InsufficientFunds();
        }

        uint256 userValidatorNumber = 0;
        for (uint256 i = 0; i < _pubkeys.length; ++i) {
            uint256 count = _stakeAndMint(operatorId, _pubkeys[i], _signatures[i], _depositDataRoots[i]);
            userValidatorNumber += count;
        }

        uint256 stakeAmount = DEPOSIT_SIZE * _pubkeys.length;
        uint256 userStakeAmount = DEPOSIT_SIZE * userValidatorNumber;
        uint256 poolStakeAmount = stakeAmount - userStakeAmount;
        operatorPoolBalances[operatorId] -= poolStakeAmount;
        operatorPoolBalancesSum -= poolStakeAmount;
        if (userStakeAmount != 0) {
            operatorNftPoolBalances[operatorId] -= userStakeAmount;
        }

        withdrawOracleContract.addPendingBalances(poolStakeAmount);
    }

    function _stakeAndMint(
        uint256 _operatorId,
        bytes calldata _pubkey,
        bytes calldata _signature,
        bytes32 _depositDataRoot
    ) internal returns (uint256) {
        bytes memory nextValidatorWithdrawalCredential = vNFTContract.getNextValidatorWithdrawalCredential(_operatorId);
        bytes memory _withdrawalCredential = (nextValidatorWithdrawalCredential.length != 0)
            ? nextValidatorWithdrawalCredential
            : liquidStakingWithdrawalCredentials;

        depositContract.deposit{value: 32 ether}(_pubkey, _withdrawalCredential, _signature, _depositDataRoot);

        uint256 tokenId = vNFTContract.whiteListMint(_pubkey, _withdrawalCredential, address(this), _operatorId);

        emit ValidatorRegistered(_operatorId, tokenId, _pubkey);

        if (nextValidatorWithdrawalCredential.length != 0) {
            return 1;
        }

        return 0;
    }

    /**
     * @notice Update the status of the corresponding nft according to the report result of the oracle machine
     * @param _tokenIds token id
     * @param _exitBlockNumbers exit block number
     */
    function nftExitHandle(uint256[] memory _tokenIds, uint256[] memory _exitBlockNumbers) external onlyVaultManager {
        vNFTContract.setNftExitBlockNumbers(_tokenIds, _exitBlockNumbers);

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            if (vNFTContract.ownerOf(tokenId) == address(this)) {
                vNFTContract.whiteListBurn(tokenId);
            }
        }

        emit NftExitBlockNumberSet(_tokenIds, _exitBlockNumbers);
    }

    /**
     * @notice According to the settlement results of the vaultManager, the income of the re-investment execution layer
     * @param _operatorIds operator id
     * @param _amounts reinvest amounts
     */
    function reinvestElRewards(uint256[] memory _operatorIds, uint256[] memory _amounts) external onlyVaultManager {
        if (_operatorIds.length != _amounts.length) revert InvalidParameter();
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            uint256 operatorId = _operatorIds[i];
            uint256 _amount = _amounts[i];
            if (_amount == 0) {
                continue;
            }

            address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(operatorId);
            IELVault(vaultContractAddress).reinvestment(_amount);

            _updateStakeFundLedger(operatorId, _amount);
            emit OperatorReinvestElRewards(operatorId, _amount);
        }
    }

    /**
     * @notice According to the reported results of the oracle machine, the income of the consensus layer is re-invested
     * @param _operatorIds operator id
     * @param _amounts reinvest amounts
     * @param _totalAmount totalAmount
     */
    function reinvestClRewards(uint256[] memory _operatorIds, uint256[] memory _amounts, uint256 _totalAmount)
        external
        onlyVaultManager
    {
        if (_operatorIds.length != _amounts.length) revert InvalidParameter();
        consensusVaultContract.reinvestment(_totalAmount);

        uint256 totalReinvestRewards = 0;
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            uint256 operatorId = _operatorIds[i];
            uint256 _amount = _amounts[i];
            if (_amount == 0) {
                continue;
            }
            totalReinvestRewards += _amount;

            uint256 operatorPendingRequestAmount;
            uint256 operatorPendingPool;
            (operatorPendingRequestAmount, operatorPendingPool) =
                withdrawalRequestContract.getOperatorLargeWithdrawalPendingInfo(operatorId);
            if (operatorPendingPool < operatorPendingRequestAmount) {
                uint256 withdrawalAmounts = 0;
                if (operatorPendingPool + _amount >= operatorPendingRequestAmount) {
                    withdrawalAmounts = operatorPendingRequestAmount - operatorPendingPool;
                    _amount -= withdrawalAmounts;
                } else {
                    withdrawalAmounts = _amount;
                    _amount = 0;
                }
                withdrawalRequestContract.receiveWithdrawals{value: withdrawalAmounts}(operatorId, withdrawalAmounts);
            }
            if (_amount != 0) {
                _updateStakeFundLedger(operatorId, _amount);
                emit OperatorReinvestClRewards(operatorId, _amount);
            }
        }

        if (_totalAmount != totalReinvestRewards) revert InvalidParameter();
    }

    /**
     * @notice When the operator is punished due to an error in operation, the penalty funds are recharged to its own pledge pool
     * @param _operatorId operator id
     * @param _amount slash amount
     */
    function addPenaltyFundToStakePool(uint256 _operatorId, uint256 _amount) external payable onlyOperatorSlash {
        _updateStakeFundLedger(_operatorId, _amount);
    }

    /**
     * @notice When withdrawing a large amount, update the user's unstake quota
     * @param _operatorId operator id
     * @param _from user address
     * @param _amount unstakeETH amount
     */
    function largeWithdrawalUnstake(uint256 _operatorId, address _from, uint256 _amount)
        external
        onlyWithdrawalRequest
    {
        _unstake(_operatorId, _from, _amount);
    }

    /**
     * @notice large withdrawals, when users claim eth, will trigger the burning of locked Neth
     * @param _totalRequestNethAmount totalRequestNethAmount will burn
     * @param _to burn neth address
     */
    function LargeWithdrawalRequestBurnNeth(uint256 _totalRequestNethAmount, address _to)
        external
        onlyWithdrawalRequest
    {
        nETHContract.whiteListBurn(_totalRequestNethAmount, address(_to));
    }

    /**
     * @notice When unstakeNFT, if the funds pledged by the user have not been deposited, the user is allowed to withdraw directly
     * @param _operatorId operator id
     * @param _tokenId tokenId
     * @param _to receiving address
     */
    function fastUnstakeNFT(uint256 _operatorId, uint256 _tokenId, address _to) external onlyWithdrawalRequest {
        operatorNftPoolBalances[_operatorId] -= DEPOSIT_SIZE;
        payable(_to).transfer(DEPOSIT_SIZE);
        emit Transferred(_to, DEPOSIT_SIZE);
        vNFTContract.whiteListBurn(_tokenId);
    }

    /**
     * @notice Obtain the available amount that the user can unstake
     * @param _from user addresss
     */
    function getUnstakeQuota(address _from) public view returns (StakeInfo[] memory) {
        return stakeRecords[_from];
    }

    /**
     * @notice Obtain the unstake amount available for users under a certain operator
     * @param _operatorId operator Id
     */
    function getOperatorNethUnstakePoolAmounts(uint256 _operatorId) public view returns (uint256) {
        uint256 targetOperatorId = _operatorId;
        bool isQuit = nodeOperatorRegistryContract.isQuitOperator(_operatorId);
        if (isQuit) {
            uint256 reAssignOperatorId = reAssignRecords[_operatorId];
            if (reAssignOperatorId != 0) {
                targetOperatorId = reAssignOperatorId;
            }
        }

        uint256 operatorBalances = operatorPoolBalances[targetOperatorId];

        uint256 operatorLoanAmounts = operatorLoanRecords[targetOperatorId];

        if (operatorLoanAmounts >= operatorCanLoanAmounts) {
            return operatorBalances;
        }

        uint256 totalUnstakePoolAmounts = operatorBalances + operatorCanLoanAmounts - operatorLoanAmounts;
        if (totalUnstakePoolAmounts > operatorPoolBalancesSum) {
            return operatorPoolBalancesSum;
        }

        return totalUnstakePoolAmounts;
    }

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
    ) external nonReentrant whenNotPaused onlyVaultManager {
        if (_tokenIds.length == 0 || _gasHeight > block.number) revert InvalidParameter();

        uint256[] memory exitBlockNumbers = vNFTContract.getNftExitBlockNumbers(_tokenIds);

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];

            if (exitBlockNumbers[i] != 0) {
                vNFTContract.whiteListBurn(tokenId);
            } else {
                vNFTContract.setUserNftGasHeight(tokenId, _gasHeight);
            }
        }

        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(_operatorId);
        IELVault(vaultContractAddress).transfer(_totalNftRewards, _owner);

        emit UserClaimRewards(_operatorId, _tokenIds, _totalNftRewards);
    }

    /**
     * @notice The operator claims the operation reward
     * @param _operatorId operator Id
     * @param _rewardAddresses reward address
     * @param _rewards _rewards
     */
    function claimRewardsOfOperator(uint256 _operatorId, address[] memory _rewardAddresses, uint256[] memory _rewards)
        external
        nonReentrant
        whenNotPaused
        onlyVaultManager
    {
        if (operatorLoanRecords[_operatorId] != 0) revert OperatorHasArrears();
        address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(_operatorId);

        for (uint256 i = 0; i < _rewardAddresses.length; ++i) {
            IELVault(vaultContractAddress).transfer(_rewards[i], _rewardAddresses[i]);
        }
    }

    /**
     * @notice The dao claims to belong to the dao reward
     * @param _operatorIds operators Id
     * @param _rewards rewards
     */
    function claimRewardsOfDao(uint256[] memory _operatorIds, uint256[] memory _rewards)
        external
        nonReentrant
        whenNotPaused
        onlyVaultManager
    {
        if (_operatorIds.length != _rewards.length || _rewards.length == 0) revert InvalidParameter();
        for (uint256 i = 0; i < _operatorIds.length; ++i) {
            uint256 _operatorId = _operatorIds[i];
            address vaultContractAddress = nodeOperatorRegistryContract.getNodeOperatorVaultContract(_operatorId);
            IELVault(vaultContractAddress).transfer(_rewards[i], daoVaultAddress);
            emit DaoClaimRewards(_operatorId, _rewards[i]);
        }
    }

    /**
     * @notice Get the total amount of ETH in the protocol
     */
    function getTotalEthValue() public view returns (uint256) {
        return operatorPoolBalancesSum + withdrawOracleContract.getPendingBalances()
            + withdrawOracleContract.getClBalances() + withdrawOracleContract.getClVaultBalances()
            - withdrawOracleContract.getLastClSettleAmount() - withdrawalRequestContract.getTotalPendingClaimedAmounts();
    }

    /**
     * @notice nETH to ETH exchange rate
     * @param _nethAmountIn nETH amount
     */
    function getEthOut(uint256 _nethAmountIn) external view returns (uint256) {
        return _getEthOut(_nethAmountIn);
    }

    function _getEthOut(uint256 _nethAmountIn) internal view returns (uint256) {
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
    function getNethOut(uint256 _ethAmountIn) external view returns (uint256) {
        return _getNethOut(_ethAmountIn);
    }

    function _getNethOut(uint256 _ethAmountIn) internal view returns (uint256) {
        uint256 totalEth = getTotalEthValue();
        uint256 nethSupply = nETHContract.totalSupply();
        if (nethSupply == 0) {
            return _ethAmountIn;
        }
        if (totalEth == 0) revert TotalEthIsZero();
        return _ethAmountIn * (nethSupply) / (totalEth);
    }

    /**
     * @notice nETH to ETH exchange rate
     */
    function getExchangeRate() external view returns (uint256) {
        return _getEthOut(1 ether);
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
     * @notice set dao address
     * @param _dao new dao address
     */
    function setDaoAddress(address _dao) external onlyOwner {
        if (_dao == address(0)) revert InvalidParameter();
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    /**
     * @notice change liquidStaking contract setting
     * @param _daoVaultAddress new dao vault address
     * @param _nodeOperatorRegistryContract new nodeOperatorRegistryContract
     * @param _withdrawOracleContractAddress new withdrawOracleContract address
     * @param _operatorSlashContract new operatorSlashContract address
     * @param _withdrawalRequestContractAddress new withdrawalRequestContract address
     * @param _vaultManagerContract new vaultManagerContract address
     */
    function changeCountractSetting(
        address _daoVaultAddress,
        address _nodeOperatorRegistryContract,
        address _withdrawOracleContractAddress,
        address _operatorSlashContract,
        address _withdrawalRequestContractAddress,
        address _vaultManagerContract
    ) external onlyDao {
        if (_daoVaultAddress != address(0)) {
            emit DaoVaultAddressChanged(daoVaultAddress, _daoVaultAddress);
            daoVaultAddress = _daoVaultAddress;
        }
        if (_nodeOperatorRegistryContract != address(0)) {
            emit NodeOperatorRegistryContractSet(address(nodeOperatorRegistryContract), _nodeOperatorRegistryContract);
            nodeOperatorRegistryContract = INodeOperatorsRegistry(_nodeOperatorRegistryContract);
        }
        if (_withdrawOracleContractAddress != address(0)) {
            emit WithdrawOracleContractSet(address(withdrawOracleContract), _withdrawOracleContractAddress);
            withdrawOracleContract = IWithdrawOracle(_withdrawOracleContractAddress);
        }
        if (_operatorSlashContract != address(0)) {
            emit OperatorSlashContractSet(address(operatorSlashContract), _operatorSlashContract);
            operatorSlashContract = IOperatorSlash(_operatorSlashContract);
        }
        if (_withdrawalRequestContractAddress != address(0)) {
            emit WithdrawalRequestContractSet(address(withdrawalRequestContract), _withdrawalRequestContractAddress);
            withdrawalRequestContract = IWithdrawalRequest(_withdrawalRequestContractAddress);
        }
        if (_vaultManagerContract != address(0)) {
            emit VaultManagerContractSet(vaultManagerContractAddress, _vaultManagerContract);
            vaultManagerContractAddress = _vaultManagerContract;
        }
    }

    /**
     * @notice Set staking fee rate
     * @param _feeRate new stake fee rate
     */
    function setDepositFeeRate(uint256 _feeRate) external onlyDao {
        if (_feeRate > 1000) revert InvalidParameter();
        emit DepositFeeRateSet(depositFeeRate, _feeRate);
        depositFeeRate = _feeRate;
    }

    /**
     * @notice Set new operatorCanLoanAmounts
     * @param _newCanLoanAmounts new _newCanloadAmounts
     */
    function setOperatorCanLoanAmounts(uint256 _newCanLoanAmounts) public onlyDao {
        if (_newCanLoanAmounts > 1000 ether) revert InvalidParameter();
        emit OperatorCanLoanAmountsSet(operatorCanLoanAmounts, _newCanLoanAmounts);
        operatorCanLoanAmounts = _newCanLoanAmounts;
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