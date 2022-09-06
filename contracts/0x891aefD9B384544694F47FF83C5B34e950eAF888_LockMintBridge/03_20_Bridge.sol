// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/HandleToken.sol";
import "./Signature.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

abstract contract Bridge is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    Signature
{
    string private constant invalidId = "Invalid bridge ID";
    string private constant invalidAmount = "Invalid amount";
    string private constant tokenNotSupported = "Token not supported";
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @dev The bridge ID. Must be unique across all connected bridges.
    uint256 public id;
    /// @dev The authorised signing address that authorises withdrawals.
    address public signer;
    /// @dev Mapping from token address to whether the bridge accepts it.
    mapping(address => bool) public tokensEnabled;
    /// @dev Mapping from user address to deposit nonce for this bridge.
    mapping(address => uint256) public depositNonce;
    /// @dev Mapping from user address to deposit bridge ID to withdrawal nonce.
    mapping(address => mapping(uint256 => uint256)) public withdrawNonce;
    /// @dev Mapping from token address to absolute withdraw fee value.
    mapping(address => uint256) tokenFees;

    event Deposit(
        address indexed depositor,
        address indexed token,
        uint256 amount,
        uint256 nonce,
        uint256 fromId,
        uint256 toId
    );
    event Withdraw(
        address indexed depositor,
        address indexed token,
        uint256 amount,
        uint256 nonce,
        uint256 fromId,
        uint256 toId
    );
    event SetTokenEnabled(address indexed token, bool enabled);
    event SetTokenFee(address indexed token, uint256 fee);
    event TransferFee(address indexed recipient, uint256 fee);

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "NO");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "NA");
        _;
    }

    modifier hasSigner() {
        require(signer != address(0), "Bridge is disabled");
        _;
    }

    /**
      * @dev Performs deposit sanity checks and emits Deposit event.
      */
    modifier depositsToken(
        address token,
        uint256 amount,
        uint256 toId
    ) {
        require(amount > 0, invalidAmount);
        require(tokensEnabled[token], tokenNotSupported);
        require(toId != id, invalidId);
        require(
            IHandleToken(token).balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );
        _;
        emit Deposit(
            msg.sender,
            token,
            amount,
            depositNonce[msg.sender]++,
            id,
            toId
        );
    }

    /**
      * @dev Performs withdrawal sanity checks and emits Withdrawal event.
      */
    modifier withdrawsToken(
        address recipient,
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 fromId,
        bytes memory signature
    ) {
        require(amount > 0, invalidAmount);
        require(tokensEnabled[token], tokenNotSupported);
        require(fromId != id, invalidId);
        require(nonce == withdrawNonce[recipient][fromId]++, "Invalid nonce");
        bytes32 message = getERC191Message(
            getWithdrawMessage(
                recipient,
                token,
                amount,
                nonce,
                fromId,
                id
            )
        );
        bool validSignature = getSignatureAddress(message, signature) == signer;
        require(validSignature, "Invalid signature");
        _;
        emit Withdraw(recipient, token, amount, nonce, fromId, id);
    }

    function initialize(uint256 _id, address _signer) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        id = _id;
        signer = _signer;
    }

    /**
      * @dev Sets the authorised signing address.
      *      May be set to zero to (temporarily) disable the bridge.
      *      Changing the address invalidates all signed messages from
      *      the previous address.
      */
    function setSigner(address _signer) external onlyAdmin {
        signer = _signer;
    }

    /**
     * @dev Sets a token fee.
     * @param token The token address to set the fee for.
     * @param fee The fee amount, in quantities of the token
     *        (NOT a ratio or percentage, but an absolute value).
     */
    function setTokenFee(address token, uint256 fee) external onlyAdmin {
        tokenFees[token] = fee;
        emit SetTokenFee(token, fee);
    }

    /**
      * @dev Deposits tokens into bridge.
      * @param token The token address.
      * @param amount The amount to deposit.
      * @param toId The bridge ID to withdraw the tokens from.
      */
    function deposit(
        address token,
        uint256 amount,
        uint256 toId
    ) external virtual hasSigner depositsToken(
        token,
        amount,
        toId
    ) {}

    /** 
      * @dev Withdraws token from the bridge using a signature.
      * @param recipient The user to withdraw the tokens for.
      * @param token The token address to be withdrawn.
      * @param nonce The deposit nonce from the deposit bridge.
      * @param fromId The deposit bridge ID.
      * @param signature The withdrawal request signed by the bridge signer.
      */
    function withdraw(
        address recipient,
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 fromId,
        bytes memory signature
    )
        external
        virtual
        hasSigner
        withdrawsToken(
            recipient,
            token,
            amount,
            nonce,
            fromId,
            signature
        )
    {}

    /**
      * @dev Sets a token as enabled or disabled for deposits and withdrawals.
      * @param token The token to enable or disable.
      * @param enabled Whether the token is to be enabled or disabled.
      */
    function setTokenEnabled(address token, bool enabled) external onlyAdmin {
        tokensEnabled[token] = enabled;
        emit SetTokenEnabled(token, enabled);
    }

    /**
      * @dev Retrieves an unsigned withdrawal message.
      * @param recipient The account to withdraw.
      * @param token The token address to be withdrawn.
      * @param amount The amount to be withdrawn.
      * @param nonce The deposit bridge's deposit nonce.
      * @param fromId The deposit bridge's ID.
      * @param toId The withdrawal bridge's ID.
      */
    function getWithdrawMessage(
        address recipient,
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 fromId,
        uint256 toId 
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    recipient,
                    token,
                    amount,
                    nonce,
                    fromId,
                    toId
                )
            );
    }

    /**
      * @dev Wraps a message into the ERC191 standard.
      * @param message The message to parse.
      */
    function getERC191Message(bytes32 message) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1("E"),
                    bytes("thereum Signed Message:\n32"),
                    message
                )
            );
    }

    /**
     * @dev Returns the net amount to be withdrawn, ensuring the net amount is
     *      greater than zero.
     * @param recipient The recipient of the withdrawal.
     * @param token The token being bridged.
     * @param amount The gross amount being bridged.
     */
    function getNetAmountAfterFee(
        address recipient,
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        if (recipient == msg.sender) return amount;
        uint256 fee = tokenFees[token];
        require(amount > fee, "Amount too small for fee");
        return amount - fee;
    }

    /** @dev Protected UUPS upgrade authorization fuction */
    function _authorizeUpgrade(address) internal override onlyAdmin {}
}