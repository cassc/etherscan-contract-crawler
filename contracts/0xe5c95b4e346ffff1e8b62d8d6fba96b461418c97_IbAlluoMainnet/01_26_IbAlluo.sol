// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AlluoERC20Upgradable.sol";
import "../../interfaces/ILiquidityHandler.sol";
import "../../mock/interestHelper/Interest.sol";
import "../../interfaces/IExchange.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract IbAlluoMainnet is
    Initializable,
    PausableUpgradeable,
    AlluoERC20Upgradable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    Interest
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // variable which grow after any action from user
    // based on current interest rate and time from last update call
    uint256 public growingRatio;

    // time of last ratio update
    uint256 public lastInterestCompound;

    // time limit for using update
    uint256 public updateTimeLimit;

    // constant for ratio calculation
    uint256 private multiplier;

    // interest per second, big number for accurate calculations (10**27)
    uint256 public interestPerSecond;

    // current annual interest rate with 2 decimals
    uint256 public annualInterest;

    // contract that will distribute money between the pool and the wallet
    address public liquidityHandler;

    // flag for upgrades availability
    bool public upgradeStatus;

    // list of tokens from which deposit available
    EnumerableSetUpgradeable.AddressSet private supportedTokens;
    
    address public exchangeAddress;

    event BurnedForWithdraw(address indexed user, uint256 amount);
    event Deposited(address indexed user, address token, uint256 amount);
    event NewHandlerSet(address oldHandler, address newHandler);
    event UpdateTimeLimitSet(uint256 oldValue, uint256 newValue);
    event DepositTokenStatusChanged(address token, bool status);
    
    event InterestChanged(
        uint256 oldYearInterest,
        uint256 newYearInterest,
        uint256 oldInterestPerSecond,
        uint256 newInterestPerSecond
    );
    
    event TransferAssetValue(
        address indexed from,
        address indexed to,
        uint256 tokenAmount,
        uint256 assetValue,
        uint256 growingRatio
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

   function initialize(
        string memory _name,
        string memory _symbol,
        address _multiSigWallet,
        address _handler,
        address[] memory _supportedTokens,
        uint256 _interestPerSecond,
        uint256 _annualInterest,
        address _exchangeAddress
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "IbAlluo: Not contract");
        require(_handler.isContract(), "IbAlluo: Not contract");

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens.add(_supportedTokens[i]);
            emit DepositTokenStatusChanged(_supportedTokens[i], true);
        }

        interestPerSecond = _interestPerSecond * 10**10;
        annualInterest = _annualInterest;
        multiplier = 10**18;
        growingRatio = 10**18;
        updateTimeLimit = 60;
        lastInterestCompound = block.timestamp;
        exchangeAddress = _exchangeAddress;
        liquidityHandler = _handler;

        emit NewHandlerSet(address(0), liquidityHandler);
    }

    /// @notice  Updates the growingRatio
    /// @dev If more than the updateTimeLimit has passed, call changeRatio from interestHelper to get correct index
    ///      Then update the index and set the lastInterestCompound date.

    function updateRatio() public whenNotPaused {
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            growingRatio = changeRatio(
                growingRatio,
                interestPerSecond,
                lastInterestCompound
            );
            lastInterestCompound = block.timestamp;
        }
    }

    /**
     * @dev See {IERC20-approve} but it approves amount of tokens
     *      which represents asset value
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * 
     * NOTE: Because of constantly growing ratio between IbAlluo and asset value
     *       we recommend to approve amount slightly more
     */
    function approveAssetValue(address spender, uint256 amount)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = msg.sender;
        updateRatio();
        uint256 adjustedAmount = (amount * multiplier) / growingRatio;
        _approve(owner, spender, adjustedAmount);
        return true;
    }

    /**
     * @dev See {IERC20-transfer} but it transfers amount of tokens
     *      which represents asset value
     */
    function transferAssetValue(address to, uint256 amount)
        public
        whenNotPaused
        returns (bool)
    {
        address owner = msg.sender;
        updateRatio();
        uint256 adjustedAmount = (amount * multiplier) / growingRatio;
        _transfer(owner, to, adjustedAmount);
        emit TransferAssetValue(owner, to, adjustedAmount, amount, growingRatio);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom} but it transfers amount of tokens
     *      which represents asset value
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     */
    function transferFromAssetValue(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        address spender = msg.sender;
        updateRatio();
        uint256 adjustedAmount = (amount * multiplier) / growingRatio;
        _spendAllowance(from, spender, adjustedAmount);
        _transfer(from, to, adjustedAmount);
        emit TransferAssetValue(from, to, adjustedAmount, amount, growingRatio);
        return true;
    }

    /// @notice  Allows deposits and updates the index, then mints the new appropriate amount.
    /// @dev When called, asset token is sent to the wallet, then the index is updated
    ///      so that the adjusted amount is accurate.
    /// @param _token Deposit token address
    /// @param _amount Amount (with token decimals)

    function deposit(address _token, uint256 _amount) external {
        // The main token is the one which isn't converted to primary tokens.
        // Small issue with deposits and withdrawals though. Need to approve.
        if (supportedTokens.contains(_token) == false) {
            IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
            (, address primaryToken) = ILiquidityHandler(liquidityHandler).getAdapterCoreTokensFromIbAlluo(address(this));
            IERC20Upgradeable(_token).safeIncreaseAllowance(exchangeAddress, _amount);
            _amount = IExchange(exchangeAddress).exchange(_token, primaryToken, _amount, 0);
            _token = primaryToken;
            IERC20Upgradeable(primaryToken).safeTransfer(address(liquidityHandler), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransferFrom(msg.sender,address(liquidityHandler),_amount);
        }
        updateRatio();
        ILiquidityHandler(liquidityHandler).deposit(_token, _amount);
        uint256 amountIn18 = _amount * 10**(18 - AlluoERC20Upgradable(_token).decimals());
        uint256 adjustedAmount = (amountIn18 * multiplier) / growingRatio;
        _mint(msg.sender, adjustedAmount);
        emit TransferAssetValue(address(0), msg.sender, adjustedAmount, amountIn18, growingRatio);
        emit Deposited(msg.sender, _token, _amount);
    }

    /// @notice  Withdraws accuratel
    /// @dev When called, immediately check for new interest index. Then find the adjusted amount in IbAlluo tokens
    ///      Then burn appropriate amount of IbAlluo tokens to receive asset token
    /// @param _targetToken Asset token
    /// @param _amount Amount (parsed 10**18) in asset value

    function withdrawTo(
        address _recipient,
        address _targetToken,
        uint256 _amount
    ) public {
        updateRatio();
        uint256 adjustedAmount = (_amount * multiplier) / growingRatio;
        _burn(msg.sender, adjustedAmount);
        ILiquidityHandler handler = ILiquidityHandler(liquidityHandler);
        if (supportedTokens.contains(_targetToken) == false) {
            (address liquidToken,) = ILiquidityHandler(liquidityHandler).getAdapterCoreTokensFromIbAlluo(address(this));
            // This just is used to revert if there is no active route.
            require(IExchange(exchangeAddress).buildRoute(liquidToken, _targetToken).length > 0, "!Supported");
            handler.withdraw(
            _recipient,
            liquidToken,
            _amount,
            _targetToken
            );
        } else {
            handler.withdraw(
            _recipient,
            _targetToken,
            _amount
            );
        }

        emit TransferAssetValue(msg.sender, address(0), adjustedAmount, _amount, growingRatio);
        emit BurnedForWithdraw(msg.sender, adjustedAmount);
    }

    /// @notice  Withdraws accuratel
    /// @dev When called, immediately check for new interest index. Then find the adjusted amount in IbAlluo tokens
    ///      Then burn appropriate amount of IbAlluo tokens to receive asset token
    /// @param _targetToken Asset token
    /// @param _amount Amount (parsed 10**18)

    function withdraw(address _targetToken, uint256 _amount) external {
        withdrawTo(msg.sender, _targetToken, _amount);
    }

    /// @notice  Withdraws accuratel
    /// @param _targetToken Asset token
    /// @param _amount Amount (parsed 10**18) in ibAlluo**** value

    function withdrawTokenValueTo(
        address _recipient,
        address _targetToken,
        uint256 _amount
    ) public {
        _burn(msg.sender, _amount);
        updateRatio();
        uint256 assetAmount = (_amount * growingRatio) / multiplier;

        ILiquidityHandler handler = ILiquidityHandler(liquidityHandler);
        if (supportedTokens.contains(_targetToken) == false) {
            (address liquidToken,) = ILiquidityHandler(liquidityHandler).getAdapterCoreTokensFromIbAlluo(address(this));
            // This just is used to revert if there is no active route.
            require(IExchange(exchangeAddress).buildRoute(liquidToken, _targetToken).length > 0, "!Supported");
            handler.withdraw(
            _recipient,
            liquidToken,
            assetAmount,
            _targetToken
            );
        } else {
            handler.withdraw(
            _recipient,
            _targetToken,
            assetAmount
            );
        }

        emit TransferAssetValue(msg.sender, address(0), _amount, assetAmount, growingRatio);
        emit BurnedForWithdraw(msg.sender, _amount);
    }

    /// @notice  Withdraws accuratel
    /// @param _targetToken Asset token
    /// @param _amount Amount of ibAlluos (10**18)

    function withdrawTokenValue(address _targetToken, uint256 _amount) external {
        withdrawTokenValueTo(msg.sender, _targetToken, _amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(owner, to, amount, assetValue, growingRatio);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(from, to, amount, assetValue, growingRatio);
        return true;
    }

    
    /// @notice  Returns balance in asset value
    /// @param _address address of user

    function getBalance(address _address) public view returns (uint256) {
        uint256 _growingRatio = changeRatio(
            growingRatio,
            interestPerSecond,
            lastInterestCompound
        );
        return (balanceOf(_address) * _growingRatio) / multiplier;
    }

    /// @notice  Returns balance in asset value with correct info from update
    /// @param _address address of user

    function getBalanceForTransfer(address _address)
        public
        view
        returns (uint256)
    {
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            uint256 _growingRatio = changeRatio(
                growingRatio,
                interestPerSecond,
                lastInterestCompound
            );
            return (balanceOf(_address) * _growingRatio) / multiplier;
        } else {
            return (balanceOf(_address) * growingRatio) / multiplier;
        }
    }

    function convertToAssetValue(uint256 _amount)
        public
        view
        returns (uint256)
    {
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            uint256 _growingRatio = changeRatio(
                growingRatio,
                interestPerSecond,
                lastInterestCompound
            );
            return (_amount * _growingRatio) / multiplier;
        } else {
            return (_amount * growingRatio) / multiplier;
        }
    }

    /// @notice  Returns total supply in asset value

    function totalAssetSupply() public view returns (uint256) {
        uint256 _growingRatio = changeRatio(
            growingRatio,
            interestPerSecond,
            lastInterestCompound
        );
        return (totalSupply() * _growingRatio) / multiplier;
    }

    function getListSupportedTokens() public view returns (address[] memory) {
        return supportedTokens.values();
    }

    /* ========== ADMIN CONFIGURATION ========== */

    function mint(address account, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(account, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(address(0), msg.sender, amount, assetValue, growingRatio);
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _burn(account, amount);
        if (block.timestamp >= lastInterestCompound + updateTimeLimit) {
            updateRatio();
        }
        uint256 assetValue = (amount * growingRatio) / multiplier;
        emit TransferAssetValue(msg.sender, address(0), amount, assetValue, growingRatio);
    }

    /// @notice  Sets the new interest rate
    /// @dev When called, it sets the new interest rate after updating the index.
    /// @param _newAnnualInterest New annual interest rate with 2 decimals 850 == 8.50%
    /// @param _newInterestPerSecond New interest rate = interest per second (100000000244041000*10**10 == 8% APY)

    function setInterest(
        uint256 _newAnnualInterest,
        uint256 _newInterestPerSecond
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldAnnualValue = annualInterest;
        uint256 oldValuePerSecond = interestPerSecond;
        updateRatio();
        annualInterest = _newAnnualInterest;
        interestPerSecond = _newInterestPerSecond * 10**10;
        emit InterestChanged(
            oldAnnualValue,
            annualInterest,
            oldValuePerSecond,
            interestPerSecond
        );
    }
    
    function changeTokenStatus(address _token, bool _status) external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_status) {
            supportedTokens.add(_token);
        } else {
            supportedTokens.remove(_token);
        }
        emit DepositTokenStatusChanged(_token, _status);
    }

    function setUpdateTimeLimit(uint256 _newLimit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 oldValue = updateTimeLimit;
        updateTimeLimit = _newLimit;

        emit UpdateTimeLimitSet(oldValue, _newLimit);
    }


    function setLiquidityHandler(address newHandler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newHandler.isContract(), "IbAlluo: Not contract");

        address oldValue = liquidityHandler;
        liquidityHandler = newHandler;
        emit NewHandlerSet(oldValue, liquidityHandler);
    }

    function setExchangeAddress(address newExchangeAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        exchangeAddress = newExchangeAddress;
    }

    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "IbAlluo: Not contract");
        }
        _grantRole(role, account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "IbAlluo: Upgrade not allowed");
        upgradeStatus = false;
    }
}