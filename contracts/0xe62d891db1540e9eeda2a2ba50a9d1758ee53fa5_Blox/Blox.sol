/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

/**

 *0xBLOX*

*/



// SPDX-License-Identifier: MIT



pragma solidity 0.8.16;



abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {

        return payable(msg.sender);

    }



    function _msgData() internal view virtual returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}



abstract contract Ownable is Context {

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



    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}



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

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



library Address {

    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // solhint-disable-next-line no-inline-assembly

        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);

    }



    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }



    function functionCall(address target, bytes memory data) internal returns (bytes memory) {

      return functionCall(target, data, "Address: low-level call failed");

    }



    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }



    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {

        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }



    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {

        require(address(this).balance >= value, "Address: insufficient balance for call");

        return _functionCallWithValue(target, data, value, errorMessage);

    }



    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {

        require(isContract(target), "Address: call to non-contract");



        // solhint-disable-next-line avoid-low-level-calls

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);

        if (success) {

            return returndata;

        } else {

            // Look for revert reason and bubble it up if present

            if (returndata.length > 0) {

                // The easiest way to bubble the revert reason is using memory via assembly



                // solhint-disable-next-line no-inline-assembly

                assembly {

                    let returndata_size := mload(returndata)

                    revert(add(32, returndata), returndata_size)

                }

            } else {

                revert(errorMessage);

            }

        }

    }

}



interface IUniswapV2Factory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);



    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);



    function createPair(address tokenA, address tokenB) external returns (address pair);



    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

}



interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);



    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);



    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);



    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);



    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;



    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    event Swap(

        address indexed sender,

        uint amount0In,

        uint amount1In,

        uint amount0Out,

        uint amount1Out,

        address indexed to

    );

    event Sync(uint112 reserve0, uint112 reserve1);



    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);



    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;



    function initialize(address, address) external;

}



interface IUniswapV2Router01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);



    function addLiquidity(

        address tokenA,

        address tokenB,

        uint amountADesired,

        uint amountBDesired,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(

        address token,

        uint amountTokenDesired,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(

        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(

        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(

        uint amountOut,

        uint amountInMax,

        address[] calldata path,

        address to,

        uint deadline

    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        external

        payable

        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)

        external

        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)

        external

        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)

        external

        payable

        returns (uint[] memory amounts);



    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}



interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountETH);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

}



contract Blox is Context, IERC20, Ownable {

    using Address for address;



    mapping (address => uint256) private _rOwned;

    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;



    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private _isExcluded;

    address[] private _excluded;



    string private _name     = "Blox";

    string private _symbol   = "BLOX";  

    uint8  private _decimals = 9;

   

    uint256 private constant MAX = type(uint256).max;

    uint256 private _tTotal = 30_000_000 * (10 ** _decimals);

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;



    uint256 public taxFee = 1;

    uint256 private _previousTaxFee = taxFee;

    

    uint256 public burnFee = 0;

    uint256 private _previousburnFee = burnFee;



    uint256 public bloxTeamFee = 1;

    uint256 private _previousbloxTeamFee = bloxTeamFee;



    uint256 public marketingFee = 0;

    uint256 private _previousMarketingFee = marketingFee;



    uint256 public foundationFee = 0;

    uint256 private _previousfoundationFee = foundationFee;



    uint256 public totalFees = taxFee + burnFee + marketingFee + foundationFee + bloxTeamFee;



    address public marketingWallet = 0x000000000000000000000000000000000000dEaD;

    address public foundationWallet = 0x000000000000000000000000000000000000dEaD;

    address public burnWallet = 0x000000000000000000000000000000000000dEaD;

    address public bloxTeamWallet = 0xDab9277349A7567fD1397f924C51dc3B0eedb243;    



    bool public walletToWalletTransferWithoutFee = true;

    

    address private DEAD = 0x000000000000000000000000000000000000dEaD;



    IUniswapV2Router02 public  uniswapV2Router;

    address public  uniswapV2Pair;



    bool private inSwapAndLiquify;

    bool public swapEnabled = true;

    uint256 public swapTokensAtAmount = _tTotal / 20000;

    

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event MarketingWalletChanged(address marketingWallet);

    event foundationWalletChanged(address foundationWallet);

    event burnWalletChanged(address burnWallet);

    event bloxTeamWalletChanged(address bloxTeamWallet);

    event SwapEnabledUpdated(bool enabled);

    event SendMarketing(uint256 bnbSend);

    event Sendfoundation(uint256 bnbSend);

    event Sendburn(uint256 bnbSend);

    event SendCharity(uint256 bnbSend);

    

    constructor() 

    { 

        address newOwner = 0x171cAD126a9360cc093e38902223bC678736c357;

        transferOwnership(newOwner);



        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())

            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;



        _approve(address(this), address(uniswapV2Router), MAX);



        _isExcludedFromFees[owner()] = true;

        _isExcludedFromFees[marketingWallet] = true;

        _isExcludedFromFees[foundationWallet] = true;

        _isExcludedFromFees[burnWallet] = true;

        _isExcludedFromFees[bloxTeamWallet] = true;

        _isExcludedFromFees[address(this)] = true;





        _rOwned[owner()] = _rTotal;

        emit Transfer(address(0), owner(), _tTotal);

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



    function totalSupply() public view override returns (uint256) {

        return _tTotal;

    }



    function balanceOf(address account) public view override returns (uint256) {

        if (_isExcluded[account]) return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);

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

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;

    }



    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;

    }



    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;

    }



    function isExcludedFromReward(address account) public view returns (bool) {

        return _isExcluded[account];

    }



    function totalReflectionDistributed() public view returns (uint256) {

        return _tFeeTotal;

    }



    function deliver(uint256 tAmount) public {

        address sender = _msgSender();

        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (uint256 rAmount,,,,,,) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _rTotal = _rTotal - rAmount;

        _tFeeTotal = _tFeeTotal + tAmount;

    }



    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {

        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {

            (uint256 rAmount,,,,,,) = _getValues(tAmount);

            return rAmount;

        } else {

            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);

            return rTransferAmount;

        }

    }



    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {

        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate =  _getRate();

        return rAmount / currentRate;

    }



    function excludeFromReward(address account) public onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");

        if(_rOwned[account] > 0) {

            _tOwned[account] = tokenFromReflection(_rOwned[account]);

        }

        _isExcluded[account] = true;

        _excluded.push(account);

    }



    function includeInReward(address account) external onlyOwner() {

        require(_isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (_excluded[i] == account) {

                _excluded[i] = _excluded[_excluded.length - 1];

                _tOwned[account] = 0;

                _isExcluded[account] = false;

                _excluded.pop();

                break;

            }

        }

    }



    receive() external payable {}



    function claimStuckTokens(address token) external onlyOwner {

        require(token != address(this), "Owner cannot claim native tokens");

        if (token == address(0x0)) {

            payable(msg.sender).transfer(address(this).balance);

            return;

        }

        IERC20 ERC20token = IERC20(token);

        uint256 balance = ERC20token.balanceOf(address(this));

        ERC20token.transfer(msg.sender, balance);

    }



    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;

    }



    function sendBNB(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        (bool success, ) = recipient.call{value: amount}("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }



    function _reflectFee(uint256 rFee, uint256 tFee) private {

        _rTotal = _rTotal - rFee;

        _tFeeTotal = _tFeeTotal + tFee;

    }



    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {

        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation) = _getTValues(tAmount);

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tfoundation,  _getRate());

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketing, tfoundation);

    }



    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {

        uint256 tFee = calculateTaxFee(tAmount);

        uint256 tMarketing = calculateMarketingFee(tAmount);

        uint256 tfoundation = calculatefoundationFee(tAmount);

        uint256 tTransferAmount = tAmount - tFee - tMarketing - tfoundation;

        return (tTransferAmount, tFee, tMarketing, tfoundation);

    }



    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation, uint256 currentRate) private pure returns (uint256, uint256, uint256) {

        uint256 rAmount = tAmount * currentRate;

        uint256 rFee = tFee * currentRate;

        uint256 rMarketing = tMarketing * currentRate;

        uint256 rfoundation = tfoundation * currentRate;

        uint256 rTransferAmount = rAmount - rFee - rMarketing - rfoundation;

        return (rAmount, rTransferAmount, rFee);

    }



    function _getRate() private view returns(uint256) {

        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply / tSupply;

    }



    function _getCurrentSupply() private view returns(uint256, uint256) {

        uint256 rSupply = _rTotal;

        uint256 tSupply = _tTotal;      

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);

            rSupply = rSupply - _rOwned[_excluded[i]];

            tSupply = tSupply - _tOwned[_excluded[i]];

        }

        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);

        return (rSupply, tSupply);

    }

    

    function _takeburn(address sender, uint256 tTransferAmount, uint256 rTransferAmount, uint256 tAmount) private returns (uint256, uint256) {

        if(burnFee==0) {

            return(tTransferAmount, rTransferAmount); }

        uint256 tburn = calculateburnFee(tAmount);

        uint256 rburn = tburn * _getRate();

        rTransferAmount = rTransferAmount - rburn;

        tTransferAmount = tTransferAmount - tburn;

        _rOwned[address(this)] = _rOwned[address(this)] + rburn;

        emit Transfer(sender, address(this), tburn);

        return(tTransferAmount, rTransferAmount);

    }



    function _takebloxTeam(address sender, uint256 tTransferAmount, uint256 rTransferAmount, uint256 tAmount) private returns (uint256, uint256) {

        if(bloxTeamFee==0) {

            return(tTransferAmount, rTransferAmount); }

        uint256 tCharity = calculatebloxTeamFee(tAmount);

        uint256 rCharity = tCharity * _getRate();

        rTransferAmount = rTransferAmount - rCharity;

        tTransferAmount = tTransferAmount - tCharity;

        _rOwned[address(this)] = _rOwned[address(this)] + rCharity;

        emit Transfer(sender, address(this), tCharity);

        return(tTransferAmount, rTransferAmount);

    }



    function _takeMarketing(uint256 tMarketing) private {

        if (tMarketing > 0) {

            uint256 currentRate =  _getRate();

            uint256 rMarketing = tMarketing * currentRate;

            _rOwned[address(this)] = _rOwned[address(this)] + rMarketing;

            if(_isExcluded[address(this)])

                _tOwned[address(this)] = _tOwned[address(this)] + tMarketing;

        }

    }



    function _takefoundation(uint256 tfoundation) private {

        if (tfoundation > 0) {

            uint256 currentRate =  _getRate();

            uint256 rfoundation = tfoundation * currentRate;

            _rOwned[address(this)] = _rOwned[address(this)] + rfoundation;

            if(_isExcluded[address(this)])

                _tOwned[address(this)] = _tOwned[address(this)] + tfoundation;

        }

    }

    

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {

        return _amount * taxFee / 100;

    }



    function calculateburnFee(uint256 _amount) private view returns (uint256) {

        return _amount * burnFee / 100;

    }



    function calculatebloxTeamFee(uint256 _amount) private view returns (uint256) {

        return _amount * bloxTeamFee / 100;

    }



    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {

        return _amount * marketingFee / 100;

    }



    function calculatefoundationFee(uint256 _amount) private view returns (uint256) {

        return _amount * foundationFee  / 100;

    }

    

    function removeAllFee() private {

        if(taxFee == 0 && burnFee == 0 && bloxTeamFee == 0 && marketingFee == 0 && foundationFee == 0) return;

        

        _previousTaxFee = taxFee;

        _previousburnFee = burnFee;

        _previousbloxTeamFee = bloxTeamFee;

        _previousMarketingFee = marketingFee;

        _previousfoundationFee = foundationFee;

        taxFee = 0;

        marketingFee = 0;

        burnFee = 0;

        bloxTeamFee = 0;

        foundationFee = 0;

    }

    

    function restoreAllFee() private {

        taxFee = _previousTaxFee;

        burnFee = _previousburnFee;

        bloxTeamFee = _previousbloxTeamFee;

        marketingFee = _previousMarketingFee;

        foundationFee = _previousfoundationFee;

    }

    

    function isExcludedFromFee(address account) public view returns(bool) {

        return _isExcludedFromFees[account];

    }



    function _approve(address owner, address spender, uint256 amount) private {

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

        require(amount > 0, "Transfer amount must be greater than zero");



        uint256 contractTokenBalance = balanceOf(address(this));        

        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if (

            overMinTokenBalance &&

            !inSwapAndLiquify &&

            to == uniswapV2Pair &&

            swapEnabled

        ) {

            inSwapAndLiquify = true;

            

            uint256 taxForSwap = foundationFee + marketingFee + burnFee + bloxTeamFee;

            if(taxForSwap > 0) {

                uint256 initialBalance = address(this).balance;



                address[] memory path = new address[](2);

                path[0] = address(this);

                path[1] = uniswapV2Router.WETH();



                uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(

                    contractTokenBalance,

                    0, // accept any amount of ETH

                    path,

                    address(this),

                    block.timestamp);



                uint256 newBalance = address(this).balance - initialBalance;



                if(foundationFee > 0) {

                    uint256 foundationBNB = newBalance * foundationFee / taxForSwap;

                    sendBNB(payable(foundationWallet), foundationBNB);

                    emit Sendfoundation(foundationBNB);

                    

                }

                

                if(marketingFee > 0) {

                    uint256 marketingBNB = newBalance * marketingFee / taxForSwap;

                    sendBNB(payable(marketingWallet), marketingBNB);

                    emit SendMarketing(marketingBNB);

                }



                if(burnFee > 0) {

                    uint256 burnBNB = newBalance * burnFee / taxForSwap;

                    sendBNB(payable(burnWallet), burnBNB);

                    emit Sendburn(burnBNB);

                }



                if(bloxTeamFee > 0) {

                    uint256 charityBNB = newBalance * bloxTeamFee / taxForSwap;

                    sendBNB(payable(bloxTeamWallet), charityBNB);

                    emit SendCharity(charityBNB);

                }



            }

            inSwapAndLiquify = false;

        }



        _tokenTransfer(from,to,amount);

    }



    //=======Swap=======//

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner() {

        require(newAmount >= totalSupply() / 100000, "SwapTokensAtAmount must be greater than 0.001% of total supply");

        swapTokensAtAmount = newAmount;

    }

    

    function setSwapEnabled(bool _enabled) external onlyOwner {

        swapEnabled = _enabled;

        emit SwapEnabledUpdated(_enabled);

    }



    //=======TaxAndTransfer=======//

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        bool restoreFees = false;

        if (_isExcludedFromFees[sender] || 

            _isExcludedFromFees[recipient] || 

            (walletToWalletTransferWithoutFee && 

            sender != uniswapV2Pair && recipient != uniswapV2Pair)

        ) {

            removeAllFee();

            restoreFees = true;

        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {

            _transferFromExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

            _transferToExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

            _transferStandard(sender, recipient, amount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

            _transferBothExcluded(sender, recipient, amount);

        } else {

            _transferStandard(sender, recipient, amount);

        }

        if (restoreFees) {

            restoreAllFee();

        }

    }



    function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation) = _getValues(tAmount);

        (tTransferAmount, rTransferAmount) = _takeburn(sender, tTransferAmount, rTransferAmount, tAmount);

        (tTransferAmount, rTransferAmount) = _takebloxTeam(sender, tTransferAmount, rTransferAmount, tAmount);

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        _takeMarketing(tMarketing);

        _takefoundation(tfoundation);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }



    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation) = _getValues(tAmount);

        (tTransferAmount, rTransferAmount) = _takeburn(sender, tTransferAmount, rTransferAmount, tAmount);

        (tTransferAmount, rTransferAmount) = _takebloxTeam(sender, tTransferAmount, rTransferAmount, tAmount);

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        _takeMarketing(tMarketing);

        _takefoundation(tfoundation);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }



    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation) = _getValues(tAmount);

        (tTransferAmount, rTransferAmount) = _takeburn(sender, tTransferAmount, rTransferAmount, tAmount);

        (tTransferAmount, rTransferAmount) = _takebloxTeam(sender, tTransferAmount, rTransferAmount, tAmount);

        _tOwned[sender] = _tOwned[sender] - tAmount;

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 

        _takeMarketing(tMarketing);

        _takefoundation(tfoundation);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }



    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tfoundation) = _getValues(tAmount);

        (tTransferAmount, rTransferAmount) = _takeburn(sender, tTransferAmount, rTransferAmount, tAmount);

        (tTransferAmount, rTransferAmount) = _takebloxTeam(sender, tTransferAmount, rTransferAmount, tAmount);

        _tOwned[sender] = _tOwned[sender] - tAmount;

        _rOwned[sender] = _rOwned[sender] - rAmount;

        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;

        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        _takeMarketing(tMarketing);

        _takefoundation(tfoundation);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }



    //=======FeeManagement=======//

    function excludeFromFees(address account) external onlyOwner {

        require(!_isExcludedFromFees[account], "Account is already the value of true");

        _isExcludedFromFees[account] = true;



        emit ExcludeFromFees(account, true);

    }

    

    function changeMarketingWallet(address _marketingWallet) external onlyOwner {

        require(_marketingWallet != marketingWallet, "Marketing wallet is already that address");

        require(!isContract(_marketingWallet), "Marketing wallet cannot be a contract");

        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);

    }



    function changefoundationWallet(address _foundationWallet) external onlyOwner {

        require(_foundationWallet != foundationWallet, "foundation wallet is already that address");

        require(!isContract(_foundationWallet), "foundation wallet cannot be a contract");

        foundationWallet = _foundationWallet;

        emit foundationWalletChanged(foundationWallet);

    }



    function changeburnWallet(address _burnWallet) external onlyOwner {

        require(_burnWallet != burnWallet, "burn wallet is already that address");

        require(!isContract(_burnWallet), "burn wallet cannot be a contract");

        burnWallet = _burnWallet;

        emit burnWalletChanged(burnWallet);

    }



    function changebloxTeamWallet(address _bloxTeamWallet) external onlyOwner {

        require(_bloxTeamWallet != bloxTeamWallet, "wallet is already that address");

        require(!isContract(_bloxTeamWallet), "wallet cannot be a contract");

        bloxTeamWallet = _bloxTeamWallet;

        emit bloxTeamWalletChanged(bloxTeamWallet);

    }



    function setTaxFeePercent(uint256 _taxFee) external onlyOwner() {

        taxFee = _taxFee;

        totalFees = taxFee + marketingFee + burnFee + foundationFee + bloxTeamFee;

        require(totalFees <= 25, "Total fees must be less than 25%");

    }



    function setMarketingFeePercent(uint256 _marketing) external onlyOwner {

        marketingFee = _marketing;

        totalFees = taxFee + marketingFee + burnFee + foundationFee + bloxTeamFee;

        require(totalFees <= 25, "Total fees must be less than 25%");

    }

    

    function setburnFeePercent(uint256 _burnFee) external onlyOwner() {

        burnFee = _burnFee;

        totalFees = taxFee + marketingFee + burnFee + foundationFee + bloxTeamFee;

        require(totalFees <= 25, "Total fees must be less than 25%");

    }



    function setbloxTeamPercent(uint256 _bloxTeam) external onlyOwner() {

        bloxTeamFee = _bloxTeam;

        totalFees = taxFee + marketingFee + burnFee + foundationFee + bloxTeamFee;

        require(totalFees <= 25, "Total fees must be less than 25%");

    }



    function setfoundationFeePercent(uint256 _foundationFee) external onlyOwner() {

        foundationFee = _foundationFee;

        totalFees = taxFee + marketingFee + burnFee + foundationFee + bloxTeamFee;

        require(totalFees <= 25, "Total fees must be less than 25%");

    }



    function enableWalletToWalletTransferWithoutFee(bool enable) external onlyOwner {

        require(walletToWalletTransferWithoutFee != enable, "Wallet to wallet transfer without fee is already set to that value");

        walletToWalletTransferWithoutFee = enable;

    }



}