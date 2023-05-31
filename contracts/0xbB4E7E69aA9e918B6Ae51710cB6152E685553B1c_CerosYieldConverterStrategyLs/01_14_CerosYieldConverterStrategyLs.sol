// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseStrategy.sol";

import "../../masterVault/interfaces/IMasterVault.sol";
import "../../ceros/interfaces/ICerosRouterLs.sol";

contract CerosYieldConverterStrategyLs is BaseStrategy {

    // --- Vars ---
    IMasterVault public masterVault;

    // --- Events ---
    event DestinationChanged(address indexed _cerosRouter);

    // --- Mods ---
    modifier onlyMasterVault() {

        require(msg.sender == address(masterVault), "Strategy/not-masterVault");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    /** Initializer for upgradeability
      * @param _destination cerosRouter contract
      * @param _feeRecipient fee recipient
      * @param _underlyingToken underlying token 
      * @param _masterVault masterVault contract
      */
    function initialize(address _destination, address _feeRecipient, address _underlyingToken, address _masterVault) external initializer {

        __BaseStrategy_init(_destination, _feeRecipient, _underlyingToken);

        masterVault = IMasterVault(_masterVault);
        underlying.approve(address(_destination), type(uint256).max);
        underlying.approve(address(_masterVault), type(uint256).max);
    }

    // --- Admin ---
    /** Change destination contract
      * @param _destination new cerosRouter contract
      */
    function changeDestination(address _destination) external onlyOwner {

        require(_destination != address(0));

        underlying.approve(address(destination), 0);
        destination = _destination;
        underlying.approve(address(_destination), type(uint256).max);

        emit DestinationChanged(_destination);
    }

    // --- MasterVault ---
    /** Deposit underlying to destination contract
      * @param _amount underlying token amount
      */
    function deposit(uint256 _amount) external onlyMasterVault whenNotPaused returns(uint256 value) {

        require(_amount <= underlying.balanceOf(address(this)), "Strategy/insufficient-balance");

        return _deposit(_amount);
    }
    /** Internal -> deposits underlying to destination
      * @param _amount underlying token amount
      */
    function _deposit(uint256 _amount) internal returns (uint256 value) {

        require(_amount > 0, "Strategy/invalid-amount");

        _beforeDeposit(_amount);
        return ICerosRouterLs(destination).deposit(_amount);
    }
    /** Withdraw underlying from destination to recipient
      * @dev incase of immediate unstake, 'msg.sender' should be used instead of '_recipient'
      * @param _recipient receiver of tokens incase of delayed unstake
      * @param _amount underlying token amount
      * @return value amount withdrawn from destination
      * return delayed if true, the unstake takes time to reach receiver, thus, can't be MasterVault
      */
    function withdraw(address _recipient, uint256 _amount) external onlyMasterVault whenNotPaused returns(uint256 value) {

        return _withdraw(_recipient, _amount);
    }
    /** Internal -> withdraws underlying from destination to recipient
      * @param _recipient receiver of tokens incase of delayed unstake
      * @param _amount underlying token amount
      * @return value amount withdrawn from destination
      */
    function _withdraw(address _recipient, uint256 _amount) internal returns (uint256 value) {

        require(_amount > 0, "Strategy/invalid-amount");        
        ICerosRouterLs(destination).withdrawFor(_recipient, _amount);

        return _amount;
    }

    // --- Strategist ---
    /** Claims yield from destination in aMATICc and transfers to feeRecipient
      */
    function harvest() external onlyOwnerOrStrategist {

        _harvestTo(feeRecipient);
    }
    /** Internal -> claims yield from destination
      * @param _to receiver of yield
      */
    function _harvestTo(address _to) private returns(uint256 yield) {

        yield = ICerosRouterLs(destination).getYieldFor(address(this));
        if(yield > 0) yield = ICerosRouterLs(destination).claim(_to);

        uint256 profit = ICerosRouterLs(destination).s_profits(address(this));
        if(profit > 0) { yield += profit; ICerosRouterLs(destination).claimProfit(_to); }
    }

    // --- Views ---
    /** Returns the depositable capacity and capacity minus fees charged based on liquidity
      * @param _amount deposit amount to check
      * @return capacity deposit capacity based on liqudity @dev includes aggregated fees, e.g swap fees
      * @return chargedCapacity deposit capacity excluding fees @dev (capacity - fees) = chargedCapacity
      */
    function canDeposit(uint256 _amount) external pure override returns(uint256 capacity, uint256 chargedCapacity) {

        // No strategy fees, thus capacity == chargedCapacity == _amount
        capacity = _amount;
        chargedCapacity = _amount;
    }
    /** Returns the withdrawable capacity and capacity minus fees charged based on liquidity
      * @param _amount withdraw amount to check
      * @return capacity withdraw capacity based on liqudity @dev includes aggregated fees, e.g swap fees
      * @return chargedCapacity withdraw capacity excluding fees @dev (capacity - fees) = chargedCapacity
      */
    function canWithdraw(uint256 _amount) external pure override returns(uint256 capacity, uint256 chargedCapacity) {

        // No strategy fees, thus capacity == chargedCapacity == _amount
        capacity = _amount;
        chargedCapacity = _amount;
    }
}