/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

/**

🔔🔔🔔 **提醒 Reminder** 🔔🔔🔔

🇨🇳 **请注意，我们并没有任何一个官方社群。BIBI 2.0 从一开始就是社区自治，任何人都可以创建关于 BIBI 2.0 的推特、电报、网站等。请大家谨慎判断，避免上当受骗。**

🇬🇧 **Please note that we do not have any official community groups. BIBI 2.0 is community-governed from the very beginning, and anyone can create Twitter accounts, Telegram groups, websites, etc., related to BIBI 2.0. Please exercise caution and avoid falling for scams.**

https://t.me/Bibi2Portal

🚀🚀🚀 **BIBI 2.0: A New Chapter, Co-creating Brilliance!** 🚀🚀🚀

Dear BIBI community members, we are thrilled to announce the birth of BIBI 2.0! This is a significant milestone, signifying the evolution of BIBI into a brand new phase. After careful consideration, we are introducing a series of changes and innovations.

💡 **Core Features and Highlights of BIBI 2.0:** 💡

1. **Chain Migration**: BIBI 2.0 will be launched on the Ethereum (ETH) blockchain, introducing the project to a broader ecosystem and endless possibilities.

2. **Strong Opening**: BIBI 2.0’s initial liquidity pool will open with 10 ETH, providing a solid foundation for the project to start.

3. **Purchase Limit for Fairness**: Each user’s purchase limit at the opening will be 0.5% of the total supply to ensure risk diversification and fairness.

4. **Automatic Tax Reduction Mechanism**: The initial tax rate will be 17%, and will gradually decrease automatically over time to 1%, to incentivize holding and long-term investment.

5. **CEX Listing and Rewards**: A portion of the tokens will be reserved for listing on centralized exchanges (CEX) and as rewards airdropped to the BIBI community admins.

6. **Greater Decentralization and Community Governance**: BIBI 2.0 will be a fully decentralized project, with no founders, no official website, no official Twitter, and not even an official Telegram group. All decisions and actions will be fully participated in and decided upon by community members through decentralized means.

We have firm faith in the power and wisdom of the community. Through thorough decentralization and community governance, BIBI 2.0 will create a brand new chapter, collectively shaping the future of the project.

Let’s commit ourselves to build a fair, transparent, and vibrant community to lay a solid foundation for the success of BIBI 2.0.

🌟 **BIBI 2.0 is with you, let’s co-create brilliance!** 🌟

Warm regards,
BIBI Team

🚀🚀🚀 **BIBI 2.0：全新篇章，共创辉煌！** 🚀🚀🚀

各位BIBI社区的成员们，我们欣喜地宣布BIBI 2.0的诞生！这是一个重大的里程碑，意味着BIBI进化到了一个全新的阶段。经过深思熟虑，我们带来了一系列的变革和创新。

💡 **BIBI 2.0 的核心特点和亮点：** 💡

1. **链上迁移**：BIBI 2.0 将在以太坊链（ETH）上发射，为项目引入更广泛的生态系统和更多的可能性。

2. **开盘强劲**：BIBI 2.0 的初始流动性池将以 10 ETH 开盘，为项目提供坚实的起步基础。

3. **限购保障公平**：每位用户在开盘时的购买上限为总量的 0.5%，以保证分散风险和公平性。

4. **自动降税机制**：初始税率为 17%，并将随着时间的推移自动逐渐降低至 1%，以激励持有和长期投资。

5. **CEX上线和奖励**：部分代币将预留，用于上线中心化交易所（CEX）以及作为奖励空投给BIBI社区的管理员们。

6. **更加去中心化与社区自治**：BIBI 2.0将是一个完全去中心化的项目，没有发起人，没有官方网站，没有官方推特，甚至没有官方电报群。一切决策和动作将完全由社区成员通过去中心化方式共同参与和决策。

我们坚信社区的力量和智慧。BIBI 2.0通过彻底的去中心化和社区自治，将开创一个全新的篇章，共同塑造项目的未来。

让我们共同致力于创建一个公正、透明和充满活力的社区，为BIBI 2.0的成功奠定坚实的基础。

🌟 **BIBI 2.0与您同在，共创辉煌！** 🌟

BIBI 团队敬上

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract BIBI20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;
    uint256 firstBlock;

    uint256 private _initialBuyTax=17;
    uint256 private _initialSellTax=17;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=25;
    uint256 private _reduceSellTaxAt=30;
    uint256 private _preventSwapBefore=25;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 4206900000000000 * 10**_decimals;
    string private constant _name = unicode"Bibi 2.0";
    string private constant _symbol = unicode"BIBI2.0";
    uint256 public _maxTxAmount =      21034500000000 * 10**_decimals;
    uint256 public _maxWalletSize =    21034500000000 * 10**_decimals;
    uint256 public _taxSwapThreshold=  4200000000000 * 10**_decimals;
    uint256 public _maxTaxSwap=        4200000000000 * 10**_decimals;

    address payable private _developmentAddress = payable(msg. sender);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {

        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

                if (firstBlock + 3  > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }

            if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;        
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function removeERC20(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(0)){
            payable(_developmentAddress).transfer(amount);
        }else{
            IERC20(tokenAddress).transfer(_developmentAddress, amount);
        }
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
}