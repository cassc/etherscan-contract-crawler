pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// @title WBNB Interface 

interface IWBNB is IERC20Upgradeable {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// @title Thena GuageV2 Interface

interface IThenaStrategyGaugeV2 {
    function deposit(uint depositAmount) external;
    function withdraw(uint withdrawAmount) external;
    function getReward() external;
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);

    function depositAll() external;
    function withdrawAll() external;
    function emergencyWithdrawAmount(uint256 emergencyWithdrawAmount) external;

}

// @title Planet's Router Interface (Routes struct only)

interface IPlanetRouter {
    struct Routes {
        address from;
        address to;
        bool stable;
    }
}

// @title Planet's Router Interface (general)

interface IPlanetRouter2 is IPlanetRouter {
    function swapSolidlyToGamma(
        uint amountIn,
        uint amountOutMin,
        Routes[] calldata routes,
        address to,
        uint deadline,
        address solidlyRouterAddress
    ) external returns (uint[] memory amounts);
}

// @title Planet's Aggregated Strategy for Thena Gauge V2
// @author Planet
contract AggregatedStrategy_GAMMA is IPlanetRouter, Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public wantAddress; // Address of Token that is deposited into Thena Gauge V2
    address public GAMMAAddress; 
    address public THENAAddress;

    address public wbnbAddress;
    address public gammaFarmAddress; // Address of Farm associated with this strategy
    address public rewardsAddress; // Address to which generated fees flow
    address public thenaStrategyAddress; // Address of Thena Guage V2 for wantAddress
    address public planetRouterAddress;
    address public thenaRouterAddress;

    uint256 public wantLockedTotal; 
    uint256 public sharesTotal; 
    uint256 public pid; // pid of pool in farmContractAddress

    uint256 public entranceFeeFactor; 
    uint256 public constant entranceFeeFactorMax = 50; // maximum entrance fee = 0.5%

    uint256 public withdrawFeeFactor;
    uint256 public constant withdrawFeeFactorMax = 200; // maximum withdraw fee = 2%

    uint256 public performanceFeeFactor; 
    uint256 public constant performanceFeeFactorMax = 2000; // maximum performance fee = 20%

    Routes[] public route; // Route for swap through ThenaRouter while converting Thena to Gamma

    event SetSettings(uint _entranceFeeFactor, uint _withdrawFeeFactor, uint performanceFeeFactor);
    event SetRewardsAddress(address _rewardsAddress);
    event SetTHENAAddress(address _THENAAddress);
    event SetPlanetRouterAddress(address _planetRouterAddress);
    event SetThenaRouterAddress(address _thenaRouterAddress);
    event SetThenaStrategyAddress(address _thenaStrategyAddress);
    event SetTHENAToPlanetRoute(Routes[] _route);


    error Unauthorized(address caller);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(){
	    _disableInitializers();
    }

    function initialize(
        address[] memory _addresses,
        uint256 _pid,
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _performanceFeeFactor
    ) public initializer(){

        wbnbAddress = _addresses[0];
        gammaFarmAddress = _addresses[1];
        GAMMAAddress = _addresses[2];
        wantAddress = _addresses[3];
        rewardsAddress = _addresses[4];
        THENAAddress = _addresses[5];
        planetRouterAddress = _addresses[6];
        thenaRouterAddress = _addresses[7];
        thenaStrategyAddress = _addresses[8];
        
        pid = _pid;     

        entranceFeeFactor = _entranceFeeFactor;
        withdrawFeeFactor = _withdrawFeeFactor;
        performanceFeeFactor = _performanceFeeFactor;

        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

 
    }
     function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
	onlyOwner
    {
    }


    // @notice Ensures deposit, withdraw and claim calls made to this strategy come only through the Farm

    function checkForFarmAddressCall() private view  {
        if(msg.sender != gammaFarmAddress) 
        {
            revert Unauthorized(msg.sender);
        }
    }

    // @notice Claims rewards from Thena Strategy Address, converts them to Gamma and sends them to the farm, which increases accGammaPerShare for the pool. This function is called by the farm every time update is called for this strategy's Pid
    // @returns earned Earn Gamma profits after deducting fees

    function earnGammaProfits() external returns (uint256){
        checkForFarmAddressCall();
        if(wantLockedTotal == 0){
            return 0;
        }
        IThenaStrategyGaugeV2(thenaStrategyAddress).getReward();
        uint256 earned = IERC20Upgradeable(THENAAddress).balanceOf(address(this));

        if (earned == 0){
            return 0;
        }

        IERC20Upgradeable(THENAAddress).safeIncreaseAllowance(
            planetRouterAddress,
            earned
        );

        _safeSwap(
            planetRouterAddress,
            earned,
            route,
            address(this),
            (block.timestamp + 600),
            thenaRouterAddress
        );
        earned = IERC20Upgradeable(GAMMAAddress).balanceOf(address(this));

        uint256 performanceFee = (earned * performanceFeeFactor) / 10000;  
        earned = earned - performanceFee;

        IERC20Upgradeable(GAMMAAddress).safeTransfer(rewardsAddress, performanceFee);
        IERC20Upgradeable(GAMMAAddress).safeTransfer(address(msg.sender), earned);
	    
        return earned;
    }

    // @notice Internal function to swap Thena rewards to Gamma through Planet Router
    // @param _planetRouterAddress Address of Planet's Router
    // @param _amountIn Amount of tokens to swap
    // @param _route Part of the swap to take place through Thena's router
    // @param _to Address to receive swapped tokens
    // @param _deadline Time by which the function call must execute. If crossed, the call is reverted
    // @param _thenaRouterAddress Address of router through which swap of paths in _route is executed

    function _safeSwap(
        address _planetRouterAddress,
        uint256 _amountIn,
        Routes[] memory _route,
        address _to,
        uint256 _deadline,
        address _thenaRouterAddress) internal virtual {

        IPlanetRouter2(_planetRouterAddress)
            .swapSolidlyToGamma( 
            _amountIn,
            1,
            _route,
            _to,
            _deadline,
            _thenaRouterAddress
        );
    }


    // @notice Deposits want tokens recieved from the user through the farm into Thena GaugeV2 after deducting fees
    // @param _wantAmt Amount of want tokens that the user is depositing
    // @returns sharesAdded Shares to be added to the user corresponding to his deposit amount

    function deposit(uint256 _wantAmt) external virtual nonReentrant returns (uint256) {
        checkForFarmAddressCall();

        uint256 depositFee = (_wantAmt * entranceFeeFactor)/ 10000;
        uint256 sharesAdded = _wantAmt - depositFee;
        wantLockedTotal = sharesTotal = sharesTotal + sharesAdded;

        if(depositFee != 0){
            IERC20Upgradeable(wantAddress).safeTransfer(rewardsAddress, depositFee);
        }
        IERC20Upgradeable(wantAddress).safeIncreaseAllowance(thenaStrategyAddress, sharesAdded);
        IThenaStrategyGaugeV2(thenaStrategyAddress).deposit(sharesAdded);

        return (sharesAdded);
    }

    // @notice Delegates the call to an internal function that withdraws want from Thena Gauge V2 and sends it to the farm, after deducting fees, which in turn sends it to the user
    // @notice _wantAmt Amount of want tokens that the user wishes to withdraw
    // @returns sharesRemoved Shares to be removed corresponding to the user's withdraw amount
    // @returns _wantAmt Want tokens to be sent to the user after deducting fees
    function withdraw(uint256 _wantAmt) external virtual nonReentrant returns (uint256, uint256) {
        return _withdraw(_wantAmt, false);
    }

    // @notice Delegates the call to an internal function that withdraws want from Thena Gauge V2 without accruing rewards and sends it to the farm, after deducting fees, which in turn sends it to the user. Called by the farm through the function emergencyWithdraw in the farm
    // @dev emergencyWithdraw can only be called when Thena Gauge V2 allows emergency withdrawal in case of emergencies
    // @notice _wantAmt Amount of want tokens that the user wishes to withdraw. Farm sends the user's balance as this amount
    // @returns sharesRemoved Shares to be removed corresponding to the user's withdraw amount
    // @returns _wantAmt Want tokens to be sent to the user after deducting fees

    function emergencyWithdraw(uint256 _wantAmt) external virtual nonReentrant returns (uint256, uint256) {
        require(_wantAmt != 0, "_wantAmt <= 0");
        return _withdraw(_wantAmt, true);
    }

    // @notice Returns wantLockedTotal and sharesTotal of the Strategy
    // @Returns wantLockedTotal Total want tokens present with the strategy, deposited into Thena Gauge V2
    // @Returns sharesTotal Total shares corresponding to tokens in the strategy. This is equal to wantLockedTotal as the strategy is not compounding want tokens

    function getShares() external virtual view returns (uint256, uint256) {
        return (wantLockedTotal, sharesTotal);
    }

    // @notice Reports Rewards to be collected by this strategy from Gauge V2
    // @returns Pending Rewards

    function getStratPendingRewards() external virtual view returns (uint256){
        return (IThenaStrategyGaugeV2(thenaStrategyAddress).earned(address(this)));
    }

    // @notice Sets fees. Fees cannot be set higher than corresponding Max amounts
    // @param _entranceFeeFactor New Entrance Fee 
    // @param _withdrawFeeFactor New Withdraw Fee
    // @param _performanceFeeFactor New Performance Fee

    function setSettings(uint256 _entranceFeeFactor, uint256 _withdrawFeeFactor, uint256 _performanceFeeFactor) external virtual onlyOwner {

        require(_entranceFeeFactor <= entranceFeeFactorMax, "_entranceFeeFactor too high");
        entranceFeeFactor = _entranceFeeFactor;

        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "_withdrawFeeFactor too high");
        withdrawFeeFactor = _withdrawFeeFactor;

        require(_performanceFeeFactor <= performanceFeeFactorMax, "_performanceFeeFactor too high");
        performanceFeeFactor = _performanceFeeFactor;

        emit SetSettings(_entranceFeeFactor, _withdrawFeeFactor, _performanceFeeFactor);

    }

    // @notice Sets Rewards Address to which fees generated flow
    // @param _rewardsAddress New Rewards Address

    function setRewardsAddress(address _rewardsAddress) external virtual onlyOwner {
        rewardsAddress = _rewardsAddress;
        emit SetRewardsAddress(_rewardsAddress);
    }

    // @notice Sets Thena Address 
    // @param _THENAAddress New Thena Address

    function setTHENAAddress(address _THENAAddress) external virtual onlyOwner {
        THENAAddress = _THENAAddress;
        emit SetTHENAAddress(_THENAAddress);
    }

    // @notice Sets Thena Strategy Address 
    // @param _thenaStrategyAddress New Thena Strategy Address

    function setThenaStrategyAddress(address _thenaStrategyAddress) external virtual onlyOwner {
        thenaStrategyAddress = _thenaStrategyAddress;
        emit SetThenaStrategyAddress(_thenaStrategyAddress);
    }

    // @notice Sets Planet Router Address 
    // @param _planetRouterAddress New Planet Router Address

    function setPlanetRouterAddress(address _planetRouterAddress) external virtual onlyOwner {
        planetRouterAddress = _planetRouterAddress;
        emit SetPlanetRouterAddress(_planetRouterAddress);
    }

    // @notice Sets Thena Router Address 
    // @param _thenaRouterAddress New Thena Router Address

    function setThenaRouterAddress(address _thenaRouterAddress) external virtual onlyOwner {
        thenaRouterAddress = _thenaRouterAddress;
        emit SetThenaRouterAddress(_thenaRouterAddress);
    }

    // @notice Sets Route to swap from Thena to Planet
    // @param _route New route to swap from Thena to Planet

    function setTHENAToPlanetRoute(Routes[] memory _route) external virtual onlyOwner{
        delete route;

        uint len = _route.length;
         
        for (uint i = 0 ; i < len; ++i){
            route.push(_route[i]);
        }
    
        emit SetTHENAToPlanetRoute(_route);
    }

    // @notice Withdraws tokens sent by mistake to the strategy. Note: Want tokens sent to the strategy cannot be removed.
    // @param _token Token to be withdraw
    // @param _amount Amount of _token to be withdrawn from the strategy
    // @param _to Address to which withdrawn tokens are to be sent
    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external virtual onlyOwner {
        require(_token != wantAddress, "!safe");
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    // @notice Internal function to wrap BNB into wBNB
    function _wrapBNB() internal virtual {
        uint256 bnbBal = address(this).balance;
        if (bnbBal != 0) {
            IWBNB(wbnbAddress).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    // @notice Function to wrap BNB into wBNB
    function wrapBNB() external virtual onlyOwner {
        _wrapBNB();
    }

    // @notice Withdraws want from Thena Gauge V2 and sends it to the farm, after deducting fees, which in turn sends it to the user
    // @notice _wantAmt Amount of want tokens that the user wishes to withdraw
    // @returns sharesRemoved Shares to be removed corresponding to the user's withdraw amount
    // @returns _wantAmt Want tokens to be sent to the user after deducting fees
    function _withdraw(uint256 _wantAmt, bool _emergency) internal virtual returns (uint256, uint256) {
        checkForFarmAddressCall();

        uint256 wantAmt = IThenaStrategyGaugeV2(thenaStrategyAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (_wantAmt > sharesTotal) {
            _wantAmt = sharesTotal;
        }

        sharesTotal = wantLockedTotal = wantLockedTotal - _wantAmt;

        uint256 sharesRemoved = _wantAmt;

        if(_emergency){
		    IThenaStrategyGaugeV2(thenaStrategyAddress).emergencyWithdrawAmount(_wantAmt);
        }
        else{
		    IThenaStrategyGaugeV2(thenaStrategyAddress).withdraw(_wantAmt);
        }
        sharesRemoved = _wantAmt = IERC20Upgradeable(wantAddress).balanceOf(address(this));

        uint256 withdrawFee = (_wantAmt*withdrawFeeFactor)/10000;
        _wantAmt = _wantAmt - withdrawFee;
	    
        if(withdrawFee != 0){
        	IERC20Upgradeable(wantAddress).safeTransfer(rewardsAddress, withdrawFee);
	    }
        IERC20Upgradeable(wantAddress).safeTransfer(gammaFarmAddress, _wantAmt);
        
	    return (sharesRemoved, _wantAmt);
    }
    function version() external virtual view returns (uint256) {
        return 1;
    }
}