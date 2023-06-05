// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IWaitingPool.sol";

import "./interfaces/IMasterVault.sol";

contract WaitingPool is IWaitingPool, Initializable {

    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    struct Person {
        address _address;
        uint256 _debt;
        bool _settled;
    }

    IMasterVault public masterVault;
    Person[] public people;
    uint256 public index;
    uint256 public totalDebt;
    uint256 public capLimit;
    
    bool public lock;

    address public underlying;


    // --- Events ---
    event WithdrawPending(address user, uint256 amount);
    event WithdrawCompleted(address user, uint256 amount);

    // --- Mods ---
    modifier onlyMasterVault() {

        require(msg.sender == address(masterVault));
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    /** Initializer for upgradeability
      * @param _masterVault masterVault contract
      * @param _underlyingToken ERC20 underlying
      * @param _capLimit number of indices to be payed in one call
      */
    function initialize(address _masterVault, address _underlyingToken, uint256 _capLimit) external initializer {

        require(_capLimit > 0, "WaitingPool/invalid-cap");

        masterVault = IMasterVault(_masterVault);
        underlying = _underlyingToken;
        capLimit = _capLimit;
    }

    // --- MasterVault ---
    /** Adds withdrawer from MasterVault to queue
      * @param _person address of withdrawer from MasterVault
      * @param _debt amount of withdrawal
      */
    function addToQueue(address _person, uint256 _debt) external onlyMasterVault {

        if(_debt != 0) {
            Person memory p = Person({_address: _person, _settled: false, _debt: _debt});
            totalDebt += _debt;
            people.push(p);

            emit WithdrawPending(_person, _debt);
        }
    }
    /** Try paying outstanding debt of users and settle flag to success
      */
    function tryRemove() external onlyMasterVault {

        uint256 balance;
        uint256 cap = 0;
        for(uint256 i = index; i < people.length; i++) {
            balance = getPoolBalance();
            uint256 userDebt = people[index]._debt;
            address userAddr = people[index]._address;
            if(balance >= userDebt && userDebt != 0 && !people[index]._settled && cap < capLimit) {
                totalDebt -= userDebt;
                people[index]._settled = true;
                emit WithdrawCompleted(userAddr, userDebt);

                cap++;
                index++;

                IERC20Upgradeable(underlying).safeTransfer(userAddr, userDebt);
            } else return;
        }
    }
    /** Sets a new cap limit per tryRemove()
      * @param _capLimit new cap limit
      */
    function setCapLimit(uint256 _capLimit) external onlyMasterVault {

        require(_capLimit != 0, "WaitingPool/invalid-cap");
        
        capLimit = _capLimit;
    }

    // --- User ---
    /** Users can manually withdraw their funds if they were not transferred in tryRemove()
      */
    function withdrawUnsettled(uint256 _index) external {
        require(!lock, "reentrancy");
        lock = true;

        address src = msg.sender;
        require(!people[_index]._settled && _index < index && people[_index]._address == src, "WaitingPool/already-settled");

        uint256 withdrawAmount = people[_index]._debt;
        totalDebt -= withdrawAmount;
        people[_index]._settled = true;

        IERC20Upgradeable(underlying).safeTransfer(src, withdrawAmount);
        lock = false;
        emit WithdrawCompleted(src, withdrawAmount);
    }

    // --- Views ---
    function getPoolBalance() public view returns(uint256) {

        return IERC20Upgradeable(underlying).balanceOf(address(this));
    }
    function getUnbackedDebt() external view returns(uint256) {

        return IERC20Upgradeable(underlying).balanceOf(address(this)) < totalDebt ? totalDebt - getPoolBalance() : 0;
    }
}