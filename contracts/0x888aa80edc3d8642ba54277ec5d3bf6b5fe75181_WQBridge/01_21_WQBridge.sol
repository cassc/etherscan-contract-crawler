// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import './IWorkQuestToken.sol';
import './WQBridgePool.sol';

contract WQBridge is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    /// @notice Statuses of a swap
    enum State {
        Empty,
        Initialized,
        Redeemed
    }

    /// @notice Swap info structure
    struct SwapData {
        uint256 nonce;
        State state;
    }

    /**
     * @notice Settings of tokens
     * @return token Address of token
     * @return enabled Is true if enabled, is false if disabled
     * @return naive Is true if native coin, is false if ERC20 token
     */
    struct TokenSettings {
        address token;
        bool enabled;
        bool native;
        bool lockable;
    }

    /// @notice Admin role constant
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    /// @notice Upgrader role constant
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

    /// @notice Validator role constant
    bytes32 public constant VALIDATOR_ROLE = keccak256('VALIDATOR_ROLE');

    /// @notice 1 - WorkQuest, 2 - Ethereum, 3 - Binance Smart Chain
    uint256 public chainId;

    address payable public pool;

    /// @notice List of enabled chain ID's
    mapping(uint256 => bool) public chains;

    /// @notice Settings of tokens
    mapping(string => TokenSettings) public tokens;

    /// @notice Map of message hash to swap state
    mapping(bytes32 => SwapData) public swaps;

    /**
     * @dev Emitted when swap created
     * @param timestamp Current block timestamp
     * @param sender Initiator of transaction
     * @param recipient Recipient address
     * @param amount Amount of tokens
     * @param chainFrom Source chain id
     * @param chainTo Destination chain id
     * @param nonce Transaction number
     */
    event SwapInitialized(
        uint256 timestamp,
        address indexed sender,
        address recipient,
        uint256 amount,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        string symbol
    );

    /**
     * @dev Emitted when swap redeemed
     * @param timestamp Current block timestamp
     * @param sender Initiator of transaction
     * @param recipient Recipient address
     * @param amount Amount of tokens
     * @param chainFrom Source chain id
     * @param nonce Transaction number
     */
    event SwapRedeemed(
        uint256 timestamp,
        address indexed sender,
        address recipient,
        uint256 amount,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        string symbol
    );

    event Transferred(address token, address recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /** @notice Bridge constructor
     * @param _chainId 1 - WorkQuest, 2 - Ethereum, 3 - Binance Smart Chain
     */
    function initialize(
        uint256 _chainId,
        address payable _pool,
        address validator
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ADMIN_ROLE);
        _setupRole(VALIDATOR_ROLE, validator);
        chainId = _chainId; // 1 - WQ, 2 - ETH, 3 - BSC     // TO_ASK why not standart numbers for chains?
        pool = _pool;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev Creates new swap. Emits a {SwapInitialized} event.
     * @param nonce Number of transaction
     * @param chainTo Destination chain id
     * @param amount Amount of tokens
     * @param recipient Recipient address in target network
     * @param symbol Symbol of token
     */
    function swap(
        uint256 nonce,
        uint256 chainTo,
        uint256 amount,
        address recipient,
        string memory symbol
    ) external payable whenNotPaused {
        require(chains[chainTo], 'WorkQuest Bridge: ChainTo ID is not allowed');
        TokenSettings storage token = tokens[symbol];
        require(
            token.enabled,
            'WorkQuest Bridge: This token not registered or disabled'
        );
        bytes32 message = keccak256(
            abi.encodePacked(nonce, amount, recipient, chainId, chainTo, symbol)
        );
        require(
            swaps[message].state == State.Empty,
            'WorkQuest Bridge: Swap is not empty state or duplicate transaction'
        );
        swaps[message] = SwapData({nonce: nonce, state: State.Initialized});

        if (token.lockable) {
            IERC20Upgradeable(token.token).safeTransferFrom(
                msg.sender,
                pool,
                amount
            );
        } else if (token.native) {
            require(
                msg.value == amount,
                'WorkQuest Bridge: Amount value is not equal to transfered funds'
            );
            pool.sendValue(amount);
        } else {
            IWorkQuestToken(token.token).burn(msg.sender, amount);
        }

        if (
            tokens[symbol].token == tokens['USDT'].token ||
            tokens[symbol].token == tokens['USDC'].token
        ) {
            if (chainTo == 3) amount *= 1e12;
            if (chainId == 3) {
                require(amount >= 1e12, 'WorkQuest Bridge: Invalid amount');
                amount /= 1e12;
            }
        }

        emit SwapInitialized(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            chainId,
            chainTo,
            nonce,
            symbol
        );
    }

    /**
     * @dev Execute redeem. Emits a {SwapRedeemed} event
     * @param nonce Number of transaction
     * @param chainFrom Source chain id
     * @param amount Amount of tokens
     * @param recipient Recipient address in target network
     * @param v V of signature
     * @param r R of signature
     * @param s S of signature
     * @param symbol Symbol of token
     */
    function redeem(
        uint256 nonce,
        uint256 chainFrom,
        uint256 amount,
        address payable recipient,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory symbol
    ) external whenNotPaused {
        require(
            chains[chainFrom],
            'WorkQuest Bridge: chainFrom ID is not allowed'
        );
        require(
            tokens[symbol].enabled,
            'WorkQuest Bridge: This token not registered or disabled'
        );

        bytes32 message = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                recipient,
                chainFrom,
                chainId,
                symbol
            )
        );
        require(
            swaps[message].state == State.Empty,
            'WorkQuest Bridge: Swap is not empty state or duplicate transaction'
        );
        require(
            hasRole(
                VALIDATOR_ROLE,
                message.toEthSignedMessageHash().recover(v, r, s)
            ),
            'WorkQuest Bridge: Validator address is invalid or signature is faked'
        );

        swaps[message] = SwapData({nonce: nonce, state: State.Redeemed});
        if (tokens[symbol].lockable) {
            WQBridgePool(pool).transfer(
                recipient,
                amount,
                tokens[symbol].token
            );
        } else if (tokens[symbol].native) {
            WQBridgePool(pool).transfer(recipient, amount, address(0));
        } else {
            IWorkQuestToken(tokens[symbol].token).mint(recipient, amount);
        }

        emit SwapRedeemed(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            chainFrom,
            chainId,
            nonce,
            symbol
        );
    }

    /**
     * @dev Returns swap state.
     * @param message Hash of swap parameters
     */
    function getSwapState(bytes32 message) external view returns (State state) {
        return swaps[message].state;
    }

    /**
     * @notice Add enabled chain direction to bridge
     * @param _chainId Id of chain
     * @param enabled True - enabled, false - disabled direction
     */
    function updateChain(
        uint256 _chainId,
        bool enabled
    ) external onlyRole(ADMIN_ROLE) {
        chains[_chainId] = enabled;
    }

    /**
     * @notice Set address of pool
     * @param _pool Address of pool
     */
    function updatePool(address payable _pool) external onlyRole(ADMIN_ROLE) {
        require(_pool != payable(0), 'WQBridge: invalid pool address');
        pool = _pool;
    }

    /**
     * @notice Update token settings
     * @param token Address of token. Ignored in swap and redeem when native is true.
     * @param enabled True - enabled, false - disabled
     * @param native If money is native for this chain set true
     * @param symbol Symbol of token
     */
    function updateToken(
        address token,
        bool enabled,
        bool native,
        bool lockable,
        string memory symbol
    ) public onlyRole(ADMIN_ROLE) {
        require(
            bytes(symbol).length > 0,
            'WorkQuest Bridge: Symbol length must be greater than 0'
        );
        tokens[symbol] = TokenSettings({
            token: token,
            enabled: enabled,
            native: native,
            lockable: lockable
        });
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function removeLiquidity(
        address payable recipient,
        uint256 amount,
        address token
    ) external onlyRole(ADMIN_ROLE) {
        require(recipient != payable(0), 'WQBridge: invalid recipient address');
        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransfer(recipient, amount);
        } else {
            recipient.sendValue(amount);
        }
        emit Transferred(token, recipient, amount);
    }
}