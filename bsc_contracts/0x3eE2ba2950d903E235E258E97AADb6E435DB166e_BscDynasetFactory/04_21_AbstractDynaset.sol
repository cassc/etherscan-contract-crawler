// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== Internal Inheritance ========== */
import {DToken} from "./DToken.sol";

/* ========== Internal Interfaces ========== */
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDynasetContract.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IDynasetTvlOracle.sol";
import "./balancer/BNum.sol";

/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license 
*************************************************************************************************/
abstract contract AbstractDynaset is DToken, BNum, IDynasetContract, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ==========  Storage  ========== */

    // Account with CONTROL role.
    // set mint/burn forges.
    address internal controller;

    address internal factory;

    address internal digitalAssetManager;

    mapping(address => bool) internal mintForges;
    mapping(address => bool) internal burnForges;
    // Array of underlying tokens in the dynaset.
    address[] internal dynasetTokens;
    // Internal records of the dynaset's underlying tokens
    mapping(address => Record) internal records;
    address internal dynasetTvlOracle;

    /* ==========  Events  ========== */

    event LogTokenAdded(address indexed tokenIn, address indexed provider);
    event LogTokenRemoved(address indexed tokenOut);
    event DynasetInitialized(
        address[] indexed tokens,
        uint256[] balances,
        address indexed tokenProvider
    );
    event MintForge(address indexed forgeAddress);
    event BurnForge(address indexed forgeAddress);
    event WithdrawalFee(address token, uint256 indexed amount);

    /* ==========  Access Modifiers (changed to internal functions to decrease contract size)  ========== */

    function onlyFactory() internal view {
        require(msg.sender == factory, "ERR_NOT_FACTORY");
    }

    function onlyController() internal view {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
    }

    function onlyDigitalAssetManager() internal view {
        require(msg.sender == digitalAssetManager, "ERR_NOT_DAM");
    }

    /* ==========  Constructor  ========== */
    constructor(
        address factoryContract,
        address dam,
        address controller_,
        string memory name,
        string memory symbol
    ) {
        require(
            factoryContract != address(0) &&
                dam != address(0) &&
                controller_ != address(0),
            "ERR_ZERO_ADDRESS"
        );
        factory = factoryContract;
        controller = controller_;
        digitalAssetManager = dam;
        _initializeToken(name, symbol);
    }

    /* ==========  External Functions  ========== */
    /**
     * @dev Sets up the initial assets for the pool.
     *
     * Note: `tokenProvider` must have approved the pool to transfer the
     * corresponding `balances` of `tokens`.
     *
     * @param tokens Underlying tokens to initialize the pool with
     * @param balances Initial balances to transfer
     * @param tokenProvider Address to transfer the balances from
     */
    function initialize(
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider
    ) external nonReentrant override {
        onlyFactory();
        require(dynasetTokens.length == 0, "ERR_INITIALIZED");
        require(tokenProvider != address(0), "INVALID_TOKEN_PROVIDER");
        uint256 len = tokens.length;
        require(len >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        require(len <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
        _mint(INIT_POOL_SUPPLY);
        address token;
        uint256 balance;
        for (uint256 i = 0; i < len; i++) {
            token = tokens[i];
            require(token != address(0), "INVALID_TOKEN");
            balance = balances[i];
            require(balance > 0, "ERR_MIN_BALANCE");
            records[token] = Record({
                bound: true,
                ready: true,
                index: uint8(i),
                balance: balance
            });

            dynasetTokens.push(token);
            // ! external interaction
            _pullUnderlying(token, tokenProvider, balance);
        }
        _push(tokenProvider, INIT_POOL_SUPPLY);
        emit DynasetInitialized(tokens, balances, tokenProvider);
    }

    function addToken(
        address token,
        uint256 minimumBalance,
        address tokenProvider
    ) external nonReentrant {
        onlyDigitalAssetManager();
        require(token != address(0), "ERR_ZERO_TOKEN");
        require(dynasetTokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
        require(tokenProvider != address(0), "ERR_ZERO_TOKEN_PROVIDER");
        require(!records[token].bound, "ERR_IS_BOUND");
        require(minimumBalance > 0, "ERR_MIN_BALANCE");
        require(
            IERC20(token).allowance(address(tokenProvider), address(this)) >=
                minimumBalance,
            "ERR_INSUFFICIENT_ALLOWANCE"
        );
        records[token] = Record({
            bound: true,
            ready: true,
            index: uint8(dynasetTokens.length),
            balance: minimumBalance
        });
        dynasetTokens.push(token);
        _pullUnderlying(token, tokenProvider, minimumBalance);
        emit LogTokenAdded(token, tokenProvider);
    }

    function removeToken(address token) external nonReentrant {
        onlyDigitalAssetManager();
        require(dynasetTokens.length > MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        Record memory record = records[token];
        uint256 tokenBalance = record.balance;
        require(tokenBalance == 0, "ERR_CAN_NOT_REMOVE_TOKEN");
        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = record.index;
        uint256 last = dynasetTokens.length - 1;
        // Only swap the token with the last token if it is not
        // already at the end of the array.
        if (index != last) {
            dynasetTokens[index] = dynasetTokens[last];
            records[dynasetTokens[index]].index = uint8(index);
            records[dynasetTokens[index]].balance = records[dynasetTokens[last]]
                .balance;
        }
        dynasetTokens.pop();
        records[token] = Record({
            bound: false,
            ready: false,
            index: 0,
            balance: 0
        });
        emit LogTokenRemoved(token);
    }

    function setMintForge(address newMintForge) external {
        onlyController();
        require(!mintForges[newMintForge], "ERR_FORGE_ALREADY_ADDED");
        mintForges[newMintForge] = true;
        emit MintForge(newMintForge);
    }

    function setBurnForge(address newBurnForge) external {
        onlyController();
        require(!burnForges[newBurnForge], "ERR_FORGE_ALREADY_ADDED");
        burnForges[newBurnForge] = true;
        emit BurnForge(newBurnForge);
    }

    function setDynasetOracle(address oracleAddress) external {
        onlyFactory();
        dynasetTvlOracle = oracleAddress;
    }

    /**
    NOTE The function can only be called using dynaset factory contract.
    * It is made sure that fee is not taken too frequently or 
    * not more than 25% more details can be found in DynasetFactory contract 
    * collectFee funciton.
    */
    function withdrawFee(address token, uint256 amount) external {
        onlyFactory();
        IERC20 token_ = IERC20(token);
        token_.safeTransfer(msg.sender, amount);
        emit WithdrawalFee(token, amount);
    }

    /**
     *
     * @param amount is number of dynaset amount
     * @return tokens returns the tokens list in the dynasets and
     * their respective @return amounts which combines make same
     * usd value as the amount of dynasets
     */
    function calcTokensForAmount(uint256 amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(amount, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        tokens = dynasetTokens;
        amounts = new uint256[](dynasetTokens.length);
        uint256 tokenAmountIn;
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            (Record memory record, ) = _getInputToken(tokens[i]);
            tokenAmountIn = bmul(ratio, record.balance);
            amounts[i] = tokenAmountIn;
        }
    }

    function getTokenAmounts()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = dynasetTokens;
        amounts = new uint256[](dynasetTokens.length);
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            amounts[i] = records[tokens[i]].balance;
        }
    }

    /**
     * @dev Returns the controller address.
     */
    function getController() external view override returns (address) {
        return controller;
    }

    /**
     * @dev Check if a token is bound to the dynaset.
     */
    function isBound(address token) external view override returns (bool) {
        return records[token].bound;
    }

    /**
     * @dev Get the number of tokens bound to the dynaset.
     */
    function getNumTokens() external view override returns (uint256) {
        return dynasetTokens.length;
    }

    /**
     * @dev Returns the record for a token bound to the dynaset.
     */
    function getTokenRecord(address token)
        external
        view
        override
        returns (Record memory record)
    {
        record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
    }

    /**
     * @dev Returns the stored balance of a bound token.
     */
    function getBalance(address token)
        external
        view
        override
        returns (uint256)
    {
        Record memory record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
        return record.balance;
    }

    /**
     * @dev Get all bound tokens.
     */
    function getCurrentTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        tokens = dynasetTokens;
    }

    /* ==========  Public Functions  ========== */
    /**
     * @dev Absorb any tokens that have been sent to the dynaset.
     * If the token is not bound, it will be sent to the unbound
     * token handler.
     */
    function updateAfterSwap(address tokenIn, address tokenOut) public {
        uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));

        records[tokenIn].balance = balanceIn;
        records[tokenOut].balance = balanceOut;
    }

    /*
     * @dev Mint new dynaset tokens by providing the proportional amount of each
     * underlying token's balance relative to the proportion of dynaset tokens minted.
     *
     * NOTE: function can only be called by the forge contracts and min/max amounts checks are
     * implemented in forge contracts.
     * For any underlying tokens which are not initialized, the caller must provide
     * the proportional share of the minimum balance for the token rather than the
     * actual balance.
     *
     * @param dynasetAmountOut Amount of dynaset tokens to mint
     * order as the dynaset's dynasetTokens list.
     */
    function joinDynaset(uint256 expectedSharesToMint)
        external
        override
        nonReentrant
        returns (uint256 sharesToMint)
    {
        require(mintForges[msg.sender], "ERR_NOT_FORGE");
        require(dynasetTvlOracle != address(0), "ERR_DYNASET_ORACLE_NOT_SET");
        sharesToMint = expectedSharesToMint;
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(sharesToMint, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        uint256 tokenAmountIn;
        address token;
        uint256 dynaset_usd_value_before_join = IDynasetTvlOracle(dynasetTvlOracle).dynasetTvlUsdc();
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            token = dynasetTokens[i];
            (, uint256 realBalance) = _getInputToken(token);
            tokenAmountIn = bmul(ratio, realBalance);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            uint256 forgeTokenBalance = IERC20(token).balanceOf(msg.sender);
            if (forgeTokenBalance < tokenAmountIn) {
                tokenAmountIn = forgeTokenBalance;
            }
            uint256 forgeTokenAllowance = IERC20(token).allowance(msg.sender, address(this));
            if (forgeTokenAllowance < tokenAmountIn) {
               tokenAmountIn = forgeTokenAllowance;
            }
            _updateInputToken(token, badd(realBalance, tokenAmountIn));
            _pullUnderlying(token, msg.sender, tokenAmountIn);
            emit LOG_JOIN(token, msg.sender, tokenAmountIn);
        }
        // calculate correct sharesToMint
        uint256 dynaset_added_value = IDynasetTvlOracle(dynasetTvlOracle).dynasetTvlUsdc() 
                                      - dynaset_usd_value_before_join;
        sharesToMint = dynaset_added_value * dynasetTotal / dynaset_usd_value_before_join;
        require(sharesToMint > 0, "MINT_ZERO_DYNASETS");
        _mint(sharesToMint);
        _push(msg.sender, sharesToMint);
    }

    /**
     * @dev Burns `_amount` dynaset tokens in exchange for the amounts of each
     * underlying token's balance proportional to the ratio of tokens burned to
     * total dynaset supply.
     *
     * @param dynasetAmountIn Exact amount of dynaset tokens to burn
     */
    function exitDynaset(uint256 dynasetAmountIn)
        external
        override
        nonReentrant
    {
        require(burnForges[msg.sender], "ERR_NOT_FORGE");
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(dynasetAmountIn, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        _pull(msg.sender, dynasetAmountIn);
        _burn(dynasetAmountIn);
        address token;
        Record memory record;
        uint256 tokenAmountOut;
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            token = dynasetTokens[i];
            record = records[token];
            require(record.ready, "ERR_OUT_NOT_READY");
            tokenAmountOut = bmul(ratio, record.balance);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");

            records[token].balance = bsub(record.balance, tokenAmountOut);
            _pushUnderlying(token, msg.sender, tokenAmountOut);
            emit LOG_EXIT(msg.sender, token, tokenAmountOut);
        }
    }

    /* ==========  Underlying Token Internal Functions  ========== */
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        IERC20(erc20).safeTransferFrom(from, address(this), amount);
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        IERC20(erc20).safeTransfer(to, amount);
    }

    /* ==========  Token Management Internal Functions  ========== */

    /**
     * @dev Handles weight changes and initialization of an
     * input token.
     * @param token Address of the input token
     * @param realBalance real balance is set to the records for token
     * and weight if the token was uninitialized.
     */
    function _updateInputToken(address token, uint256 realBalance) internal {
        records[token].balance = realBalance;
    }

    /* ==========  Token Query Internal Functions  ========== */

    /**
     * @dev Get the record for a token.
     * The token must be bound to the dynaset. If the token is not
     * initialized (meaning it does not have the minimum balance)
     * this function will return the actual balance of the token
     */
    function _getInputToken(address token)
        internal
        view
        returns (Record memory record, uint256 realBalance)
    {
        record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
        realBalance = record.balance;
    }
}