// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// Linked Libraries
import { SavingLib } from "./lib/SavingLib.sol";
import { Utils } from "./lib/Utils.sol";

// External imports
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Interfaces imports
import { ICToken } from "./interfaces/ICToken.sol";
import { ICETH } from "./interfaces/ICETH.sol";
import { IGlobalConfig } from "./interfaces/IGlobalConfig.sol";
import { IPoolRegistry } from "../interfaces/IPoolRegistry.sol";
import { IBank } from "./interfaces/IBank.sol";

// Other imports
import { Constant, ActionType } from "./config/Constant.sol";
import { InitializableReentrancyGuard } from "./InitializableReentrancyGuard.sol";
import { InitializablePausable } from "./InitializablePausable.sol";

contract SavingAccount is Initializable, InitializableReentrancyGuard, Constant, InitializablePausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IGlobalConfig public globalConfig;
    IPoolRegistry public poolRegistry;
    address public baseToken;
    IERC20 public miningToken;
    // UNIX timestamp, when it matures and enable withdrawal for the baseToken
    uint256 public maturesOn;
    uint256 public poolId;

    address public constant COMP_ADDR = address(0); // disabled

    event Transfer(address indexed token, address from, address to, uint256 amount);
    event Borrow(address indexed token, address from, uint256 amount);
    event Repay(address indexed token, address from, uint256 amount);
    event Deposit(address indexed token, address from, uint256 amount);
    event Withdraw(address indexed token, address from, uint256 amount);
    event WithdrawAll(address indexed token, address from, uint256 amount);
    event Liquidate(
        address liquidator,
        address borrower,
        address borrowedToken,
        uint256 repayAmount,
        address collateralToken,
        uint256 payAmount
    );
    event Claim(address from, uint256 amount);
    event WithdrawCOMP(address beneficiary, uint256 amount);

    modifier onlySupportedToken(address _token) {
        if (_token != ETH_ADDR) {
            require(globalConfig.tokenRegistry().isTokenExist(_token), "Unsupported token");
        }
        _;
    }

    modifier onlyEnabledToken(address _token) {
        require(globalConfig.tokenRegistry().isTokenEnabled(_token), "The token is not enabled");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.bank()), "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    modifier onlyPoolRegistry() {
        require(msg.sender == address(poolRegistry), "not a poolRegistry");
        _;
    }

    modifier whenMatured(address _token) {
        if (_token == baseToken) {
            require(block.timestamp > maturesOn, "not matured");
        }
        _;
    }

    /**
     * @dev Check that this pool is in "Configured" state.
     * @notice check only in the "deposit()" as this is the very first operation in a pool.
     */
    modifier whenPoolConfigured() {
        require(poolRegistry.isPoolConfigured(poolId), "pool not Configured");
        _;
    }

    /**
     * Initialize function to be called by the Deployer for the first time
     * @param _tokenAddresses list of token addresses
     * @param _cTokenAddresses list of corresponding cToken addresses
     * @param _globalConfig global configuration contract
     */
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        IGlobalConfig _globalConfig,
        IPoolRegistry _poolRegistry,
        uint256 _poolId
    ) public initializer {
        // Initialize InitializableReentrancyGuard
        super._initialize();
        super._initialize(address(_globalConfig));

        globalConfig = _globalConfig;
        poolRegistry = _poolRegistry;
        poolId = _poolId;

        require(_tokenAddresses.length == _cTokenAddresses.length, "Token and cToken length don't match.");
        uint256 tokenNum = _tokenAddresses.length;
        for (uint256 i = 0; i < tokenNum; i++) {
            if (_cTokenAddresses[i] != address(0x0) && _tokenAddresses[i] != ETH_ADDR) {
                approveAll(_tokenAddresses[i]);
            }
        }
    }

    function configure(
        address _baseToken,
        IERC20 _miningToken,
        uint256 _maturesOn
    ) external onlyPoolRegistry {
        require(address(miningToken) == address(0), "miningToken already set");
        baseToken = _baseToken;
        miningToken = _miningToken;
        maturesOn = _maturesOn;
    }

    /**
     * Approve transfer of all available tokens
     * @param _token token address
     */
    function approveAll(address _token) public {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        require(cToken != address(0x0), "cToken address is zero");
        IERC20(_token).safeApprove(cToken, 0);
        IERC20(_token).safeApprove(cToken, type(uint256).max);
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * Transfer the token between users inside DeFiner
     * @param _to the address that the token be transfered to
     * @param _token token address
     * @param _amount amout of tokens transfer
     */
    function transfer(
        address _to,
        address _token,
        uint256 _amount
    ) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {
        globalConfig.bank().newRateIndexCheckpoint(_token);
        uint256 amount = globalConfig.accounts().withdraw(msg.sender, _token, _amount);
        globalConfig.accounts().deposit(_to, _token, amount);

        emit Transfer(_token, msg.sender, _to, amount);
    }

    /**
     * Borrow the amount of token from the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     */
    function borrow(address _token, uint256 _amount)
        external
        onlySupportedToken(_token)
        onlyEnabledToken(_token)
        whenNotPaused
        nonReentrant
    {
        require(_amount != 0, "Borrow zero amount of token is not allowed.");

        globalConfig.bank().borrow(msg.sender, _token, _amount);

        // Transfer the token on Ethereum
        SavingLib.sendAssets(_amount, _token);

        emit Borrow(_token, msg.sender, _amount);
    }

    /**
     * Repay the amount of token back to the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     * @dev If the repay amount is larger than the borrowed balance, the extra will be returned.
     */
    function repay(address _token, uint256 _amount) public payable onlySupportedToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.collectAssets(_amount, _token);

        // Add a new checkpoint on the index curve.
        uint256 amount = globalConfig.bank().repay(msg.sender, _token, _amount);

        // Send the remain money back
        if (amount < _amount) {
            SavingLib.sendAssets(_amount.sub(amount), _token);
        }

        emit Repay(_token, msg.sender, amount);
    }

    /**
     * Deposit the amount of token to the saving pool.
     * @param _token the address of the deposited token
     * @param _amount the mount of the deposited token
     */
    function deposit(address _token, uint256 _amount)
        public
        payable
        onlySupportedToken(_token)
        onlyEnabledToken(_token)
        whenPoolConfigured
        nonReentrant
    {
        require(_amount != 0, "Amount is zero");
        SavingLib.collectAssets(_amount, _token);
        globalConfig.bank().deposit(msg.sender, _token, _amount);

        emit Deposit(_token, msg.sender, _amount);
    }

    /**
     * Withdraw a token from an address
     * @param _token token address
     * @param _amount amount to be withdrawn
     */
    function withdraw(address _token, uint256 _amount)
        external
        onlySupportedToken(_token)
        whenNotPaused
        whenMatured(_token)
        nonReentrant
    {
        require(_amount != 0, "Amount is zero");
        uint256 amount = globalConfig.bank().withdraw(msg.sender, _token, _amount);
        SavingLib.sendAssets(amount, _token);

        emit Withdraw(_token, msg.sender, amount);
    }

    /**
     * Withdraw all tokens from the saving pool.
     * @param _token the address of the withdrawn token
     */
    function withdrawAll(address _token)
        external
        onlySupportedToken(_token)
        whenNotPaused
        whenMatured(_token)
        nonReentrant
    {
        // Sanity check
        require(
            globalConfig.accounts().getDepositPrincipal(msg.sender, _token) > 0,
            "Token depositPrincipal must be greater than 0"
        );

        // Add a new checkpoint on the index curve.
        globalConfig.bank().newRateIndexCheckpoint(_token);

        // Get the total amount of token for the account
        uint256 amount = globalConfig.accounts().getDepositBalanceCurrent(_token, msg.sender);

        uint256 actualAmount = globalConfig.bank().withdraw(msg.sender, _token, amount);
        if (actualAmount != 0) {
            SavingLib.sendAssets(actualAmount, _token);
        }
        emit WithdrawAll(_token, msg.sender, actualAmount);
    }

    function liquidate(
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    ) public onlySupportedToken(_borrowedToken) onlySupportedToken(_collateralToken) whenNotPaused nonReentrant {
        IBank bank = IBank(address(globalConfig.bank()));
        bank.newRateIndexCheckpoint(_borrowedToken);
        bank.newRateIndexCheckpoint(_collateralToken);
        bank.updateDepositFINIndex(_borrowedToken);
        bank.updateDepositFINIndex(_collateralToken);
        bank.updateBorrowFINIndex(_borrowedToken);
        bank.updateBorrowFINIndex(_collateralToken);

        (uint256 repayAmount, uint256 payAmount) = globalConfig.accounts().liquidate(
            msg.sender,
            _borrower,
            _borrowedToken,
            _collateralToken
        );

        bank.update(_borrowedToken, repayAmount, ActionType.LiquidateRepayAction);

        emit Liquidate(msg.sender, _borrower, _borrowedToken, repayAmount, _collateralToken, payAmount);
    }

    /**
     * Withdraw token from Compound
     * @param _token token address
     * @param _amount amount of token
     */
    function fromCompound(address _token, uint256 _amount) external onlyAuthorized {
        require(
            ICToken(globalConfig.tokenRegistry().getCToken(_token)).redeemUnderlying(_amount) == 0,
            "redeemUnderlying failed"
        );
    }

    function toCompound(address _token, uint256 _amount) external onlyAuthorized {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (Utils._isETH(_token)) {
            ICETH(cToken).mint{ value: _amount }();
        } else {
            // uint256 success = ICToken(cToken).mint(_amount);
            require(ICToken(cToken).mint(_amount) == 0, "mint failed");
        }
    }

    /**
     * An account claim all mined FIN token
     */
    function claim() public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claim(msg.sender);
        miningToken.safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    function claimForToken(address _token) public nonReentrant returns (uint256) {
        uint256 finAmount = globalConfig.accounts().claimForToken(msg.sender, _token);
        if (finAmount > 0) miningToken.safeTransfer(msg.sender, finAmount);
        emit Claim(msg.sender, finAmount);
        return finAmount;
    }

    // NOTICE: Withdraw COMP is disabled in Gemini
    /**
     * Withdraw COMP token to beneficiary
     */
    /*
    function withdrawCOMP(address _beneficiary) external onlyOwner {
        uint256 compBalance = IERC20(COMP_ADDR).balanceOf(address(this));
        IERC20(COMP_ADDR).safeTransfer(_beneficiary, compBalance);

        emit WithdrawCOMP(_beneficiary, compBalance);
    }
    */

    function version() public pure virtual returns (string memory) {
        return "v2.0.0";
    }
}