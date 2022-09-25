pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IAlpacaToken.sol";
import "./interfaces/IVaultConfig.sol";
import "./interfaces/IGymVault.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBuyAndBurn.sol";

interface IFarm {
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 bonusDebt,
            uint256 fundedBy
        );
}

interface ITreasury {
    function notifyExternalReward(uint256 _amount) external;
}

interface IFairLaunch {
    function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);

    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
contract GymVaultsStrategyAlpacaBNB is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// This vault is purely for staking
    bool public isAutoComp;
    bool public strategyStopped;
    bool public checkForUnlockReward;

    /// address of vault.
    address public alpacaVaultContractAddress;
    /// address of farm
    address public fairLaunchAddress;
    /// pid of pool in fairLaunchAddress
    uint256 public pid;
    /// address of want token contract
    address public wantAddress;
    /// address of earn token contract
    address public alpacaTokenAddress;
    /// address of buy and burn contract
    address public buyAndBurnAddress;
    /// PancakeSwap: Router address
    address public uniRouterAddress;
    /// address of vault config from alpaca
    address public vaultConfigAlpaca;

    address public strategist;
    /// allow public to call earn() function
    bool public notPublic;

    uint256 public lastEarnBlock;
    uint256 public wantLockedTotal;
    uint256 public sharesTotal;

    uint256 public controllerFee;
    /// 100 = 1%
    uint256 public constant controllerFeeMax = 10000;
    uint256 public constant controllerFeeUL = 300;
    /// 0% entrance fee (goes to pool + prevents front-running)
    uint256 public entranceFeeFactor;
    /// 100 = 1%
    uint256 public constant entranceFeeFactorMax = 10000;
    /// 0.5% is the max entrance fee settable. LL = lowerlimit
    uint256 public constant entranceFeeFactorLL = 9950;

    address[] public earnedToWantPath;
    address[] public earnedToBusdPath;
    address[] public wantToEarnedPath;

    address public bankAddress;

    event Initialized(address indexed executor, uint256 at);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event Farm(uint256 amount);
    event Compound(
        address token0Address,
        uint256 token0Amt,
        address token1Address,
        uint256 token1Amt
    );
    event Earned(address alpacaTokenAddress, uint256 earnedAmt);
    event DistributeFee(address alpacaTokenAddress, uint256 fee, address receiver);
    event ConvertDustToEarned(address tokenAddress, address alpacaTokenAddress, uint256 tokenAmt);
    event InCaseTokensGetStuck(address tokenAddress, uint256 tokenAmt, address receiver);
    event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);

    event SetStrategist(address indexed _address);
    event SetBuyAndBurnAddress(address indexed _address);
    event SetEntranceFeeFactor(uint256 fee);
    event SetBankFee(uint256 fee);
    event SetNotPublic(bool _notPublic);
    event SetCheckForUnlockReward(bool _check);
    event ResumeStrategy();

    // _bank:  BvaultsBank
    // _buyBurnToken1Info[]: buyBurnToken1, buyBurnAddress1, buyBurnToken1MidRouteAddress
    // _buyBurnToken2Info[]: buyBurnToken2, buyBurnAddress2, buyBurnToken2MidRouteAddress
    // _token0Info[]: token0Address, token0MidRouteAddress
    // _token1Info[]: token1Address, token1MidRouteAddress
    function initialize(
        address _bank,
        bool _isAutoComp,
        address _alpacaVaultContractAddress,
        address _fairLaunchAddress,
        uint256 _pid,
        address _wantAddress,
        address _busdAddress,
        address _alpacaTokenAddress,
        address _uniRouterAddress, // address[] memory _token0Info, // address[] memory _token1Info
        address _vaultConfigAlpaca,
        address _buyAndBurnAddress
    ) external initializer {
        strategist = msg.sender;
        // to call earn if public not allowed
        if (_uniRouterAddress != address(0)) uniRouterAddress = _uniRouterAddress;
        notPublic = false;
        controllerFee = 0;
        isAutoComp = _isAutoComp;
        wantAddress = _wantAddress;
        entranceFeeFactor = 10000;

        if (isAutoComp) {
            alpacaVaultContractAddress = _alpacaVaultContractAddress;
            fairLaunchAddress = _fairLaunchAddress;
            pid = _pid;
            alpacaTokenAddress = _alpacaTokenAddress;
            uniRouterAddress = _uniRouterAddress;
            vaultConfigAlpaca = _vaultConfigAlpaca;
            buyAndBurnAddress = _buyAndBurnAddress;
            bankAddress = _bank;

            earnedToBusdPath = [alpacaTokenAddress, _busdAddress];
            earnedToWantPath = [alpacaTokenAddress, _wantAddress];
            wantToEarnedPath = [_wantAddress, alpacaTokenAddress];
        }
        __Ownable_init();
        __ReentrancyGuard_init();

        emit Initialized(msg.sender, block.number);
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyStrategist() {
        require(
            strategist == msg.sender || owner() == msg.sender,
            "GymVaultsStrategyAlpaca: caller is not the strategist"
        );
        _;
    }

    modifier onlyGymVault() {
        require(bankAddress == msg.sender, "GymVaultsStrategyAlpaca: caller is not the bank");
        _;
    }

    modifier strategyRunning() {
        require(!strategyStopped, "GymVaultsStrategyAlpaca: strategy is not running");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;

        emit SetStrategist(_strategist);
    }

    function setBuyAndBurnAddress(address _buyAndBurnAddress) external onlyOwner {
        buyAndBurnAddress = _buyAndBurnAddress;

        emit SetBuyAndBurnAddress(_buyAndBurnAddress);
    }

    /**
     * @notice  Function to set entrance fee
     * @param _entranceFeeFactor 100 = 1%
     */
    function setEntranceFeeFactor(uint256 _entranceFeeFactor) external onlyOwner {
        require(
            _entranceFeeFactor > entranceFeeFactorLL,
            "GymVaultsStrategyAlpaca: !safe - too low"
        );
        require(
            _entranceFeeFactor <= entranceFeeFactorMax,
            "GymVaultsStrategyAlpaca: !safe - too high"
        );
        entranceFeeFactor = _entranceFeeFactor;

        emit SetEntranceFeeFactor(_entranceFeeFactor);
    }

    /**
     * @notice  Function to set controller fee
     * @param _bankFee 100 = 1%
     */
    function setBankFee(uint256 _bankFee) external onlyOwner {
        require(_bankFee <= controllerFeeUL, "GymVaultsStrategyAlpaca: too high");
        controllerFee = _bankFee;

        emit SetBankFee(_bankFee);
    }

    function setNotPublic(bool _notPublic) external onlyOwner {
        notPublic = _notPublic;

        emit SetNotPublic(_notPublic);
    }

    function setCheckForUnlockReward(bool _checkForUnlockReward) external onlyOwner {
        checkForUnlockReward = _checkForUnlockReward;

        emit SetCheckForUnlockReward(_checkForUnlockReward);
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        require(_token != alpacaTokenAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        emit InCaseTokensGetStuck(_token, _amount, _to);
    }

    function resumeStrategy() external onlyOwner {
        strategyStopped = false;
        farm();

        emit ResumeStrategy();
    }

    /**
     * @notice  Function checks if user Autorised or not
     * @param _account Users address
     */
    function isAuthorised(address _account) public view returns (bool) {
        return (_account == owner()) || (msg.sender == strategist);
    }

    /**
     * @notice  Adds deposit
     * @param _wantAmt Amount of want tokens that will be added to pool
     */
    function deposit(address, uint256 _wantAmt)
        public
        onlyGymVault
        whenNotPaused
        strategyRunning
        returns (uint256)
    {
        IERC20Upgradeable(wantAddress).safeTransferFrom(msg.sender, address(this), _wantAmt);
        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0) {
            sharesAdded =
                (_wantAmt * sharesTotal * entranceFeeFactor) /
                wantLockedTotal /
                entranceFeeFactorMax;
        }

        sharesTotal = sharesTotal + sharesAdded;

        if (isAutoComp) {
            _farm();
        } else {
            wantLockedTotal = wantLockedTotal + _wantAmt;
        }

        emit Deposit(_wantAmt);

        return sharesAdded;
    }

    function farm() public nonReentrant strategyRunning {
        _farm();
    }

    /**
     * @notice  Function to withdraw assets
     * @param _wantAmt Amount of want tokens that will be withdrawn
     */
    function withdraw(address, uint256 _wantAmt)
        public
        onlyGymVault
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "GymVaultsStrategyAlpaca: !_wantAmt");
        IGymVault vault = IGymVault(alpacaVaultContractAddress);
        if (isAutoComp && !strategyStopped) {
            uint256 ibAmount = (_wantAmt * vault.totalSupply()) / vault.totalToken();
            IFairLaunch(fairLaunchAddress).withdraw(address(this), pid, ibAmount);
            vault.withdraw(ibAmount);
            if (
                vault.token() == IVaultConfig(vaultConfigAlpaca).getWrappedNativeAddr()
                // address(this).balance > 0
            ) {
                IWETH(wantAddress).deposit{value: _wantAmt}();
            }
        }

        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }
        uint256 sharesRemoved = (_wantAmt * sharesTotal) / wantLockedTotal;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal - sharesRemoved;
        wantLockedTotal = wantLockedTotal - _wantAmt;

        IERC20Upgradeable(wantAddress).safeTransfer(msg.sender, _wantAmt);

        emit Withdraw(_wantAmt);

        return sharesRemoved;
    }

    /**
     *  1. Harvest farm tokens
     *  2. Converts farm tokens into want tokens
     *  3. Deposits want tokens
     */
    function earn(uint256 _amountOutAmt, uint256 _deadline) public onlyOwner {
        require(isAutoComp, "GymVaultsStrategyAlpaca: !isAutoComp");
        require(!notPublic || isAuthorised(msg.sender), "GymVaultsStrategyAlpaca: !authorised");

        // Harvest farm tokens
        IFairLaunch(fairLaunchAddress).harvest(pid);
        // Check if there is any unlocked amount
        if (checkForUnlockReward) {
            if (IAlpacaToken(alpacaTokenAddress).canUnlockAmount(address(this)) > 0) {
                IAlpacaToken(alpacaTokenAddress).unlock();
            }
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20Upgradeable(alpacaTokenAddress).balanceOf(address(this));

        emit Earned(alpacaTokenAddress, earnedAmt);

        uint256 _distributeFee = distributeFees(earnedAmt);

        earnedAmt = earnedAmt - _distributeFee;

        IERC20Upgradeable(alpacaTokenAddress).safeIncreaseAllowance(uniRouterAddress, earnedAmt);

        if (alpacaTokenAddress != wantAddress) {
            // Swap half earned to token0
            IPancakeRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    earnedAmt,
                    _amountOutAmt,
                    earnedToWantPath,
                    address(this),
                    _deadline
                );
        }

        // Get want tokens, ie. add liquidity
        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        if (wantAmt > 0) {
            emit Compound(wantAddress, wantAmt, address(0), 0);
        }

        lastEarnBlock = block.number;
    }

    /**
     * @notice  Converts dust tokens into earned tokens, which will be reinvested on the next earn().
     */
    function convertDustToEarned(uint256 _amountOutAmt, uint256 _deadline) public whenNotPaused {
        require(isAutoComp, "GymVaultsStrategyAlpaca: !isAutoComp");

        // Converts token0 dust (if any) to earned tokens
        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        if (wantAddress != alpacaTokenAddress && wantAmt > 0) {
            IERC20Upgradeable(wantAddress).safeIncreaseAllowance(uniRouterAddress, wantAmt);

            // Swap all dust tokens to earned tokens
            IPancakeRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    wantAmt,
                    _amountOutAmt,
                    wantToEarnedPath,
                    address(this),
                    _deadline
                );
            emit ConvertDustToEarned(wantAddress, alpacaTokenAddress, wantAmt);
        }
    }

    function uniExchangeRate(uint256 _tokenAmount, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amounts = IPancakeRouter02(uniRouterAddress).getAmountsOut(
            _tokenAmount,
            _path
        );
        return amounts[amounts.length - 1];
    }

    function pendingHarvest() public view returns (uint256) {
        uint256 _earnedBal = IERC20Upgradeable(alpacaTokenAddress).balanceOf(address(this));
        return IFairLaunch(fairLaunchAddress).pendingAlpaca(pid, address(this)) + _earnedBal;
    }

    function pendingHarvestDollarValue() public view returns (uint256) {
        uint256 _pending = pendingHarvest();
        return (_pending == 0) ? 0 : uniExchangeRate(_pending, earnedToBusdPath);
    }

    function balanceInPool() public view returns (uint256) {
        (uint256 amount, , , ) = IFarm(fairLaunchAddress).userInfo(pid, address(this));
        return amount;
    }

    /**
     * @notice Function to buy and burn tokens
     */
    function buyAndBurn() external onlyGymVault {
        uint256 burnableAmount = IERC20Upgradeable(wantAddress).balanceOf(address(this));

        IERC20Upgradeable(wantAddress).safeTransfer(buyAndBurnAddress, burnableAmount);

        IBuyAndBurn(buyAndBurnAddress).buyAndBurnGymWithBNB(
            burnableAmount,
            0,
            block.timestamp + 100
        );
    }

    /**
     * @notice  Adds assets in vault
     */
    function _farm() internal {
        // add to vault to get ibToken
        uint256 wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal + wantAmt;
        IERC20Upgradeable(wantAddress).safeIncreaseAllowance(alpacaVaultContractAddress, wantAmt);
        IGymVault(alpacaVaultContractAddress).deposit(wantAmt);
        // add ibToken to farm contract
        uint256 ibWantAmt = IERC20Upgradeable(alpacaVaultContractAddress).balanceOf(address(this));
        IERC20Upgradeable(alpacaVaultContractAddress).safeIncreaseAllowance(
            fairLaunchAddress,
            ibWantAmt
        );
        IFairLaunch(fairLaunchAddress).deposit(address(this), pid, ibWantAmt);
        emit Farm(wantAmt);
    }

    /**
     * @notice  Function to distribute Fees
     * @param _earnedAmt Amount of earned tokens that will be sent to owner ass fee
     */
    function distributeFees(uint256 _earnedAmt) internal returns (uint256 _fee) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (controllerFee > 0) {
                _fee = (_earnedAmt * controllerFee) / controllerFeeMax;
                IERC20Upgradeable(alpacaTokenAddress).safeTransfer(owner(), _fee);
                emit DistributeFee(alpacaTokenAddress, _fee, owner());
            }
        }
    }
}