// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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

contract Pool is ILiquidityPool, Initializable, ERC20, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public override underlyer;
    IManager public manager;

    // implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
    uint256 public override withheldLiquidity;

    // fAsset holder -> WithdrawalInfo
    mapping(address => WithdrawalInfo) public override requestedWithdrawals;

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

    function decimals() public view override returns (uint8) {
        return underlyer.decimals();
    }

    function deposit(uint256 amount) external override whenNotPaused {
        _deposit(msg.sender, msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override whenNotPaused {
        _deposit(msg.sender, account, amount);
    }

    /// @dev References the WithdrawalInfo for how much the user is permitted to withdraw
    /// @dev No withdrawal permitted unless currentCycle >= minCycle
    /// @dev Decrements withheldLiquidity by the withdrawn amount
    /// @dev TODO Update rewardsContract with proper accounting
    function withdraw(uint256 requestedAmount) external override whenNotPaused {
        require(
            requestedAmount <= requestedWithdrawals[msg.sender].amount,
            "WITHDRAW_INSUFFICIENT_BALANCE"
        );
        require(requestedAmount > 0, "NO_WITHDRAWAL");
        require(underlyer.balanceOf(address(this)) >= requestedAmount, "INSUFFICIENT_POOL_BALANCE");

        require(
            requestedWithdrawals[msg.sender].minCycle <= manager.getCurrentCycleIndex(),
            "INVALID_CYCLE"
        );

        requestedWithdrawals[msg.sender].amount = requestedWithdrawals[msg.sender].amount.sub(
            requestedAmount
        );

        if (requestedWithdrawals[msg.sender].amount == 0) {
            delete requestedWithdrawals[msg.sender];
        }

        withheldLiquidity = withheldLiquidity.sub(requestedAmount);

        _burn(msg.sender, requestedAmount);

        underlyer.safeTransfer(msg.sender, requestedAmount);
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
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(2);
        } else {
            requestedWithdrawals[msg.sender].minCycle = manager.getCurrentCycleIndex().add(1);
        }
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
        returns (bool)
    {
        preTransferAdjustWithheldLiquidity(msg.sender, amount);
        return super.transfer(recipient, amount);
    }

    /// @dev Adjust withheldLiquidity and requestedWithdrawal if sender does not have sufficient unlocked balance for the transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        preTransferAdjustWithheldLiquidity(sender, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
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
    }
}