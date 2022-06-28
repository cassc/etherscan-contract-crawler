// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import './WQBridgeTokenInterface.sol';

contract WQBridgeStable is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    /**
     * @notice Settings of tokens
     * @return token Address of token
     * @return enabled Is true if enabled, is false if disabled
     * @return naive Is true if native coin, is false if ERC20 token
     */
    struct TokenSettings {
        uint256 minAmount;
        uint256 maxAmount;
        uint256 factor;
        address token;
        bool enabled;
    }

    /// @notice Admin role constant
    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    /// @notice Contract upgrader role constant
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

    /// @notice 1 - WorkQuest, 2 - Ethereum, 3 - Binance Smart Chain
    uint256 public chainId;

    address payable public pool;

    /// @notice List of enabled chain ID's
    mapping(uint256 => bool) public chains;

    /// @notice Settings of tokens
    mapping(string => TokenSettings) public tokens;

    /// @notice Map of message hash to swap state
    mapping(bytes32 => bool) public swaps;

    /**
     * @dev Emitted when swap created
     * @param timestamp Current block timestamp
     * @param recipient Recipient address
     * @param amount Amount of tokens
     * @param chainFrom Source chain id
     * @param chainTo Destination chain id
     * @param nonce Transaction number
     */
    event SwapInitialized(
        uint256 timestamp,
        address recipient,
        uint256 amount,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        string userId,
        string symbol
    );

    event Transferred(address token, address recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /** @notice Bridge constructor
     * @param _chainId 1 - WorkQuest, 2 - Ethereum, 3 - Binance Smart Chain
     */
    function initialize(uint256 _chainId, address payable _pool)
        external
        initializer
    {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);

        chainId = _chainId; // 1 - WQ, 2 - ETH, 3 - BSC     // TO_ASK why not standart numbers for chains?
        pool = _pool;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

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
        string calldata userId,
        string calldata symbol
    ) external payable whenNotPaused {
        require(chainTo != chainId, 'WorkQuest Bridge: Invalid chainTo id');
        require(chains[chainTo], 'WorkQuest Bridge: ChainTo ID is not allowed');
        TokenSettings storage token = tokens[symbol];
        require(
            token.enabled,
            'WorkQuest Bridge: This token not registered or disabled'
        );
        require(
            amount >= token.minAmount && amount <= token.maxAmount,
            'WorkQuest Bridge: Invalid amount'
        );
        bytes32 message = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                recipient,
                chainId,
                chainTo,
                userId,
                symbol
            )
        );
        require(
            !swaps[message],
            'WorkQuest Bridge: Swap is not empty state or duplicate transaction'
        );

        swaps[message] = true;
        IERC20Upgradeable(token.token).safeTransferFrom(
            msg.sender,
            pool,
            amount
        );
        emit SwapInitialized(
            block.timestamp,
            recipient,
            amount / token.factor,
            chainId,
            chainTo,
            nonce,
            userId,
            symbol
        );
    }

    /**
     * @notice Add enabled chain direction to bridge
     * @param _chainId Id of chain
     * @param enabled True - enabled, false - disabled direction
     */
    function updateChain(uint256 _chainId, bool enabled)
        external
        onlyRole(ADMIN_ROLE)
    {
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
     * @param factor The token factor to 18 decimals
     * @param minAmount Minimum amount of tokens
     * @param maxAmount Maximum amount of tokens
     * @param symbol Symbol of token
     */
    function updateToken(
        address token,
        bool enabled,
        uint256 factor,
        uint256 minAmount,
        uint256 maxAmount,
        string memory symbol
    ) public onlyRole(ADMIN_ROLE) {
        require(
            bytes(symbol).length > 0,
            'WorkQuest Bridge: Symbol length must be greater than 0'
        );
        tokens[symbol] = TokenSettings({
            minAmount: minAmount,
            maxAmount: maxAmount,
            token: token,
            enabled: enabled,
            factor: factor
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