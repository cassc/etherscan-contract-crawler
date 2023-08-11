// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./lib/Misc.sol";
import "./tokens/DERC20.sol";

contract DecimalBridge is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    // 1 - DEL, 2 - ETH, 3 - BSC
    uint256 public immutable chainId;

    // the list of all registered tokens
    address[] tokenList;

    // tokenBySymbol[Symbol] = tokenAddress
    mapping(string => address) public tokenBySymbol;

    // chainList[chainId] = enabled
    mapping(uint256 => bool) public chainList;

    // swaps[hashedMsg] = SwapData
    mapping(bytes32 => SwapData) public swaps;

    // Struct of swap
    struct SwapData {
        uint256 transaction; // transaction number
        State state;
    }

    // Status of swap
    enum State {
        Empty,
        Initialized,
        Redeemed
    }

    /**
     * @dev Emitted when swap to Decimal chain created
     *
     */
    event SwapToDecimalInitialized(
        uint256 timestamp,
        address indexed initiator,
        string recipient,
        uint256 amount,
        string tokenSymbol,
        uint256 chainTo,
        uint256 nonce
    );

    /**
     * @dev Emitted when swap to other chain created
     *
     */
    event SwapInitialized(
        uint256 timestamp,
        address indexed initiator,
        address recipient,
        uint256 amount,
        string tokenSymbol,
        uint256 chainTo,
        uint256 nonce
    );

    /**
     * @dev Emitted when swap redeemed.
     */
    event SwapRedeemed(
        address indexed initiator,
        uint256 timestamp,
        uint256 nonce
    );

    /**
     * @dev Emitted when new token added
     */
    event TokenAdded(address token, string symbol);

    constructor(uint256 _chainId) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        // Sets `ADMIN_ROLE` as `VALIDATOR_ROLE`'s admin role.
        _setRoleAdmin(VALIDATOR_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `MINTER_ROLE`'s admin role.
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `BURNER_ROLE`'s admin role.
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        // Sets `ADMIN_ROLE` as `PAUSER_ROLE`'s admin role.
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);

        chainId = _chainId; // 1 - DEL, 2 - ETH, 3 - BSC
    }

    /**
     * @dev Returned list of registered tokens
     */
    function getTokenList() public view returns (address[] memory) {
        return tokenList;
    }

    /**
     * @dev Creates new swap.
     *
     * Emits a {SwapInitialized} event
     *
     * Arguments
     *
     * - `amount` amount of tokens
     * - `nonce` number of transaction
     * - `recipient` recipient address in another network
     * - `chainTo` destination chain id
     * - `tokenSymbol` - symbol of token
     */
    function swap(
        uint256 amount,
        uint256 nonce,
        address recipient,
        uint256 chainTo,
        string memory tokenSymbol
    ) external {
        require(chainTo != chainId, "DecimalBridge: Invalid chainTo id");
        require(chainList[chainTo], "DecimalBridge: ChainTo id is not allowed");
        address tokenAddress = tokenBySymbol[tokenSymbol];
        require(
            tokenAddress != address(0),
            "DecimalBridge: Token is not registered"
        );
        bytes32 hashedMsg = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainId,
                chainTo
            )
        );

        require(
            swaps[hashedMsg].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        swaps[hashedMsg] = SwapData({
            transaction: nonce,
            state: State.Initialized
        });

        DERC20(tokenAddress).burn(msg.sender, amount);

        emit SwapInitialized(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            tokenSymbol,
            chainTo,
            nonce
        );
    }

    /**
     * @dev Creates new swap to decimal chain
     *
     * Emits a {SwapInitialized} event.
     *
     * Arguments
     *
     * - `amount` amount of tokens
     * - `nonce` number of transaction
     * - `recipient` recipient address in decimal network
     * - `tokenSymbol` symbol of token
     */
    function swapToDecimal(
        uint256 amount,
        uint256 nonce,
        string memory recipient,
        string memory tokenSymbol
    ) external {
        address tokenAddress = tokenBySymbol[tokenSymbol];
        require(
            tokenAddress != address(0),
            "DecimalBridge: Token is not registered"
        );
        require(
            bytes(recipient).length == 41,
            "DecimalBridge: Recipient must be 41 symbols long"
        );
        bytes32 hashedMsg = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainId,
                uint256(1)
            )
        );

        require(
            swaps[hashedMsg].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        swaps[hashedMsg] = SwapData({
            transaction: nonce,
            state: State.Initialized
        });

        DERC20(tokenAddress).burn(msg.sender, amount);

        emit SwapToDecimalInitialized(
            block.timestamp,
            msg.sender,
            recipient,
            amount,
            tokenSymbol,
            1,
            nonce
        );
    }

    /**
     * @dev Execute redeem.
     *
     * Emits a {SwapRedeemed} event.
     * Emits a {TokenAdded} event when new token sended
     *
     * Arguments:
     *
     * - `amount` amount of transaction.
     * - `recipient` recipient address in target network.
     * - `nonce` number of transaction.
     * - `chainFrom` source chain id
     * - `_v` v of signature.
     * - `_r` r of signature.
     * - `_s` s of signature.
     * - `tokenSymbol` symbol of token
     */
    function redeem(
        uint256 amount,
        address recipient,
        uint256 nonce,
        uint256 chainFrom,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        string memory tokenSymbol
    ) external {
        require(chainFrom != chainId, "DecimalBridge: Invalid chainFrom id");
        require(
            chainList[chainFrom],
            "DecimalBridge: ChainFrom id not allowed"
        );
        require(
            bytes(tokenSymbol).length > 0,
            "DecimalBridge: Symbol length should be greater than 0"
        );
        address tokenAddress = tokenBySymbol[tokenSymbol];
        if (tokenAddress == address(0)) {
            tokenAddress = address(new DERC20(tokenSymbol));
            tokenBySymbol[tokenSymbol] = tokenAddress;
            tokenList.push(tokenAddress);
            emit TokenAdded(tokenAddress, tokenSymbol);
        }
        bytes32 message = keccak256(
            abi.encodePacked(
                nonce,
                amount,
                tokenSymbol,
                recipient,
                chainFrom,
                chainId
            )
        );
        require(
            swaps[message].state == State.Empty,
            "DecimalBridge: Swap is not empty state or duplicate tx"
        );

        bytes32 hashedMsg = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        address signer = Misc.recover(hashedMsg, _v, _r, _s);
        require(
            hasRole(VALIDATOR_ROLE, signer),
            "DecimalBridge: Validator address is invalid"
        );

        swaps[message] = SwapData({transaction: nonce, state: State.Redeemed});

        DERC20(tokenAddress).mint(recipient, amount);

        emit SwapRedeemed(msg.sender, block.timestamp, nonce);
    }

    /**
     * @dev Returns swap state.
     *
     * Arguments
     *
     * - `hashedSecret` hash of swap.
     */
    function getSwapState(bytes32 hashedSecret)
        external
        view
        returns (State state)
    {
        return swaps[hashedSecret].state;
    }

    /**
     * @dev Add a new token
     *
     * Emits a {TokenAdded} event.
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function addToken(string memory symbol) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        require(
            bytes(symbol).length > 0,
            "DecimalBridge: Symbol length should be greater than 0"
        );
        address tokenAddress = tokenBySymbol[symbol];
        require(
            tokenAddress == address(0),
            "DecimalBridge: Token is already registered"
        );

        tokenAddress = address(new DERC20(symbol));
        tokenBySymbol[symbol] = tokenAddress;
        tokenList.push(tokenAddress);
        emit TokenAdded(tokenAddress, symbol);
    }

    /**
     * @dev Update a token address
     *
     * Arguments
     *
     * - `symbol` symbol of a token.
     * - `newToken` new address of a token
     */
    function updateToken(string memory symbol, address newToken) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        tokenBySymbol[symbol] = newToken;
    }

    /**
     * @dev Manually mint token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `to` recipient address.
     * - `amount` amount of tokens.
     */
    function mintToken(
        string memory symbol,
        address to,
        uint256 amount
    ) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a minter"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).mint(to, amount);
    }

    /**
     * @dev Manually burn token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `from` address of user.
     * - `amount` amount of tokens.
     */
    function burnToken(
        string memory symbol,
        address from,
        uint256 amount
    ) external {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a burner"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).burn(from, amount);
    }

    /**
     * @dev Grant role for token by symbol
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `role` role constant.
     * - `user` address of user.
     */
    function grantRoleToken(
        string memory symbol,
        bytes32 role,
        address user
    ) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).grantRole(role, user);
    }

    /**
     * @dev Add enabled chain direction to bridge
     *
     * Arguments
     *
     * - `_chainId` id of chain.
     * - `enabled` true - enable chain, false - disable chain.
     */
    function updateChain(uint256 _chainId, bool enabled) external {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        chainList[_chainId] = enabled;
    }

    /**
     * @dev Update name of token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     * - `name` name of token
     */
    function updateTokenName(string memory symbol, string memory name)
        external
    {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "DecimalBridge: Caller is not an admin"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).updateName(name);
    }

    /**
     * @dev Pause token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function pauseToken(string memory symbol) external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a pauser"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).pause();
    }

    /**
     * @dev Unpause token
     *
     * Arguments
     *
     * - `symbol` symbol of token.
     */
    function unpauseToken(string memory symbol) external {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "DecimalBridge: Caller is not a pauser"
        );
        address token = tokenBySymbol[symbol];
        require(token != address(0), "DecimalBridge: Token is not registered");
        DERC20(token).unpause();
    }
}