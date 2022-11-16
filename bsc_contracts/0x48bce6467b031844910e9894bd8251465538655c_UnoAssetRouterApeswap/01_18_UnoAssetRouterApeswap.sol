// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IUnoFarmApeswap as Farm} from './interfaces/IUnoFarmApeswap.sol'; 
import '../../interfaces/IUnoFarmFactory.sol';
import '../../interfaces/IUnoAccessManager.sol'; 
import '../../interfaces/IUniswapV2Pair.sol';
import '../../interfaces/IWBNB.sol';
import '../../libs/SafeBEP20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

contract UnoAssetRouterApeswap is Initializable, PausableUpgradeable, UUPSUpgradeable {
    using SafeBEP20 for IBEP20;

    /**
     * @dev Contract Variables:
     * farmFactory - The contract that deploys new Farms and links them to {lpPair}s.
     * accessManager - Role manager contract.
     */
    IUnoFarmFactory public farmFactory;
    IUnoAccessManager public accessManager;

    bytes32 private constant DISTRIBUTOR_ROLE = keccak256('DISTRIBUTOR_ROLE');
    bytes32 private constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

    uint256 public fee;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    event Deposit(address indexed lpPool, address indexed sender, address indexed recipient, uint256 amount);
    event Withdraw(address indexed lpPool, address indexed sender, address indexed recipient, uint256 amount);
    event Distribute(address indexed lpPool, uint256 reward);
    
    event FeeChanged(uint256 previousFee, uint256 newFee);

    modifier onlyRole(bytes32 role){
        require(accessManager.hasRole(role, msg.sender), 'CALLER_NOT_AUTHORIZED');
        _;
    }

    // ============ Methods ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _accessManager, address _farmFactory) external initializer{
        require (_accessManager != address(0), 'BAD_ACCESS_MANAGER');
        require (_farmFactory != address(0), 'BAD_FARM_FACTORY');

        __Pausable_init();
        accessManager = IUnoAccessManager(_accessManager);
        farmFactory = IUnoFarmFactory(_farmFactory);
    }

    receive() external payable {
        require(msg.sender == WBNB, 'ONLY_ACCEPT_WBNB'); // only accept ETH via fallback from the WBNB contract
    }

    /**
     * @dev Deposits tokens in the given pool. Creates new Farm contract if there isn't one deployed for the {lpPair} and deposits tokens in it. Emits a {Deposit} event.
     * @param lpPair - Address of the pool to deposit tokens in.
     * @param amountA  - Token A amount to deposit.
     * @param amountB -  Token B amount to deposit.
     * @param amountAMin - Bounds the extent to which the B/A price can go up before the transaction reverts.
     * @param amountBMin - Bounds the extent to which the A/B price can go up before the transaction reverts.
     * @param amountLP - Additional LP Token amount to deposit.
     * @param recipient - Address which will receive the deposit.
     
     * @return sentA - Token A amount sent to the farm.
     * @return sentB - Token B amount sent to the farm.
     * @return liquidity - Total liquidity sent to the farm (in lpTokens).
     */
    function deposit(address lpPair, uint256 amountA, uint256 amountB, uint256 amountAMin, uint256 amountBMin, uint256 amountLP, address recipient) external whenNotPaused returns(uint256 sentA, uint256 sentB, uint256 liquidity){
        Farm farm = Farm(farmFactory.Farms(lpPair));
        if(farm == Farm(address(0))){
            farm = Farm(farmFactory.createFarm(lpPair));
        }

        if(amountLP > 0){
            IBEP20(lpPair).safeTransferFrom(msg.sender, address(farm), amountLP);
        }
        if(amountA > 0){
            IBEP20(farm.tokenA()).safeTransferFrom(msg.sender, address(farm), amountA);
        }
        if(amountB > 0){
            IBEP20(farm.tokenB()).safeTransferFrom(msg.sender, address(farm), amountB);
        }

        (sentA, sentB, liquidity) = farm.deposit(amountA, amountB, amountAMin, amountBMin, amountLP, msg.sender, recipient);
        emit Deposit(lpPair, msg.sender, recipient, liquidity); 
    }

    /**
     * @dev Autoconverts MATIC into WBNB and deposits tokens in the given pool. Creates new Farm contract if there isn't one deployed for the {lpStakingPool} and deposits tokens in it. Emits a {Deposit} event.
     * @param lpPair - Address of the pool to deposit tokens in.
     * @param amountToken  - Token amount to deposit.
     * @param amountTokenMin - Bounds the extent to which the TOKEN/WBNB price can go up before the transaction reverts.
     * @param amountETHMin - Bounds the extent to which the WBNB/TOKEN price can go up before the transaction reverts.
     * @param amountLP - Additional LP Token amount to deposit.
     * @param recipient - Address which will receive the deposit.
     
     * @return sentToken - Token amount sent to the farm.
     * @return sentETH - WBNB amount sent to the farm.
     * @return liquidity - Total liquidity sent to the farm (in lpTokens).
     */
    function depositETH(address lpPair, uint256 amountToken, uint256 amountTokenMin, uint256 amountETHMin, uint256 amountLP, address recipient) external payable whenNotPaused returns(uint256 sentToken, uint256 sentETH, uint256 liquidity){
        require(msg.value > 0, "NO_MATIC_SENT");
        Farm farm = Farm(farmFactory.Farms(lpPair));
        if(farm == Farm(address(0))){
            farm = Farm(farmFactory.createFarm(lpPair));
        }

        if(amountLP > 0){
            IBEP20(lpPair).safeTransferFrom(msg.sender, address(farm), amountLP);
        }

        address tokenA = farm.tokenA();
        address tokenB = farm.tokenB();

        IWBNB(WBNB).deposit{value: msg.value}();
        IBEP20(WBNB).safeTransfer(address(farm), msg.value);
        if (tokenA == WBNB) {
            if (amountToken > 0) {
                IBEP20(tokenB).safeTransferFrom(msg.sender, address(farm), amountToken);
            }
            (sentETH, sentToken, liquidity) = farm.deposit(msg.value, amountToken, amountETHMin, amountTokenMin, amountLP, address(this), recipient);
            IBEP20(tokenB).safeTransfer(msg.sender, amountToken - sentToken);
        } else if (tokenB == WBNB) {
            if (amountToken > 0) {
                IBEP20(tokenA).safeTransferFrom(msg.sender, address(farm), amountToken);
            }
            (sentToken, sentETH, liquidity) = farm.deposit(amountToken, msg.value, amountTokenMin, amountETHMin, amountLP, address(this), recipient);
            IBEP20(tokenA).safeTransfer(msg.sender, amountToken - sentToken);
        } else {
            revert("NOT_WBNB_POOL");
        }

        uint256 dust = msg.value - sentETH;
        if (dust > 0){
            IWBNB(WBNB).withdraw(dust);
            payable(msg.sender).transfer(dust);
        }
        emit Deposit(lpPair, msg.sender, recipient, liquidity);
    }

    /** 
     * @dev Withdraws tokens from the given pool. Emits a {Withdraw} event.
     * @param lpPair - LP pool to withdraw from.
     * @param amount - LP amount to withdraw. 
     * @param amountAMin - The minimum amount of tokenA that must be received for the transaction not to revert.
     * @param amountBMin - The minimum amount of tokenB that must be received for the transaction not to revert.
     * @param withdrawLP - True: Withdraw in LP tokens, False: Withdraw in normal tokens.
     * @param recipient - The address which will receive tokens.

     * @return amountA - Token A amount sent to the {recipient}, 0 if withdrawLP == false.
     * @return amountB - Token B amount sent to the {recipient}, 0 if withdrawLP == false.
     */ 
    function withdraw(address lpPair, uint256 amount, uint256 amountAMin, uint256 amountBMin, bool withdrawLP, address recipient) external returns(uint256 amountA, uint256 amountB){
        Farm farm = Farm(farmFactory.Farms(lpPair));
        require(farm != Farm(address(0)),'FARM_NOT_EXISTS');
        
        (amountA, amountB) = farm.withdraw(amount, amountAMin, amountBMin, withdrawLP, msg.sender, recipient);
        emit Withdraw(lpPair, msg.sender, recipient, amount);  
    }

    /** 
     * @dev Autoconverts WBNB into MATIC and withdraws tokens from the pool. Emits a {Withdraw} event.
     * @param lpPair - LP pool to withdraw from.
     * @param amount - LP amount to withdraw. 
     * @param amountTokenMin - The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin - The minimum amount of MATIC that must be received for the transaction not to revert.
     * @param recipient - The address which will receive tokens.

     * @return amountToken - Token amount sent to the {recipient}.
     * @return amountETH - MATIC amount sent to the {recipient}.
     */ 
    function withdrawETH(address lpPair, uint256 amount, uint256 amountTokenMin, uint256 amountETHMin, address recipient) external payable returns(uint256 amountToken, uint256 amountETH){
        Farm farm = Farm(farmFactory.Farms(lpPair));
        require(farm != Farm(address(0)),'FARM_NOT_EXISTS');

        address tokenA = farm.tokenA();
        address tokenB = farm.tokenB();

        if (tokenA == WBNB) {
            (amountETH, amountToken) = farm.withdraw(amount, amountETHMin, amountTokenMin, false, msg.sender, address(this));
            IBEP20(tokenB).safeTransfer(recipient, amountToken);
        } else if (tokenB == WBNB) {
            (amountToken, amountETH) = farm.withdraw(amount, amountTokenMin, amountETHMin, false, msg.sender, address(this)); 
            IBEP20(tokenA).safeTransfer(recipient, amountToken);
        } else {
            revert("NOT_WMATIC_POOL");
        }

        IWBNB(WBNB).withdraw(amountETH);
        payable(recipient).transfer(amountETH);
        emit Withdraw(lpPair, msg.sender, recipient, amount);
    }

    /**
     * @dev Distributes tokens between users.
     * @param lpPair - LP pool to distribute tokens in.
     * @param swapInfos - Arrays of structs with token arrays describing swap routes (rewardTokenToTokenA, rewardTokenToTokenB, rewarderTokenToTokenA, rewarderTokenToTokenB) and minimum amounts of output tokens that must be received for the transaction not to revert.
     * @param feeSwapInfo - Struct with token arrays describing swap route (rewardTokenToFeeToken, rewarderTokenToFeeToken) and minimum amounts of output tokens that must be received for the transaction not to revert.
     * @param feeTo - Address to collect fees to.
     *
     * Note: This function can only be called by the distributor.
     */ 
    function distribute(
        address lpPair,
        Farm.SwapInfo[2] calldata swapInfos,
        Farm.SwapInfo calldata feeSwapInfo,
        address feeTo
    ) external whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        Farm farm = Farm(farmFactory.Farms(lpPair));
        require(farm != Farm(address(0)), 'FARM_NOT_EXISTS');

        uint256 reward = farm.distribute(swapInfos, feeSwapInfo, Farm.FeeInfo(feeTo, fee));
        emit Distribute(lpPair, reward);
    }

    /**
     * @dev Returns tokens staked by the {_address} for the given {lpPair}.
     * @param _address - The address to check stakes for.
     * @param lpPair - LP pool to check stakes in.

     * @return stakeLP - Total user stake(in LP tokens).
     * @return stakeA - Token A stake.
     * @return stakeB - Token B stake.
     */
    function userStake(address _address, address lpPair) external view returns (uint256 stakeLP, uint256 stakeA, uint256 stakeB) {
        Farm farm = Farm(farmFactory.Farms(lpPair));
        if (farm != Farm(address(0))) {
            stakeLP = farm.userBalance(_address);
            (stakeA, stakeB) = getTokenStake(lpPair, stakeLP);
        }
    }

    /**
     * @dev Returns total amount locked in the pool. Doesn't take pending rewards into account.
     * @param lpPair - LP pool to check total deposits in.

     * @return totalDepositsLP - Total deposits (in LP tokens).
     * @return totalDepositsA - Token A deposits.
     * @return totalDepositsB - Token B deposits.
     */  
    function totalDeposits(address lpPair) external view returns (uint256 totalDepositsLP, uint256 totalDepositsA, uint256 totalDepositsB) {
        Farm farm = Farm(farmFactory.Farms(lpPair));
        if (farm != Farm(address(0))) {
            totalDepositsLP = farm.getTotalDeposits(); 
            (totalDepositsA, totalDepositsB) = getTokenStake(lpPair, totalDepositsLP);
        }
    }

    /**
     * @dev Returns addresses of tokens in {lpPair}.
     * @param lpPair - LP pair to check tokens in.

     * @return tokens - Tokens addresses.
     */  
    function getTokens(address lpPair) external view returns(IBEP20[] memory tokens){
        tokens = new IBEP20[](2);
        tokens[0] = IBEP20(IUniswapV2Pair(lpPair).token0());
        tokens[1] = IBEP20(IUniswapV2Pair(lpPair).token1());
    }

    /**
     * @dev Converts LP tokens to normal tokens, value(amountA) == value(amountB) == 0.5*amountLP
     * @param lpPair - LP pair for conversion.
     * @param amountLP - Amount of LP tokens to convert.

     * @return amountA - Token A amount.
     * @return amountB - Token B amount.
     */ 
    function getTokenStake(address lpPair, uint256 amountLP) internal view returns (uint256 amountA, uint256 amountB) {
        uint256 totalSupply = IBEP20(lpPair).totalSupply();
        amountA = amountLP * IBEP20(IUniswapV2Pair(lpPair).token0()).balanceOf(lpPair) / totalSupply;
        amountB = amountLP * IBEP20(IUniswapV2Pair(lpPair).token1()).balanceOf(lpPair) / totalSupply;
    }

    /**
     * @dev Change fee amount.
     * @param _fee -New fee to collect from farms. [10^18 == 100%]
     *
     * Note: This function can only be called by ADMIN_ROLE.
     */ 
    function setFee(uint256 _fee) external onlyRole(accessManager.ADMIN_ROLE()){
        require (_fee <= 1 ether, "BAD_FEE");
        if(fee != _fee){
            emit FeeChanged(fee, _fee); 
            fee = _fee;
        }
    }
 
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyRole(accessManager.ADMIN_ROLE()) {

    }
}