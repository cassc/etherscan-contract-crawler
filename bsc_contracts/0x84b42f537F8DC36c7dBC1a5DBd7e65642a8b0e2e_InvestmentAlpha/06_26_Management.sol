// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; 
import "./libraries/SafeBEP20.sol";
import "./Token.sol";
/** 
* @author Formation.Fi.
* @notice Implementation of the contract Management.
*/

contract Management is Ownable {
    using SafeBEP20 for IBEP20;
    uint256 public constant FACTOR_FEES_DECIMALS = 1e4; 
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e18;
    uint256 public constant  SECONDES_PER_YEAR = 365 days; 
    uint256 public maxDepositAmount = 1000000 * 1e18;
    uint256 public maxWithdrawalAmount = 1000000 * 1e18;
    uint256 public slippageTolerance = 200;
    uint256 public amountScaleDecimals; 
    uint256 public depositFeeRate = 50;  
    uint256 public minDepositFee;
    uint256 public maxDepositFee = 1000000000000000000000;
    uint256 public managementFeeRate = 200;
    uint256 public performanceFeeRate = 2000;
    uint256 public performanceFee;
    uint256 public managementFee;
    uint256 public managementFeeTime = 1670916182;
    uint256 public tokenPrice = 997758019855786000;
    uint256 public tokenPriceMean = 1000834742672732075;
    uint256 public minAmount= 100 * 1e18;
    uint256 public lockupPeriodUser = 604800; 
    uint256 public netDepositInd;
    uint256 public netAmountEvent;
    address public manager;
    address public treasury;
    address public safeHouse;
    address public investment;
    bool public isCancel;
    mapping(address => bool) public managers;
    Token public token;
    IBEP20 public stableToken;


    constructor( address _manager, address _treasury,  address _stableToken,
     address _token) {
        require(_manager!= address(0),
            "Formation.Fi: zero address");
        require(_treasury!= address(0),
            "Formation.Fi: zero address");
        require(_stableToken!= address(0),
            "Formation.Fi: zero address");
        require(_token!= address(0),
            "Formation.Fi: zero address");
        manager = _manager;
        managers[_manager] = true;
        treasury = _treasury; 
        token = Token(_token);
        stableToken = IBEP20(_stableToken);
        uint8 _stableTokenDecimals = uint8(18) - stableToken.decimals();
        amountScaleDecimals = 10 ** _stableTokenDecimals;
    }

    modifier onlyInvestment() {
        require(investment != address(0),
            "Formation.Fi: zero address");
        require(msg.sender == investment,
            "Formation.Fi: not investment");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager , 
            "Formation.Fi: not manager");
        _;
    }

    /**
     * @dev getter functions.
    */
    function getDepositFee(uint256 _value) public view    
        returns (uint256 _fee){
        _fee = Math.max(Math.mulDiv(depositFeeRate, _value, FACTOR_FEES_DECIMALS), minDepositFee);
        _fee = Math.min(_fee, maxDepositFee);    
    }

    function isManager(address _manager) public view returns(bool) {
        require(_manager != address(0),
            "Formation.Fi: zero address");
        return managers[_manager] ;
    }

    /**
     * @dev Setter functions to update the Portfolio Parameters.
    */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0),
            "Formation.Fi: zero address");
        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(_manager != address(0),
            "Formation.Fi: zero address");
        manager = _manager ;
    }

    function updateManagers(address _manager, bool _state) external {
        require(_manager != address(0),
            "Formation.Fi: zero address");
        managers[_manager] = _state ;
    }

    function setStableToken(address _stableTokenAddress) external onlyOwner {
        require(_stableTokenAddress != address(0),
            "Formation.Fi: zero address");
        stableToken = IBEP20(_stableTokenAddress);
        uint8 _stableTokenDecimals = uint8(18) - stableToken.decimals();
        amountScaleDecimals = 10 ** _stableTokenDecimals;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0),
            "Formation.Fi: zero address");
        token = Token(_token);
    }

    function setInvestment(address _investment) external onlyOwner {
        require(_investment!= address(0),
            "Formation.Fi: zero address");
        investment = _investment;
    } 

    function setSafeHouse(address _safeHouse) external onlyOwner {
        require(_safeHouse!= address(0),
            "Formation.Fi: zero address");
        safeHouse = _safeHouse;
    } 

    function setCancel(bool _isCancel) external onlyManager {
        require(_isCancel!= isCancel,
            "Formation.Fi: no change");
        isCancel = _isCancel;
    }
  
    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        lockupPeriodUser = _lockupPeriodUser;
    }

    function setMaxDepositFee(uint256 _maxDepositFee) 
        external onlyManager {
        maxDepositFee = _maxDepositFee;
    }

    function setMinDepositFee(uint256 _minDepositFee) 
        external onlyManager {
        minDepositFee = _minDepositFee;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        depositFeeRate= _rate;
    }

    function setSlippageTolerance(uint256 _value) external onlyManager {
        slippageTolerance = _value;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        managementFeeRate = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        performanceFeeRate  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        minAmount= _minAmount;
    }

    function setMaxDepositAmount(uint256 _maxDepositAmount) external 
        onlyManager {
        maxDepositAmount = _maxDepositAmount;

    }
    function setMaxWithdrawalAmount(uint256 _maxWithdrawalAmount) external 
        onlyManager{
         maxWithdrawalAmount = _maxWithdrawalAmount;      
    }

    function updateTokenPrice(uint256 _price) external {
        require (managers[msg.sender] == true,
            "Formation.Fi: no manager");
        require(_price > 0,
            "Formation.Fi: zero price");
        tokenPrice = _price;
    }

    function updateTokenPriceMean(uint256 _price) external onlyInvestment {
        require(_price > 0,
            "Formation.Fi: zero price");
        tokenPriceMean = _price;
    }

    function updateManagementFeeTime(uint256 _time) external onlyInvestment {
        managementFeeTime = _time;
    }
    

    /**
     * @dev Calculate performance Fee.
    */
    function calculateperformanceFee() external {
        require (managers[msg.sender] == true, 
            "Formation.Fi: no manager");
        require(performanceFee == 0, 
            "Formation.Fi: fees on pending");
        uint256 _deltaPrice;
        if (tokenPrice > tokenPriceMean) {
            _deltaPrice = tokenPrice - tokenPriceMean;
            tokenPriceMean = tokenPrice;
            performanceFee = Math.mulDiv(token.totalSupply(),
            (_deltaPrice * performanceFeeRate), (tokenPrice * FACTOR_FEES_DECIMALS)); 
        }
    }

    /**
     * @dev Calculate management Fee.
    */
    function calculatemanagementFee() external {
        require (managers[msg.sender] == true, 
            "Formation.Fi: no manager");
        require(managementFee == 0, 
            "Formation.Fi: fees on pending");
        if (managementFeeTime!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  managementFeeTime; 
           managementFee = Math.mulDiv(token.totalSupply(), (managementFeeRate * _deltaTime),
           (FACTOR_FEES_DECIMALS * SECONDES_PER_YEAR));
           managementFeeTime = block.timestamp; 
        }
    }
     
    /**
     * @dev Mint Fees.
    */
    function mintFees() external{
        require (managers[msg.sender] == true, 
            "Formation.Fi: no manager");
        require ((performanceFee + managementFee) > 0, 
            "Formation.Fi: zero fees");
        token.mint(treasury, performanceFee + managementFee);
        performanceFee = 0;
        managementFee = 0;
    }

    /**
     * @dev Calculate net amount Event
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param  _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     */
    function calculateNetAmountEvent(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestment{
        _depositAmountTotal = Math.min(_depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal = Math.mulDiv(_withdrawalAmountTotal, tokenPrice, FACTOR_PRICE_DECIMALS);
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
        if (_depositAmountTotal >= _withdrawalAmountTotal ){
            netDepositInd = 1;
            netAmountEvent = _depositAmountTotal - _withdrawalAmountTotal;
        }
        else {
            netDepositInd = 0;
            netAmountEvent = _withdrawalAmountTotal - _depositAmountTotal;

        }
    }
 
    /**
     * @dev Protect against slippage due to assets sale.
     * @param _withdrawalAmount the value of sold assets in Stablecoin.
     * _withdrawalAmount has to be sent to the contract.
     * treasury has to approve the contract for both Stablecoin and token.
     * @return Missed amount to send to the contract due to slippage.
     */
    function protectAgainstSlippage(uint256 _withdrawalAmount) external  
        returns (uint256) {
        require (managers[msg.sender] == true, 
            "Formation.Fi: no manager");
        require(_withdrawalAmount != 0, 
            "Formation.Fi: zero amount");
        require(netDepositInd == 0, 
            "Formation.Fi: no slippage");
        uint256 _amount; 
        uint256 _deltaAmount;
        uint256 _slippage;
        uint256  _tokenAmount;
        uint256 _balanceTokenTreasury = token.balanceOf(treasury);
        uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * amountScaleDecimals;
        if (_withdrawalAmount< netAmountEvent){
            _amount = netAmountEvent - _withdrawalAmount;   
            _slippage = Math.mulDiv(_amount, FACTOR_FEES_DECIMALS, netAmountEvent);
            if (_slippage >= slippageTolerance) {
                return netAmountEvent;
            }
            else {
                _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if (_deltaAmount > 0){
                    stableToken.safeTransferFrom(treasury, investment, _deltaAmount/amountScaleDecimals);
                    _tokenAmount = Math.mulDiv(_deltaAmount, FACTOR_PRICE_DECIMALS, tokenPrice);
                    token.mint(treasury, _tokenAmount);
                    return _amount - _deltaAmount;
                }
                else {
                     return _amount; 
                }  
            }    
        
        }
        else {
            _amount = _withdrawalAmount - netAmountEvent;   
            _tokenAmount = Math.mulDiv(_amount, FACTOR_PRICE_DECIMALS, tokenPrice);
            _tokenAmount = Math.min(_tokenAmount, _balanceTokenTreasury);
            if (_tokenAmount >0){
                _deltaAmount = Math.mulDiv(_tokenAmount, tokenPrice, FACTOR_PRICE_DECIMALS);
                stableToken.safeTransfer(treasury, _deltaAmount/amountScaleDecimals);   
                token.burn( treasury, _tokenAmount);
            }
            if ((_amount - _deltaAmount) > 0) {
                stableToken.safeTransfer(safeHouse, (_amount - _deltaAmount)/amountScaleDecimals); 
            }
        }
        return 0;

    } 
  
}