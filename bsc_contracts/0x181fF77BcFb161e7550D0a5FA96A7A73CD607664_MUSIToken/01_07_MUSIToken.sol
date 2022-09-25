// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20/IERC20.sol";
import "./ERC20/extensions/IERC20Metadata.sol";
import "./ERC20/utils/Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract MUSIToken {
    using SafeMath for uint256;
    using Address for address payable;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address public _owner;
    address public marketing;
    address public development;
    address public burn = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Music1 Token";
    string private _symbol = "MUSI";
    uint8 private _decimals = 18;

    uint256 public __reflectFee = 20;
    uint256 public __marketingFee = 20;
    uint256 public __developmentFee = 20;
    uint256 public __burnFee = 10;
    uint256 public __liquidityFee = 30;
    uint256 public feeTax = 10;

    uint256 public immutable contract_deployed;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // uint256 public _maxWalletHolding = 25 * 10**12 * 10**9;
    // uint256 private numTokensSellToAddToLiquidity = 9 * 10**12 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(
        address payable _marketing,
        address payable _development,
        address router
    ) {
        _owner = msg.sender;
        marketing = _marketing;
        development = _development;
        contract_deployed = block.timestamp;
        _rOwned[msg.sender] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function addExcludedFromFee (address _user) public onlyOwner {
        _isExcludedFromFee[_user] = true;
    }

    function removeExcludedFromFee (address _user) public onlyOwner {
        _isExcludedFromFee[_user] = false;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function setFeeTax(uint256 feeTax_) public onlyOwner {
        require(feeTax_ <= 15, "FeeTax must be less than 15");
        feeTax = feeTax_;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
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

    //to receive ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256[2] memory tValues = _getTValuesArray(tAmount);
        uint256 currentRate = _getRate();
        uint256[2] memory rValues = _getRValuesArray(
            tAmount,
            tValues[1],
            currentRate
        );
        return (rValues[0], rValues[1], tValues[0], tValues[1]);
    }

    function _getTValuesArray(uint256 tAmount)
        private
        view
        returns (uint256[2] memory val)
    {
        uint256 tFeeTax = tAmount.mul(feeTax).div(10**2);
        uint256 tTransferAmount = tAmount.sub(tFeeTax);

        return [tTransferAmount, tFeeTax];
    }

    function _getRValuesArray(
        uint256 tAmount,
        uint256 tFeeTax,
        uint256 currentRate
    ) private pure returns (uint256[2] memory val) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(tFeeTax.mul(currentRate));
        return [rAmount, rTransferAmount];
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeFeeTax(uint256 tFeeTax) private returns (uint256, uint256) {
        if (feeTax == 0) return (0, 0);
        uint256 currentRate = _getRate();
        // fee for liquidity
        uint256 tLiquidity = tFeeTax.mul(__liquidityFee).div(10**2);
        _rOwned[uniswapV2Pair] = _rOwned[uniswapV2Pair].add(
            tLiquidity.mul(currentRate)
        );
        // fee for marketing
        uint256 tMarketting = tFeeTax.mul(__marketingFee).div(10**2);
        _rOwned[marketing] = _rOwned[marketing].add(
            tMarketting.mul(currentRate)
        );
        uint256 tOerpators = tLiquidity.add(tMarketting);
        // fee for development
        uint256 tDevelopment = tFeeTax.mul(__developmentFee).div(10**2);
        _rOwned[development] = _rOwned[development].add(
            tDevelopment.mul(currentRate)
        );
        tOerpators = tOerpators.add(tDevelopment);
        // fee for burn
        uint256 tBurn = tFeeTax.mul(__burnFee).div(10**2);
        _rOwned[burn] = _rOwned[burn].add(tBurn.mul(currentRate));
        tOerpators = tOerpators.add(tBurn);
        uint256 tFee = tFeeTax.sub(tOerpators);
        uint256 rFee = tFee.mul(currentRate);
        return (tFee, rFee);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
        // if ((contract_deployed + 30 days) < block.timestamp) {
        //     __liquidityFee = 0;
        // }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        bool isTransferBuy = from == uniswapV2Pair;
        bool isTransferSell = to == uniswapV2Pair;
        if (!isTransferBuy && !isTransferSell) takeFee = false;

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        _transferStandard(sender, recipient, amount, takeFee);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tFeeTax
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (takeFee) {
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            (uint256 tFee, uint256 rFee) = _takeFeeTax(tFeeTax);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        }
        
    }
}