// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/libraries/MultiSend.sol";
import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "@gnosis.pm/zodiac/contracts/factory/ModuleProxyFactory.sol";

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";


interface IERC20 {
    // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function totalShares() external view returns (uint256);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function getUserTokenBalance(address user, address token)
        external
        view
        returns (uint256);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function memberAddressByDelegateKey(address user)
        external
        view
        returns (address);

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;

    struct Proposal {
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals (doubles as guild kick target for gkick proposals)
        address proposer; // the account that submitted the proposal (can be non-member)
        address sponsor; // the member that sponsored the proposal (moving it into the queue)
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 lootRequested; // the amount of loot the applicant is requesting
        uint256 tributeOffered; // amount of tokens offered as tribute
        address tributeToken; // tribute token contract reference
        uint256 paymentRequested; // amount of tokens requested as payment
        address paymentToken; // payment token contract reference
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool[6] flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 maxTotalSharesAndLootAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
    }

    function proposals(uint256 proposalId)
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            address,
            uint256,
            uint256,
            uint256
        );
}

/// @title SafeMinion - Gnosis compatible module to manage state of a Safe through Moloch v2 governance
/// @dev Executes arbitrary transactions on behalf of the Safe based on proposals submitted through this Minion's interface
///  Must be configured to interact with one Moloch contract and one Safe
///
///  Safe Settings:
///
///     Must be enabled on the Safe through `enableModule`
///        This happens automatically if using the included minion & safe factory
///     Optionally can be enabled as an owner on the Safe so the Moloch can act as a signer
///     Optionally can enable additional signers on the Safe to act as delegates to bypass governance
///
///  Minion Settings:
///
///     Optional Quorum settings for early execution of proposals
///
///  Actions:
///
///     All actions use the Gnosis multisend library and must be encoded as shown in docs/ tests
///
///  Minion is owned by the Safe
///  Owner can change the safe address via `setAvatar`
///  Owner can change the target address via `setTarget`
/// @author Isaac Patka, Dekan Brown
contract SafeMinion is Enum, Module {
    // Moloch configured to instruct this minion
    IMOLOCH public moloch;

    // Gnosis multisendLibrary library contract
    address public multisendLibrary;

    // Default ERC20 token address to include in Moloch proposals as tribute token
    address public molochDepositToken;

    // Optional quorum for early execution - set to 0 to disable
    uint256 public minQuorum;

    // Keep track of actions associated with proposal IDs
    struct Action {
        bytes32 id;
        address proposer;
        bool executed;
        address token;
        bool nonZeroAmount;
        bool memberOnlyEnabled; // 0 anyone , 1 memberOnly
    }

    mapping(uint256 => Action) public actions;

    // Error Strings
    string private constant ERROR_REQS_NOT_MET =
        "Minion::proposal execution requirements not met";
    string private constant ERROR_NOT_VALID = "Minion::not a valid operation";
    string private constant ERROR_EXECUTED = "Minion::action already executed";
    string private constant ERROR_DELETED = "Minion::action was deleted";
    string private constant ERROR_CALL_FAIL = "Minion::call failure";
    string private constant ERROR_NOT_PROPOSER = "Minion::not proposer";
    string private constant ERROR_MEMBER_ONLY = "Minion::not member";
    string private constant ERROR_AVATAR_ONLY = "Minion::not avatar";
    string private constant ERROR_INVALID_SELF_XWITHDRAW = "Minion::invalid self crosswithdraw";
    string private constant ERROR_INVALID_BAL_XWITHDRAW = "Minion::invalid balance crosswithdraw";
    string private constant ERROR_NOT_SPONSORED =
        "Minion::proposal not sponsored";
    string private constant ERROR_MIN_QUORUM_BOUNDS =
        "Minion::minQuorum must be 0 to 100";
    string private constant ERROR_ZERO_DEPOSIT_TOKEN =
        "Minion:zero deposit token is not allowed";
    string private constant ERROR_NO_ACTION = "Minion:action does not exist";
    string private constant ERROR_NOT_WL = "Minion:token is not whitelisted";

    event ProposeNewAction(
        bytes32 indexed id,
        uint256 indexed proposalId,
        address withdrawToken,
        uint256 withdrawAmount,
        address moloch,
        bool memberOnly,
        bytes transactions
    );
    event ExecuteAction(
        bytes32 indexed id,
        uint256 indexed proposalId,
        bytes transactions,
        address avatar
    );

    event DoWithdraw(address token, uint256 amount);
    event ActionCanceled(uint256 proposalId);
    event ActionDeleted(uint256 proposalId);
    event CrossWithdraw(address target, address token, uint256 amount);

    modifier memberOnly() {
        require(isMember(msg.sender), ERROR_MEMBER_ONLY);
        _;
    }

    modifier avatarOnly() {
        require(msg.sender == avatar, ERROR_AVATAR_ONLY);
        _;
    }

    /// @dev This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() initializer {
        // By setting the owner it is not possible to call setUp
        // This is an unusable minion, perfect for the singleton
        __Ownable_init();
        transferOwnership(address(0xdead));
    }

    /// @dev Factory Friendly setup function
    /// @notice Can only be called once by factory
    /// @param _initializationParams ABI Encoded parameters needed for configuration
    function setUp(bytes memory _initializationParams) public override(FactoryFriendly) initializer {
        // Decode initialization parameters
        (
            address _moloch,
            address _avatar,
            address _multisendLibrary,
            uint256 _minQuorum
        ) = abi.decode(
                _initializationParams,
                (address, address, address, uint256)
            );

        // Initialize ownership and transfer immediately to avatar
        // Ownable Init reverts if already initialized
        __Ownable_init();
        transferOwnership(_avatar);

        // min quorum must be between 0% and 100%, if 0 early execution is disabled
        require(_minQuorum >= 0 && _minQuorum <= 100, ERROR_MIN_QUORUM_BOUNDS);
        minQuorum = _minQuorum;

        // Set the moloch to instruct this minion
        moloch = IMOLOCH(_moloch);

        // Set the Gnosis safe address
        avatar = _avatar;
        target = _avatar; /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/

        // Set the library to use for all transaction executions
        multisendLibrary = _multisendLibrary;

        // Set the default moloch token to use in proposals
        molochDepositToken = moloch.depositToken();
    }

    /// @dev Member accessible interface to withdraw funds from Moloch directly to Safe
    /// @notice Can only be called by member of Moloch
    /// @param _token ERC20 address of token to withdraw
    /// @param _amount ERC20 token amount to withdraw
    function doWithdraw(address _token, uint256 _amount) public memberOnly {
        // Construct transaction data for safe to execute
        bytes memory withdrawData = abi.encodeWithSelector(
            moloch.withdrawBalance.selector,
            _token,
            _amount
        );
        require(
            exec(address(moloch), 0, withdrawData, Operation.Call),
            ERROR_CALL_FAIL
        );
        emit DoWithdraw(_token, _amount);
    }

    /// @dev Member accessible interface to withdraw funds from another Moloch directly to Safe or to the DAO
    /// @notice Can only be called by member of Moloch
    /// @param _moloch MOLOCH address to withdraw from
    /// @param _token ERC20 address of token to withdraw
    /// @param _amount ERC20 token amount to withdraw
    /// @param _transfer Flag to send the retrieved tokens to the new Moloch
    function crossWithdraw(
        IMOLOCH _moloch,
        address _token,
        uint256 _amount,
        bool _transfer
    ) external memberOnly {
        require(address(_moloch) != address(moloch), ERROR_INVALID_SELF_XWITHDRAW); /*Disallow crosswithdraw from self to prevent execution frontrun griefing*/
        uint256 _balanceBefore = IERC20(_token).balanceOf(avatar); /*Save balance before so we can check for violation*/
        // Construct transaction data for safe to execute
        bytes memory withdrawData = abi.encodeWithSelector(
            _moloch.withdrawBalance.selector,
            _token,
            _amount
        );
        require(
            exec(address(_moloch), 0, withdrawData, Operation.Call),
            ERROR_CALL_FAIL
        );

        // Transfers token into DAO treasury
        if (_transfer) {
            bool whitelisted = moloch.tokenWhitelist(_token);
            require(whitelisted, ERROR_NOT_WL);
            bytes memory transferData = abi.encodeWithSelector(
                IERC20(_token).transfer.selector,
                address(moloch),
                _amount
            );
            require(
                exec(_token, 0, transferData, Operation.Call),
                ERROR_CALL_FAIL
            );
        }
        uint256 _balanceAfter = IERC20(_token).balanceOf(avatar); /*Save balance after so we can check for violation*/
        
        require(_balanceAfter >= _balanceBefore, ERROR_INVALID_BAL_XWITHDRAW); /*Check for violation where safe token balance has decreased*/

        emit CrossWithdraw(address(_moloch), _token, _amount);
    }

    /// @dev Internal utility function to store hash of transaction data to ensure executed action is the same as proposed action
    /// @param _proposalId Proposal ID associated with action to delete
    /// @param _transactions Multisend encoded transactions to be executed if proposal succeeds
    /// @param _withdrawToken ERC20 token for any payment requested
    /// @param _withdrawAmount ERC20 amount for any payment requested
    /// @param _memberOnlyEnabled Optionally restrict execution of this action to only memgbers
    function saveAction(
        uint256 _proposalId,
        bytes memory _transactions,
        address _withdrawToken,
        uint256 _withdrawAmount,
        bool _memberOnlyEnabled
    ) internal {
        bytes32 _id = hashOperation(_transactions);
        Action memory _action = Action({
            id: _id,
            proposer: msg.sender,
            executed: false,
            token: _withdrawToken,
            nonZeroAmount: _withdrawAmount > 0,
            memberOnlyEnabled: _memberOnlyEnabled
        });
        actions[_proposalId] = _action;
        emit ProposeNewAction(
            _id,
            _proposalId,
            _withdrawToken,
            _withdrawAmount,
            address(moloch),
            _memberOnlyEnabled,
            _transactions
        );
    }

    /// @dev Utility function to check if proposal is passed internally and can also be used on the DAO UI
    /// @param _proposalId Proposal ID associated with action to check
    function isPassed(uint256 _proposalId) public view returns (bool) {
        // Retrieve proposal status flags from moloch
        bool[6] memory flags = moloch.getProposalFlags(_proposalId);
        require(flags[0], ERROR_NOT_SPONSORED);

        // If proposal has passed, return without checking quorm
        if (flags[2]) return true;

        // If quorum enabled, calculate status. Quorum must be met and there cannot be any NO votes
        if (minQuorum != 0) {
            uint256 totalShares = moloch.totalShares();
            (, , , , , , , , , , uint256 yesVotes, ) = moloch.proposals(
                _proposalId
            );
            uint256 quorum = (yesVotes * 100) / totalShares;
            return quorum >= minQuorum;
        }

        return false;
    }

    /// @dev Internal utility function to check if user is member of associate Moloch
    /// @param _user Address of user to check
    function isMember(address _user) internal view returns (bool) {
        // member only check should check if member or delegate
        address _memberAddress = moloch.memberAddressByDelegateKey(_user);
        (, uint256 _shares, , , , ) = moloch.members(_memberAddress);
        return _shares > 0;
    }

    /// @dev Internal utility function to hash transactions for storing & checking prior to execution
    /// @param _transactions Encoded transction data
    function hashOperation(bytes memory _transactions)
        public
        pure
        virtual
        returns (bytes32 hash)
    {
        return keccak256(abi.encode(_transactions));
    }

    /// @dev Member accessible interface to make a proposal to Moloch and store associated action information
    /// @notice Can only be called by member of Moloch
    /// @param _transactions Multisend encoded transactions to be executed if proposal succeeds
    /// @param _withdrawToken ERC20 token for any payment requested
    /// @param _withdrawAmount ERC20 amount for any payment requested
    /// @param _details Optional metadata to include in proposal
    /// @param _memberOnlyEnabled Optionally restrict execution of this action to only memgbers
    function proposeAction(
        bytes memory _transactions,
        address _withdrawToken,
        uint256 _withdrawAmount,
        string calldata _details,
        bool _memberOnlyEnabled
    ) external memberOnly returns (uint256) {
        uint256 _proposalId = moloch.submitProposal(
            avatar,
            0,
            0,
            0,
            molochDepositToken,
            _withdrawAmount,
            _withdrawToken,
            _details
        );

        saveAction(
            _proposalId,
            _transactions,
            _withdrawToken,
            _withdrawAmount,
            _memberOnlyEnabled
        );

        return _proposalId;
    }

    /// @dev Function to delete an action submitted in prior proposal
    /// @notice Can only be called by the avatar which means this can only be called if passed by another
    ///     proposal or by a delegated signer on the Safe
    ///     Makes it so the action can not be executed
    /// @param _proposalId Proposal ID associated with action to delete
    function deleteAction(uint256 _proposalId)
        external
        avatarOnly
        returns (bool)
    {
        // check action exists
        require(actions[_proposalId].proposer != address(0), ERROR_NO_ACTION);
        delete actions[_proposalId];
        emit ActionDeleted(_proposalId);
        return true;
    }

    /// @dev Function to Execute arbitrary code as the minion - useful if funds are accidentally sent here
    /// @notice Can only be called by the avatar which means this can only be called if passed by another
    ///     proposal or by a delegated signer on the Safe
    /// @param _to address to call
    /// @param _value value to include in wei
    /// @param _data arbitrary transaction data
    function executeAsMinion(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external avatarOnly {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "call failure");
    }

    /// @dev Function to execute an action if the proposal has passed or quorum has been met
    ///     Can be restricted to only members if specified in proposal
    /// @param _proposalId Proposal ID associated with action to execute
    /// @param _transactions Multisend encoded transactions, must be same as transactions in proposal
    function executeAction(uint256 _proposalId, bytes memory _transactions)
        external
        returns (bool)
    {
        Action memory _action = actions[_proposalId];
        require(!_action.executed, ERROR_EXECUTED);
        // Mark executed before doing any external stuff
        actions[_proposalId].executed = true;

        // Check if restricted to only member execution and enforce it
        if (_action.memberOnlyEnabled) {
            require(isMember(msg.sender), ERROR_MEMBER_ONLY);
        }

        // Confirm proposal has passed or quorum is met
        require(isPassed(_proposalId), ERROR_REQS_NOT_MET);

        // Confirm action has not been deleted prior to attempting execution
        require(_action.id != 0, ERROR_DELETED);

        // Recover the hash of the submitted transctions and confirm they match the proposal
        bytes32 _id = hashOperation(_transactions);
        require(_id == _action.id, ERROR_NOT_VALID);

        // Withdraw tokens from Moloch to safe if specified by the proposal, and if they have not already been withdrawn via `doWithdraw`
        if (_action.nonZeroAmount) {
            uint256 _balance = moloch.getUserTokenBalance(
                avatar,
                _action.token
            );
            if (_balance > 0) {
                // withdraw tokens if any
                doWithdraw(_action.token, _balance);
            }
        }

        // Execute the action via the multisend library
        require(
            exec(multisendLibrary, 0, _transactions, Operation.DelegateCall),
            ERROR_CALL_FAIL
        );

        emit ExecuteAction(_id, _proposalId, _transactions, msg.sender);

        delete actions[_proposalId];

        return true;
    }

    /// @dev Function to cancel an action by the proposer if not yet sponsored
    /// @param _proposalId Proposal ID associated with action to cancel
    function cancelAction(uint256 _proposalId) external {
        Action memory action = actions[_proposalId];
        require(msg.sender == action.proposer, ERROR_NOT_PROPOSER);
        delete actions[_proposalId];
        moloch.cancelProposal(_proposalId);
        emit ActionCanceled(_proposalId);
    }
}

/// @title SafeMinionSummoner - Factory contract to depoy new Minions and Safes
/// @dev Can deploy a minion and a new safe, or just a minion to be attached to an existing safe
/// @author Isaac Patka, Dekan Brown
contract SafeMinionSummoner is ModuleProxyFactory {
    // Template contract to use for new minion proxies
    address payable public immutable safeMinionSingleton;

    // Template contract to use for new Gnosis safe proxies
    address public immutable gnosisSingleton;

    // Library to use for EIP1271 compatability
    address public immutable gnosisFallbackLibrary;

    // Library to use for all safe transaction executions
    address public immutable gnosisMultisendLibrary;

    //
    GnosisSafeProxyFactory gnosisSafeProxyFactory;
    ModuleProxyFactory moduleProxyFactory;

    // Track list and count of deployed minions
    address[] public minionList;

    function minionCount() public view returns (uint256) {
        return minionList.length;
    }

    // Track metadata and associated moloch for deployed minions
    struct AMinion {
        address moloch;
        string details;
    }
    mapping(address => AMinion) public minions;

    // Public type data
    string public constant minionType = "SAFE MINION V0";

    event SummonMinion(
        address indexed minion,
        address indexed moloch,
        address indexed avatar,
        string details,
        string minionType,
        uint256 minQuorum
    );

    /// @dev Construtor sets the initial templates
    /// @notice Can only be called once by factory
    /// @param _safeMinionSingleton Template contract to be used for minion factory
    /// @param _gnosisSingleton Template contract to be used for safe factory
    /// @param _gnosisFallbackLibrary Library contract to be used in configuring new safes
    /// @param _gnosisMultisendLibrary Library contract to be used in configuring new safes
    /// @param _gnosisSafeProxyFactory Factory address to deploy safes (use official)
    /// @param _moduleProxyFactory Todo
    constructor(
        address payable _safeMinionSingleton,
        address _gnosisSingleton,
        address _gnosisFallbackLibrary,
        address _gnosisMultisendLibrary,
        address _gnosisSafeProxyFactory,
        address _moduleProxyFactory
    ) {
        safeMinionSingleton = _safeMinionSingleton;
        gnosisSingleton = _gnosisSingleton;
        gnosisFallbackLibrary = _gnosisFallbackLibrary;
        gnosisMultisendLibrary = _gnosisMultisendLibrary;
        gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
        moduleProxyFactory = ModuleProxyFactory(_moduleProxyFactory);
    }

    /// @dev Function to only summon a minion to be attached to an existing safe
    /// @param _moloch Already deployed Moloch to instruct minion
    /// @param _avatar Already deployed safe
    /// @param _details Optional metadata to store
    /// @param _minQuorum Optional quorum settings, set 0 to disable
    /// @param _saltNonce Number used to calculate the address of the new minion
    function summonMinion(
        address _moloch,
        address _avatar,
        string memory _details,
        uint256 _minQuorum,
        uint256 _saltNonce
    ) external returns (address) {
        // Encode initializer for setup function
        bytes memory _initializer = abi.encode(
            _moloch,
            _avatar,
            gnosisMultisendLibrary,
            _minQuorum
        );
        // bytes memory _initializerCall = abi.encodeWithSignature(
        //     "setUp(bytes)",
        //     _initializer
        // );

        SafeMinion _minion = SafeMinion(
            payable(
                moduleProxyFactory.deployModule(
                    safeMinionSingleton,
                    abi.encodeWithSignature("setUp(bytes)", _initializer),
                    _saltNonce
                )
            )
        );

        minions[address(_minion)] = AMinion(_moloch, _details);
        minionList.push(address(_minion));

        emit SummonMinion(
            address(_minion),
            _moloch,
            _avatar,
            _details,
            minionType,
            _minQuorum
        );

        return (address(_minion));
    }

    /// @dev Function to summon minion and configure with a new safe
    /// @param _moloch Already deployed Moloch to instruct minion
    /// @param _details Optional metadata to store
    /// @param _minQuorum Optional quorum settings, set 0 to disable
    /// @param _saltNonce Number used to calculate the address of the new minion
    function summonMinionAndSafe(
        address _moloch,
        string memory _details,
        uint256 _minQuorum,
        uint256 _saltNonce
    ) external returns (address) {
        // Deploy new safe but do not set it up yet
        GnosisSafe _safe = GnosisSafe(
            payable(
                gnosisSafeProxyFactory.createProxy(
                    gnosisSingleton,
                    abi.encodePacked(_moloch, _saltNonce)
                )
            )
        );
        
        bytes memory _initializer = abi.encode(
            _moloch,
            address(_safe),
            gnosisMultisendLibrary,
            _minQuorum
        );

        // Deploy new minion but do not set it up yet
        SafeMinion _minion = SafeMinion(
            moduleProxyFactory.deployModule(
                safeMinionSingleton,
                abi.encodeWithSignature("setUp(bytes)", _initializer),
                _saltNonce
            )
        );

        // Generate delegate calls so the safe calls enableModule on itself during setup
        bytes memory _enableMinion = abi.encodeWithSignature(
            "enableModule(address)",
            address(_minion)
        );
        bytes memory _enableMinionMultisend = abi.encodePacked(
            uint8(0),
            address(_safe),
            uint256(0),
            uint256(_enableMinion.length),
            bytes(_enableMinion)
        );
        bytes memory _multisendAction = abi.encodeWithSignature(
            "multiSend(bytes)",
            _enableMinionMultisend
        );

        // Workaround for solidity dynamic memory array
        address[] memory _owners = new address[](1);
        _owners[0] = address(_minion);

        // Call setup on safe to enable our new module and set the module as the only signer
        _safe.setup(
            _owners,
            1,
            gnosisMultisendLibrary,
            _multisendAction,
            gnosisFallbackLibrary,
            address(0),
            0,
            payable(address(0))
        );

        minions[address(_minion)] = AMinion(_moloch, _details);
        minionList.push(address(_minion));
        emit SummonMinion(
            address(_minion),
            _moloch,
            address(_safe),
            _details,
            minionType,
            _minQuorum
        );

        return (address(_minion));
    }
}