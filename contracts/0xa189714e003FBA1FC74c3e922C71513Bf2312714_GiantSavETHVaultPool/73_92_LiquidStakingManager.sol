// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ITransactionRouter.sol";
import { IBalanceReporter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IBalanceReporter.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";
import { IStakeHouseRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseRegistry.sol";

import { SavETHVaultDeployer } from "./SavETHVaultDeployer.sol";
import { StakingFundsVaultDeployer } from "./StakingFundsVaultDeployer.sol";
import { StakingFundsVault } from "./StakingFundsVault.sol";
import { SavETHVault } from "./SavETHVault.sol";
import { LSDNFactory } from "./LSDNFactory.sol";
import { LPToken } from "./LPToken.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { SyndicateFactory } from "../syndicate/SyndicateFactory.sol";
import { Syndicate } from "../syndicate/Syndicate.sol";
import { OptionalHouseGatekeeper } from "./OptionalHouseGatekeeper.sol";
import { OptionalGatekeeperFactory } from "./OptionalGatekeeperFactory.sol";
import { OwnableSmartWalletFactory } from "../smart-wallet/OwnableSmartWalletFactory.sol";
import { IOwnableSmartWalletFactory } from "../smart-wallet/interfaces/IOwnableSmartWalletFactory.sol";
import { IOwnableSmartWallet } from "../smart-wallet/interfaces/IOwnableSmartWallet.sol";
import { ISyndicateFactory } from "../interfaces/ISyndicateFactory.sol";
import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";
import { IBrandNFT } from "../interfaces/IBrandNFT.sol";
import { IBrandCentral } from "../interfaces/IBrandCentral.sol";
import { IRestrictedTickerRegistry } from "../interfaces/IRestrictedTickerRegistry.sol";
import { ICIP } from "../interfaces/ICIP.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

error EmptyArray();
error ZeroAddress();
error OnlyEOA();
error InconsistentArrayLength();
error OnlyDAO();
error OnlyDAOOrNodeRunner();
error InvalidTickerLength();
error TickerAlreadyTaken();
error InvalidAddress();
error NodeRunnerNotWhitelisted();
error NotEnoughETHToStake();
error InvalidAmount();
error GoMintDerivatives();
error HouseAlreadyCreated();
error BLSPubKeyBanned();
error OnlyNodeRunner();
error InitialsNotRegistered();
error DAOKillSwitchNotActivated();
error OnlyCIP();
error NewRunnerHasASmartWallet();
error NodeRunnerNotPermitted();
error BLSKeyAlreadyRegistered();
error BLSKeyNotRegistered();
error InvalidEOA();
error DepositNotCompleted();
error InvalidCommission();
error NothingReceived();

contract LiquidStakingManager is ILiquidStakingManager, Initializable, ReentrancyGuard, StakehouseAPI, ETHTransferHelper {

    /// @notice signalize change in status of whitelisting
    event WhitelistingStatusChanged(address indexed dao, bool updatedStatus);

    /// @notice signalize updated whitelist status of node runner
    event NodeRunnerWhitelistingStatusChanged(address indexed nodeRunner, bool updatedStatus);

    /// @notice signalize creation of a new smart wallet
    event SmartWalletCreated(address indexed smartWallet, address indexed nodeRunner);

    /// @notice signalize appointing of a representative for a smart wallet by the node runner
    event RepresentativeAppointed(address indexed smartWallet, address indexed eoaRepresentative);

    /// @notice signalize staking of a KNOT
    event KnotStaked(bytes _blsPublicKeyOfKnot, address indexed trigerringAddress);

    /// @notice signalize creation of stakehouse
    event StakehouseCreated(string stakehouseTicker, address indexed stakehouse);

    /// @notice signalize joining a stakehouse
    event StakehouseJoined(bytes blsPubKey);

    ///@notice signalize removal of representative from smart wallet
    event RepresentativeRemoved(address indexed smartWallet, address indexed eoaRepresentative);

    /// @notice signalize refund of withdrawal of 4 ETH for a BLS public key by the node runner
    event ETHWithdrawnFromSmartWallet(address indexed associatedSmartWallet, bytes blsPublicKeyOfKnot, address nodeRunner);

    /// @notice signalize that the network has updated its ticker before its house was created
    event NetworkTickerUpdated(string newTicker);

    /// @notice signalize that the node runner has claimed rewards from the syndicate
    event NodeRunnerRewardsClaimed(address indexed nodeRunner, address indexed recipient);

    /// @notice signalize that the node runner of the smart wallet has been rotated
    event NodeRunnerOfSmartWalletRotated(address indexed wallet, address indexed oldRunner, address indexed newRunner);

    /// @notice signalize banning of a node runner
    event NodeRunnerBanned(address indexed nodeRunner);

    /// @notice signalize that the dao management address has been moved
    event UpdateDAOAddress(address indexed oldAddress, address indexed newAddress);

    /// @notice signalize that the dao commission from network revenue has been updated
    event DAOCommissionUpdated(uint256 old, uint256 newCommission);

    /// @notice signalize that a new BLS public key for an LSD validator has been registered
    event NewLSDValidatorRegistered(address indexed nodeRunner, bytes blsPublicKey);

    /// @notice Address of brand NFT
    address public brand;

    /// @notice stakehouse created by the LSD network
    address public override stakehouse;

    /// @notice Fees and MEV EIP1559 distribution contract for the LSD network
    address public syndicate;

    /// @notice address of the DAO deploying the contract
    address public dao;

    /// @notice address of optional gatekeeper for admiting new knots to the house created by the network
    OptionalHouseGatekeeper public gatekeeper;

    /// @notice instance of the syndicate factory that deploys the syndicates
    ISyndicateFactory public syndicateFactory;

    /// @notice instance of the smart wallet factory that deploys the smart wallets for node runners
    IOwnableSmartWalletFactory public smartWalletFactory;

    /// @notice string name for the stakehouse 3-5 characters long
    string public stakehouseTicker;

    /// @notice DAO staking funds vault
    StakingFundsVault public stakingFundsVault;

    /// @notice SavETH vault
    SavETHVault public savETHVault;

    /// @notice Address of the factory that deployed the liquid staking manager
    LSDNFactory public factory;

    /// @notice whitelisting indicator. true for enables and false for disabled
    bool public enableWhitelisting;

    /// @notice mapping to store if a node runner is whitelisted
    mapping(address => bool) public isNodeRunnerWhitelisted;

    /// @notice EOA representative appointed for a smart wallet
    mapping(address => address) public smartWalletRepresentative;

    /// @notice Smart wallet used to deploy KNOT
    mapping(bytes => address) public smartWalletOfKnot;

    /// @notice Smart wallet issued to the Node runner. Node runner address <> Smart wallet address
    mapping(address => address) public smartWalletOfNodeRunner;

    /// @notice Node runner issued to Smart wallet. Smart wallet address <> Node runner address
    mapping(address => address) public nodeRunnerOfSmartWallet;

    /// @notice Track number of staked KNOTs of a smart wallet
    mapping(address => uint256) public stakedKnotsOfSmartWallet;

    /// @notice smart wallet <> dormant rep.
    mapping(address => address) public smartWalletDormantRepresentative;

    /// @notice Track BLS public keys that have been banned. 
    /// If banned, the BLS public key will be mapped to its respective smart wallet
    mapping(bytes => address) public bannedBLSPublicKeys;

    /// @notice Track node runner addresses that are banned.
    /// Malicious node runners can be banned by the DAO
    mapping(address => bool) public bannedNodeRunners;

    /// @notice count of KNOTs interacted with LSD network
    uint256 public numberOfKnots;

    /// @notice Commission percentage to 5 decimal places
    uint256 public daoCommissionPercentage;

    /// @notice 100% to 5 decimal places
    uint256 public constant MODULO = 100_00000;

    /// @notice Maximum commission that can be requested from the DAO
    uint256 public constant MAX_COMMISSION = MODULO / 2;

    modifier onlyDAO() {
        if (msg.sender != dao) revert OnlyDAO();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc ILiquidStakingManager
    function init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) external virtual override initializer {
        _init(
            _dao,
            _syndicateFactory,
            _smartWalletFactory,
            _lpTokenFactory,
            _brand,
            _savETHVaultDeployer,
            _stakingFundsVaultDeployer,
            _optionalGatekeeperDeployer,
            _optionalCommission,
            _deployOptionalGatekeeper,
            _stakehouseTicker
        );
    }

    /// @notice Allow DAO or node runner to recover the signing key of a validator
    /// @param _safeBox Address of the safe box performing recovery
    /// @param _nodeRunner Address of the node runner associated with a BLS key
    /// @param _blsPublicKey BLS public key of validator requesting signing key recovery
    /// @param _hAesPublicKey Hybrid encryption public key that can unlock multiparty computation used for recovery
    function recoverSigningKey(
        address _safeBox,
        address _nodeRunner,
        bytes calldata _blsPublicKey,
        bytes calldata _hAesPublicKey
    ) external nonReentrant {
        address smartWallet = smartWalletOfNodeRunner[_nodeRunner];
        if (smartWallet == address(0)) revert ZeroAddress();
        if (smartWalletOfKnot[_blsPublicKey] != smartWallet) revert BLSKeyNotRegistered();
        if (msg.sender != dao && msg.sender != _nodeRunner) revert OnlyDAOOrNodeRunner();
        IOwnableSmartWallet(smartWallet).execute(
            _safeBox,
            abi.encodeWithSelector(
                ICIP.applyForDecryption.selector,
                _blsPublicKey,
                stakehouse,
                _hAesPublicKey
            )
        );
    }

    /// @notice Allow the rage quit of a knot from the Stakehouse protocol
    /// @param _nodeRunner Address of the node runner that has a smart wallet associated with the BLS public key
    /// @param _blsPublicKey BLS public key of the KNOT being rage quit
    /// @param _balanceReport of the KNOT before rage quit
    /// @param _signature Signature from the designated verifier over the balance report
    function rageQuit(
        address _nodeRunner,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _balanceReport,
        IDataStructures.EIP712Signature calldata _signature
    ) external {
        address smartWallet = smartWalletOfNodeRunner[_nodeRunner];
        if (smartWallet == address(0)) revert ZeroAddress();
        if (smartWalletOfKnot[_blsPublicKey] != smartWallet) revert BLSKeyNotRegistered();
        if (msg.sender != dao && msg.sender != _nodeRunner) revert OnlyDAOOrNodeRunner();
        IOwnableSmartWallet(smartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                IBalanceReporter.rageQuitKnot.selector,
                stakehouse,
                _blsPublicKey,
                _balanceReport,
                _signature
            )
        );
    }

    /// @notice After kill switch has been enabled by the DAO, allow a node operator to transfer ownership of their smart wallet
    /// @param _newOwner Address of the account that will take ownership of wallet and collateralized slot
    function transferSmartWalletOwnership(address _newOwner) external {
        if (dao != address(0)) revert DAOKillSwitchNotActivated();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert ZeroAddress();

        IOwnableSmartWallet(smartWallet).transferOwnership(_newOwner);
    }

    /// @notice Allow the DAO to manage whether the house can received members outside LSD (if it has a deployed gatekeeper)
    function toggleHouseGatekeeper(bool _enabled) external onlyDAO {
        if (_enabled) {
            IStakeHouseRegistry(stakehouse).setGateKeeper(address(gatekeeper));
        } else {
            IStakeHouseRegistry(stakehouse).setGateKeeper(address(0));
        }
    }

    /// @notice For knots no longer operational, DAO can de register the knot from the syndicate
    function deRegisterKnotFromSyndicate(bytes[] calldata _blsPublicKeys) external onlyDAO nonReentrant {
        Syndicate(payable(syndicate)).deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allows the DAO to append to the list of knots that are part of the syndicate
    /// @param _newBLSPublicKeyBeingRegistered List of BLS public keys being added to the syndicate
    function registerKnotsToSyndicate(
        bytes[] calldata _newBLSPublicKeyBeingRegistered
    ) external onlyDAO nonReentrant {
        Syndicate(payable(syndicate)).registerKnotsToSyndicate(_newBLSPublicKeyBeingRegistered);
    }

    /// @notice Allows the DAO to manage the syndicate activation distance based on the consensus layer activation queue
    function updateSyndicateActivationDistanceInBlocks(uint256 _distance) external onlyDAO {
        Syndicate(payable(syndicate)).updateActivationDistanceInBlocks(_distance);
    }

    /// @notice Configure the house that users are joining when minting derivatives only for an empty LSD network
    function configureStakeHouse(bytes calldata _blsPublicKeyOfKnot) external onlyDAO {
        if (numberOfKnots != 0) revert HouseAlreadyCreated();

        numberOfKnots = 1;
        stakehouse = getStakeHouseUniverse().memberKnotToStakeHouse(_blsPublicKeyOfKnot);
        if (stakehouse == address(0)) revert ZeroAddress();

        _deploySyndicateAndApproveSETH(_blsPublicKeyOfKnot, IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse)));
    }

    /// @notice Liquid staking DAO can set the description and image of the brand NFT for the network
    function updateBrandInfo(
        uint256 _tokenId, string calldata _description, string calldata _imageURI
    ) external onlyDAO {
        IBrandNFT(brand).setBrandMetadata(_tokenId, _description, _imageURI);
    }

    /// @notice Allow DAO to migrate to a new address
    function updateDAOAddress(address _newAddress) external onlyDAO {
        emit UpdateDAOAddress(dao, _newAddress);
        dao = _newAddress;
    }

    /// @notice Allow DAO to take a commission of network revenue
    function updateDAORevenueCommission(uint256 _commissionPercentage) external onlyDAO {
        _updateDAORevenueCommission(_commissionPercentage);
    }

    /// @notice Allow the DAO to rotate the network ticker before the network house is created
    function updateTicker(string calldata _newTicker) external onlyDAO {
        _updateTicker(_newTicker);
    }

    /// @notice function to change whether node runner whitelisting of node runners is required by the DAO
    /// @param _changeWhitelist boolean value. true to enable and false to disable
    function updateWhitelisting(bool _changeWhitelist) external onlyDAO returns (bool) {
        enableWhitelisting = _changeWhitelist;
        emit WhitelistingStatusChanged(msg.sender, enableWhitelisting);

        return enableWhitelisting;
    }

    /// @notice Function to enable/disable whitelisting of a multiple node operators
    /// @param _nodeRunners List of node runners being whitelisted
    /// @param isWhitelisted true if the node runner should be whitelisted. false otherwise.
    function updateNodeRunnerWhitelistStatus(address[] calldata _nodeRunners, bool isWhitelisted) external onlyDAO {
        for (uint256 i; i < _nodeRunners.length; ++i) {
            isNodeRunnerWhitelisted[_nodeRunners[i]] = isWhitelisted;
            emit NodeRunnerWhitelistingStatusChanged(_nodeRunners[i], isWhitelisted);
        }
    }

    /// @notice Allow a node runner to rotate the EOA representative they use for their smart wallet
    /// @dev if any KNOT is staked for a smart wallet, no rep can be appointed or updated until the derivatives are minted
    /// @param _newRepresentative address of the new representative to be appointed
    function rotateEOARepresentative(address _newRepresentative) external {
        if (Address.isContract(_newRepresentative)) revert OnlyEOA();
        if (_newRepresentative == address(0)) revert ZeroAddress();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert OnlyNodeRunner();
        if (stakedKnotsOfSmartWallet[smartWallet] != 0) revert GoMintDerivatives();

        // unauthorize old representative
        _authorizeRepresentative(smartWallet, smartWalletRepresentative[smartWallet], false);

        // authorize new representative
        _authorizeRepresentative(smartWallet, _newRepresentative, true);
    }

    /// @notice Allow node runners to withdraw ETH from their smart wallet. ETH can only be withdrawn until the KNOT has not been staked.
    /// @dev A banned node runner cannot withdraw ETH for the KNOT. 
    /// @param _blsPublicKeyOfKnot BLS public key of the KNOT for which the ETH needs to be withdrawn
    function withdrawETHForKnot(address _recipient, bytes calldata _blsPublicKeyOfKnot) external nonReentrant {
        if (_recipient == address(0)) revert ZeroAddress();
        if (!isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot)) revert BLSKeyNotRegistered();
        if (isBLSPublicKeyBanned(_blsPublicKeyOfKnot)) revert BLSPubKeyBanned();

        address associatedSmartWallet = smartWalletOfKnot[_blsPublicKeyOfKnot];
        if (smartWalletOfNodeRunner[msg.sender] != associatedSmartWallet) revert OnlyNodeRunner();
        if (
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) != IDataStructures.LifecycleStatus.INITIALS_REGISTERED
        ) revert InitialsNotRegistered();

        // update the mapping
        bannedBLSPublicKeys[_blsPublicKeyOfKnot] = associatedSmartWallet;

        // refund 4 ether from smart wallet to node runner's EOA
        IOwnableSmartWallet(associatedSmartWallet).rawExecute(_recipient, "", 4 ether);

        emit ETHWithdrawnFromSmartWallet(associatedSmartWallet, _blsPublicKeyOfKnot, msg.sender);
    }

    /// @notice In the event the node runner coordinates with the DAO to sell their wallet, allow rotation
    /// @dev EOA representative rotation done outside this method because there may be knots currently staked etc.
    /// @param _current address of the present node runner of the smart wallet
    /// @param _new address of the new node runner of the smart wallet
    function manageNodeRunnerSmartWallet(
        address _current,
        address _new,
        bool _wasPreviousNodeRunnerMalicious
    ) external onlyDAO {
        if (_new != address(0) && _new != _current) {
            address wallet = smartWalletOfNodeRunner[_current];
            if (wallet == address(0)) revert ZeroAddress();
            if (wallet.balance >= 4 ether) revert InvalidAmount();

            if (smartWalletOfNodeRunner[_new] != address(0)) revert NewRunnerHasASmartWallet();

            smartWalletOfNodeRunner[_new] = wallet;
            nodeRunnerOfSmartWallet[wallet] = _new;

            delete smartWalletOfNodeRunner[_current];

            emit NodeRunnerOfSmartWalletRotated(wallet, _current, _new);
        }

        if (_wasPreviousNodeRunnerMalicious) {
            bannedNodeRunners[_current] = true;
            emit NodeRunnerBanned(_current);
        }
    }

    /// @notice function to allow a node runner to claim ETH from the syndicate from their smart wallet
    /// @param _recipient End recipient of ETH from syndicate rewards
    /// @param _blsPubKeys list of BLS public keys to claim reward for
    function claimRewardsAsNodeRunner(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert ZeroAddress();

        for(uint256 i; i < numOfKeys; ++i) {
            // check that the node runner doesn't claim rewards for KNOTs from other smart wallets
            if (smartWalletOfKnot[_blsPubKeys[i]] != smartWallet) revert OnlyNodeRunner();
        }

        // Fetch ETH accrued
        uint256 balBefore = address(this).balance;
        IOwnableSmartWallet(smartWallet).execute(
            syndicate,
            abi.encodeWithSelector(
                Syndicate.claimAsCollateralizedSLOTOwner.selector,
                address(this),
                _blsPubKeys
            )
        );

        (uint256 nodeRunnerAmount, uint256 daoAmount) = _calculateCommission(address(this).balance - balBefore);

        _transferETH(_recipient, nodeRunnerAmount);

        if (daoAmount > 0) _transferETH(dao, daoAmount);

        emit NodeRunnerRewardsClaimed(msg.sender, _recipient);
    }

    /// @notice register a node runner to LSD by creating a new smart wallet
    /// @param _blsPublicKeys list of BLS public keys
    /// @param _blsSignatures list of BLS signatures
    /// @param _eoaRepresentative EOA representative of wallet
    function registerBLSPublicKeys(
        bytes[] calldata _blsPublicKeys,
        bytes[] calldata _blsSignatures,
        address _eoaRepresentative
    ) external payable nonReentrant {
        uint256 len = _blsPublicKeys.length;
        if (len == 0) revert EmptyArray();
        if (len != _blsSignatures.length) revert InconsistentArrayLength();
        if (msg.value != len * 4 ether) revert InvalidAmount();
        if (Address.isContract(_eoaRepresentative)) revert OnlyEOA();
        if (!_isNodeRunnerValid(msg.sender)) revert NodeRunnerNotPermitted();
        if (isNodeRunnerBanned(msg.sender)) revert NodeRunnerNotPermitted();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];

        if(smartWallet == address(0)) {
            // create new wallet owned by liquid staking manager
            smartWallet = smartWalletFactory.createWallet(address(this));
            emit SmartWalletCreated(smartWallet, msg.sender);

            // associate node runner with the newly created wallet
            smartWalletOfNodeRunner[msg.sender] = smartWallet;
            nodeRunnerOfSmartWallet[smartWallet] = msg.sender;

            _authorizeRepresentative(smartWallet, _eoaRepresentative, true);
        }

        // Ensure that the node runner does not whitelist multiple EOA representatives - they can only have 1 active at a time
        if(smartWalletRepresentative[smartWallet] != address(0)) {
            if (smartWalletRepresentative[smartWallet] != _eoaRepresentative) revert InvalidEOA();
        }

        // transfer ETH to smart wallet
        _transferETH(smartWallet, msg.value);

        for(uint256 i; i < len; ++i) {
            bytes calldata _blsPublicKey = _blsPublicKeys[i];

            // check if the BLS public key is part of LSD network and is not banned
            if (isBLSPublicKeyPartOfLSDNetwork(_blsPublicKey)) revert BLSKeyAlreadyRegistered();
            if (bannedBLSPublicKeys[_blsPublicKey] != address(0)) revert BLSPubKeyBanned();

            if (
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKey) != IDataStructures.LifecycleStatus.UNBEGUN
            ) revert BLSKeyAlreadyRegistered();

            // register validtor initals for each of the KNOTs
            IOwnableSmartWallet(smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.registerValidatorInitials.selector,
                    smartWallet,
                    _blsPublicKey,
                    _blsSignatures[i]
                )
            );

            // register the smart wallet with the BLS public key
            smartWalletOfKnot[_blsPublicKey] = smartWallet;

            emit NewLSDValidatorRegistered(msg.sender, _blsPublicKey);
        }
    }

    /// @inheritdoc ILiquidStakingManager
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        return smartWalletOfKnot[_blsPublicKeyOfKnot] != address(0);
    }

    /// @inheritdoc ILiquidStakingManager
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        bool isPartOfNetwork = isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot);
        return !isPartOfNetwork ? true : bannedBLSPublicKeys[_blsPublicKeyOfKnot] != address(0);
    }

    /// @notice function to check if a node runner address is banned
    /// @param _nodeRunner address of the node runner
    /// @return true if the node runner is banned, false otherwise
    function isNodeRunnerBanned(address _nodeRunner) public view returns (bool) {
        return bannedNodeRunners[_nodeRunner];
    }

    /// @notice Anyone can call this to trigger staking once they have all of the required input params from BLS authentication
    /// @param _blsPublicKeyOfKnots List of knots being staked with the Ethereum deposit contract (32 ETH sourced within the network)
    /// @param _ciphertexts List of backed up validator operations encrypted and stored to the Ethereum blockchain
    /// @param _aesEncryptorKeys List of public identifiers of credentials that performed the trustless backup
    /// @param _encryptionSignatures List of EIP712 signatures attesting to the correctness of the BLS signature
    /// @param _dataRoots List of serialized SSZ containers of the DepositData message for each validator used by Ethereum deposit contract
    function stake(
        bytes[] calldata _blsPublicKeyOfKnots,
        bytes[] calldata _ciphertexts,
        bytes[] calldata _aesEncryptorKeys,
        IDataStructures.EIP712Signature[] calldata _encryptionSignatures,
        bytes32[] calldata _dataRoots
    ) external nonReentrant {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        if (numOfValidators == 0) revert EmptyArray();
        if (numOfValidators != _ciphertexts.length) revert InconsistentArrayLength();
        if (numOfValidators != _aesEncryptorKeys.length) revert InconsistentArrayLength();
        if (numOfValidators != _encryptionSignatures.length) revert InconsistentArrayLength();
        if (numOfValidators != _dataRoots.length) revert InconsistentArrayLength();

        for (uint256 i; i < numOfValidators; ++i) {
            bytes calldata blsPubKey = _blsPublicKeyOfKnots[i];
            // check if BLS public key is registered with liquid staking derivative network and not banned
            if (isBLSPublicKeyBanned(blsPubKey)) revert BLSPubKeyBanned();

            address associatedSmartWallet = smartWalletOfKnot[blsPubKey];
            if (associatedSmartWallet == address(0)) revert InitialsNotRegistered();
            if (isNodeRunnerBanned(nodeRunnerOfSmartWallet[associatedSmartWallet])) revert NodeRunnerNotPermitted();
            if (
                getAccountManager().blsPublicKeyToLifecycleStatus(blsPubKey) != IDataStructures.LifecycleStatus.INITIALS_REGISTERED
            ) revert InitialsNotRegistered();

            // check minimum balance of smart wallet, dao staking fund vault and savETH vault
            _assertEtherIsReadyForValidatorStaking(blsPubKey);

            _stake(
                blsPubKey,
                _ciphertexts[i],
                _aesEncryptorKeys[i],
                _encryptionSignatures[i],
                _dataRoots[i]
            );

            address representative = smartWalletRepresentative[associatedSmartWallet];

            if(representative != address(0)) {
                // unauthorize the EOA representative on the Stakehouse
                _authorizeRepresentative(associatedSmartWallet, representative, false);
                // make the representative dormant before unauthorizing it
                smartWalletDormantRepresentative[associatedSmartWallet] = representative;
            }
        }
    }

    /// @notice Anyone can call this to trigger creating a knot which will mint derivatives once the balance has been reported
    /// @param _blsPublicKeyOfKnots List of BLS public keys registered with the network becoming knots and minting derivatives
    /// @param _beaconChainBalanceReports List of beacon chain balance reports
    /// @param _reportSignatures List of attestations for the beacon chain balance reports
    function mintDerivatives(
        bytes[] calldata _blsPublicKeyOfKnots,
        IDataStructures.ETH2DataReport[] calldata _beaconChainBalanceReports,
        IDataStructures.EIP712Signature[] calldata _reportSignatures
    ) external nonReentrant {
        uint256 numOfKnotsToProcess = _blsPublicKeyOfKnots.length;
        if (numOfKnotsToProcess == 0) revert EmptyArray();
        if (numOfKnotsToProcess != _beaconChainBalanceReports.length) revert InconsistentArrayLength();
        if (numOfKnotsToProcess != _reportSignatures.length) revert InconsistentArrayLength();

        for (uint256 i; i < numOfKnotsToProcess; ++i) {
            // check if BLS public key is registered and not banned
            if (isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i])) revert BLSPubKeyBanned();

            // check that the BLS pub key has deposited lifecycle
            if(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) != IDataStructures.LifecycleStatus.DEPOSIT_COMPLETED
            ) revert DepositNotCompleted();

            // Expand the staking funds vault shares that can claim rewards
            stakingFundsVault.updateDerivativesMinted(_blsPublicKeyOfKnots[i]);

            // Poke the giant pools in the event they need to know about the minting of derivatives they funded
            factory.giantSavETHPool().onMintDerivatives(_blsPublicKeyOfKnots[i]);
            factory.giantFeesAndMev().onMintDerivatives(_blsPublicKeyOfKnots[i]);

            // The first knot will create the Stakehouse
            if(numberOfKnots == 0) {
                _createLSDNStakehouse(
                    _blsPublicKeyOfKnots[i],
                    _beaconChainBalanceReports[i],
                    _reportSignatures[i]
                );
            }
            else {
                // join stakehouse
                _joinLSDNStakehouse(
                    _blsPublicKeyOfKnots[i],
                    _beaconChainBalanceReports[i],
                    _reportSignatures[i]
                );
            }

            address smartWallet = smartWalletOfKnot[_blsPublicKeyOfKnots[i]];
            stakedKnotsOfSmartWallet[smartWallet] -= 1;

            if(stakedKnotsOfSmartWallet[smartWallet] == 0) {
                _authorizeRepresentative(smartWallet, smartWalletDormantRepresentative[smartWallet], true);

                // delete the dormant representative as it is set active
                delete smartWalletDormantRepresentative[smartWallet];
            }
        }
    }

    receive() external payable {}

    /// @notice Every liquid staking derivative network has a single fee recipient determined by its syndicate contract
    /// @dev The syndicate contract is only deployed after the first KNOT to mint derivatives creates the network Stakehouse
    /// @dev Because the syndicate contract for the LSDN is deployed with CREATE2, we can predict the fee recipient ahead of time
    /// @dev This is important because node runners need to configure their nodes before or immediately after staking
    function getNetworkFeeRecipient() external view returns (address) {
        // Always 1 knot initially registered to the syndicate because we expand it one by one
        return syndicateFactory.calculateSyndicateDeploymentAddress(
            address(this),
            address(this),
            1
        );
    }

    /// @dev Internal method for managing the initialization of the staking manager contract
    function _init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) internal {
        if (_dao == address(0)) revert ZeroAddress();

        brand = _brand;
        dao = _dao;
        syndicateFactory = ISyndicateFactory(_syndicateFactory);
        smartWalletFactory = IOwnableSmartWalletFactory(_smartWalletFactory);

        _updateTicker(_stakehouseTicker);

        _updateDAORevenueCommission(_optionalCommission);

        _initStakingFundsVault(_stakingFundsVaultDeployer, _lpTokenFactory);
        _initSavETHVault(_savETHVaultDeployer, _lpTokenFactory);

        factory = LSDNFactory(msg.sender);

        if (_deployOptionalGatekeeper) {
            gatekeeper = OptionalGatekeeperFactory(_optionalGatekeeperDeployer).deploy(address(this));
            enableWhitelisting = true;
            emit WhitelistingStatusChanged(dao, enableWhitelisting);
        }
    }

    /// @dev function checks if a node runner is valid depending upon whitelisting status
    /// @param _nodeRunner address of the user requesting to become node runner
    /// @return true if eligible. reverts with message if not eligible
    function _isNodeRunnerValid(address _nodeRunner) internal view returns (bool) {
        return enableWhitelisting && !isNodeRunnerWhitelisted[_nodeRunner] ? false : true;
    }

    /// @dev Manage the removal and appointing of smart wallet representatives including managing state
    function _authorizeRepresentative(
        address _smartWallet, 
        address _eoaRepresentative, 
        bool _isEnabled
    ) internal {
        if(!_isEnabled && smartWalletRepresentative[_smartWallet] != address(0)) {

            // authorize the EOA representative on the Stakehouse
            IOwnableSmartWallet(_smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.authorizeRepresentative.selector,
                    _eoaRepresentative,
                    _isEnabled
                )
            );

            // delete the mapping
            delete smartWalletRepresentative[_smartWallet];

            emit RepresentativeRemoved(_smartWallet, _eoaRepresentative);
        }
        else if(_isEnabled && smartWalletRepresentative[_smartWallet] == address(0)) {

            // authorize the EOA representative on the Stakehouse
            IOwnableSmartWallet(_smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.authorizeRepresentative.selector,
                    _eoaRepresentative,
                    _isEnabled
                )
            );

            // store EOA to the wallet mapping
            smartWalletRepresentative[_smartWallet] = _eoaRepresentative;

            emit RepresentativeAppointed(_smartWallet, _eoaRepresentative);
        } else {
            revert("Error");
        }
    }

    /// @dev Internal method for doing just staking - pre-checks done outside this method to avoid stack too deep
    function _stake(
        bytes calldata _blsPublicKey,
        bytes calldata _cipherText,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 dataRoot
    ) internal {
        address smartWallet = smartWalletOfKnot[_blsPublicKey];

        // send 24 ether from savETH vault to smart wallet
        savETHVault.withdrawETHForStaking(smartWallet, 24 ether);

        // send 4 ether from DAO staking funds vault
        stakingFundsVault.withdrawETH(smartWallet, 4 ether);

        // interact with transaction router using smart wallet to deposit 32 ETH
        IOwnableSmartWallet(smartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.registerValidator.selector,
                smartWallet,
                _blsPublicKey,
                _cipherText,
                _aesEncryptorKey,
                _encryptionSignature,
                dataRoot
            ),
            32 ether
        );

        // increment number of staked KNOTs in the wallet
        stakedKnotsOfSmartWallet[smartWallet] += 1;

        emit KnotStaked(_blsPublicKey, msg.sender);
    }

    /// @dev The second knot onwards will join the LSDN stakehouse and expand the registered syndicate knots
    function _joinLSDNStakehouse(
        bytes calldata _blsPubKey,
        IDataStructures.ETH2DataReport calldata _beaconChainBalanceReport,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) internal {
        // total number of knots created with the syndicate increases
        numberOfKnots += 1;

        // The savETH will go to the savETH vault, the collateralized SLOT for syndication owned by the smart wallet
        // sETH will also be minted in the smart wallet but will be moved out and distributed to the syndicate for claiming by the DAO
        address associatedSmartWallet = smartWalletOfKnot[_blsPubKey];

        // Join the LSDN stakehouse
        string memory lowerTicker = IBrandNFT(brand).toLowerCase(stakehouseTicker);
        IOwnableSmartWallet(associatedSmartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.joinStakehouse.selector,
                associatedSmartWallet,
                _blsPubKey,
                stakehouse,
                IBrandNFT(brand).lowercaseBrandTickerToTokenId(lowerTicker),
                savETHVault.indexOwnedByTheVault(),
                _beaconChainBalanceReport,
                _reportSignature
            )
        );

        // Register the knot to the syndicate
        bytes[] memory _blsPublicKeyOfKnots = new bytes[](1);
        _blsPublicKeyOfKnots[0] = _blsPubKey;
        Syndicate(payable(syndicate)).registerKnotsToSyndicate(_blsPublicKeyOfKnots);

        // Autostake DAO sETH with the syndicate
        _autoStakeWithSyndicate(associatedSmartWallet, _blsPubKey);

        emit StakehouseJoined(_blsPubKey);
    }

    /// @dev Perform all the steps required to create the LSDN stakehouse that other knots will join
    function _createLSDNStakehouse(
        bytes calldata _blsPublicKeyOfKnot,
        IDataStructures.ETH2DataReport calldata _beaconChainBalanceReport,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) internal {
        // create stakehouse and mint derivative for first bls key - the others are just used to create the syndicate
        // The savETH will go to the savETH vault, the collateralized SLOT for syndication owned by the smart wallet
        // sETH will also be minted in the smart wallet but will be moved out and distributed to the syndicate for claiming by the DAO
        address associatedSmartWallet = smartWalletOfKnot[_blsPublicKeyOfKnot];
        IOwnableSmartWallet(associatedSmartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.createStakehouse.selector,
                associatedSmartWallet,
                _blsPublicKeyOfKnot,
                stakehouseTicker,
                savETHVault.indexOwnedByTheVault(),
                _beaconChainBalanceReport,
                _reportSignature
            )
        );

        // Number of knots has increased
        numberOfKnots += 1;

        // Capture the address of the Stakehouse for future knots to join
        stakehouse = getStakeHouseUniverse().memberKnotToStakeHouse(_blsPublicKeyOfKnot);
        IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse));

        // Give liquid staking manager ability to manage keepers and set a house keeper if decided by the network
        IOwnableSmartWallet(associatedSmartWallet).execute(
            stakehouse,
            abi.encodeWithSelector(
                Ownable.transferOwnership.selector,
                address(this)
            )
        );

        IStakeHouseRegistry(stakehouse).setGateKeeper(address(gatekeeper));

        // Let the liquid staking manager take ownership of the brand NFT for management
        IOwnableSmartWallet(associatedSmartWallet).execute(
            brand,
            abi.encodeWithSelector(
                IBrandNFT.transferFrom.selector,
                associatedSmartWallet,
                address(this),
                IBrandNFT(brand).lowercaseBrandTickerToTokenId(IBrandNFT(brand).toLowerCase(stakehouseTicker))
            )
        );

        // Approve any future sETH for being staked in the Syndicate
        _deploySyndicateAndApproveSETH(_blsPublicKeyOfKnot, sETH);

        // Auto-stake sETH by pulling sETH out the smart wallet and staking in the syndicate
        _autoStakeWithSyndicate(associatedSmartWallet, _blsPublicKeyOfKnot);

        emit StakehouseCreated(stakehouseTicker, stakehouse);
    }

    function _deploySyndicateAndApproveSETH(
        bytes calldata _blsPublicKeyOfKnot,
        IERC20 _sETH
    ) internal {
        // Deploy the EIP1559 transaction reward sharing contract but no priority required because sETH will be auto staked
        address[] memory priorityStakers = new address[](0);
        bytes[] memory initialKnots = new bytes[](1);
        initialKnots[0] = _blsPublicKeyOfKnot;
        syndicate = syndicateFactory.deploySyndicate(
            address(this),
            0,
            priorityStakers,
            initialKnots
        );

        // Contract approves syndicate to take sETH on behalf of the DAO
        _sETH.approve(syndicate, (2 ** 256) - 1);
    }

    /// @dev Remove the sETH from the node runner smart wallet in order to auto-stake the sETH in the syndicate
    function _autoStakeWithSyndicate(address _associatedSmartWallet, bytes memory _blsPubKey) internal {
        IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse));

        uint256 stakeAmount = 12 ether;
        IOwnableSmartWallet(_associatedSmartWallet).execute(
            address(sETH),
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(this),
                stakeAmount
            )
        );

        // Create the payload for staking
        bytes[] memory stakingKeys = new bytes[](1);
        stakingKeys[0] = _blsPubKey;

        uint256[] memory stakeAmounts = new uint256[](1);
        stakeAmounts[0] = stakeAmount;

        // Stake the sETH to be received by the LPs of the Staking Funds Vault (fees and mev)
        Syndicate(payable(syndicate)).stake(stakingKeys, stakeAmounts, address(stakingFundsVault));
    }

    /// @dev Something that can be overriden during testing
    function _initSavETHVault(address _savETHVaultDeployer, address _lpTokenFactory) internal virtual {
        // Use an external deployer to reduce the size of the liquid staking manager
        savETHVault = SavETHVault(
            SavETHVaultDeployer(_savETHVaultDeployer).deploySavETHVault(address(this), _lpTokenFactory)
        );
    }

    /// @dev Something that can be overriden during testing
    function _initStakingFundsVault(address _stakingFundsVaultDeployer, address _tokenFactory) internal virtual {
        stakingFundsVault = StakingFundsVault(
            payable(StakingFundsVaultDeployer(_stakingFundsVaultDeployer).deployStakingFundsVault(
                address(this),
                _tokenFactory
            ))
        );
    }

    /// @dev This can be overriden to customise fee percentages
    function _calculateCommission(uint256 _received) internal virtual view returns (uint256 _nodeRunner, uint256 _dao) {
        if (_received == 0) revert NothingReceived();

        if (daoCommissionPercentage > 0) {
            uint256 daoAmount = (_received * daoCommissionPercentage) / MODULO;
            uint256 rest = _received - daoAmount;
            return (rest, daoAmount);
        }

        return (_received, 0);
    }

    /// @dev Check the savETH vault, staking funds vault and node runner smart wallet to ensure 32 ether required for staking has been achieved
    function _assertEtherIsReadyForValidatorStaking(bytes calldata blsPubKey) internal view {
        address associatedSmartWallet = smartWalletOfKnot[blsPubKey];
        if (associatedSmartWallet.balance < 4 ether) revert NotEnoughETHToStake();

        LPToken stakingFundsLP = stakingFundsVault.lpTokenForKnot(blsPubKey);
        if (stakingFundsLP.totalSupply() < 4 ether) revert NotEnoughETHToStake();

        LPToken savETHVaultLP = savETHVault.lpTokenForKnot(blsPubKey);
        if (savETHVaultLP.totalSupply() < 24 ether) revert NotEnoughETHToStake();
    }

    /// @dev Internal method for dao to trigger updating commission it takes of node runner revenue
    function _updateDAORevenueCommission(uint256 _commissionPercentage) internal {
        if (_commissionPercentage > MAX_COMMISSION) revert InvalidCommission();

        emit DAOCommissionUpdated(daoCommissionPercentage, _commissionPercentage);

        daoCommissionPercentage = _commissionPercentage;
    }

    /// @dev Re-usable logic for updating LSD ticker used to mint derivatives
    function _updateTicker(string calldata _newTicker) internal {
        if (bytes(_newTicker).length < 3 || bytes(_newTicker).length > 5) revert InvalidTickerLength();
        if (numberOfKnots != 0) revert HouseAlreadyCreated();

        IBrandNFT brandNFT = IBrandNFT(brand);
        string memory lowerTicker = brandNFT.toLowerCase(_newTicker);
        if (
            brandNFT.lowercaseBrandTickerToTokenId(lowerTicker) != 0
        ) revert TickerAlreadyTaken();

        IBrandCentral brandCentral = IBrandCentral(brandNFT.brandCentral());
        IRestrictedTickerRegistry restrictedRegistry = IRestrictedTickerRegistry(brandCentral.claimAuction());

        if (restrictedRegistry.isRestrictedBrandTicker(lowerTicker)) revert TickerAlreadyTaken();

        stakehouseTicker = _newTicker;

        emit NetworkTickerUpdated(_newTicker);
    }
}