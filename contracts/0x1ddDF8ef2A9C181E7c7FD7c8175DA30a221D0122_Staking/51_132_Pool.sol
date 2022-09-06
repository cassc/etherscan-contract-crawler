// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/Destinations.sol";
import "../fxPortal/IFxStateSender.sol";
import "../interfaces/events/IEventSender.sol";

contract Pool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable, IEventSender {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer; // Underlying ERC20 token
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

    // NonReentrant
    bool private _entered;
    bool public _eventSend;
    Destinations public destinations;

    bool public depositsPaused;

    mapping (address => bool) public registeredBurners;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    modifier whenDepositsNotPaused() {
        require(!paused(), "Pausable: paused");
        require(!depositsPaused, "DEPOSITS_PAUSED");
        _;
    }

    modifier onlyRegisteredBurner() {
      require(registeredBurners[msg.sender], "NOT_REGISTERED_BURNER");
      _;
    }

    function initialize(
        ERC20 _underlyer,
        IManager _manager,
        string memory _name,
        string memory _symbol
    ) public initializer {
        require(address(_underlyer) != address(0), "ZERO_ADDRESS");
        require(address(_manager) != address(0), "ZERO_ADDRESS");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        underlyer = _underlyer;
        manager = _manager;
    }

    ///@notice Gets decimals of underlyer so that tAsset decimals will match
    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function registerBurner(address burner, bool allowedBurner) external override onlyOwner {
      require(burner != address(0), "INVALID_ADDRESS");
      registeredBurners[burner] = allowedBurner;

      emit BurnerRegistered(burner, allowedBurner);
    }

    function deposit(uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenDepositsNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    function withdraw(uint256 requestedAmount) external override whenNotPaused nonReentrant {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        // Checks for manager cycle and if user is allowed to withdraw based on their minimum withdrawal cycle
        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        // If full amount withdrawn delete from mapping
        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);
        underlyer.safeTransfer(msg.sender, requestedAmount);

        bytes32 eventSig = "Withdraw";
        encodeAndSendData(eventSig, msg.sender);
    }

    /// @dev Adjusts the withheldLiquidity as necessary
    /// @dev Updates the WithdrawalInfo for when a user can withdraw and for what requested amount
    function requestWithdrawal(uint256 amount) external override {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

        //adjust withheld liquidity by removing the original withheld amount and adding the new amount
        withheldLiquidity = withheldLiquidity.sub(requestedWithdrawals[msg.sender].amount).add(
            amount
        );
        requestedWithdrawals[msg.sender].amount = amount;
        if (manager.getRolloverStatus()) {
            // If manger is currently rolling over add two to min withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            // If manager is not rolling over add one to minimum withdrawal cycle
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }

        emit WithdrawalRequested(msg.sender, amount);
    }

    function preTransferAdjustWithheldLiquidity(address sender, uint256 amount) internal {
        if (requestedWithdrawals[sender].amount > 0) {
            //reduce requested withdraw amount by transferred amount;
            uint256 newRequestedWithdrawl = requestedWithdrawals[sender].amount.sub(
                Math.min(amount, requestedWithdrawals[sender].amount)
            );

            //subtract from global withheld liquidity (reduce) by removing the delta of (requestedAmount - newRequestedAmount)
            withheldLiquidity = withheldLiquidity.sub(
                requestedWithdrawals[sender].amount.sub(newRequestedWithdrawl)
            );

            //update the requested withdraw for user
            requestedWithdrawals[sender].amount = newRequestedWithdrawl;

            //if the withdraw request is 0, empty it out
            if (requestedWithdrawals[sender].amount == 0) {
                delete requestedWithdrawals[sender];
            }
        }
    }

    function approveManager(uint256 amount) public override onlyOwner {
        uint256 currentAllowance = underlyer.allowance(address(this), address(manager));
        if (currentAllowance < amount) {
            uint256 delta = amount.sub(currentAllowance);
            underlyer.safeIncreaseAllowance(address(manager), delta);
        } else {
            uint256 delta = currentAllowance.sub(amount);
            underlyer.safeDecreaseAllowance(address(manager), delta);
        }
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        bool success = super.transfer(recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, msg.sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused nonReentrant returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        bool success = super.transferFrom(sender, recipient, amount);

        bytes32 eventSig = "Transfer";
        encodeAndSendData(eventSig, sender);
        encodeAndSendData(eventSig, recipient);

        return success;
    }

    function controlledBurn(uint256 amount, address account) 
      external 
      override 
      onlyRegisteredBurner 
      whenNotPaused
    {
      require(account != address(0), "INVALID_ADDRESS");
      require(amount > 0, "INVALID_AMOUNT");
      if(account != msg.sender) {
        uint256 currentAllowance = allowance(account, msg.sender);
        require (currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
        _approve(account, msg.sender, currentAllowance.sub(amount));
      }
      
      // Updating withdrawal requests only if currentBalance - burn amount is 
      // Less than requested withdrawal
      uint256 requestedAmount = requestedWithdrawals[account].amount;
      uint256 balance = balanceOf(account);
      require(amount <= balance, "INSUFFICIENT_BALANCE");
      uint256 currentBalance = balance.sub(amount);
      if(requestedAmount > currentBalance) {
        if(currentBalance == 0) {
          delete requestedWithdrawals[account];
          withheldLiquidity = withheldLiquidity.sub(requestedAmount);
        } else {
          requestedWithdrawals[account].amount = currentBalance;
          withheldLiquidity = withheldLiquidity.sub(requestedAmount.sub(currentBalance));
        }
      }
      _burn(account, amount);

      emit Burned(account, msg.sender, amount);
    }

    function pauseDeposit() external override onlyOwner {
        depositsPaused = true;

        emit DepositsPaused();
    }

    function unpauseDeposit() external override onlyOwner {
        depositsPaused = false;

        emit DepositsUnpaused();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2)
        external
        override
        onlyOwner
    {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function _deposit(
        address fromAccount,
        address toAccount,
        uint256 amount
    ) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(toAccount != address(0), "INVALID_ADDRESS");

        _mint(toAccount, amount);
        underlyer.safeTransferFrom(fromAccount, address(this), amount);

        bytes32 eventSig = "Deposit";
        encodeAndSendData(eventSig, toAccount);
    }

    function encodeAndSendData(bytes32 _eventSig, address _user) private onEventSend {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        uint256 userBalance = balanceOf(_user);
        bytes memory data = abi.encode(
            BalanceUpdateEvent({
                eventSig: _eventSig,
                account: _user,
                token: address(this),
                amount: userBalance
            })
        );

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}