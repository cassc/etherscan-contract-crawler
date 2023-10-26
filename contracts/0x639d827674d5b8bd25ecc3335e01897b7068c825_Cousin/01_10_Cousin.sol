// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Cousin is Context, IERC20, Ownable
{
    using SafeMath for uint;
    using Address for address;

    string public name = "Cousin";
    string public symbol = "CUZ";

    uint public decimals = 18;
    uint public totalSupply = 1000000000 * 10 ** decimals;

    uint public swapThresholdMin = totalSupply / 100000;
    uint public swapThresholdMax = totalSupply / 2000;

    address public dexPair;
    IUniswapV2Router02 public dexRouter;

    address payable public marketingAddress;

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowances;

    mapping (address => bool) private isBot;
    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) public isMarketPair;

    struct Fees
    {
        uint inFee;
        uint outFee;
        uint transferFee;
    }

    Fees public fees;

    bool public renounceAntiBot;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public swapAndLiquifyByLimitOnly;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint tokensSwapped, uint ethReceived, uint tokensIntoLiqudity);
    event SwapETHForTokens(uint amountIn, address[] path);
    event SwapTokensForETH(uint amountIn, address[] path);

    modifier lockTheSwap
    {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _marketing) Ownable(_msgSender())
    {
        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        allowances[address(this)][address(dexRouter)] = totalSupply;

        marketingAddress = payable(_marketing);

        fees.inFee = 20;
        fees.outFee = 20;
        fees.transferFee = 0;

        swapAndLiquifyEnabled = true;
        swapAndLiquifyByLimitOnly = true;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(0)] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingAddress] = true;

        isMarketPair[address(dexPair)] = true;

        balances[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function balanceOf(address wallet) public view override returns (uint256)
    {
        return balances[wallet];
    }

    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return allowances[owner][spender];
    }

    function getCirculatingSupply() public view returns (uint256)
    {
        return totalSupply.sub(balanceOf(address(0)));
    }

    function setMarketingAddress(address wallet) external onlyOwner()
    {
        require(wallet != address(0), "ERROR: Wallet must not be null address!");
        require(wallet != marketingAddress, "ERROR: Wallet must not be existing address!");

        isFeeExempt[marketingAddress] = false;

        marketingAddress = payable(wallet);
        isFeeExempt[marketingAddress] = true;
    }

    function setMarketPairStatus(address wallet, bool status) public onlyOwner
    {
        isMarketPair[wallet] = status;
    }

    function renounceBotStatus() public onlyOwner
    {
        require(!renounceAntiBot, "ERROR: Anti-bot system is already renounced!");

        renounceAntiBot = true;
    }

    function setBotStatus(address[] memory wallets, bool status) public onlyOwner
    {
        require(!renounceAntiBot, "ERROR: Anti-bot system is permanently disabled!");
        require(wallets.length <= 200, "ERROR: Maximum wallets at once is 200!");

        for (uint i = 0; i < wallets.length; i++)
            isBot[wallets[i]] = status;
    }

    function setFees(uint inFee, uint outFee, uint transferFee) external onlyOwner()
    {
        require(inFee <= 20 && outFee <= 20 && transferFee <= 20, "ERROR: Maximum directional fee is 2%!");

        fees.inFee = inFee;
        fees.outFee = outFee;
        fees.transferFee = transferFee;
    }

    function setSwapThresholds(uint min, uint max) external onlyOwner()
    {
        swapThresholdMin = min;
        swapThresholdMax = max;
    }

    function setSwapAndLiquifyStatus(bool status) public onlyOwner
    {
        swapAndLiquifyEnabled = status;
        emit SwapAndLiquifyEnabledUpdated(status);
    }

    function setSwapAndLiquifyByLimitStatus(bool status) public onlyOwner
    {
        swapAndLiquifyByLimitOnly = status;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].sub(subtractedValue, "ERROR: Decreased allowance below zero!"));
        return true;
    }

    function approve(address spender, uint amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private
    {
        require(owner != address(0), "ERROR: Approve from the zero address!");
        require(spender != address(0), "ERROR: Approve to the zero address!");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferToAddressNative(address payable recipient, uint amount) private
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");

        recipient.transfer(amount);
    }

    function transfer(address recipient, uint amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "ERROR: Transfer amount exceeds allowance!"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) private returns (bool)
    {
        require(sender != address(0), "ERROR: Transfer from the zero address!");
        require(recipient != address(0), "ERROR: Transfer to the zero address!");
        require(!isBot[recipient] && !isBot[sender], "ERROR: Transfers are not permitted!");

        if (inSwapAndLiquify)
        {
            balances[sender] = balances[sender].sub(amount, "ERROR: Insufficient balance!");
            balances[recipient] = balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
            return true;
        }
        else
        {
            uint contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance >= swapThresholdMin && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled)
            {
                if (swapAndLiquifyByLimitOnly)
                    contractTokenBalance = contractTokenBalance > swapThresholdMax ? swapThresholdMax : contractTokenBalance;

                swapAndLiquify(contractTokenBalance);
            }

            balances[sender] = balances[sender].sub(amount, "ERROR: Insufficient balance!");

            uint finalAmount = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, recipient, amount);
            balances[recipient] = balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function swapAndLiquify(uint amount) private lockTheSwap
    {
        swapTokensForNative(amount);
        transferToAddressNative(marketingAddress, address(this).balance);
    }

    function takeFee(address sender, address recipient, uint amount) internal returns (uint256)
    {
        uint feeAmount = 0;

        if (isMarketPair[sender])
            feeAmount = amount.mul(fees.inFee).div(1000);
        else if (isMarketPair[recipient])
            feeAmount = amount.mul(fees.outFee).div(1000);
        else
            feeAmount = amount.mul(fees.transferFee).div(1000);

        if (feeAmount > 0)
        {
            balances[address(this)] = balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function swapTokensForNative(uint tokenAmount) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function withdrawStuckNative(address recipient, uint amount) public onlyOwner
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");

        payable(recipient).transfer(amount);
    }

    function withdrawForeignToken(address tokenAddress, address recipient, uint amount) public onlyOwner
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");

        IERC20(tokenAddress).transfer(recipient, amount);
    }

    receive() external payable {}
}