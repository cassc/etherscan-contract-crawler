//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./RadiusToken.sol";


contract RadiusCore {

    
    event Lend(address indexed lender, uint amount);
    event WithdrawLend(address indexed lender, uint amount);
    event ClaimYield(address indexed lender, uint amount);
    event Collateralize(address indexed borrower, uint amount);
    event WithdrawCollateral(address indexed borrower, uint amount);
    event Borrow(address indexed borrower, uint amount);
    event Repay(address indexed borrower, uint amount);
    event Liquidate(address liquidator, uint reward, address indexed borrower);

    
    mapping(address => uint) public lendingBalance;
    mapping(address => uint) public RadiusBalance;
    mapping(address => uint) public startTime;
    mapping(address => bool) public isLending;

    
    mapping(address => uint) public collateralBalance;
    mapping(address => uint) public borrowBalance;
    mapping(address => bool) public isBorrowing;

    
    AggregatorV3Interface internal priceFeed;

    
    IERC20 public immutable baseAsset;
    RadiusToken public immutable radiusToken;

    
    constructor(IERC20 _baseAssetAddress, RadiusToken _radiusAddress, address _aggregatorAddress) {
        baseAsset = _baseAssetAddress;
        radiusToken = _radiusAddress;
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
    } 

    
    modifier passedLiquidation(address _borrower) virtual {
        uint collatAssetPrice = getCollatAssetPrice();
        require((collatAssetPrice * collateralBalance[_borrower]) / 10 ** 8 <= calculateLiquidationPoint(_borrower), "Position can't be liquidated!");
        _;
    }

    
    function getCollatAssetPrice() public view returns(uint collatAssetPrice){
        (,int price,,,) = priceFeed.latestRoundData();
        collatAssetPrice = uint(price);
    }

    
    function calculateYieldTime(address _lender) public view returns(uint lendingTime) {
        lendingTime = block.timestamp - startTime[_lender];
    }

    
    function calculateYieldTotal(address _lender) public view returns(uint yield) {
        uint timeStaked = calculateYieldTime(_lender) * 10**18;
        yield = (lendingBalance[_lender] * timeStaked / 31536000) / 10**18;
    }

    
    function calculateBorrowLimit(address _borrower) public view returns(uint limit) {
        uint collatAssetPrice = getCollatAssetPrice();
        limit = ((((collatAssetPrice * collateralBalance[_borrower]) * 70) / 100)) / 10 ** 8 - borrowBalance[_borrower];
    }

    function calculateLiquidationPoint(address _borrower) public view returns(uint point) {
        point = borrowBalance[_borrower] + (borrowBalance[_borrower] * 10) / 100;
    }

    
    function lend(uint _amount) external payable {
        
        require(_amount > 0, "Can't lend amount: 0!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient balance!");

        

        if(isLending[msg.sender]) {
            uint yield = calculateYieldTotal(msg.sender);
            RadiusBalance[msg.sender] += yield; 
        }

        (lendingBalance[msg.sender] + _amount);
         
        lendingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        isLending[msg.sender] = true;

        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction failed!");

        
        require(startTime[msg.sender] > 0, "Transaction failed!");
        require(isLending[msg.sender], "Transaction failed!");
        require(lendingBalance[msg.sender] > 0, "Transaction failed!");

          lendingBalance[msg.sender] += _amount;
        startTime[msg.sender] = block.timestamp;
        isLending[msg.sender] = true;

        
    }

    
    function withdrawLend(uint _amount) public {
        require(isLending[msg.sender], "Can't withdraw before lending!");
        require(lendingBalance[msg.sender] >= _amount, "Insufficient lending balance!");

        uint yield = calculateYieldTotal(msg.sender);
        RadiusBalance[msg.sender] += yield;
        startTime[msg.sender] = block.timestamp;

        uint withdrawAmount = _amount;
        _amount = 0;
        lendingBalance[msg.sender] -= withdrawAmount;

        if(lendingBalance[msg.sender] == 0){
            isLending[msg.sender] = false;
        }

        require(baseAsset.transfer(msg.sender, withdrawAmount), "Transaction failed!");

        emit WithdrawLend(msg.sender, withdrawAmount);

        
    }
    
    
    function claimYield() external payable {
        uint yield = calculateYieldTotal(msg.sender);

        require(yield > 0 || RadiusBalance[msg.sender] > 0, "No, $RADI tokens earned!");

        if(RadiusBalance[msg.sender] != 0) {
            uint oldYield = RadiusBalance[msg.sender];
            RadiusBalance[msg.sender] = 0;
            yield += oldYield;
        }

        startTime[msg.sender] = block.timestamp;
        radiusToken.mint(msg.sender, yield);

        emit ClaimYield(msg.sender, yield);
    }

    
    function collateralize() external payable {
        require(msg.value > 0, "Can't collaterlize BNB amount: 0!");

        collateralBalance[msg.sender] += msg.value;

        emit Collateralize(msg.sender, msg.value);
    } 

   
    function withdrawCollateral(uint _amount) external {
        require(collateralBalance[msg.sender] >= _amount, "Not enough collateral to withdraw!");
        require(!isBorrowing[msg.sender], "Can't withdraw collateral while borrowing!");

        collateralBalance[msg.sender] -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transaction Failed!");

        emit WithdrawCollateral(msg.sender, _amount);
    }

    
    function borrow(uint _amount) external {
        collateralBalance[msg.sender] -= (collateralBalance[msg.sender] * 3) / 1000;

        require(collateralBalance[msg.sender] > 0, "No BNB collateralized!");
        require(calculateBorrowLimit(msg.sender) >= _amount, "Borrow amount exceeds borrow limit!");

        isBorrowing[msg.sender] = true;
        borrowBalance[msg.sender] += _amount;

        require(baseAsset.transfer(msg.sender, _amount), "Transaction failed!");

        emit Borrow(msg.sender, _amount);
    }
    
    
    function repay(uint _amount) external {
        require(isBorrowing[msg.sender], "Can't repay before borrowing!");
        require(baseAsset.balanceOf(msg.sender) >= _amount, "Insufficient funds!");
        require(_amount > 0 && _amount <= borrowBalance[msg.sender], "Can't repay amount: 0 or more than amount borrowed!");

        if(_amount == borrowBalance[msg.sender]){ 
            isBorrowing[msg.sender] = false;
        }

        borrowBalance[msg.sender] -= _amount;

        require(baseAsset.transferFrom(msg.sender, address(this), _amount), "Transaction Failed!");

        emit Repay(msg.sender, _amount);
    }

    
    function liquidate(address _borrower) external passedLiquidation(_borrower) {
        require(isBorrowing[_borrower], "This address is not borrowing!");
        require(msg.sender != _borrower, "Can't liquidated your own position!");    

        uint liquidationReward = (collateralBalance[_borrower] * 125) / 10000; 

        collateralBalance[_borrower] = 0;
        borrowBalance[_borrower] = 0;
        isBorrowing[_borrower] = false;

        (bool success, ) = msg.sender.call{value: liquidationReward}("");
        require(success, "Transaction Failed!");

        emit Liquidate(msg.sender, liquidationReward, _borrower);
    }

   
    function getLendingStatus(address _lender) external view returns(bool){
        return isLending[_lender];
         
    }  

    
    function getEarnedRadiusTokens(address _lender) external view returns(uint){
        return RadiusBalance[_lender] + calculateYieldTotal(_lender);
    }

   
    function getLendingBalance(address _lender) external view returns(uint){
        return lendingBalance[_lender];
    }

    
    function getCollateralBalance(address _borrower) external view returns(uint){
        return collateralBalance[_borrower];
    }

    
    function getBorrowingStatus(address _borrower) external view returns(bool){
        return isBorrowing[_borrower];
    }

    
    function getBorrowBalance(address _borrower) external view returns(uint){
        return borrowBalance[_borrower];
    }

    
    function getBorrowLimit(address _borrower) external view returns(uint){
        return calculateBorrowLimit(_borrower);
    }

    
    function getLiquidationPoint(address _borrower) external view returns(uint){
        return calculateLiquidationPoint(_borrower);
    }
}