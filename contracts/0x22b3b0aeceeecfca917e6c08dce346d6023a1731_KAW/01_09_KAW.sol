// https://kawaiweb.xyz/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract KAW is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;
    
    struct TradingFees{
        uint256 developmentFee;
        uint256 liquidityFee;
    }

    TradingFees public tradingFees = TradingFees(2,1);    
    uint256 private constant FEE_DENOMINATOR = 100;

    uint256 private immutable SWAPBACK_THRESHOLD;
    uint256 public maxWalletAmount;
    
    IUniswapV2Router01 constant private UNISWAP_V2_ROUTER = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address immutable private WETH = UNISWAP_V2_ROUTER.WETH();
    address immutable private UNISWAP_V2_PAIR;
    
    address payable public feeReceiver = payable(msg.sender);

    bool public tradingOpen;
    bool private inSwap;

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    event TradingFeeUpdate(uint256 indexed newDevelopmentFee, uint256 indexed newLiquidityFee);

    event MaxWalletUpdate(uint256 indexed newMaxWalletAmount);

    event FeeReceiverUpdate(address indexed newFeeReceiver);

    event FeeExclusion(address indexed wallet, bool indexed shouldExclude);

    event Blacklist(address[] indexed wallets, bool indexed shouldBlacklist);

    event TradingOpened();

    event EthDistributionFailure(address indexed targetAddress, uint256 indexed ethAmount);

    event SwapBack(uint256 indexed tokensToDevelopment, uint256 indexed tokensToLiquidity);

    constructor() ERC20("Kawai", "KAW"){
        _approve(address(this), address(UNISWAP_V2_ROUTER), type(uint256).max);

        UNISWAP_V2_PAIR = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
            .createPair(address(this), WETH);

        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;

        _mint(msg.sender, 1_000_000 * 10**decimals());

        maxWalletAmount = 10 * totalSupply() / 100;
        SWAPBACK_THRESHOLD = 1 * totalSupply() / 2000;
    }

    receive() external payable {}

    function setFees(uint256 newDevelopmentFeeProcent, uint256 newLiquidityFeeProcent) external onlyOwner {
        require(newDevelopmentFeeProcent + newLiquidityFeeProcent <= 10, 
            "TOKEN: total fees may not exceed 10 procent");
        tradingFees.developmentFee = newDevelopmentFeeProcent;
        tradingFees.liquidityFee = newLiquidityFeeProcent;

        emit TradingFeeUpdate(newDevelopmentFeeProcent, newLiquidityFeeProcent);
    }

    function setMaxWallet(uint256 newMaxWalletPermille) external onlyOwner {
        require(newMaxWalletPermille >= 20, 
            "TOKEN: max wallet may not subceed 20 promille");
        maxWalletAmount = newMaxWalletPermille * totalSupply() / 1_000;

        emit MaxWalletUpdate(maxWalletAmount / 10**decimals());
    }

    function setFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), 
            "TOKEN: fee receiver cannot be the zero address");
        require(newFeeReceiver != feeReceiver, 
            "TOKEN: fee receiver already {newFeeReceiver}");
        feeReceiver = newFeeReceiver;

        emit FeeReceiverUpdate(newFeeReceiver);
    }

    function excludeFromFees(address wallet, bool shouldExclude) external onlyOwner {
        require(isExcludedFromFees[wallet] != shouldExclude, 
            "TOKEN: wallet already {shouldExclude}");
        isExcludedFromFees[wallet] = shouldExclude;

        emit FeeExclusion(wallet, shouldExclude);
    }

    function blacklist(address[] calldata wallets, bool shouldBlacklist) external onlyOwner {
        for(uint256 i = 0;i<wallets.length;i++){
            require(wallets[i] != UNISWAP_V2_PAIR && 
                wallets[i] != address(UNISWAP_V2_ROUTER) && 
                wallets[i] != address(this) && 
                !isExcludedFromFees[wallets[i]], 
                    "TOKEN: invalid blacklist");
            isBlacklisted[wallets[i]] = shouldBlacklist;
        }
        emit Blacklist(wallets, shouldBlacklist);
    }

    function openTrading() external onlyOwner {
        require(tradingOpen == false, 
            "TOKEN: trading already open");
        tradingOpen = true;

        emit TradingOpened();
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        require(isBlacklisted[from] == false,
             "TOKEN: blacklisted");
        require(tradingOpen == true || isExcludedFromFees[from] || isExcludedFromFees[to], 
            "TOKEN: trading closed");                    
    }

    function _transfer(address from, address to, uint256 amount) internal override  {
        maxWalletCheck(to, amount);

        if(!isExcludedFromFees[from] && !isExcludedFromFees[to]){            
            if(shouldSwapBack(to))
                swapBack();

            uint256 feeAmount = calculateFees(from, to, amount);
            if(feeAmount > 0){
                super._transfer(from, address(this), feeAmount);    
                amount -= feeAmount;
            }
        }
        super._transfer(from, to, amount);    
    }

    function maxWalletCheck(address to, uint256 amount) private view {
        require(amount + balanceOf(to) <= maxWalletAmount || 
            to == UNISWAP_V2_PAIR || isExcludedFromFees[to], 
            "TOKEN: max wallet restriction");
    }

    function shouldSwapBack(address to) private view returns (bool) {
        return to == UNISWAP_V2_PAIR && inSwap == false && 
            balanceOf(address(this)) >= SWAPBACK_THRESHOLD;
    }

    function swapBack() private swapping {
        uint256 tokensToSwap = SWAPBACK_THRESHOLD * tradingFees.developmentFee / 
            ((tradingFees.developmentFee + tradingFees.liquidityFee) == 0 ? 1 : 
            (tradingFees.developmentFee + tradingFees.liquidityFee));
        uint256 tokensToLiquidity = SWAPBACK_THRESHOLD - tokensToSwap;
        
        if(tokensToSwap > 0){
            address[] memory pathSell = new address[](2);
            pathSell[0] = address(this);
            pathSell[1] = WETH;

            try UNISWAP_V2_ROUTER.swapExactTokensForETH(
                tokensToSwap, 
                0, 
                pathSell, 
                address(this), 
                block.timestamp){}
            catch { return; }

            (bool success) = feeReceiver.send(address(this).balance); 
            if(!success)
                emit EthDistributionFailure(feeReceiver, address(this).balance);
        }

        if(tokensToLiquidity > 0)
            super._transfer(address(this), UNISWAP_V2_PAIR, tokensToLiquidity);

        emit SwapBack(tokensToSwap, tokensToLiquidity);
    }

    function calculateFees(address from, address to, uint256 amount) private view returns (uint256) {
        if(from != UNISWAP_V2_PAIR && to != UNISWAP_V2_PAIR)
            return 0;
        else 
            return amount * (tradingFees.developmentFee + tradingFees.liquidityFee) / FEE_DENOMINATOR;
    }
}