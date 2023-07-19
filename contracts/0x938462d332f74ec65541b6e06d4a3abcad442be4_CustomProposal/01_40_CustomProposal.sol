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

/**
 * @title Custom Proposal Contract
 * @notice This contract is designed for constructing proposals from user input. The methods generate calldata from the input arguments and pass it to the specified pool as a proposal.
 * @dev It is a supporting part of the protocol that takes user input arguments and constructs OZ Governor-compatible structures describing the transactions to be executed upon successful voting on the proposal. It does not store user input, but only passes it on in a transformed format to the specified pool contract.
 */
contract CustomProposal is Initializable, AccessControlEnumerableUpgradeable {
    // STORAGE

    /// @dev The address of the Service contract.
    IService public service;

    // MODIFIERS

    /// @notice Modifier that makes the function callable only by the Service contract.
    /// @dev Allows the function to be executed only if the address sending the transaction is equal to the address of the Service contract stored in the memory of this contract.
    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    /// @notice Modifier that checks the existence of a pool at the given address.
    /// @dev Checks the existence of the pool for which the proposal is being constructed. The pool should store the same Service contract address as stored in the Custom Proposal contract and be registered in the Registry contract with the corresponding type.
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

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @dev This method replaces the constructor for upgradeable contracts.
     */
    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Stores a new address of the Service contract in the memory of this contract.
     * @param service_ The new address of the Service contract.
     */
    function setService(
        address service_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        service = IService(service_);
    }

    /**
     * @notice This proposal is the only way to withdraw funds from the pool account.
     * @dev This function prepares a proposal from the list of recipients and corresponding amounts and submits it to the pool for a vote to transfer those amounts to the specified recipients. The asset type is specified as a separate argument, which is the same for all recipients.
     * @param pool The address of the pool on behalf of which this proposal will be launched and from whose balance the values will be transferred.
     * @param asset Asset to transfer (address(0) for ETH transfers).
     * @param recipients Transfer recipients.
     * @param amounts Transfer amounts.
     * @param description Proposal description.
     * @param metaHash Hash value of proposal metadata.
     * @return proposalId The ID of the created proposal.
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
            recipients.length > 0 && recipients.length == amounts.length,
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
     * @notice This proposal is launched when there is a need to issue additional tokens (both Governance and Preference) for an existing pool. In other words, the issuance of tokens for any DAO is possible only through the creation of such a proposal.
     * @dev Proposal to launch a new token generation event (TGE). It can only be created if the maximum supply threshold value for an existing token has not been reached or if a new token is being created, in which case a new token contract will be deployed simultaneously with the TGE contract.
     * @param pool The address of the pool on behalf of which this proposal will be launched and for which the TGE event will be launched.
     * @param tgeInfo TGE parameters.
     * @param tokenInfo Token parameters.
     * @param metadataURI TGE metadata URI.
     * @param description Proposal description.
     * @param metaHash Hash value of proposal metadata.
     * @return proposalId The ID of the created proposal.
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
     * @notice Proposal to replace Governance settings. One of the two methods to change voting parameters.
     * @dev The main parameter should be a structure of type NewGovernanceSettings, which includes the Governance Threshold, Decision Threshold, Proposal Threshold, and execution delay lists for proposals.
     * @param pool The address of the pool on behalf of which this proposal will be launched and for which the Governance settings will be changed.
     * @param settings New governance settings.
     * @param description Proposal description.
     * @param metaHash Hash value of proposal metadata.
     * @return proposalId The ID of the created proposal.
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
     * @notice Creating a custom proposal.
     * @dev This tool can be useful for creating a transaction with arbitrary parameters and putting it to a vote for execution on behalf of the pool.
     * @param pool The address of the pool on behalf of which this proposal will be launched.
     * @param targets Transfer recipients.
     * @param values Transfer amounts for payable.
     * @param callDatas Raw calldatas.
     * @param description Proposal description.
     * @param metaHash Hash value of proposal metadata.
     * @return proposalId The ID of the created proposal.
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
     * @notice This proposal is launched when there is a need to issue ERC1155 Preference tokens, additional collections, and token units in existing collections for an existing ERC1155 token. In other words, the issuance of tokens of this format for any DAO is possible only through the creation of such a proposal.
     * @dev Proposal to launch a new token generation event (TGE) for ERC1155 preference tokens.
     * @param tgeInfo TGE parameters.
     * @param tokenId Token ID.
     * @param tokenIdMetadataURI Token ID metadata URI.
     * @param tokenInfo Token parameters.
     * @param metadataURI TGE metadata URI.
     * @param description Proposal description.
     * @param metaHash Hash value of proposal metadata.
     * @return proposalId The ID of the created proposal.
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
        
            require(
                    address(token) == address(0) ||
                    ITokenERC1155(token).cap(tokenId)==0 ||
                    ITGE(ITokenERC1155(token).lastTGE(tokenId)).state() !=
                    ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );
        
        if (token != address(0)) {
            if (tokenId!=0 && ITokenERC1155(token).isPrimaryTGESuccessful(tokenId)) {
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
            6,
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
     * @notice Proposal to replace Governance settings and change the pool's list of secretaries and executors. One of the two methods to change voting parameters. The only way for a DAO to modify the lists of secretaries and executors.
     * @dev The main parameter should be a structure of type NewGovernanceSettings, which includes the Governance Threshold, Decision Threshold, Proposal Threshold, execution delay lists for proposals, as well as two sets of addresses: one for the new list of secretaries and another for the new list of executors.
     * @param pool The address of the pool on behalf of which this proposal will be launched and for which the Governance settings will be changed.
     * @param settings New governance settings.
     * @param secretary Add a new address to the pool's secretary list.
     * @param executor Add a new address to the pool's executor list.
     * @param description Proposal description.
     * @param metaHash Hash value of the proposal metadata.
     * @return proposalId The ID of the created proposal.
     */
    function proposeGovernanceSettingsWithRoles(
        address pool,
        IGovernanceSettings.NewGovernanceSettings memory settings,
        address[] memory secretary,
        address[] memory executor,
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
            IPool.setSettings.selector,
            settings,
            secretary,
            executor
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