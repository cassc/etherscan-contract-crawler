// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IP2Controller.sol";
import "./interface/IOracle.sol";
import "./interface/IXNFT.sol";
import "./P2ControllerStorage.sol";
import "./Exponential.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract P2Controller is P2ControllerStorage, Exponential,  Initializable{

    using SafeMath for uint256;

    function initialize(ILiquidityMining _liquidityMining) external initializer {
        admin = msg.sender;
        liquidityMining = _liquidityMining;
    }

    function mintAllowed(address xToken, address minter, uint256 mintAmount) external view whenNotPaused(xToken, 1){
        require(poolStates[xToken].isListed, "token not listed");

        uint256 supplyCap = poolStates[xToken].supplyCap;

        if (supplyCap != 0) {
            uint256 _totalSupply = IXToken(xToken).totalSupply();
            uint256 _exchangeRate = IXToken(xToken).exchangeRateStored();
            
            uint256 totalUnderlyingSupply = mulScalarTruncate(_exchangeRate, _totalSupply);
            uint nextTotalUnderlyingSupply = totalUnderlyingSupply.add(mintAmount);
            require(nextTotalUnderlyingSupply < supplyCap, "market supply cap reached");
        }
    }

    function mintVerify(address xToken, address account) external whenNotPaused(xToken, 1){
        updateSupplyVerify(xToken, account, true);
    }

    function redeemAllowed(address xToken, address redeemer, uint256 redeemTokens, uint256 redeemAmount) external view whenNotPaused(xToken, 2){
        require(poolStates[xToken].isListed, "token not listed");
    }

    function redeemVerify(address xToken, address redeemer) external whenNotPaused(xToken, 2){
        updateSupplyVerify(xToken, redeemer, false);
    } 

    function orderAllowed(uint256 orderId, address borrower) internal view returns(address){
        (address _collection , , address _pledger) = xNFT.getOrderDetail(orderId);

        require((_collection != address(0) && _pledger != address(0)), "order not exist");
        require(_pledger == borrower, "borrower don't hold the order");

        bool isLiquidated = xNFT.isOrderLiquidated(orderId);
        require(!isLiquidated, "order has been liquidated");
        return _collection;
    }

    function borrowAllowed(address xToken, uint256 orderId, address borrower, uint256 borrowAmount) external whenNotPaused(xToken, 3){
        require(poolStates[xToken].isListed, "token not listed");

        orderAllowed(orderId, borrower);

        (address _collection , , ) = xNFT.getOrderDetail(orderId);

        CollateralState storage _collateralState = collateralStates[_collection];
        require(_collateralState.isListed, "collection not exist");
        require(_collateralState.supportPools[xToken] || _collateralState.isSupportAllPools, "collection don't support this pool");

        address _lastXToken = orderDebtStates[orderId];
        require(_lastXToken == address(0) || _lastXToken == xToken, "only support borrowing of one xToken");

        (uint256 _price, bool valid) = oracle.getPrice(_collection, IXToken(xToken).underlying());
        require(_price > 0 && valid, "price is not valid");

        // Borrow cap of 0 corresponds to unlimited borrowing
        if (poolStates[xToken].borrowCap != 0) {
            require(IXToken(xToken).totalBorrows().add(borrowAmount) < poolStates[xToken].borrowCap, "pool borrow cap reached");
        }

        uint256 _maxBorrow = mulScalarTruncate(_price, _collateralState.collateralFactor);
        uint256 _mayBorrowed = borrowAmount;
        if (_lastXToken != address(0)){
            _mayBorrowed = IXToken(_lastXToken).borrowBalanceStored(orderId).add(borrowAmount);  
        }
        require(_mayBorrowed <= _maxBorrow, "borrow amount exceed");

        if (_lastXToken == address(0)){
            orderDebtStates[orderId] = xToken;
        }
    }

    function borrowVerify(uint256 orderId, address xToken, address borrower) external whenNotPaused(xToken, 3){
        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
        uint256 _borrowBalance = IXToken(xToken).borrowBalanceCurrent(orderId);
        updateBorrowVerify(orderId, xToken, borrower, _borrowBalance, true);
    }

    function repayBorrowAllowed(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external view whenNotPaused(xToken, 4){
        require(poolStates[xToken].isListed, "token not listed");

        address _collection = orderAllowed(orderId, borrower);

        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
    }

    function repayBorrowVerify(address xToken, uint256 orderId, address borrower, address payer, uint256 repayAmount) external whenNotPaused(xToken, 4){
        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");
        uint256 _borrowBalance = IXToken(xToken).borrowBalanceCurrent(orderId);

        updateBorrowVerify(orderId, xToken, borrower, _borrowBalance, false);

        if (_borrowBalance == 0) {
            delete orderDebtStates[orderId];
        }
    }

    function repayBorrowAndClaimVerify(address xToken, uint256 orderId) external whenNotPaused(xToken, 4){
        require(orderDebtStates[orderId] == address(0), "address invalid");
        xNFT.notifyRepayBorrow(orderId);
    }

    function liquidateBorrowAllowed(address xToken, uint256 orderId, address borrower, address liquidator) external view whenNotPaused(xToken, 5){
        require(poolStates[xToken].isListed, "token not listed");

        orderAllowed(orderId, borrower);

        (address _collection , , ) = xNFT.getOrderDetail(orderId);

        require(orderDebtStates[orderId] == xToken , "collateral debt invalid");

        (uint256 _price, bool valid) = oracle.getPrice(_collection, IXToken(xToken).underlying());
        require(_price > 0 && valid, "price is not valid");

        uint256 _borrowBalance = IXToken(xToken).borrowBalanceStored(orderId);
        uint256 _liquidateBalance = mulScalarTruncate(_price, collateralStates[_collection].liquidateFactor);

        require(_borrowBalance > _liquidateBalance, "order don't exceed borrow balance");
    } 

    function liquidateBorrowVerify(address xToken, uint256 orderId, address borrower, address liquidator, uint256 repayAmount)external whenNotPaused(xToken, 5){
        orderAllowed(orderId, borrower);

        (bool _valid, address _liquidator, uint256 _liquidatedPrice) = IXToken(xToken).orderLiquidated(orderId);

        if (_valid && _liquidator != address(0)){
            xNFT.notifyOrderLiquidated(xToken, orderId, _liquidator, _liquidatedPrice);
        }
    }

    function transferAllowed(address xToken, address src, address dst, uint256 transferTokens) external view{
        require(poolStates[xToken].isListed, "token not listed");
    }

    function transferVerify(address xToken, address src, address dst) external{
        updateSupplyVerify(xToken, src, false);
        updateSupplyVerify(xToken, dst, true);
    }

    function getOrderBorrowBalanceCurrent(uint256 orderId) external returns(uint256){
        address _xToken = orderDebtStates[orderId];
        if (_xToken == address(0)){
            return 0;
        }
        uint256 _borrowBalance = IXToken(_xToken).borrowBalanceCurrent(orderId);
        return _borrowBalance;
    }

    function getCollateralStateSupportPools(address collection, address xToken) external view returns(bool){
        return collateralStates[collection].supportPools[xToken];
    }

    function updateSupplyVerify(address xToken, address account, bool isDeposit) internal{
        uint256 balance = IXToken(xToken).balanceOf(account);
        if(address(liquidityMining) != address(0)){
            liquidityMining.updateSupply(xToken, balance, account, isDeposit);
        }
    }

    function updateBorrowVerify(uint256 orderId, address xToken, address account, uint256 borrowBalance, bool isDeposit) internal{
        address collection = orderAllowed(orderId, account);
        if(address(liquidityMining) != address(0)){
            liquidityMining.updateBorrow(xToken, collection, borrowBalance, account, orderId, isDeposit);
        }
    }

    //================== admin funtion ==================

    function addPool(address xToken, uint256 _borrowCap, uint256 _supplyCap) external onlyAdmin{
        require(!poolStates[xToken].isListed, "pool has added");
        poolStates[xToken] = PoolState(
            true,
            _borrowCap,
            _supplyCap
        );
    }

    function addCollateral(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor, address[] calldata _pools) external onlyAdmin{
        require(!collateralStates[_collection].isListed, "collection has added");
        require(_collateralFactor <= COLLATERAL_FACTOR_MAX, "_collateralFactor is greater than COLLATERAL_FACTOR_MAX");
        require(_liquidateFactor <= LIQUIDATE_FACTOR_MAX, " _liquidateFactor is greater than LIQUIDATE_FACTOR_MAX");
        
        collateralStates[_collection].isListed = true;
        collateralStates[_collection].collateralFactor = _collateralFactor;
        collateralStates[_collection].liquidateFactor = _liquidateFactor;

        if (_pools.length == 0){
            collateralStates[_collection].isSupportAllPools = true;
        }else{
            collateralStates[_collection].isSupportAllPools = false;

            for (uint i = 0; i < _pools.length; i++){
                collateralStates[_collection].supportPools[_pools[i]] = true;
            }
        }
    }

    function setCollateralState(address _collection, uint256 _collateralFactor, uint256 _liquidateFactor) external onlyAdmin {
        require(collateralStates[_collection].isListed, "collection has not added");
        require(_collateralFactor <= COLLATERAL_FACTOR_MAX, "_collateralFactor is greater than COLLATERAL_FACTOR_MAX");
        require(_liquidateFactor <= LIQUIDATE_FACTOR_MAX, " _liquidateFactor is greater than LIQUIDATE_FACTOR_MAX");
        collateralStates[_collection].collateralFactor = _collateralFactor;
        collateralStates[_collection].liquidateFactor = _liquidateFactor;
    }

    function setCollateralSupportPools(address _collection, address[] calldata _pools) external onlyAdmin{
        require(collateralStates[_collection].isListed, "collection has not added");
        
        if (_pools.length == 0){
            collateralStates[_collection].isSupportAllPools = true;
        }else{
            collateralStates[_collection].isSupportAllPools = false;

            for (uint i = 0; i < _pools.length; i++){
                collateralStates[_collection].supportPools[_pools[i]] = true;
            }
        }
    }

    function setOracle(address _oracle) external onlyAdmin{
        oracle = IOracle(_oracle);
    }

    function setXNFT(address _xNFT) external onlyAdmin{
        xNFT = IXNFT(_xNFT);
    }

    function setLiquidityMining(ILiquidityMining _liquidityMining) external onlyAdmin{
        liquidityMining = _liquidityMining;
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    // 1 mint, 2 redeem, 3 borrow, 4 repayborrow, 5 liquidity
    function setPause(address xToken, uint256 index, bool isPause) external onlyAdmin{
        xTokenPausedMap[xToken][index] = isPause;
    }

    //================== admin funtion ==================
    modifier onlyAdmin(){
        require(msg.sender == admin, "admin auth");
        _;
    }

    modifier whenNotPaused(address xToken, uint256 index) {
        require(!xTokenPausedMap[xToken][index], "Pausable: paused");
        _;
    }
}