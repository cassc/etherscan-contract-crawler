/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

pragma solidity 0.8.18;

/**************************************************
 *                    Interfaces
 **************************************************/
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface IRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256,
        uint256,
        route[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory);
}

interface IVe {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function locked(uint256) external view returns (LockedBalance memory);

    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);

    function attachments(uint256) external view returns (uint256);

    function voted(uint256) external view returns (bool);

    function isApprovedOrOwner(address, uint256) external view returns (bool);
}

interface IFactory {
    function isPair(address) external returns (bool);
}

interface IMonoDepositor {
    function withdraw(address, uint256) external;
}

interface IPair {
    function burn(address) external returns (uint256, uint256);

    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function stable() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IMonoPair {
    function pool() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

/**************************************************
 *                    Libraries
 **************************************************/

library SafeCast {
    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }
}

/**************************************************
 *               Migration logic
 **************************************************/

contract MonoMigrator {
    /**************************************************
     *                   Configuration
     **************************************************/
    IFactory constant factory =
        IFactory(0x777de5Fe8117cAAA7B44f396E93a401Cf5c9D4d6);
    IVe public constant veNft = IVe(0x77730ed992D286c53F3A0838232c3957dAeaaF73);
    IMonoDepositor public constant monoDepositor =
        IMonoDepositor(0x822EF744C568466D40Ba28b0f9e4A4961837a46a);
    IRouter public constant router =
        IRouter(0x77784f96C936042A3ADB1dD29C91a55EB2A4219f);
    address public constant solid = 0x777172D858dC1599914a1C4c6c9fC48c99a60990;
    address public constant moSolid =
        0x848578e351D25B6Ec0d486E42677891521c3d743;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public immutable migrateStartTime;

    // Storage slots start here
    address public owner;
    uint256 internal _unlocked = 1; // For simple reentrancy check

    uint256 public deadline; // No tokens can be migrated after this date

    address[] public validEcosystemTokenAddresses; // List of all valid migratable ecosystem ERC20 token addresses
    mapping(address => bool) public tokenIsEcosystemToken; // Mapping to keep track whether a specific token is migratable
    mapping(address => mapping(address => uint256))
        public tokensMigratedByAccount; // tokensMigratedByAccount[tokenAddress][accountAddress]
    mapping(address => uint256) public tokensMigratedByToken; // Total tokens migrated by token address

    mapping(address => bool) tokenMigrated; // Check if individual token is migrated already via LP
    address[] public migratedTokenAddresses; // List of tokens migrated

    mapping(address => mapping(uint256 => uint256))
        public veNftMigratedIndexById; // tokenId index in array of user migrated veNFTs
    mapping(address => uint256[]) public veNftMigratedIdByIndex; // array of veNFT tokenIds a user has migrated
    mapping(address => uint256) public veNftMigratedAmountByAccount; // total SOLID equivalent migrated via veNFT of a user
    uint256 public veNftMigratedAmountTotal; // total SOLID equivalent migrated via veNFTs

    /**************************************************
     *                    Events
     **************************************************/
    event NftMigrated(address indexed from, uint256 tokenId, uint256 amount);

    event EcosystemTokenMigrated(
        address indexed from,
        address indexed token,
        uint256 amount
    );

    event LpMigrated(
        address indexed from,
        address pair,
        bool stable,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    );

    /**************************************************
     *                    Structs
     **************************************************/
    struct Token {
        address id; // Token address
        uint256 balance; // Token balance
        uint256 migrated; // Tokens migrated
        bool approved; // Did user approve tokens to be migrated
    }

    struct VeNft {
        uint256 id; // NFT ID
        uint256 migrated; // Amount migrated
    }

    /**************************************************
     *                   Modifiers
     **************************************************/

    // Simple reentrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Only allow migrating for predefined period
    modifier onlyMigratePeriod() {
        require(block.timestamp < deadline, "Migrate period over");
        _;
    }

    // Only allow after predefined period
    modifier onlyAfterMigratePeriod() {
        require(block.timestamp >= deadline, "Migrate period not over");
        _;
    }

    /**************************************************
     *                   Initialization
     **************************************************/

    /**
     * @notice Initialization
     */
    constructor() {
        owner = msg.sender;
        migrateStartTime = block.timestamp;
        deadline = migrateStartTime + 7 days; // Set deadline
    }

    /**
     * @notice Transfers ownership
     * @param newOwner new owner, or address(0) to renounce ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    /**
     * @notice Extends deadline
     * @param _newDeadline new deadline
     * @dev _newDealine must be longer than existing deadline
     */
    function extendDeadline(uint256 _newDeadline) external onlyOwner {
        require(
            _newDeadline > deadline,
            "New dealdine must be longer than existing deadline"
        );
        deadline = _newDeadline;
    }

    function setEcosystemTokens(address[] memory _validEcosystemTokenAddresses)
        external
        onlyOwner
    {
        validEcosystemTokenAddresses = _validEcosystemTokenAddresses; // Set migrate token addresses
        migratedTokenAddresses = _validEcosystemTokenAddresses;

        // Set migrate token mapping
        for (uint256 i = 0; i < _validEcosystemTokenAddresses.length; i++) {
            tokenIsEcosystemToken[_validEcosystemTokenAddresses[i]] = true;
            tokenMigrated[_validEcosystemTokenAddresses[i]] = true;
        }
    }

    /**************************************************
     *                  ERC20 migrate logic
     **************************************************/

    /**
     * @notice Primary migrate method for ERC20 ecosystem tokens
     * @param tokenAddress Address of the token to migrate
     * @dev Only allow migrating entire user balance. YOLO
     * @dev Method can only be called during migrate period
     */
    function migrate(address tokenAddress) external lock onlyMigratePeriod {
        _migrate(tokenAddress, msg.sender);
    }

    function migrateFor(address tokenAddress, address recipient)
        external
        lock
        onlyMigratePeriod
    {
        _migrate(tokenAddress, recipient);
    }

    function _migrate(address tokenAddress, address recipientAddress) internal {
        require(tokenIsEcosystemToken[tokenAddress], "Invalid ecosystem token");
        require(
            tokenAddress != solid,
            "Solid must be migrated using the migrateSolid method"
        );
        uint256 amountToMigrate = IERC20(tokenAddress).balanceOf(msg.sender);
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountToMigrate
        );
        _recordMigration(tokenAddress, recipientAddress, amountToMigrate);
    }

    /**
     * @notice Dump SOLID for moSOLID and migrate
     */
    function migrateSolid(uint256 minimumAmountOut)
        external
        lock
        onlyMigratePeriod
    {
        uint256 amountIn = IERC20(solid).balanceOf(msg.sender);
        IERC20(solid).transferFrom(msg.sender, address(this), amountIn);
        IRouter.route[] memory routes = new IRouter.route[](2);
        routes[0] = IRouter.route({from: solid, to: weth, stable: false});
        routes[1] = IRouter.route({from: weth, to: moSolid, stable: false});
        IERC20(solid).approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            minimumAmountOut,
            routes,
            address(this),
            block.timestamp
        );
        uint256 amountOut = amounts[amounts.length - 1];
        _recordMigration(moSolid, msg.sender, amountOut);
    }

    function _recordMigration(
        address tokenAddress,
        address recipientAddress,
        uint256 amountToMigrate
    ) internal {
        // Record migrated token and amount
        tokensMigratedByAccount[tokenAddress][
            recipientAddress
        ] += amountToMigrate;

        // Increment global token amount migrated for this token
        tokensMigratedByToken[tokenAddress] += amountToMigrate;
        emit EcosystemTokenMigrated(
            recipientAddress,
            tokenAddress,
            amountToMigrate
        );
    }

    /**************************************************
     *                  veNFT migrate logic
     **************************************************/

    /**
     * @notice Migrate veNFT
     * @param tokenId Token ID to migrate
     * @dev veNFT is converted to moSOLID first
     * @dev Method can only be called during migrate period
     */
    function migrateVeNft(uint256 tokenId) external lock onlyMigratePeriod {
        _migrateVeNft(tokenId, msg.sender);
    }

    function migrateVeNftFor(uint256 tokenId, address recipient)
        external
        lock
        onlyMigratePeriod
    {
        _migrateVeNft(tokenId, recipient);
    }

    function _migrateVeNft(uint256 tokenId, address recipient) internal {
        veNft.safeTransferFrom(msg.sender, address(this), tokenId); // Transfer veNFT to this contract
        uint256 moSolidBalanceBefore = IERC20(moSolid).balanceOf(address(this));
        veNft.safeTransferFrom(address(this), moSolid, tokenId); // Convert veNFT to moSOLID
        uint256 moSolidBalanceAfter = IERC20(moSolid).balanceOf(address(this));
        uint256 moSolidDelta = moSolidBalanceAfter - moSolidBalanceBefore;
        _recordMigration(moSolid, recipient, moSolidDelta);
    }

    /**************************************************
     *                  LP migrate logic
     **************************************************/
    function migrateMonoPair(IMonoPair monoPair)
        external
        lock
        onlyMigratePeriod
    {
        _migrateMonoPair(monoPair, msg.sender);
    }

    function migrateMonoPairFor(IMonoPair monoPair, address recipient)
        external
        lock
        onlyMigratePeriod
    {
        _migrateMonoPair(monoPair, recipient);
    }

    function _migrateMonoPair(IMonoPair monoPair, address recipient) internal {
        // Withdraw from Monolith
        IPair pair = IPair(monoPair.pool());
        uint256 amount = monoPair.balanceOf(msg.sender);
        monoPair.transferFrom(msg.sender, address(this), amount);
        monoDepositor.withdraw(address(pair), amount);

        // Withdraw from Solidly
        require(factory.isPair(address(pair)), "Not a pair");
        require(pair.transfer(address(pair), amount));
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        address token0 = pair.token0();
        address token1 = pair.token1();
        tokensMigratedByAccount[token0][recipient] += amount0;
        tokensMigratedByAccount[token1][recipient] += amount1;
        tokensMigratedByToken[token0] += amount0;
        tokensMigratedByToken[token1] += amount1;

        require(amount0 > 0 && amount1 > 0, "Invalid amount");
        if (tokenMigrated[token0] == false) {
            tokenMigrated[token0] = true;
            migratedTokenAddresses.push(token0);
        }
        if (tokenMigrated[token1] == false) {
            tokenMigrated[token1] = true;
            migratedTokenAddresses.push(token1);
        }

        emit LpMigrated(
            recipient,
            address(pair),
            pair.stable(),
            token0,
            token1,
            amount0,
            amount1
        );
    }

    /**************************************************
     *                Multisig Execution
     **************************************************/
    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external payable onlyOwner onlyAfterMigratePeriod returns (bool success) {
        if (operation == Operation.Call) {
            success = executeCall(to, value, data);
        } else if (operation == Operation.DelegateCall) {
            success = executeDelegateCall(to, data);
        }
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    function executeDelegateCall(address to, bytes memory data)
        internal
        returns (bool success)
    {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    /**************************************************
     *                 Refund methods
     **************************************************/

    /**
     * @notice Owner callable function to issue refunds
     * @param accountAddress User address to be refunded
     * @param tokenAddress Token address to be refunded
     */
    function refund(address accountAddress, address tokenAddress)
        external
        lock
        onlyOwner
    {
        // Fetch amount of tokens to return
        uint256 amountToReturn = tokensMigratedByAccount[tokenAddress][
            accountAddress
        ];
        tokensMigratedByAccount[tokenAddress][accountAddress] = 0; // Set user token balance to zero
        tokensMigratedByToken[tokenAddress] -= amountToReturn; // Decrement global token amount migrated for this token
        IERC20(tokenAddress).transfer(accountAddress, amountToReturn); // Return tokens to user
    }

    /**************************************************
     *                  View methods
     **************************************************/

    function migratedTokenAddressesLength() external view returns (uint256) {
        return migratedTokenAddresses.length;
    }

    /**
     * @notice Fetch migrated tokens per account
     * @param accountAddress Address of the account for which to view
     * @return tokens Returns an array of migratable and migrated tokens without filtering
     */
    function migratedTokensByAccount(address accountAddress)
        external
        view
        returns (Token[] memory tokens)
    {
        Token[] memory _tokens = new Token[](migratedTokenAddresses.length); // Create an array of tokens

        // Iterate through all valid migratable tokens
        for (
            uint256 tokenIdx = 0;
            tokenIdx < migratedTokenAddresses.length;
            tokenIdx++
        ) {
            address tokenAddress = migratedTokenAddresses[tokenIdx]; // Fetch token address
            IERC20 _token = IERC20(tokenAddress); // Fetch ERC20 interface for the current token
            uint256 _userBalance = _token.balanceOf(accountAddress); // Fetch token balance

            // Fetch migrated balance
            uint256 _migratedBalance = tokensMigratedByAccount[tokenAddress][
                accountAddress
            ];

            // Fetch allowance state
            bool _tokenTransferAllowed = _token.allowance(
                accountAddress,
                address(this)
            ) >= _userBalance;

            // Fetch token metadata
            Token memory token = Token({
                id: tokenAddress,
                balance: _userBalance,
                migrated: _migratedBalance,
                approved: _tokenTransferAllowed
            });
            _tokens[tokenIdx] = token; // Save migratable token data in array
        }
        tokens = _tokens; // Return migratable tokens
    }

    /**************************************************
     *                      NFT
     **************************************************/
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        require(msg.sender == address(veNft)); // Only accept veNfts
        require(_unlocked == 2, "No direct transfers");
        return this.onERC721Received.selector;
    }
}