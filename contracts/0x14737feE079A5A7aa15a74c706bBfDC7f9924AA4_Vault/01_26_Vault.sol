// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./interfaces/IController.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/IAmm.sol";

contract Vault is Owned {
    using FixedPointMathLib for uint256; 
    using SafeTransferLib for ERC20;    

    address public immutable controller_address;
    IController public immutable CONTROLLER;
    ERC20 public immutable COLLATERAL_TOKEN;
    address public immutable reserve;
    IAmm public immutable AMM;

    ERC20 constant CRVUSD = ERC20(address(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E));
    
    int256 public constant CAP_TO_SAVE = 30e15; // 3%
    uint256 public constant REPAY_FEES = 25e15; // 2.5%
    uint256 public constant TREASURY_FEES = 50e14; // .5%
    
    uint256 public repayLimit = 0;
    bool public repayLimited = false;
    uint256 public collateral_fees;

    event LoanCreated(uint256 collateral, uint256 debt, uint256 N, uint256 debtToSaveMe);
    event RepayLimit(uint256 _repayLimit, bool _repayLimited);
    event CollateralAdded(uint256 collateral);
    event CollateralRemoved(uint256 collateral);
    event BorrowMore(uint256 collateral, uint256 debt);
    event Repaid(uint256 debt);
    event SavedMe(uint256 totalDebt, uint256 debt, uint256 debtFees, uint256 debtTreasuryFees, bool repayLimited, uint256 repayLimit);
    event SetCollateralFees(uint256 collateral_fees);
    
    constructor(address user, address _controller_address, address _reserve, uint256 _collateral_fees) Owned(user) {
        require(_collateral_fees >= 35e15, "Not enough collateral fees");
        controller_address = _controller_address;
        reserve = _reserve;

        collateral_fees = _collateral_fees;

        CONTROLLER = IController(controller_address);
        AMM = IAmm(CONTROLLER.amm());
        COLLATERAL_TOKEN = ERC20(CONTROLLER.collateral_token());

        CRVUSD.approve(controller_address, type(uint256).max);
        CRVUSD.approve(reserve, type(uint256).max);
        COLLATERAL_TOKEN.approve(controller_address, type(uint256).max);
    }

    function create_loan(uint256 collateral, uint256 debt, uint256 N, uint256 debtToSaveMe) external onlyOwner {
        COLLATERAL_TOKEN.safeTransferFrom(owner, address(this), collateral);

        // Create crvUSD loan
        CONTROLLER.create_loan(collateral, debt, N);

        // Send collateral here
        if(debtToSaveMe > 0) {
            IReserve(reserve).deposit_for(owner, debtToSaveMe);
        }

        // Transfer crvUSD received from loan to user
        CRVUSD.safeTransfer(owner, debt - debtToSaveMe);

        emit LoanCreated(collateral, debt, N, debtToSaveMe);
    }

    function set_repay_limit(uint256 _repayLimit, bool _repayLimited) external onlyOwner {
        repayLimit = _repayLimit;
        repayLimited = _repayLimited;

        emit RepayLimit(repayLimit, repayLimited);
    }

    function set_collateral_fees(uint256 _collateral_fees) external onlyOwner {
        collateral_fees = _collateral_fees;
        emit SetCollateralFees(_collateral_fees);
    }

    function add_collateral(uint256 collateral) external onlyOwner {
        COLLATERAL_TOKEN.safeTransferFrom(owner, address(this), collateral);
        CONTROLLER.add_collateral(collateral, address(this));

        emit CollateralAdded(collateral);
    }

    function remove_collateral(uint256 collateral) external onlyOwner {
        CONTROLLER.remove_collateral(collateral, true);
        COLLATERAL_TOKEN.safeTransfer(owner, collateral);

        emit CollateralRemoved(collateral);
    }

    function withdraw(uint256 collateral) external onlyOwner {
        COLLATERAL_TOKEN.safeTransfer(owner, collateral);
        emit CollateralRemoved(collateral);
    }

    function borrow_more(uint256 collateral, uint256 debt) external onlyOwner {
        if(collateral > 0) {
            COLLATERAL_TOKEN.safeTransferFrom(owner, address(this), collateral);
        }

        CONTROLLER.borrow_more(collateral, debt);

        CRVUSD.safeTransfer(owner, debt);

        emit BorrowMore(collateral, debt);
    }

    function repay(uint256 debt) external onlyOwner {
        CRVUSD.safeTransferFrom(owner, address(this), debt);

        CONTROLLER.repay(debt);

        emit Repaid(debt);
    }

    function save_me() external {
        // Check health if enough rekt
        int256[2] memory ticks = AMM.read_user_tick_numbers(address(this));
        require(ticks[1] >= AMM.active_band(), "Not enough rekt");

        // Check health if enough rekt
        int256 health = CONTROLLER.health(address(this), false);
        require(health <= CAP_TO_SAVE, "Not enough rekt");

        // Calculate debt to repay
        uint256 totalDebt = CONTROLLER.debt(address(this));
        uint256 debt = totalDebt.mulWadUp(REPAY_FEES);
        uint256 debtFees = totalDebt.mulWadDown(collateral_fees);
        uint256 debtTreasuryFees = totalDebt.mulWadDown(TREASURY_FEES);
        uint256 totalRepayFees = debtFees + debtTreasuryFees;

        if(repayLimited) {
            require(repayLimit >= totalRepayFees, "Repay limit reached");
            repayLimit -= totalRepayFees;
        }
        
        // Repay
        CRVUSD.safeTransferFrom(msg.sender, address(this), debt);
        CONTROLLER.repay(debt);

        // Send fees
        IReserve(reserve).withdraw_from_vault(owner, debtFees, debtTreasuryFees);
        CRVUSD.safeTransfer(msg.sender, debtFees);

        emit SavedMe(totalDebt, debt, debtFees, debtTreasuryFees, repayLimited, repayLimit);
    }
}