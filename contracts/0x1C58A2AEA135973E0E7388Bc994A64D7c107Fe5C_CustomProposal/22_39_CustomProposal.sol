// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./interfaces/IPool.sol";

import "./interfaces/governor/IGovernanceSettings.sol";
import "./interfaces/governor/IGovernor.sol";
import "./interfaces/IService.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IToken.sol";
import "./libraries/ExceptionsLibrary.sol";

contract CustomProposal is Initializable, AccessControlEnumerableUpgradeable {
    // STORAGE

    /// @dev Service address
    IService public service;

    // MODIFIERS

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyForPool(address pool) {
        //check if pool registry record exists
        require(
            service.registry().typeOf(pool) ==
                IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    // INITIALIZER

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer
     */
    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // PUBLIC FUNCTIONS

    function setService(
        address service_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        service = IService(service_);
    }

    /**
     * @dev Propose transfer of assets
     * @param asset Asset to transfer (address(0) for ETH transfers)
     * @param recipients Transfer recipients
     * @param amounts Transfer amounts
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeTransfer(
        address pool,
        address asset,
        address[] memory recipients,
        uint256[] memory amounts,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        // Check lengths
        
        require(
            recipients.length > 0 &&
            recipients.length == amounts.length,
            ExceptionsLibrary.INVALID_VALUE
        );

        // Prepare proposal actions
        address[] memory targets = new address[](recipients.length);
        uint256[] memory values = new uint256[](recipients.length);
        bytes[] memory callDatas = new bytes[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            if (asset == address(0)) {
                targets[i] = recipients[i];
                callDatas[i] = "";
                values[i] = amounts[i];
            } else {
                targets[i] = asset;
                callDatas[i] = abi.encodeWithSelector(
                    IERC20Upgradeable.transfer.selector,
                    recipients[i],
                    amounts[i]
                );
                values[i] = 0;
            }
        }

        // Create proposal

        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            0,
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.Transfer,
                description: description,
                metaHash: metaHash
            })
        );
        return proposalId_;
    }

    /**
     * @dev Proposal to launch a new token generation event (TGE), can be created only if the maximum supply threshold value for an existing token has not been reached or if a new token is being created, in which case, a new token contract will be deployed simultaneously with the TGE contract.
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI TGE metadata URI
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeTGE(
        address pool,
        address token,
        ITGE.TGEInfo memory tgeInfo,
        IToken.TokenInfo memory tokenInfo,
        string memory metadataURI,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        // Get cap and supply data
        uint256 totalSupplyWithReserves = 0;

        //Check if token is new or exists for pool
        require(
            address(token) == address(0) ||
                IPool(pool).tokenExists(IToken(token)),
            ExceptionsLibrary.WRONG_TOKEN_ADDRESS
        );

        if (tokenInfo.tokenType == IToken.TokenType.Governance) {
            tokenInfo.cap = IToken(token).cap();
            totalSupplyWithReserves = IToken(token).totalSupplyWithReserves();
        } else if (tokenInfo.tokenType == IToken.TokenType.Preference) {
            if (token != address(0)) {
                if (IToken(token).isPrimaryTGESuccessful()) {
                    tokenInfo.cap = IToken(token).cap();
                    totalSupplyWithReserves = IToken(token)
                        .totalSupplyWithReserves();
                }
            }
        }

        // Validate TGE info
        IService(service).validateTGEInfo(
            tgeInfo,
            tokenInfo.cap,
            totalSupplyWithReserves,
            tokenInfo.tokenType
        );

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = address(IService(service).tgeFactory());

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            ITGEFactory.createSecondaryTGE.selector,
            token,
            tgeInfo,
            tokenInfo,
            metadataURI
        );

        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            1,
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.TGE,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }

    /**
     * @notice A proposal that changes the governance settings. First of all, the percentage of the total number of free votes changes, the achievement of which within the framework of voting leads to the achievement of a quorum (the vote will be considered to have taken place, that is, one of the conditions for a positive decision on the propositional is fulfilled). Further, the Decision Threshold can be changed, which is set as a percentage of the sum of the votes "for" and "against" for a specific proposal, at which the sum of the votes "for" ensures a positive decision-making. In addition, a set of delays (measured in blocks) is set, used for certain features of transactions submitted to the proposal. The duration of all subsequent votes is also set (measured in blocks) and the number of Governance tokens required for the address to create a proposal. All parameters are set in one transaction. To change one of the parameters, it is necessary to send the old values of the other settings along with the changed value of one setting.
     * @param settings New governance settings
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeGovernanceSettings(
        address pool,
        IGovernanceSettings.NewGovernanceSettings memory settings,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        //Check if last GovernanceSettings proposal is not Active

        require(
            !IPool(pool).isLastProposalIdByTypeActive(2),
            ExceptionsLibrary.ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS
        );

        // Validate settings
        IPool(pool).validateGovernanceSettings(settings);

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = pool;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            IGovernanceSettings.setGovernanceSettings.selector,
            settings
        );

        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            2,
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.GovernanceSettings,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }

    /**
     * @notice A proposal that changes the PoolSecretary list.
     * @param addSecretary add new address to pool secretary list
     * @param removeSecretary remove address to pool secretary list
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposePoolSecretary(
        address pool,
        address[] memory addSecretary,
        address[] memory removeSecretary,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        // Validate
        require(
            addSecretary.length > 0 || removeSecretary.length > 0,
            ExceptionsLibrary.EMPTY_ADDRESS
        );

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = pool;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            IPool.changePoolSecretary.selector,
            addSecretary,
            removeSecretary
        );
        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            3, // changePoolSecretary
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.GovernanceSettings,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }

    /**
     * @dev Propose custom transactions
     * @param targets Transfer recipients
     * @param values Transfer amounts for payable
     * @param callDatas raw calldatas
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeCustomTx(
        address pool,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory callDatas,
        string memory description,
        string memory metaHash
    ) external onlyForPool(pool) returns (uint256 proposalId) {
        // Check lengths
        require(
            targets.length == values.length &&
                targets.length == callDatas.length,
            ExceptionsLibrary.INVALID_VALUE
        );

        for (uint256 i = 0; i < targets.length; i++) {
            require(
                IRegistry(IService(service).registry()).typeOf(targets[i]) ==
                    IRecordsRegistry.ContractType.None,
                ExceptionsLibrary.INVALID_TARGET
            );
        }

        // Create proposal

        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            4, // - CustomTx Type
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.Transfer,
                description: description,
                metaHash: metaHash
            })
        );
        return proposalId_;
    }

    /**
     * @notice A proposal that changes the PoolExecutor list.
     * @param addExecutor add new address to pool Executor list
     * @param removeExecutor remove address to pool Executor list
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposePoolExecutor(
        address pool,
        address[] memory addExecutor,
        address[] memory removeExecutor,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        // Validate
        require(
            addExecutor.length > 0 || removeExecutor.length > 0,
            ExceptionsLibrary.EMPTY_ADDRESS
        );

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = pool;

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            IPool.changePoolExecutor.selector,
            addExecutor,
            removeExecutor
        );
        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            5, // PoolExecutor
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.GovernanceSettings,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }


    /**
     * @dev Proposal to launch a new token generation event (TGE) for ERC1155 preference tokens
     * @param tgeInfo TGE parameters
     * @param tokenId TokenId
     * @param tokenIdMetadataURI tokenIdMetadataURI
     * @param tokenInfo Token parameters
     * @param metadataURI TGE metadata URI
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeTGEERC1155(
        address pool,
        address token,
        uint256 tokenId,
        string memory tokenIdMetadataURI,
        ITGE.TGEInfo memory tgeInfo,
        IToken.TokenInfo memory tokenInfo,
        string memory metadataURI,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        // Get cap and supply data
        uint256 totalSupplyWithReserves = 0;

        //Check if token is new or exists for pool
        require(
            address(token) == address(0) ||
                IPool(pool).tokenExists(IToken(token)),
            ExceptionsLibrary.WRONG_TOKEN_ADDRESS
        );

        if (token != address(0)) {
            if (ITokenERC1155(token).isPrimaryTGESuccessful(tokenId)) {
                tokenInfo.cap = ITokenERC1155(token).cap(tokenId);
                totalSupplyWithReserves = ITokenERC1155(token)
                    .totalSupplyWithReserves(tokenId);
            }
        }

        // Validate TGE info
        IService(service).validateTGEInfo(
            tgeInfo,
            tokenInfo.cap,
            totalSupplyWithReserves,
            tokenInfo.tokenType
        );

        // Prepare proposal action
        address[] memory targets = new address[](1);
        targets[0] = address(IService(service).tgeFactory());

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = abi.encodeWithSelector(
            ITGEFactory.createSecondaryTGEERC1155.selector,
            token,
            tokenId,
            tokenIdMetadataURI,
            tgeInfo,
            tokenInfo,
            metadataURI
        );

        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            1,
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.TGE,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }
     /**
     * @notice A proposal that changes the governance settings. First of all, the percentage of the total number of free votes changes, the achievement of which within the framework of voting leads to the achievement of a quorum (the vote will be considered to have taken place, that is, one of the conditions for a positive decision on the propositional is fulfilled). Further, the Decision Threshold can be changed, which is set as a percentage of the sum of the votes "for" and "against" for a specific proposal, at which the sum of the votes "for" ensures a positive decision-making. In addition, a set of delays (measured in blocks) is set, used for certain features of transactions submitted to the proposal. The duration of all subsequent votes is also set (measured in blocks) and the number of Governance tokens required for the address to create a proposal. All parameters are set in one transaction. To change one of the parameters, it is necessary to send the old values of the other settings along with the changed value of one setting. With Secretary and Executor Roles
     * @param settings New governance settings
     * @param addSecretary add new address to pool secretary list
     * @param removeSecretary remove address to pool secretary list
     * @param addExecutor add new address to pool Executor list
     * @param removeExecutor remove address to pool Executor list
     * @param description Proposal description
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal's ID
     */
    function proposeGovernanceSettingsWithRoles(
        address pool,
        IGovernanceSettings.NewGovernanceSettings memory settings,
        address[] memory addSecretary,
        address[] memory removeSecretary,
        address[] memory addExecutor,
        address[] memory removeExecutor,
        string memory description,
        string memory metaHash
    ) external returns (uint256 proposalId) {
        //Check if last GovernanceSettings proposal is not Active

        require(
            !IPool(pool).isLastProposalIdByTypeActive(2),
            ExceptionsLibrary.ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS
        );

        // Validate settings
        IPool(pool).validateGovernanceSettings(settings);

        // Prepare proposal action
        address[] memory targets = new address[](3);
        targets[0] = pool;

        uint256[] memory values = new uint256[](3);
        values[0] = 0;

        bytes[] memory callDatas = new bytes[](3);
        callDatas[0] = abi.encodeWithSelector(
            IGovernanceSettings.setGovernanceSettings.selector,
            settings
        );

        //// secretary 
        targets[1] = pool;
        values[1] = 0;
        callDatas[1] = abi.encodeWithSelector(
            IPool.changePoolSecretary.selector,
            addSecretary,
            removeSecretary
        );
        //// executors
        targets[2] = pool;
        values[2] = 0;
        callDatas[2] = abi.encodeWithSelector(
            IPool.changePoolExecutor.selector,
            addExecutor,
            removeExecutor
        );

        // Propose
        uint256 proposalId_ = IPool(pool).propose(
            msg.sender,
            2,
            IGovernor.ProposalCoreData({
                targets: targets,
                values: values,
                callDatas: callDatas,
                quorumThreshold: 0,
                decisionThreshold: 0,
                executionDelay: 0
            }),
            IGovernor.ProposalMetaData({
                proposalType: IRecordsRegistry.EventType.GovernanceSettings,
                description: description,
                metaHash: metaHash
            })
        );

        return proposalId_;
    }
}