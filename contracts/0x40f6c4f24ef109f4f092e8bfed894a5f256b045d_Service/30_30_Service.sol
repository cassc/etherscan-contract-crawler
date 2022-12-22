// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IDispatcher.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Protocol entry point
contract Service is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IService
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    /// @dev Dispatcher address
    IDispatcher public dispatcher;

    /// @dev Pool beacon
    address public poolBeacon;

    /// @dev Token beacon
    address public tokenBeacon;

    /// @dev TGE beacon
    address public tgeBeacon;

    ///@dev ProposalGteway address
    address public proposalGateway;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 public ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 public ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 public ballotLifespan;

    /// @dev UniswapRouter contract address
    ISwapRouter public uniswapRouter;

    /// @dev UniswapQuoter contract address
    IQuoter public uniswapQuoter;

    /**
     * @dev Addresses that are allowed to participate in TGE.
     * If list is empty, anyone can participate.
     */
    EnumerableSetUpgradeable.AddressSet private _userWhitelist;

    /// @dev address that collects protocol token fees
    address public protocolTreasury;

    /// @dev protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public protocolTokenFee;

    /**
     * @dev block delay for executeBallot
     * [0] - ballot value in USDT after which delay kicks in
     * [1] - base delay applied to all ballots to mitigate FlashLoan attacks.
     * [2] - delay for TransferETH proposals
     * [3] - delay for TransferERC20 proposals
     * [4] - delay for TGE proposals
     * [5] - delay for GovernanceSettings proposals
     */
    uint256[10] public ballotExecDelay;

    /// @dev Primary contract address. Used to estimate proposal value.
    address public primaryAsset;

    /// @dev Secondary contract address. Used to estimate proposal value.
    address public secondaryAsset;

    /// @dev List of managers
    EnumerableSetUpgradeable.AddressSet private _managerWhitelist;

    /// @dev List of executors
    EnumerableSetUpgradeable.AddressSet private _executorWhitelist;

    // EVENTS

    /**
     * @dev Event emitted on change in user's whitelist status.
     * @param account User's account
     * @param whitelisted Is whitelisted
     */
    event UserWhitelistedSet(address account, bool whitelisted);

    /**
     * @dev Event emitted on pool creation.
     * @param pool Pool address
     * @param token Pool token address
     * @param tge Pool primary TGE address
     */
    event PoolCreated(address pool, address token, address tge);

    /**
     * @dev Event emitted on creation of secondary TGE.
     * @param pool Pool address
     * @param tge Secondary TGE address
     * @param token Preference token address
     */
    event SecondaryTGECreated(address pool, address tge, address token);

    /**
     * @dev Event emitted on protocol treasury change.
     * @param protocolTreasury Protocol treasury address
     */
    event ProtocolTreasuryChanged(address protocolTreasury);

    /**
     * @dev Event emitted on protocol token fee change.
     * @param protocolTokenFee Protocol token fee
     */
    event ProtocolTokenFeeChanged(uint256 protocolTokenFee);

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param dispatcher_ Dispatcher address
     * @param poolBeacon_ Pool beacon
     * @param tokenBeacon_ Governance token beacon
     * @param tgeBeacon_ TGE beacon
     * @param ballotParams [ballotQuorumThreshold, ballotLifespan, ballotDecisionThreshold, ...ballotExecDelay]
     * @param uniswapRouter_ UniswapRouter address
     * @param uniswapQuoter_ UniswapQuoter address
     * @param protocolTokenFee_ Protocol token fee
     */
    function initialize(
        IDispatcher dispatcher_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        address proposalGateway_,
        uint256[13] calldata ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        uint256 protocolTokenFee_
    ) external initializer {
        require(
            address(dispatcher_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(poolBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tokenBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(tgeBeacon_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(proposalGateway_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(
            address(uniswapRouter_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );
        require(
            address(uniswapQuoter_) != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        __Ownable_init();
        __UUPSUpgradeable_init();

        dispatcher = dispatcher_;
        poolBeacon = poolBeacon_;
        tokenBeacon = tokenBeacon_;
        tgeBeacon = tgeBeacon_;
        proposalGateway = proposalGateway_;
        ballotQuorumThreshold = ballotParams[0];
        ballotDecisionThreshold = ballotParams[1];
        ballotLifespan = ballotParams[2];

        ballotExecDelay = [
            ballotParams[3],
            ballotParams[4],
            ballotParams[5],
            ballotParams[6],
            ballotParams[7],
            ballotParams[8],
            ballotParams[9],
            ballotParams[10],
            ballotParams[11],
            ballotParams[12]
        ];

        uniswapRouter = uniswapRouter_;
        uniswapQuoter = uniswapQuoter_;

        setProtocolTreasury(address(this));
        setProtocolTokenFee(protocolTokenFee_);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // PUBLIC FUNCTIONS

    /**
     * @dev Create pool
     * @param pool Pool address. If not address(0) - creates new token and new primary TGE for an existing pool.
     * @param tokenInfo Pool token parameters
     * @param tgeInfo Pool TGE parameters
     * @param ballotSettings Ballot setting parameters
     * @param jurisdiction Pool jurisdiction
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param trademark Pool trademark
     * @param entityType Company entity type
     */
    function createPool(
        IPool pool,
        IToken.TokenInfo memory tokenInfo,
        ITGE.TGEInfo memory tgeInfo,
        uint256[3] memory ballotSettings,
        uint256 jurisdiction,
        uint256[10] memory ballotExecDelay_,
        string memory trademark,
        uint256 entityType,
        string memory metadataURI
    ) external payable onlyWhitelisted nonReentrant whenNotPaused {
        require(
            tokenInfo.cap >= 10**18,
            ExceptionsLibrary.INVALID_CAP
        );
        tokenInfo.cap += getProtocolTokenFee(tokenInfo.cap);
        IDispatcher _dispatcher = dispatcher;

        if (address(pool) == address(0)) {
            (address pool_, uint256 fee_) = _dispatcher.lockRecord(jurisdiction, entityType);
            require(pool_ != address(0), ExceptionsLibrary.NO_COMPANY);
            require(msg.value == fee_, ExceptionsLibrary.INCORRECT_ETH_PASSED);

            pool = IPool(pool_);
            pool.launch(
                msg.sender,
                ballotSettings[0],
                ballotSettings[1],
                ballotSettings[2],
                ballotExecDelay_,
                trademark
            );
        } else {
            require(
                _dispatcher.typeOf(address(pool)) == IDispatcher.ContractType.Pool,
                ExceptionsLibrary.NOT_POOL
            );
            require(
                msg.sender == pool.owner(),
                ExceptionsLibrary.NOT_POOL_OWNER
            );
            require(!pool.isDAO(), ExceptionsLibrary.IS_DAO);
        }

        IToken token = IToken(
            address(new BeaconProxy(tokenBeacon, ""))
        );
        _dispatcher.addContractRecord(
            address(token),
            IDispatcher.ContractType.GovernanceToken,
            ""
        );

        ITGE tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));
        _dispatcher.addContractRecord(address(tge), IDispatcher.ContractType.TGE, metadataURI);
        _dispatcher.addEventRecord(
            address(pool),
            IDispatcher.EventType.TGE,
            0,
            ""
        );

        token.initialize(address(pool), tokenInfo.symbol, tokenInfo.cap, IToken.TokenType.Governance, address(tge), "");
        pool.setToken(address(token), IToken.TokenType.Governance);
        tge.initialize(token, tgeInfo);

        _userWhitelist.remove(msg.sender);

        emit PoolCreated(address(pool), address(token), address(tge));
    }

    // PUBLIC INDIRECT FUNCTIONS (CALLED THROUGH POOL)

    /**
     * @dev Create secondary TGE
     * @param tgeInfo TGE parameters
     */
    function createSecondaryTGE(
        ITGE.TGEInfo calldata tgeInfo, 
        string memory metadataURI, 
        IToken.TokenType tokenType, 
        string memory tokenDescription,
        uint256 preferenceTokenCap
    )
        external
        override
        onlyPool
        nonReentrant
        whenNotPaused
    {
        ITGE tge = ITGE(address(new BeaconProxy(tgeBeacon, "")));
        IToken token = IPool(msg.sender).tokens(tokenType); 
        if (tokenType == IToken.TokenType.Governance) {
            require(
                ITGE(token.lastTGE()).state() != ITGE.State.Active,
                ExceptionsLibrary.ACTIVE_TGE_EXISTS
            );
            tge.initialize(token, tgeInfo);
            token.addTGE(address(tge));
        }
        if (tokenType == IToken.TokenType.Preference) {
            if (address(token) == address(0)) {
                token = IToken(address(new BeaconProxy(tokenBeacon, "")));
                token.initialize(msg.sender, "", preferenceTokenCap, tokenType, address(tge), tokenDescription);
                tge.initialize(token, tgeInfo);
                IPool(msg.sender).setToken(address(token), IToken.TokenType.Preference);
                dispatcher.addContractRecord(address(token), IDispatcher.ContractType.PreferenceToken, "");
            } else {
                if (ITGE(token.getTGEList()[0]).state() == ITGE.State.Failed) {
                    token = IToken(address(new BeaconProxy(tokenBeacon, "")));
                    token.initialize(msg.sender, "", preferenceTokenCap, tokenType, address(tge), tokenDescription);
                    tge.initialize(token, tgeInfo);
                    IPool(msg.sender).setToken(address(token), IToken.TokenType.Preference);
                    dispatcher.addContractRecord(address(token), IDispatcher.ContractType.PreferenceToken, "");
                } else {
                    require(
                        ITGE(token.lastTGE()).state() != ITGE.State.Active,
                        ExceptionsLibrary.ACTIVE_TGE_EXISTS
                    );
                    tge.initialize(token, tgeInfo);
                    token.addTGE(address(tge));
                }
            }
        }
        dispatcher.addContractRecord(address(tge), IDispatcher.ContractType.TGE, metadataURI);

        emit SecondaryTGECreated(msg.sender, address(tge), address(token));
    }

    /**
     * @dev Add proposal to directory
     * @param proposalId Proposal ID
     */
    function addProposal(uint256 proposalId) external onlyPool whenNotPaused {
        dispatcher.addProposalRecord(msg.sender, proposalId);
    }

    /**
     * @dev Add event to directory
     * @param eventType Event type
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    function addEvent(
        IDispatcher.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external onlyPool whenNotPaused {
        dispatcher.addEventRecord(
            msg.sender,
            eventType,
            proposalId,
            metaHash
        );
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Add user to whitelist
     * @param account User address
     */
    function addUserToWhitelist(address account) external onlyManager {
        require(
            _userWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
        emit UserWhitelistedSet(account, true);
    }

    /**
     * @dev Remove user from whitelist
     * @param account User address
     */
    function removeUserFromWhitelist(address account) external onlyManager {
        require(
            _userWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
        emit UserWhitelistedSet(account, false);
    }

    /**
     * @dev Add manager to whitelist
     * @param account Manager address
     */
    function addManagerToWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
    }

    /**
     * @dev Remove manager from whitelist
     * @param account Manager address
     */
    function removeManagerFromWhitelist(address account) external onlyOwner {
        require(
            _managerWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
    }

    /**
     * @dev Add executor to whitelist
     * @param account executor address
     */
    function addExecutorToWhitelist(address account) external onlyOwner {
        require(
            _executorWhitelist.add(account),
            ExceptionsLibrary.ALREADY_WHITELISTED
        );
    }

    /**
     * @dev Remove executor from whitelist
     * @param account executor address
     */
    function removeExecutorFromWhitelist(address account) external onlyOwner {
        require(
            _executorWhitelist.remove(account),
            ExceptionsLibrary.ALREADY_NOT_WHITELISTED
        );
    }

    /**
     * @dev Transfer collected createPool protocol fees
     * @param to Transfer recipient
     */
    function transferCollectedFees(address to) external onlyOwner {
        require(to != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        (bool success,) = payable(to).call{ value: payable(address(this)).balance }("");
        require(success, ExceptionsLibrary.EXECUTION_FAILED);
    }

    /**
     * @dev Set Service governance settings
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     */
    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay_
    ) external onlyOwner {
        dispatcher.validateBallotParams(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_, 
            ballotExecDelay_
        );

        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    /**
     * @dev Set protocol treasury address
     * @param _protocolTreasury Protocol treasury address
     */
    function setProtocolTreasury(address _protocolTreasury) public onlyOwner {
        require(
            _protocolTreasury != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        protocolTreasury = _protocolTreasury;
        emit ProtocolTreasuryChanged(protocolTreasury);
    }

    /**
     * @dev Set protocol token fee
     * @param _protocolTokenFee protocol token fee percentage value with 4 decimals.
     * Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000.
     */
    function setProtocolTokenFee(uint256 _protocolTokenFee) public onlyOwner {
        require(_protocolTokenFee <= 1000000, ExceptionsLibrary.INVALID_VALUE);

        protocolTokenFee = _protocolTokenFee;
        emit ProtocolTokenFeeChanged(_protocolTokenFee);
    }

    /**
     * @dev Cancel pool's ballot
     * @param _pool pool
     * @param proposalId proposalId
     */
    function cancelBallot(address _pool, uint256 proposalId) public onlyOwner {
        IPool(_pool).serviceCancelBallot(proposalId);
    }

    /**
     * @dev Pause service
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause service
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set primary token address
     * @param primaryAsset_ Token address
     */
    function setPrimaryAsset(address primaryAsset_) external onlyOwner {
        primaryAsset = primaryAsset_;
    }

    /**
     * @dev Set secondary token address
     * @param secondaryAsset_ Token address
     */
    function setSecondaryAsset(address secondaryAsset_) external onlyOwner {
        secondaryAsset = secondaryAsset_;
    }

    // VIEW FUNCTIONS

    /**
     * @dev Return manager's whitelist status
     * @param account Manager's address
     * @return Whitelist status
     */
    function isManagerWhitelisted(address account)
        public
        view
        override
        returns (bool)
    {
        return _managerWhitelist.contains(account);
    }

    /**
     * @dev Return executor's whitelist status
     * @param account Executor's address
     * @return Whitelist status
     */
    function isExecutorWhitelisted(address account)
        public
        view
        override
        returns (bool)
    {
        return _executorWhitelist.contains(account);
    }

    /**
     * @dev Return user's whitelist status
     * @param account User's address
     * @return Whitelist status
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return _userWhitelist.contains(account);
    }

    /**
     * @dev Return all whitelisted users
     * @return Whitelisted addresses
     */
    function userWhitelist() external view returns (address[] memory) {
        return _userWhitelist.values();
    }

    /**
     * @dev Return number of whitelisted users
     * @return Number of whitelisted users
     */
    function userWhitelistLength() external view returns (uint256) {
        return _userWhitelist.length();
    }

    /**
     * @dev Return whitelisted user at particular index
     * @param index Whitelist index
     * @return Whitelisted user's address
     */
    function userWhitelistAt(uint256 index) external view returns (address) {
        return _userWhitelist.at(index);
    }

    /**
     * @dev Return all whitelisted tokens
     * @return Whitelisted tokens
     */
    function tokenWhitelist() external view returns (address[] memory) {
        return dispatcher.tokenWhitelist();
    }

    /**
     * @dev Return Service owner
     * @return Service owner's address
     */
    function owner()
        public
        view
        override(IService, OwnableUpgradeable)
        returns (address)
    {
        // Ownable
        return super.owner();
    }

    /**
     * @dev Calculate minimum soft cap for token fee mechanism to work
     * @return softCap minimum soft cap
     */
    function getMinSoftCap() public view returns (uint256) {
        return 1000000 / protocolTokenFee;
    }

    /**
     * @dev calculates protocol token fee for given token amount
     * @param amount Token amount
     * @return tokenFee
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        require(amount >= getMinSoftCap(), ExceptionsLibrary.INVALID_VALUE);

        uint256 mul = 1;
        if (amount > 100000000000000000000) {
            mul = 1000000000000;
            amount = amount / mul;
        }

        return ((protocolTokenFee * amount) / 1000000) * mul;
    }

    /**
     * @dev Return max hard cap accounting for protocol token fee
     * @param _pool pool to calculate hard cap against
     * @return Maximum hard cap
     */
    function getMaxHardCap(address _pool) public view returns (uint256) {
        if (
            dispatcher.typeOf(_pool) == IDispatcher.ContractType.Pool &&
            IPool(_pool).isDAO()
        ) {
            return
                IPool(_pool).tokens(IToken.TokenType.Governance).cap() -
                getProtocolTokenFee(IPool(_pool).tokens(IToken.TokenType.Governance).cap());
        }

        return type(uint256).max - getProtocolTokenFee(type(uint256).max);
    }

    function getBallotExecDelay() public view returns(uint256[10] memory) {
        return ballotExecDelay;
    }

    // MODIFIERS

    modifier onlyWhitelisted() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == owner() || isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyPool() {
        require(
            dispatcher.typeOf(msg.sender) == IDispatcher.ContractType.Pool,
            ExceptionsLibrary.NOT_POOL
        );
        _;
    }

    // function test83122() external pure returns (uint256) {
    //     return 3;
    // }
}