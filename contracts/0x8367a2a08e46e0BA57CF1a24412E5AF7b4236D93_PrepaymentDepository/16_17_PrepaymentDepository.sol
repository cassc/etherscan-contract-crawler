// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../access-control-registry/AccessControlRegistryAdminnedWithManager.sol";
import "./interfaces/IPrepaymentDepository.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Contract that enables micropayments to be prepaid in batch
/// @notice `manager` represents the payment recipient, and its various
/// privileges can be delegated to other accounts through respective roles.
/// `manager`, `userWithdrawalLimitIncreaser` and `claimer` roles should only
/// be granted to a multisig or an equivalently decentralized account.
/// `withdrawalSigner` issues ERC191 signatures, and thus has to be an EOA. It
/// being compromised poses a risk in proportion to the redundancy in user
/// withdrawal limits. Have a `userWithdrawalLimitDecreaser` decrease user
/// withdrawal limits as necessary to mitigate this risk.
/// The `userWithdrawalLimitDecreaser` role can be granted to an EOA, as it
/// cannot cause irreversible harm.
/// This contract accepts prepayments in an ERC20 token specified immutably
/// during construction. Do not use tokens that are not fully ERC20-compliant.
/// An optional `depositWithPermit()` function is added to provide ERC2612
/// support.
contract PrepaymentDepository is
    AccessControlRegistryAdminnedWithManager,
    IPrepaymentDepository
{
    using ECDSA for bytes32;

    /// @notice Withdrawal signer role description
    string public constant override WITHDRAWAL_SIGNER_ROLE_DESCRIPTION =
        "Withdrawal signer";
    /// @notice User withdrawal limit increaser role description
    string
        public constant
        override USER_WITHDRAWAL_LIMIT_INCREASER_ROLE_DESCRIPTION =
        "User withdrawal limit increaser";
    /// @notice User withdrawal limit decreaser role description
    string
        public constant
        override USER_WITHDRAWAL_LIMIT_DECREASER_ROLE_DESCRIPTION =
        "User withdrawal limit decreaser";
    /// @notice Claimer role description
    string public constant override CLAIMER_ROLE_DESCRIPTION = "Claimer";

    // We prefer revert strings over custom errors because not all chains and
    // block explorers support custom errors
    string private constant AMOUNT_ZERO_REVERT_STRING = "Amount zero";
    string private constant AMOUNT_EXCEEDS_LIMIT_REVERT_STRING =
        "Amount exceeds limit";
    string private constant TRANSFER_UNSUCCESSFUL_REVERT_STRING =
        "Transfer unsuccessful";

    /// @notice Withdrawal signer role
    bytes32 public immutable override withdrawalSignerRole;
    /// @notice User withdrawal limit increaser role
    bytes32 public immutable override userWithdrawalLimitIncreaserRole;
    /// @notice User withdrawal limit decreaser role
    bytes32 public immutable override userWithdrawalLimitDecreaserRole;
    /// @notice Claimer role
    bytes32 public immutable override claimerRole;

    /// @notice Contract address of the ERC20 token that prepayments can be
    /// made in
    address public immutable override token;

    /// @notice Returns the withdrawal destination of the user
    mapping(address => address) public userToWithdrawalDestination;

    /// @notice Returns the withdrawal limit of the user
    mapping(address => uint256) public userToWithdrawalLimit;

    /// @notice Returns if the withdrawal with the hash is executed
    mapping(bytes32 => bool) public withdrawalWithHashIsExecuted;

    /// @param user User address
    /// @param amount Amount
    /// @dev Reverts if user address or amount is zero
    modifier onlyNonZeroUserAddressAndAmount(address user, uint256 amount) {
        require(user != address(0), "User address zero");
        require(amount != 0, AMOUNT_ZERO_REVERT_STRING);
        _;
    }

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    /// @param _token Contract address of the ERC20 token that prepayments are
    /// made in
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _token
    )
        AccessControlRegistryAdminnedWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
    {
        require(_token != address(0), "Token address zero");
        token = _token;
        withdrawalSignerRole = _deriveRole(
            _deriveAdminRole(manager),
            WITHDRAWAL_SIGNER_ROLE_DESCRIPTION
        );
        userWithdrawalLimitIncreaserRole = _deriveRole(
            _deriveAdminRole(manager),
            USER_WITHDRAWAL_LIMIT_INCREASER_ROLE_DESCRIPTION
        );
        userWithdrawalLimitDecreaserRole = _deriveRole(
            _deriveAdminRole(manager),
            USER_WITHDRAWAL_LIMIT_DECREASER_ROLE_DESCRIPTION
        );
        claimerRole = _deriveRole(
            _deriveAdminRole(manager),
            CLAIMER_ROLE_DESCRIPTION
        );
    }

    /// @notice Called by the user that has not set a withdrawal destination to
    /// set a withdrawal destination, or called by the withdrawal destination
    /// of a user to set a new withdrawal destination
    /// @param user User address
    /// @param withdrawalDestination Withdrawal destination
    function setWithdrawalDestination(
        address user,
        address withdrawalDestination
    ) external override {
        require(user != withdrawalDestination, "Same user and destination");
        require(
            (msg.sender == user &&
                userToWithdrawalDestination[user] == address(0)) ||
                (msg.sender == userToWithdrawalDestination[user]),
            "Sender not destination"
        );
        userToWithdrawalDestination[user] = withdrawalDestination;
        emit SetWithdrawalDestination(user, withdrawalDestination);
    }

    /// @notice Called to increase the withdrawal limit of the user
    /// @dev This function is intended to be used to revert faulty
    /// `decreaseUserWithdrawalLimit()` calls
    /// @param user User address
    /// @param amount Amount to increase the withdrawal limit by
    /// @return withdrawalLimit Increased withdrawal limit
    function increaseUserWithdrawalLimit(
        address user,
        uint256 amount
    )
        external
        override
        onlyNonZeroUserAddressAndAmount(user, amount)
        returns (uint256 withdrawalLimit)
    {
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    userWithdrawalLimitIncreaserRole,
                    msg.sender
                ),
            "Cannot increase withdrawal limit"
        );
        withdrawalLimit = userToWithdrawalLimit[user] + amount;
        userToWithdrawalLimit[user] = withdrawalLimit;
        emit IncreasedUserWithdrawalLimit(
            user,
            amount,
            withdrawalLimit,
            msg.sender
        );
    }

    /// @notice Called to decrease the withdrawal limit of the user
    /// @param user User address
    /// @param amount Amount to decrease the withdrawal limit by
    /// @return withdrawalLimit Decreased withdrawal limit
    function decreaseUserWithdrawalLimit(
        address user,
        uint256 amount
    )
        external
        override
        onlyNonZeroUserAddressAndAmount(user, amount)
        returns (uint256 withdrawalLimit)
    {
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    userWithdrawalLimitDecreaserRole,
                    msg.sender
                ),
            "Cannot decrease withdrawal limit"
        );
        uint256 oldWithdrawalLimit = userToWithdrawalLimit[user];
        require(
            amount <= oldWithdrawalLimit,
            AMOUNT_EXCEEDS_LIMIT_REVERT_STRING
        );
        withdrawalLimit = oldWithdrawalLimit - amount;
        userToWithdrawalLimit[user] = withdrawalLimit;
        emit DecreasedUserWithdrawalLimit(
            user,
            amount,
            withdrawalLimit,
            msg.sender
        );
    }

    /// @notice Called to claim tokens
    /// @param recipient Recipient address
    /// @param amount Amount of tokens to claim
    function claim(address recipient, uint256 amount) external override {
        require(recipient != address(0), "Recipient address zero");
        require(amount != 0, AMOUNT_ZERO_REVERT_STRING);
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    claimerRole,
                    msg.sender
                ),
            "Cannot claim"
        );
        emit Claimed(recipient, amount, msg.sender);
        require(
            IERC20(token).transfer(recipient, amount),
            TRANSFER_UNSUCCESSFUL_REVERT_STRING
        );
    }

    /// @notice Called to deposit tokens on behalf of a user
    /// @param user User address
    /// @param amount Amount of tokens to deposit
    /// @return withdrawalLimit Increased withdrawal limit
    function deposit(
        address user,
        uint256 amount
    )
        public
        override
        onlyNonZeroUserAddressAndAmount(user, amount)
        returns (uint256 withdrawalLimit)
    {
        withdrawalLimit = userToWithdrawalLimit[user] + amount;
        userToWithdrawalLimit[user] = withdrawalLimit;
        emit Deposited(user, amount, withdrawalLimit, msg.sender);
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            TRANSFER_UNSUCCESSFUL_REVERT_STRING
        );
    }

    /// @notice Called to apply a ERC2612 permit and deposit tokens on behalf
    /// of a user
    /// @param user User address
    /// @param amount Amount of tokens to deposit
    /// @param deadline Deadline of the permit
    /// @param v v component of the signature
    /// @param r r component of the signature
    /// @param s s component of the signature
    /// @return withdrawalLimit Increased withdrawal limit
    function applyPermitAndDeposit(
        address user,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 withdrawalLimit) {
        IERC20Permit(token).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        withdrawalLimit = deposit(user, amount);
    }

    /// @notice Called by a user to withdraw tokens
    /// @param amount Amount of tokens to withdraw
    /// @param expirationTimestamp Expiration timestamp of the signature
    /// @param withdrawalSigner Address of the account that signed the
    /// withdrawal
    /// @param signature Withdrawal signature
    /// @return withdrawalDestination Withdrawal destination
    /// @return withdrawalLimit Decreased withdrawal limit
    function withdraw(
        uint256 amount,
        uint256 expirationTimestamp,
        address withdrawalSigner,
        bytes calldata signature
    )
        external
        override
        returns (address withdrawalDestination, uint256 withdrawalLimit)
    {
        require(amount != 0, AMOUNT_ZERO_REVERT_STRING);
        require(block.timestamp < expirationTimestamp, "Signature expired");
        bytes32 withdrawalHash = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                amount,
                expirationTimestamp
            )
        );
        require(
            !withdrawalWithHashIsExecuted[withdrawalHash],
            "Withdrawal already executed"
        );
        require(
            withdrawalSigner == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    withdrawalSignerRole,
                    withdrawalSigner
                ),
            "Cannot sign withdrawal"
        );
        require(
            (withdrawalHash.toEthSignedMessageHash()).recover(signature) ==
                withdrawalSigner,
            "Signature mismatch"
        );
        withdrawalWithHashIsExecuted[withdrawalHash] = true;
        uint256 oldWithdrawalLimit = userToWithdrawalLimit[msg.sender];
        require(
            amount <= oldWithdrawalLimit,
            AMOUNT_EXCEEDS_LIMIT_REVERT_STRING
        );
        withdrawalLimit = oldWithdrawalLimit - amount;
        userToWithdrawalLimit[msg.sender] = withdrawalLimit;
        if (userToWithdrawalDestination[msg.sender] == address(0)) {
            withdrawalDestination = msg.sender;
        } else {
            withdrawalDestination = userToWithdrawalDestination[msg.sender];
        }
        emit Withdrew(
            msg.sender,
            withdrawalHash,
            amount,
            expirationTimestamp,
            withdrawalSigner,
            withdrawalDestination,
            withdrawalLimit
        );
        require(
            IERC20(token).transfer(withdrawalDestination, amount),
            TRANSFER_UNSUCCESSFUL_REVERT_STRING
        );
    }
}