//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./PancakeSwap/IPancakeV2Factory.sol";
import "./PancakeSwap/IPancakeV2Pair.sol";
import "./PancakeSwap/IPancakeV2Router01.sol";
import "./PancakeSwap/IPancakeV2Router02.sol";

import "./DividendDistributor.sol";

contract REKT is ERC20, Ownable, ERC20Burnable {
    using SafeMath for uint256;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 public distributorGas = 500000;
    uint256 public minimumTokenBalanceForDividends = 2000;

/////////////////////////////
    uint256 public totalDividendsDistributed;
    uint256 private constant TOTAL_SUPPLY = 21000000;
    uint256 public minimumBuy             = 1000;

    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    uint256 public swapTokensAtAmount;

    // How the contract balance needs to be allocated
    uint256 private totalReflection_fee;
    uint256 private totalLP_fee;
    uint256 marketing_fee;
    
    address public constant ADMIN_WALLET = 0x4AcBEd6612085d9C20C020468108537193b90C0B;
    address public LP_recipient          = 0xED8b8258fb3ec7458Ecb2d921365686dd5640617;
    address public MARKETING_WALLET      = 0xFcc0E82Ee08CEAA15071415024f42600DFF15Dc7;
    address public WBNB;

    bool public inSwapAndLiquify = false;

    struct feeRatesStruct {
      uint256 reflections;
      uint256 marketingWallet;
      uint256 LP;
      uint256 totalFee;
    }
    
    feeRatesStruct public buyFees = feeRatesStruct(
    { reflections: 100,     //1%
      marketingWallet: 100, //1%
      LP: 100,              //1%
      totalFee: 300         //3%
    });

    feeRatesStruct public sellFees = feeRatesStruct(
    { reflections: 600,     //6%
      marketingWallet: 100, //2%
      LP: 200,              //2%
      totalFee: 1000        //10%
    });

    feeRatesStruct public transferFees = feeRatesStruct(
    { reflections: 0,     //0%
      marketingWallet: 0, //0%
      LP: 100,            //1%
      totalFee: 100       //1%
    });

    uint public PERCENTAGE_MULTIPLIER = 10000;

    //mapping(address => uint256) private _balances;
    mapping (address => bool) public isAutomatedMarketMakerPair;
    mapping (address => bool) public isExcludedFromTxFees;
    mapping (address => bool) isDividendExempt;

    mapping(address => bool) private _excludedFromAntiSniper;

    constructor() ERC20("REKT", "REKT") {
        uint256 _cap = TOTAL_SUPPLY.mul(10**decimals());
        swapTokensAtAmount = TOTAL_SUPPLY.mul(2).div(10**6); // 0.002%

        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet 
        //address _router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // testnet
        
        distributor = new DividendDistributor(_router);
        distributorAddress = address(distributor);

        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(_router); 
        WBNB = _pancakeV2Router.WETH();
        // Create a pancakeswap pair for this new token
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
        .createPair(address(this), WBNB);


        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router; 

        _setAutomatedMarketMakerPair(pancakeV2Pair, true);

        isExcludedFromTxFees[address(this)] = true;
        isExcludedFromTxFees[MARKETING_WALLET] = true;
        isExcludedFromTxFees[ADMIN_WALLET] = true;

        isDividendExempt[pancakeV2Pair] = true;
        isDividendExempt[address(this)] = true;

        _excludedFromAntiSniper[address(this)] = true;
        _excludedFromAntiSniper[pancakeV2Pair] = true;
        _excludedFromAntiSniper[_router] = true;

        transferOwnership(ADMIN_WALLET);    
        _mint(ADMIN_WALLET, _cap);
    }


    modifier antiSniper(address from, address to, address callee){
        uint256 size1;
        uint256 size2;
        uint256 size3;
        assembly {
            size1 := extcodesize(callee)
            size2 := extcodesize(to)
            size3 := extcodesize(from)
        }

        if(!_excludedFromAntiSniper[from]
            && !_excludedFromAntiSniper[to] && !_excludedFromAntiSniper[callee]) {
                require(!(size1 > 0 || size2 > 0 || size3 > 0),"Bag Holder: Sniper Detected");
            }
        _;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function calcPercent(uint amount, uint percentBP) internal view returns (uint) {
        return amount.mul(percentBP).div(PERCENTAGE_MULTIPLIER);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiSniper(sender, recipient, msg.sender) {
        require(sender    != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(balanceOf(sender) >= amount, "BEP20: transfer amount exceeds balance");
        
        if (recipient != owner() && !isAutomatedMarketMakerPair[recipient]) {
            require(balanceOf(recipient) < totalSupply().mul(125).div(10000), "BEP20: user cannot hold more than 1.25% of the total supply");
        }

        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this)).div(1000000000000000000);
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !inSwapAndLiquify &&
            !isAutomatedMarketMakerPair[sender] &&
            sender != owner() &&
            recipient != owner()
        ) {
            inSwapAndLiquify = true;
            swapAndLiquify(totalLP_fee);
            totalLP_fee = 0;

            super._transfer(sender, MARKETING_WALLET, marketing_fee);
            marketing_fee = 0;

            uint256 oldBalance = address(this).balance;
            swapTokensForEth(balanceOf(address(this)));
            uint256 newBalance = address(this).balance;
            try distributor.deposit{value: newBalance.sub(oldBalance)}() {} catch {}
            totalReflection_fee = 0;

            inSwapAndLiquify = false;
        }
        
        uint256 totalContractFee = 0;
        if(!isExcludedFromTxFees[sender] && !isExcludedFromTxFees[recipient]) {
            feeRatesStruct memory appliedFee;

            if(isAutomatedMarketMakerPair[sender]) {
                appliedFee = buyFees;
                require(amount >= minimumBuy.mul(10**decimals()), "Minimum amount of tokens purchased should be 1000");
            } 
            else if(isAutomatedMarketMakerPair[recipient]) { 
                appliedFee = sellFees;
            } 
            else {
                appliedFee = transferFees;
            }

            marketing_fee       += calcPercent(amount, appliedFee.marketingWallet);
            totalReflection_fee += calcPercent(amount, appliedFee.reflections);
            totalLP_fee         += calcPercent(amount, appliedFee.LP);
            totalContractFee     = calcPercent(amount, appliedFee.totalFee);

            super._transfer(sender, address(this), totalContractFee);
        }

        uint256 sendToRecipient = amount.sub(totalContractFee);
        super._transfer(sender, recipient, sendToRecipient);

        if(!isDividendExempt[sender]) {
            setShare(sender);
        }
        if(!isDividendExempt[recipient]) { 
            setShare(recipient);
        }
        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amount);

    }

    function setShare(address _user) internal {
        uint256 balance =  balanceOf(_user);
        if(balance > minimumTokenBalanceForDividends * 10 ** 18) {
            { try distributor.setShare(_user, balance) {} catch {} }
        } 
        else {
            { try distributor.setShare(_user, 0) {} catch {} }
        }
    }

    function swapAndLiquify(uint256 amount) private {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half); // <- this breaks the BNB -> QCONE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LP_recipient,
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeV2Pair, "QCONE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(isAutomatedMarketMakerPair[pair] != value, "QCONE: Automated market maker pair is already set to that value");
        isAutomatedMarketMakerPair[pair] = value;

        if (value) {
            isDividendExempt[pair] = true;
        }
    }

    function setSellFee(uint256 _reflections, uint256 _marketingWallet, uint256 _LP) external onlyOwner{
        sellFees.reflections     = _reflections.mul(100);
        sellFees.marketingWallet = _marketingWallet.mul(100);
        sellFees.LP              = _LP.mul(100);
        sellFees.totalFee        = _reflections.add(_marketingWallet).add(_LP).mul(100);
    }

    function setBuyFee(uint256 _reflections, uint256 _marketingWallet, uint256 _LP) external onlyOwner{
        buyFees.reflections     = _reflections.mul(100);
        buyFees.marketingWallet = _marketingWallet.mul(100);
        buyFees.LP              = _LP.mul(100);
        buyFees.totalFee        = _reflections.add(_marketingWallet).add(_LP).mul(100);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        MARKETING_WALLET = _marketingWallet;
    }

    function setLPRecipient(address _LP_recipient) external onlyOwner {
        LP_recipient = _LP_recipient;
    }

    function excludeFromFees(address _address) external onlyOwner {
        require(!isExcludedFromTxFees[_address], "already excluded");
        isExcludedFromTxFees[_address] = true;
    }

    function includeInFees(address _address) external onlyOwner {
        require(isExcludedFromTxFees[_address], "already included");
        isExcludedFromTxFees[_address] = false;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && !isAutomatedMarketMakerPair[holder]);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas should be less than 750000");
        distributorGas = gas;
    }

    function setExcludedFromAntiSniper(address _account, bool _excluded)public onlyOwner{
        _excludedFromAntiSniper[_account] = _excluded;
    }
    //to receive BNB from pancakeSwapV2Router when swapping
    receive() external payable {}

}