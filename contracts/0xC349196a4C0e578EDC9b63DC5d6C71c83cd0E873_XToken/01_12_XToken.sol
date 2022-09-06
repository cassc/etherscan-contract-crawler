// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./interface/IInterestRateModel.sol";
import "./interface/IXToken.sol";
import "./interface/IP2Controller.sol";
import "./interface/IERC20.sol";
import "./Exponential.sol";
import "./library/SafeERC20.sol";
import "./XTokenStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract XToken is XTokenStorage, Exponential, Initializable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /**event */
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed minter, uint256 mintAmount, uint256 mintTokens, uint256 accountTokensAmount, uint256 exchageRate);
    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 accountTokensAmount, uint256 exchageRate);
    event Borrow(uint256 orderId, address borrower, uint256 borrowAmount, uint256 orderBorrows, uint256 totalBorrows);
    event RepayBorrow(uint256 orderId, address borrower, address payer, uint256 repayAmount, uint256 orderBorrowBalance, uint256 totalBorrows);
    event LiquidateBorrow(uint256 orderId, address indexed borrower, address indexed liquidator, uint256 liquidatePrice);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);

    function initialize(
        uint256 _initialExchangeRate,
        address _controller,
        address _initialInterestRateModel,
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        initialExchangeRate = _initialExchangeRate;
        controller = IP2Controller(_controller);
        interestRateModel = IInterestRateModel(_initialInterestRateModel);
        require(interestRateModel.isInterestRateModel(), "not an interestratemodel contract address.");
        admin = payable(msg.sender);
        underlying = _underlying;
        accrualBlockNumber = getBlockNumber();
        borrowIndex = ONE;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _notEntered = true;
    }


    function doTransferIn(address account, uint256 amount) internal returns (uint256){
        if(underlying == ADDRESS_ETH){
            require(msg.value >= amount, "ETH value not enough");
            if (msg.value > amount){
                uint256 changeAmount = msg.value.sub(amount);
                (bool result, ) = account.call{value: changeAmount,gas: transferEthGasCost}("");
                require(result, "Transfer of ETH failed");
            }

        }else{
            require(msg.value == 0, "ERC20 don't accecpt ETH");

            uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
            IERC20(underlying).safeTransferFrom(account, address(this), amount);
            uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

            require(balanceAfter - balanceBefore == amount,"TransferIn amount not valid");
        }

        totalCash = totalCash.add(amount);
        return amount;
    }

    function doTransferOut(address payable account, uint256 amount) internal {
        if (underlying == ADDRESS_ETH) {
            (bool result, ) = account.call{value: amount, gas: transferEthGasCost}("");
            require(result, "Transfer of ETH failed");
        } else {
            IERC20(underlying).safeTransfer(account, amount);
        }

        totalCash = totalCash.sub(amount);
    }

    receive() external payable {
        accrueInterest();
        mintInternal(msg.sender, msg.value);
    }

    function mint(uint256 amount) external payable{
        accrueInterest();
        mintInternal(msg.sender, amount);
    }

    struct MintLocalVars {
        uint256 exchangeRate;
        uint256 mintTokens;
        uint256 totalSupplyNew;
        uint256 accountTokensNew;
        uint256 actualMintAmount;
    }

    function mintInternal(address minter, uint256 amount) internal nonReentrant {

        controller.mintAllowed(address(this), minter, amount);

        require(accrualBlockNumber == getBlockNumber(), "blocknumber check fails");

        MintLocalVars memory vars;
        vars.exchangeRate = exchangeRateStoredInternal();

        vars.actualMintAmount = doTransferIn(minter, amount);

        vars.mintTokens = divScalarByExpTruncate(vars.actualMintAmount, vars.exchangeRate);
        vars.totalSupplyNew = addExp(totalSupply, vars.mintTokens);
        vars.accountTokensNew = addExp(accountTokens[minter], vars.mintTokens);

        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        controller.mintVerify(address(this), minter);

        emit Mint(minter, vars.actualMintAmount, vars.mintTokens,vars.accountTokensNew, vars.exchangeRate);
        emit Transfer(address(0), minter, vars.mintTokens);
    }

    function redeem(uint256 redeemTokens) external{
        accrueInterest();
        redeemInternal(payable(msg.sender), redeemTokens, 0);
    }

    function redeemUnderlying(uint256 redeemAmounts) external{
        accrueInterest();
        redeemInternal(payable(msg.sender), 0, redeemAmounts);
    }

    struct RedeemLocalVars {
        uint256 exchangeRate;
        uint256 redeemTokens;
        uint256 redeemAmount;
        uint256 totalSupplyNew;
        uint256 accountTokensNew;
    }

    /**
    * redeemTokensIn: xToken amount
    * redeemAmountIn: underlying assets amount
    */
    function redeemInternal(address payable redeemer, uint256 redeemTokensIn, uint256 redeemAmountIn) internal nonReentrant {

        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn should be 0");

        RedeemLocalVars memory vars;
        vars.exchangeRate = exchangeRateStoredInternal();

        if (redeemTokensIn > 0 ){
            vars.redeemTokens = redeemTokensIn;
            vars.redeemAmount = mulScalarTruncate(vars.exchangeRate, redeemTokensIn);
        }else {
            vars.redeemTokens = divScalarByExpTruncate(redeemAmountIn,vars.exchangeRate);
            vars.redeemAmount = redeemAmountIn;
        }

        controller.redeemAllowed(address(this), redeemer, vars.redeemTokens, vars.redeemAmount);

        require(accrualBlockNumber == getBlockNumber(), "blocknumber check fails");

        vars.totalSupplyNew = totalSupply.sub(vars.redeemTokens);
        vars.accountTokensNew = accountTokens[redeemer].sub(vars.redeemTokens);

        require(getCashPrior() >= vars.redeemAmount, "insufficient balance of underlying asset");

        doTransferOut(redeemer, vars.redeemAmount);

        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        controller.redeemVerify(address(this), redeemer);

        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens, vars.accountTokensNew, vars.exchangeRate);
        emit Transfer(redeemer, address(0), vars.redeemTokens);
    }

    function borrow(uint256 orderId, address payable borrower, uint256 borrowAmount) external{
        require(msg.sender == borrower || tx.origin == borrower, "borrower is wrong");
        accrueInterest();
        borrowInternal(orderId, borrower, borrowAmount);
    }

    struct BorrowLocalVars {
        uint256 orderBorrows;
        uint256 orderBorrowsNew;
        uint256 totalBorrowsNew;
    }

    function borrowInternal(uint256 orderId, address payable borrower, uint256 borrowAmount) internal nonReentrant{
        
        controller.borrowAllowed(address(this), orderId, borrower, borrowAmount);

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        
        require(getCashPrior() >= borrowAmount, "insufficient balance of underlying asset");

        BorrowLocalVars memory vars;

        vars.orderBorrows = borrowBalanceStoredInternal(orderId);
        vars.orderBorrowsNew = addExp(vars.orderBorrows, borrowAmount);
        vars.totalBorrowsNew = addExp(totalBorrows, borrowAmount);
        
        doTransferOut(borrower, borrowAmount);

        orderBorrows[orderId].principal = vars.orderBorrowsNew;
        orderBorrows[orderId].interestIndex = borrowIndex;

        totalBorrows = vars.totalBorrowsNew;

        controller.borrowVerify(orderId, address(this), borrower);

        emit Borrow(orderId, borrower, borrowAmount, vars.orderBorrowsNew, vars.totalBorrowsNew);
    }

    function repayBorrow(uint256 orderId, address borrower, uint256 repayAmount) external payable{
        accrueInterest();
        repayBorrowInternal(orderId, borrower, msg.sender, repayAmount);
    }

    struct RepayBorrowLocalVars {
        uint256 repayAmount;
        uint256 borrowerIndex;
        uint256 orderBorrows;
        uint256 orderBorrowsNew;
        uint256 totalBorrowsNew;
        uint256 actualRepayAmount;
    }

    function repayBorrowInternal(uint256 orderId, address borrower, address payer, uint256 repayAmount) internal returns(uint256){

        controller.repayBorrowAllowed(address(this), orderId, borrower, payer, repayAmount);

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        
        RepayBorrowLocalVars memory vars;

        vars.borrowerIndex = orderBorrows[orderId].interestIndex;
        vars.orderBorrows = borrowBalanceStoredInternal(orderId);

        if (repayAmount == type(uint256).max) {
            vars.repayAmount = vars.orderBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

        require(vars.orderBorrows >= vars.actualRepayAmount, "invalid repay amount");
        vars.orderBorrowsNew = vars.orderBorrows.sub(vars.actualRepayAmount);

        if (totalBorrows < vars.actualRepayAmount) {
            vars.totalBorrowsNew = 0;
        } else {
            vars.totalBorrowsNew = totalBorrows.sub(vars.actualRepayAmount);
        }

        orderBorrows[orderId].principal = vars.orderBorrowsNew;
        orderBorrows[orderId].interestIndex = borrowIndex;

        totalBorrows = vars.totalBorrowsNew;

        controller.repayBorrowVerify(address(this), orderId, borrower, payer, vars.actualRepayAmount);

        emit RepayBorrow(orderId, borrower, payer, vars.actualRepayAmount, vars.orderBorrowsNew, totalBorrows);

        return vars.actualRepayAmount;
    }

    function repayBorrowAndClaim(uint256 orderId, address borrower) external nonReentrant payable{
        require(msg.sender == borrower || tx.origin == borrower, "borrower is wrong");
        accrueInterest();
        repayBorrowAndClaimInternal(orderId, borrower, msg.sender);
    }

    function repayBorrowAndClaimInternal(uint256 orderId, address borrower, address payer) internal{
        repayBorrowInternal(orderId, borrower, payer, type(uint256).max);
        controller.repayBorrowAndClaimVerify(address(this), orderId);
    }

    function liquidateBorrow(uint256 orderId, address borrower) external nonReentrant payable{
        accrueInterest();
        liquidateBorrowInternal(orderId, borrower, msg.sender);
    }
    
    function liquidateBorrowInternal(uint256 orderId, address borrower, address liquidator) internal returns(uint256){
        controller.liquidateBorrowAllowed(address(this), orderId, borrower, liquidator);
        
        require(accrualBlockNumber == getBlockNumber(),"block number check fails");

        uint256 _repayAmount = repayBorrowInternal(orderId, borrower, liquidator, type(uint256).max);

        LiquidateState storage _state = liquidatedOrders[orderId];
        _state.liquidated = true;
        _state.liquidator = msg.sender;
        _state.liquidatedPrice = _repayAmount;

        controller.liquidateBorrowVerify(address(this), orderId, borrower, liquidator, _repayAmount);

        emit LiquidateBorrow(orderId, borrower, liquidator, _repayAmount);
        return _repayAmount;
    }

    function orderLiquidated(uint256 orderId) external view returns(bool, address, uint256){
        LiquidateState storage _state = liquidatedOrders[orderId];
        return (_state.liquidated, _state.liquidator, _state.liquidatedPrice);
    }

    function borrowBalanceCurrent(uint256 orderId) external returns (uint256){
        accrueInterest();
        return borrowBalanceStoredInternal(orderId);
    }

    function borrowBalanceStored(uint256 orderId) external view returns (uint256){
        return borrowBalanceStoredInternal(orderId);
    }

    function borrowBalanceStoredInternal(uint256 orderId) internal view returns (uint256){
        BorrowSnapshot storage borrowSnapshot = orderBorrows[orderId];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        return mulExp(borrowSnapshot.principal, divExp(borrowIndex, borrowSnapshot.interestIndex));
    }

    function exchangeRateCurrent() public returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    function exchangeRateStored() public view returns (uint256) {
        return exchangeRateStoredInternal();
    }

    function exchangeRateStoredInternal() internal view returns (uint256) {
        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            return initialExchangeRate;
        } else {
            uint256 _totalCash = getCashPrior();
            uint256 cashPlusBorrowsMinusReserves = subExp(addExp(_totalCash, totalBorrows),totalReserves);

            uint256 exchangeRate = getDiv(cashPlusBorrowsMinusReserves, _totalSupply);
            return exchangeRate;
        }
    }

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function getCashPrior() internal view returns (uint256) {
        return totalCash;
    }

    function accrueInterest() public {
        uint256 currentBlockNumber =  getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return;
        }

        uint256 cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        uint256 borrowRate = interestRateModel.getBorrowRate(cashPrior,borrowsPrior,reservesPrior);
        
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);

        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 totalBorrowsNew;
        uint256 totalReservesNew;
        uint256 borrowIndexNew;

        simpleInterestFactor = mulScalar(borrowRate, blockDelta);

        interestAccumulated = divExp(mulExp(simpleInterestFactor, borrowsPrior),expScale);

        totalBorrowsNew = addExp(interestAccumulated, borrowsPrior);

        totalReservesNew = addExp(divExp(mulExp(reserveFactor, interestAccumulated), expScale),reservesPrior);

        borrowIndexNew = addExp(divExp(mulExp(simpleInterestFactor, borrowIndexPrior), expScale),borrowIndexPrior);

        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        borrowRate = interestRateModel.getBorrowRate(cashPrior,totalBorrows,totalReserves);
       
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");
    }

    function accrueInterestReadOnly() public view returns(uint256, uint256, uint256){
        uint256 currentBlockNumber =  getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return (totalBorrows, totalReserves, borrowIndex);
        }

        uint256 cashPrior = getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        uint256 borrowRate = interestRateModel.getBorrowRate(cashPrior,borrowsPrior,reservesPrior);
        
        require(borrowRate <= borrowRateMax, "borrow rate is absurdly high");

        uint256 blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);

        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 totalBorrowsNew;
        uint256 totalReservesNew;
        uint256 borrowIndexNew;

        simpleInterestFactor = mulScalar(borrowRate, blockDelta);

        interestAccumulated = divExp(mulExp(simpleInterestFactor, borrowsPrior), expScale);

        totalBorrowsNew = addExp(interestAccumulated, borrowsPrior);

        totalReservesNew = addExp(divExp(mulExp(reserveFactor, interestAccumulated), expScale),reservesPrior);

        borrowIndexNew = addExp(divExp(mulExp(simpleInterestFactor, borrowIndexPrior), expScale),borrowIndexPrior);

        return (totalBorrowsNew, totalReservesNew, borrowIndexNew);
    }

    function getSupplyed(uint256 amount) external view returns(uint256){
        (uint256 totalBorrows, uint256 totalReserves,) = accrueInterestReadOnly();
        uint256 exchangeRate;
        if (totalSupply == 0) {
            exchangeRate = initialExchangeRate;
        } else {
            uint256 cashPlusBorrowsMinusReserves = subExp(addExp(getCashPrior(), totalBorrows), totalReserves);
            exchangeRate = getDiv(cashPlusBorrowsMinusReserves, totalSupply);
        }
        return mulScalarTruncate(exchangeRate, amount);
    }

    function getBorrowed(uint256 orderId) external view returns (uint256){
        (, , uint256 borrowIndexTemp) = accrueInterestReadOnly();
        BorrowSnapshot storage borrowSnapshot = orderBorrows[orderId];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }
        uint256 currentDebt = mulExp(borrowSnapshot.principal, divExp(borrowIndexTemp, borrowSnapshot.interestIndex));
        return currentDebt;
    }

    function getBorrowApy() external view returns(uint256){
        return interestRateModel.getBorrowRate(getCashPrior() , totalBorrows, totalReserves).mul(interestRateModel.blocksPerYear());
    }

    function getSupplyApy() external view returns(uint256){
        return interestRateModel.getSupplyRate(getCashPrior() , totalBorrows, totalReserves, reserveFactor).mul(interestRateModel.blocksPerYear());
    }

    function balanceOfUnderlying(address owner) external returns (uint256) {
        uint256 exchangeRate = exchangeRateCurrent();
        uint256 balance = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        return balance;
    }

    //================ ERC20 standand function ================
    function allowance(address owner, address spender) external view returns (uint256){
        return transferAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        return transferTokens(msg.sender, sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool){
        return transferTokens(msg.sender, msg.sender, recipient, amount);
    }

    function transferTokens(address spender, address src, address dst, uint256 tokens) internal returns (bool) {
        controller.transferAllowed(address(this), src, dst, tokens);
        require(src != dst, "Cannot transfer to self");

        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        uint256 allowanceNew = startingAllowance.sub(tokens);

        accountTokens[src] = accountTokens[src].sub(tokens);
        accountTokens[dst] = accountTokens[dst].add(tokens);

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        controller.transferVerify(address(this), src, dst);

        emit Transfer(src, dst, tokens);

        return true;
    }

    function balanceOf(address owner) external view  returns (uint256) {
        return accountTokens[owner];
    }

    //================ admin ================

    function setPendingAdmin(address payable newPendingAdmin) external onlyAdmin{
        
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function setController(address _controller) external onlyAdmin {
        controller = IP2Controller(_controller);
    }

    function setReserveFactor(uint256 newReserveFactor) external onlyAdmin {
        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(newReserveFactor < reserveFactorMax, "new reserveFactor too lardge");

        reserveFactor = newReserveFactor;
    }

    function reduceReserves(uint256 reduceAmount) external onlyAdmin {

        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(reduceAmount <= getCashPrior(), "insufficient balance of underlying asset");
        require(reduceAmount <= totalReserves, "invalid reduce amount");

        totalReserves = totalReserves.sub(reduceAmount);
        doTransferOut(admin, reduceAmount);
    }

    function setInterestRateModel(IInterestRateModel newInterestRateModel) external onlyAdmin {
        accrueInterest();

        require(accrualBlockNumber == getBlockNumber(),"block number check fails");
        require(newInterestRateModel.isInterestRateModel(), "invalid interestRateModel");

        interestRateModel = newInterestRateModel;
    }

    function setTransferEthGasCost(uint256 _transferEthGasCost) external onlyAdmin {
        transferEthGasCost = _transferEthGasCost;
    }

    //================ modifier ================
     modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "require admin auth");
        _;
    }
}