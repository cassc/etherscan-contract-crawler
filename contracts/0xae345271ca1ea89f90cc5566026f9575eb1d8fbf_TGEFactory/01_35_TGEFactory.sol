// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IService.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITGEFactory.sol";
import "./interfaces/governor/IGovernanceSettings.sol";
import "./libraries/ExceptionsLibrary.sol";

/**
 * @title TGE Factory contract
 * @notice Event emitted on creation of primary TGE.
 * @dev Deployment of a TGE can occur both within the execution of transactions prescribed by a proposal, and during the execution of a transaction initiated by the pool owner, who has not yet become a DAO.
 */
contract TGEFactory is ReentrancyGuardUpgradeable, ITGEFactory {
    // STORAGE

    /// @notice Service contract address
    IService public service;

    // EVENTS

    /**
     * @dev Event emitted when the primary TGE contract is deployed.
     * @param pool Address of the pool for which the TGE is launched.
     * @param tge Address of the deployed TGE contract.
     * @param token Address of the token contract.
     */
    event PrimaryTGECreated(address pool, address tge, address token);

    /**
     * @dev Event emitted when a secondary TGE contract operating with ERC20 tokens is deployed.
     * @param pool Address of the pool for which the TGE is launched.
     * @param tge Address of the deployed TGE contract.
     * @param token Address of the ERC20 token contract.
     */
    event SecondaryTGECreated(address pool, address tge, address token);

    /**
     * @dev Event emitted when a secondary TGE contract operating with ERC1155 tokens is * deployed.
     * @param pool Address of the pool for which the TGE is launched.*
     * @param tge Address of the deployed TGE contract.*
     * @param token Address of the ERC1155 token contract.*
     * @param tokenId Identifier of the ERC1155 token collection.
     */
    event SecondaryTGEERC1155Created(
        address pool,
        address tge,
        address token,
        uint256 tokenId
    );

    // MODIFIERS
    /// @notice Modifier that allows the method to be called only by the Pool contract.
    modifier onlyPool() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }
    /// @notice Modifier that allows the method to be called only if the Service contract is not paused.
    modifier whenNotPaused() {
        require(!service.paused(), ExceptionsLibrary.SERVICE_PAUSED);
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
     * @dev This method replaces the constructor for upgradeable contracts. It also sets the address of the Service contract in the contract's storage.
     * @param service_ The address of the Service contract.
     */
    function initialize(IService service_) external initializer {
        __ReentrancyGuard_init();
        service = service_;
    }

    // EXTERNAL FUNCTIONS

    /**
     * @dev This method is used to launch the primary TGE of the Governance token. When launching such a TGE, a new Token contract is deployed with TokenType = "Governance". If this TGE is successful, it will no longer be possible to repeat such a launch, and the created token will irreversibly become the Governance token of the pool.
     * @dev Simultaneously with contract deployment, Governance Settings and lists of secretaries and executors are set.
     * @param poolAddress Pool address.
     * @param tokenInfo New token parameters (token type, decimals & description are ignored)
     * @param tgeInfo Pool TGE parameters
     * @param metadataURI Metadata URI
     * @param governanceSettings_ Set of Governance settings
     * @param secretary Secretary address
     * @param executor Executor address
     */
    function createPrimaryTGE(
        address poolAddress,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        string memory metadataURI,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external nonReentrant whenNotPaused {
        // Check that sender is pool owner
        IPool pool = IPool(poolAddress);
        require(pool.owner() == msg.sender, ExceptionsLibrary.NOT_POOL_OWNER);

        // Check token cap
        require(tokenInfo.cap >= 1 ether, ExceptionsLibrary.INVALID_CAP);

        // Check that pool is not active yet
        require(
            address(pool.getGovernanceToken()) == address(0) || !pool.isDAO(),
            ExceptionsLibrary.GOVERNANCE_TOKEN_EXISTS
        );
        pool.setSettings(governanceSettings_, secretary, executor);

        // Create TGE contract
        ITGE tge = _createTGE(metadataURI, address(pool));

        // Create token contract
        tokenInfo.tokenType = IToken.TokenType.Governance;
        tokenInfo.decimals = 18;
        address token = service.tokenFactory().createToken(
            address(pool),
            tokenInfo,
            address(tge)
        );

        // Set token as pool token
        pool.setToken(address(token), IToken.TokenType.Governance);

        // Initialize TGE
        tge.initialize(
            address(service),
            address(token),
            0,
            "",
            tgeInfo,
            service.protocolTokenFee()
        );
        emit PrimaryTGECreated(address(pool), address(tge), address(token));

        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(
                ITGEFactory.createPrimaryTGE.selector,
                poolAddress,
                tokenInfo,
                tgeInfo,
                metadataURI,
                governanceSettings_,
                secretary,
                executor
            )
        );
    }

    /**
     * @dev This method allows users to launch primary and secondary TGEs for Governance and Preference tokens deployed based on the ERC20 contract. The creation of a token occurs if the TGE involves the distribution of a previously nonexistent Preference token. Launch is only possible by executing a successful proposal.
     * @param token ERC20 token address for distribution in the TGE
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function createSecondaryTGE(
        address token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external onlyPool nonReentrant whenNotPaused {
        ITGE tge;
        // Check whether it's initial preference TGE or any secondary token
        if (
            tokenInfo.tokenType == IToken.TokenType.Preference &&
            address(token) == address(0)
        ) {
            (token, tge) = _createInitialPreferenceTGE(
                0,
                "",
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        } else {
            (token, tge) = _createSecondaryTGE(
                token,
                0,
                "",
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        }

        // Add proposal id to TGE
        IPool(msg.sender).setProposalIdToTGE(address(tge));

        // Emit event
        emit SecondaryTGECreated(msg.sender, address(tge), address(token));
    }

    /**
     * @dev This method launches a secondary TGE for a specified series of ERC1155 Preference tokens. If an unused series is being used, the maximum cap for this series is determined within this transaction. If no token address is specified, a new ERC1155 Preference token contract is deployed.
     * @param token ERC1155 token address for distribution in the TGE
     * @param tokenId ERC1155 token collection address for distribution of units in the TGE
     * @param uri Metadata URI according to the ERC1155 specification
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function createSecondaryTGEERC1155(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external onlyPool nonReentrant whenNotPaused {
        require(
            tokenInfo.tokenType == IToken.TokenType.Preference,
            ExceptionsLibrary.WRONG_STATE
        );
        ITGE tge;
        // Check whether it's initial preference TGE or any secondary token
        if (address(token) == address(0)) {
            (token, tge) = _createInitialPreferenceTGE(
                tokenId,
                uri,
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        } else {
            if (tokenId == 0) tokenId = ITokenERC1155(token).lastTokenId();
            (token, tge) = _createSecondaryTGE(
                token,
                tokenId,
                uri,
                tgeInfo,
                tokenInfo,
                metadataURI
            );
        }
        if (ITokenERC1155(token).cap(tokenId) == 0) {
            ITokenERC1155(token).setTokenIdCap(tokenId, tokenInfo.cap);
        }

        // Add proposal id to TGE
        IPool(msg.sender).setProposalIdToTGE(address(tge));

        // Emit event
        emit SecondaryTGEERC1155Created(
            msg.sender,
            address(tge),
            address(token),
            tokenId
        );
    }

    // INTERNAL FUNCTIONS

    function _createSecondaryTGE(
        address token,
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) internal returns (address, ITGE) {
        // Check that token is valid
        require(
            tokenInfo.tokenType != IToken.TokenType.None &&
                IPool(msg.sender).tokenTypeByAddress(address(token)) ==
                tokenInfo.tokenType,
            ExceptionsLibrary.WRONG_TOKEN_ADDRESS
        );

        // Check that there is no active TGE
        if (tokenId != 0) {
            require(
                ITokenERC1155(token).cap(tokenId) == 0 ||
                    ITGE(ITokenERC1155(token).lastTGE(tokenId)).state() !=
                    ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );
        } else {
            require(
                ITGE(IToken(token).lastTGE()).state() != ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );
        }
        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);

        // Add TGE to token's list
        if (tokenId != 0) {
            ITokenERC1155(token).addTGE(address(tge), tokenId);
        } else {
            IToken(token).addTGE(address(tge));
        }
        // Get protocol fee
        uint256 protocolTokenFee = tokenInfo.tokenType ==
            IToken.TokenType.Governance
            ? service.protocolTokenFee()
            : 0;

        // Initialize TGE
        tge.initialize(
            address(service),
            address(token),
            tokenId,
            uri,
            tgeInfo,
            protocolTokenFee
        );

        return (token, tge);
    }

    /**
     * @dev This internal method implements the logic of launching a TGE for Preference tokens that do not yet have their own contract.
     * @param tokenId ERC1155 token collection address for distribution of units in the TGE
     * @param uri Metadata URI according to the ERC1155 specification
     * @param tgeInfo TGE parameters
     * @param tokenInfo Token parameters
     * @param metadataURI Metadata URI
     */
    function _createInitialPreferenceTGE(
        uint256 tokenId,
        string memory uri,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) internal returns (address, ITGE) {
        // Create TGE
        ITGE tge = _createTGE(metadataURI, msg.sender);
        address token;
        if (tokenId != 0) {
            // Create token contract
            token = address(
                service.tokenFactory().createTokenERC1155(
                    msg.sender,
                    tokenInfo,
                    address(tge)
                )
            );
        } else {
            // Create token contract
            token = address(
                service.tokenFactory().createToken(
                    msg.sender,
                    tokenInfo,
                    address(tge)
                )
            );
        }

        // Add token to Pool
        IPool(msg.sender).setToken(token, IToken.TokenType.Preference);

        // Initialize TGE
        tge.initialize(address(service), token, tokenId, uri, tgeInfo, 0);

        return (token, tge);
    }

    /**
     * @dev This method deploys the TGE contract and returns its address after creation.
     * @param metadataURI TGE metadata URI
     * @param pool Pool address
     * @return tge TGE contract
     */
    function _createTGE(
        string memory metadataURI,
        address pool
    ) internal returns (ITGE tge) {
        // Create TGE contract
        tge = ITGE(address(new BeaconProxy(service.tgeBeacon(), "")));

        // Add TGE contract to registry
        service.registry().addContractRecord(
            address(tge),
            IRecordsRegistry.ContractType.TGE,
            metadataURI
        );

        // Add TGE event to registry
        service.registry().addEventRecord(
            pool,
            IRecordsRegistry.EventType.TGE,
            address(tge),
            0,
            ""
        );
    }
}