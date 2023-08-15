// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NftBond.sol";
import "./SwapHelper.sol";

error InitProject_InvalidTimestampInput();
error InitProject_InvalidTotalAmountInput();
error Deposit_NotStarted();
error Deposit_Ended();
error Deposit_ExceededTotalAmount();
error Deposit_NotDivisibleByDecimals();
error Withdraw_NotRepayedProject();
error Repay_NotEnoughAmountInput();
error Repay_AlreadyDepositted();
error NotExistingProject();
error Borrow_DepositNotEnded();
error Repay_DepositNotEnded();
error AlreadyBorrowed();

interface IController {
    event Deposited(
        address _depositor,
        uint256 indexed _projectId,
        uint256 _amount
    );
    event Borrowed(
        address _borrower,
        uint256 indexed _projectId,
        uint256 _amount
    );
    event Repaid(address _repayer, uint256 indexed _projectId, uint256 _amount);
    event Withdrawed(
        address _withdrawer,
        uint256 indexed _projectId,
        uint256 _amount
    );

    /**
     * @notice A user deposits ETH or USDC and buys a NFT.
     * @param projectId id of the project the user wants to invest.
     * @param depositAmount the amount of USDC user wants to deposit.
     */
    function deposit(uint256 projectId, uint256 depositAmount) external payable;

    /**
     * @notice A user burns his/her NFT and receives USDC with accrued interests.
     * @param tokenId id of the NFT the user wants to burn.
     */
    function withdraw(uint256 tokenId) external;

    /**
     * @notice The owner withdraws all deposited USDC.
     * @param projectId id of the project
     * @dev totalAmount is updated equal to the currentAmount to handle when
     *      the total deposited amount is below the target amount.
     */
    function borrow(uint256 projectId) external;

    /**
     * @notice The owner transfers USDC for depositors to withdraw.
     * @param projectId id of the project
     * @param amount the amount of USDC the owner wants to transfer to this contract.
     */
    function repay(uint256 projectId, uint256 amount) external;
}

contract Controller is Ownable, SwapHelper, IController {
    /**
     * totalAmount: target amount (Before Borrow) & total deposited (After Project Ended). Changes with borrow.
     * currentAmount: balance of this project. Changes with deposit, withdraw, borrow, and repay.
     * finalAmount: repaid amount after interest. Changes with repay.
     */
    struct Project {
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 depositStartTs;
        uint256 depositEndTs;
        uint256 finalAmount;
    }
    NftBond public nft;
    mapping(uint256 => Project) public projects;

    /**
     * Events.
     */
    event Controller_NewProject(
        uint256 _totalAmount,
        uint256 _depositStartTs,
        uint256 _depositEndTs,
        uint256 _unit,
        string _uri
    );

    /**
     * Constructor.
     */
    constructor(
        NftBond nft_,
        address router_,
        address usdc_,
        address weth_
    ) SwapHelper(router_, usdc_, weth_) {
        nft = nft_;
    }

    /**
     * @notice projectId starts from 0.
     */
    function initProject(
        uint256 totalAmount,
        uint256 depositStartTs,
        uint256 depositEndTs,
        uint256 unit,
        string memory uri
    ) external onlyOwner {
        if (depositEndTs <= block.timestamp || depositEndTs <= depositStartTs)
            revert InitProject_InvalidTimestampInput();
        if (totalAmount == 0) revert InitProject_InvalidTotalAmountInput();

        Project memory newProject = Project({
            totalAmount: totalAmount,
            currentAmount: 0,
            depositStartTs: depositStartTs,
            depositEndTs: depositEndTs,
            finalAmount: 0
        });

        uint256 projectId = nft.tokenIdCounter();
        projects[projectId] = newProject;

        nft.initProject(uri, unit);
        emit Controller_NewProject(
            totalAmount,
            depositStartTs,
            depositEndTs,
            unit,
            uri
        );
    }

    function deposit(uint256 projectId, uint256 amount)
        external
        payable
        override
    {
        // check
        Project storage project = projects[projectId];
        if (project.depositStartTs == 0) revert NotExistingProject();
        if (block.timestamp < project.depositStartTs)
            revert Deposit_NotStarted();
        if (project.depositEndTs <= block.timestamp) revert Deposit_Ended();
        if (project.currentAmount + amount > project.totalAmount)
            revert Deposit_ExceededTotalAmount();
        if (amount % (10**decimal) != 0)
            revert Deposit_NotDivisibleByDecimals();

        // effect
        projects[projectId].currentAmount += amount;

        // interaction
        if (msg.value != 0) {
            swapExactOutputSingle(amount);
        } else {
            TransferHelper.safeTransferFrom(
                usdc,
                msg.sender,
                address(this),
                amount
            );
        }

        uint256 principal = _calculatePrincipal(amount);
        nft.createLoan(projectId, principal, msg.sender);

        emit Deposited(msg.sender, projectId, amount);
    }

    function borrow(uint256 projectId) external onlyOwner {
        // check
        Project storage project = projects[projectId];
        if (project.depositStartTs == 0) revert NotExistingProject();
        if (
            block.timestamp < project.depositEndTs &&
            project.currentAmount != project.totalAmount
        ) revert Borrow_DepositNotEnded();
        if (project.currentAmount == 0) revert AlreadyBorrowed();

        // effect
        project.totalAmount = project.currentAmount;
        uint256 amount = project.currentAmount;
        project.currentAmount = 0;

        // interaction
        IERC20(usdc).transfer(msg.sender, amount);

        emit Borrowed(msg.sender, projectId, amount);
    }

    function repay(uint256 projectId, uint256 amount)
        external
        override
        onlyOwner
    {
        Project storage project = projects[projectId];
        // check
        if (project.finalAmount != 0) revert Repay_AlreadyDepositted();
        if (project.depositStartTs == 0) revert NotExistingProject();
        if (amount < project.totalAmount) revert Repay_NotEnoughAmountInput();
        if (project.depositEndTs > block.timestamp)
            revert Repay_DepositNotEnded();

        // effect
        project.finalAmount = project.currentAmount = amount;

        // interaction
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);

        emit Repaid(msg.sender, projectId, amount);
    }

    function withdraw(uint256 projectId) external override {
        Project storage project = projects[projectId];
        if (project.depositStartTs == 0) revert NotExistingProject();
        if (project.finalAmount == 0) revert Withdraw_NotRepayedProject();

        uint256 userTokenBalance = nft.balanceOf(msg.sender, projectId);
        uint256 userDollarBalance = _calculateDollarBalance(
            projectId,
            userTokenBalance
        );

        // effect
        // Multiply first to prevent decimal from going down to 0.
        uint256 userBalancePlusInterest = (project.finalAmount *
            userDollarBalance) / project.totalAmount;
        project.currentAmount -= userBalancePlusInterest;

        // interaction
        TransferHelper.safeTransfer(usdc, msg.sender, userBalancePlusInterest);

        nft.redeem(projectId, msg.sender, userTokenBalance);

        emit Withdrawed(msg.sender, projectId, userBalancePlusInterest);
    }

    function _calculatePrincipal(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount / (10**decimal);
    }

    function _calculateDollarBalance(uint256 projectId, uint256 balance)
        internal
        view
        returns (uint256)
    {
        uint256 unit = nft.unit(projectId);

        return balance * unit * (10**decimal);
    }
}