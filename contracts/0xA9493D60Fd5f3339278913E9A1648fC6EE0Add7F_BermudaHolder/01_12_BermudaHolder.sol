// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UniswapV2Interfaces.sol";
import "./IBermuda.sol";
import "./IWETH.sol";
import "./Cycled.sol";

contract BermudaHolder is Cycled, ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    //Immutable
    IUniswapV2Router02 public immutable uniswapV2Router;

    //Public variables
    mapping(address => bool) public tokenApproved;

    //These two are never subtracted, only added. A different interface will keep track of subtracted amounts.
    //[tokenAddress][userAddress]
    mapping(address => mapping (address => uint256)) public balanceIn;
    //[userAddress]
    //mapping(address => uint256) public gasBalanceIn; //Prepaying gas not supported anymore.

    //[tokenAddress], should only be used for recoverLostTokens.
    mapping(address => uint256) public totalBalance;

    mapping(address => bool) public depositBlacklist;
    mapping(address => bool) public sendBlacklist;

    uint256 public requiredBMDAForDeposit;
    IWETH public WETH;
    IBermuda public BMDA;
    //No longer needed as we get this from the BMDA contract
    //address feeWallet;

    //Events
    event Deposit(address indexed sender, address indexed token, uint256 amount);

    //Constructor
    constructor(IBermuda bmda, uint256 initialRequiredForDeposit)
    {
        BMDA = bmda;
        uniswapV2Router = bmda.uniswapV2Router();
        WETH = IWETH(uniswapV2Router.WETH());
        requiredBMDAForDeposit = initialRequiredForDeposit; //For beta testers.
        //feeWallet = wallet;
    }

    //Internal Functions
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BermudaHolder: EXPIRED');
        _;
    }
    function buybackAndBurnBMDA(IERC20 token, uint256 amount) internal
    {
        if(amount == 0) return;
        //Generate path
        address[] memory path;
        uint256 length;
        if(address(token) == address(WETH))
        {
            length = 2;
            path = new address[](length);
            path[0] = address(token);
            path[1] = address(BMDA);
        }
        else
        {
            length = 3;
            path = new address[](length);
            path[0] = address(token);
            path[1] = address(WETH);
            path[2] = address(BMDA);
        }
        uint256 bmdaBefore = BMDA.balanceOf(address(this));
        token.approve(address(uniswapV2Router), 0); //For weird tokens/USDT/race conditions. This should never be needed, but better safe than sorry. Gas shouldn't increase by much.
        token.approve(address(uniswapV2Router), amount);
        //Swap, covering even transfer fee tokens (just in case).
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, //Full slippage
            path,
            address(this),
            block.timestamp
        );

        //Burn whatever we've gotten.
        uint256 burnAmount = BMDA.balanceOf(address(this)) - bmdaBefore;
        if(burnAmount > 0) BMDA.burn(burnAmount);
    }

    function swapToETH(IERC20 token, address payable to, uint256 amount) internal
    {
        if(amount == 0) return;
        if(address(token) == address(0))
        {
            to.transfer(amount);
            return;
        }
        if(address(token) == address(WETH))
        {
            WETH.withdraw(amount);
            to.transfer(amount);
            return;
        }
        //Generate path
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WETH);
        token.approve(address(uniswapV2Router), 0); //For weird tokens/USDT/race conditions. This should never be needed, but better safe than sorry. Gas shouldn't increase by much.
        token.approve(address(uniswapV2Router), amount);
        //Swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            1, //Almost full slippage. Error out if unswappable (aka 0).
            path,
            to,
            block.timestamp
        );
    }

    //0 == ETH
    function swapTo(IERC20 token, address payable to, uint256 amount, IERC20 dest, uint256 amountMin, uint256 timestamp) internal ensure(timestamp)
    {
        if(amount == 0) return;
        if(address(token) == address(dest))
        {
            if(address(token) == address(0)) to.transfer(amount);
            else token.safeTransfer(to, amount);
            return;
        }
        if(address(dest) == address(0) && address(token) == address(WETH))
        {
            WETH.withdraw(amount);
            to.transfer(amount);
            return;
        }
        else if(address(dest) == address(WETH) && address(token) == address(0))
        {
            WETH.deposit{value: amount}();
            WETH.safeTransfer(to, amount);
            return;
        }
        //Generate path
        address[] memory path;
        uint256 length;
        if(address(token) == address(WETH) || address(dest) == address(WETH) || address(token) == address(0) || address(dest) == address(0))
        {
            length = 2;
            path = new address[](length);
            path[0] = address(token) == address(0) ? address(WETH) : address(token);
            path[1] = address(dest) == address(0) ? address(WETH) : address(dest);
        }
        else
        {
            length = 3;
            path = new address[](length);
            path[0] = address(token) == address(0) ? address(WETH) : address(token);
            path[1] = address(WETH);
            path[2] = address(dest) == address(0) ? address(WETH) : address(dest);
        }
        //Swap ETH
        if(address(dest) == address(0))
        {
            token.approve(address(uniswapV2Router), 0); //For weird tokens/USDT/race conditions. This should never be needed, but better safe than sorry. Gas shouldn't increase by much.
            token.approve(address(uniswapV2Router), amount);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                amountMin,
                path,
                to,
                timestamp
            );
            return;
        }
        //Swap to ETH
        if(address(token) == address(0))
        {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                amountMin,
                path,
                to,
                timestamp
            );
            return;
        }
        //Swap two tokens
        token.approve(address(uniswapV2Router), 0); //For weird tokens/USDT/race conditions. This should never be needed, but better safe than sorry. Gas shouldn't increase by much.
        token.approve(address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            amountMin,
            path,
            to,
            timestamp
        );
    }

    //External Functions
    receive() external payable {
        //Still required for WETH withdraw.
        require(msg.sender == address(WETH), "Only WETH may deposit ETH.");
        //gasBalanceIn[msg.sender] += msg.value;
    }

    function deposit(IERC20 token, uint256 amount) external nonReentrant {
        require(!depositBlacklist[msg.sender], "Blacklisted.");
        require(BMDA.balanceOf(msg.sender) >= requiredBMDAForDeposit, "Not enough BMDA required to deposit!");
        require(address(token) == address(WETH) || address(token) != address(0) && tokenApproved[address(token)], "Token not authorized.");
        //External needs to be called first to support some tokens with tax, so this should be nonReentrant.
        uint256 oldBalance = token.balanceOf(address(this));

        token.safeTransferFrom(msg.sender, address(this), amount);
        amount = token.balanceOf(address(this)) - oldBalance;

        balanceIn[address(token)][msg.sender] += amount;
        totalBalance[address(token)] += amount;
        emit Deposit(msg.sender, address(token), amount);
    }

    function depositETH() external payable {
        require(!depositBlacklist[msg.sender], "Blacklisted.");
        require(BMDA.balanceOf(msg.sender) >= requiredBMDAForDeposit, "Not enough BMDA required to deposit!");
        balanceIn[address(WETH)][msg.sender] += msg.value;
        totalBalance[address(WETH)] += msg.value;
        WETH.deposit{ value: msg.value }();
        emit Deposit(msg.sender, address(WETH), msg.value);
    }

    //Admin Functions
    //Authorized should be a secured EOA distributor controlled by a bot, or it should be a valid smart contract.
    //We may want multiple bots to handle multiple requests at a time, and so we set this to onlyCycledAuthorized.
    //We might want to also cycle which authorized is able to make the call,
    //which would have better security as well as fix the multiple request issue.
    function sendTo(address payTo, IERC20 token, uint256 amount, uint256 gas, uint256 fee, uint256 burn, IERC20 toToken, uint256 amountOutMin, uint256 deadline) external onlyCycledAuthorized {
        require(!sendBlacklist[payTo], "Recipient blacklisted.");
        require(address(token) == address(WETH) || address(token) != address(0) && tokenApproved[address(token)], "Token not authorized.");
        require(address(toToken) == address(WETH) || address(toToken) == address(0) || tokenApproved[address(toToken)], "To token not authorized.");
        require(amount > 0, "Cannot send nothing.");
        uint256 maxFeeAndBurn = amount / 10;
        if(maxFeeAndBurn == 0) maxFeeAndBurn = 1; //Allow eating of small values to prevent system-gaming.
        require(fee + burn <= maxFeeAndBurn, "Total fee minus gas must be <= 10% of amount.");
        //This won't work. Unfortunately, gas might be really high compared to the transaction amount.
        //uint256 maxGas = amount / 4;
        //require(gas <= maxGas, "Gas must be <= 25% of amount.");
        require(gas < (amount - fee - burn), "Gas not be the entire amount.");

        uint256 oldBalance = token.balanceOf(address(this));
        totalBalance[address(token)] -= amount; //Keep track for recoverLostTokens. This amount is kept track of in good-faith!

        swapTo(token, payable(payTo), amount - gas - fee - burn, toToken, amountOutMin, deadline);
        swapToETH(token, payable(msg.sender), gas);
        swapToETH(token, payable(BMDA.devWallet()), fee);

        if(address(token) == address(BMDA))
        {
            if(burn > 0) BMDA.burn(burn);
        }
        else
        {
            buybackAndBurnBMDA(token, burn);
        }

        //Tokens taking more or less than they are supposed to is not supported.
        require(amount == (oldBalance - token.balanceOf(address(this))), "BermudaHolder: K");
    }

    function sendETHTo(address payable payTo, uint256 amount, uint256 gas, uint256 fee, uint256 burn, IERC20 toToken, uint256 amountOutMin, uint256 deadline) external onlyCycledAuthorized {
        require(!sendBlacklist[payTo], "Blacklisted.");
        require(address(toToken) == address(WETH) || address(toToken) == address(0) || tokenApproved[address(toToken)], "To token not authorized.");
        require(amount > 0, "Cannot send nothing.");
        uint256 maxFeeAndBurn = amount / 10;
        if(maxFeeAndBurn == 0) maxFeeAndBurn = 1; //Allow eating of small values to prevent system-gaming.
        require(fee + burn <= maxFeeAndBurn, "Fee must be <= 10% of amount.");
        //This won't work. Unfortunately, gas might be really high compared to the transaction amount.
        //uint256 maxGas = amount / 4;
        //require(gas <= maxGas, "Gas must be <= 25% of amount.");
        require(gas < (amount - fee - burn), "Gas not be the entire amount.");

        totalBalance[address(WETH)] -= amount; //Keep track for recoverLostTokens. This amount is kept track of in good-faith!

        WETH.withdraw(amount - burn); //Buyback will be done with WETH instead of ETH for consistency.
        swapTo(IERC20(address(0)), payable(payTo), amount - gas - fee - burn, toToken, amountOutMin, deadline);
        payable(msg.sender).transfer(gas);
        payable(BMDA.devWallet()).transfer(fee);

        buybackAndBurnBMDA(WETH, burn);
    }

    function setTokenApproved(address token, bool approval) external onlyOwner
    {
        tokenApproved[token] = approval;
    }

      //No longer needed as we get this from the BMDA contract
//    function setFeeWallet(address wallet) external onlyOwner
//    {
//        feeWallet = wallet;
//    }

    function setBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        depositBlacklist[wallet] = blacklisted;
        sendBlacklist[wallet] = blacklisted;
    }

    function setDepositBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        depositBlacklist[wallet] = blacklisted;
    }

    function setSendBlacklist(address wallet, bool blacklisted) external onlyOwner
    {
        sendBlacklist[wallet] = blacklisted;
    }

    function setRequiredBMDAForDeposit(uint256 amount) external onlyOwner
    {
        requiredBMDAForDeposit = amount;
    }

    function recoverLostTokens(IERC20 token, uint256 amount, address to) external onlyOwner
    {
        //Careful! If you transfer an unknown token, it may be malicious.
        //No longer needed as transferring ETH should no longer be possible.
        //However, just in case it somehow lingers, this line remains.
        if(address(token) == address(0))
        {
            //ETH fallback. ETH is never stored (outside of a function) purposefully, so no checks need to be done here.
            payable(to).transfer(amount);
            return;
        }
        require(amount <= (token.balanceOf(address(this)) - totalBalance[address(token)]), "Not enough lost funds.");
        //We cannot recover tokens that have been deposited normally (in good-faith).
        token.safeTransfer(to, amount); //sendTo does this too, but it cannot transfer non-approved tokens.
    }
}