/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

pragma solidity ^0.8.12;
// SPDX-License-Identifier: Unlicensed
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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != - 1 || a != MIN_INT256);
        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? - a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {

    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IV2SwapRouter {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);
}

contract PrinterGoesMemeTransferRouter is Ownable{
    using SafeMath for uint256;
    address private _development = 0x6e6199584d116650e2d9dbE5E9A3De54D7e5cA13;
    address private _pgmRewards = 0xC4563Aaaa95347223c579f1cDB3B8ff877A79793;
    address private _insertRewards = 0x1001fE5112B55757488108aa8824f348240d59e0;
    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //Mainnet
    //address private usdcAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b; //rinkeby
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IV2SwapRouter public v2SwapRouter = IV2SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
    IERC20 public usdcToken = IERC20(usdcAddress);

    uint256 public gasForProcessing = 80000;
    struct Distribution {
        uint256 development;
        uint256 insertRewards;
        uint256 pgmRewards;
        uint256 dividend;
    }

    struct TrackerAndDistribution {
        DividendTracker dividendTracker;
        uint256 dividendPercentage;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    Distribution public distribution = Distribution(100,0,0,0);
    TrackerAndDistribution[] public trackerAndDistributions;
    constructor () {
    }

    function setWalletAddresses(address development, address pgmRewards, address insertRewards) external onlyOwner {
        _development = development;
        _pgmRewards = pgmRewards;
        _insertRewards = insertRewards;
    }

    function setDistribution(uint256 development, uint256 insertRewards, uint256 pgmRewards, uint256 dividend) external onlyOwner {
        distribution.development = development;
        distribution.insertRewards = insertRewards;
        distribution.pgmRewards = pgmRewards;
        distribution.dividend = dividend;

    }

    function getDevelopmentAddress() public view returns(address) {
        return _development;
    }

    function getPgmRewardsAddress() public view returns(address) {
        return _pgmRewards;
    }

    function getInsertRewardsAddress() public view returns(address) {
        return _insertRewards;
    }

    function distributeUSDC() external {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));

        uint256 developmentShare = usdcBalance.mul(distribution.development).div(100).div(2);
        uint256 insertShare = usdcBalance.mul(distribution.insertRewards).div(100).div(2);
        uint256 pgmShare = usdcBalance.mul(distribution.pgmRewards).div(100).div(2);
        uint256 dividendShare = usdcBalance.mul(distribution.dividend).div(100).div(2);

        usdcToken.transfer(_development, developmentShare);
        usdcToken.transfer(_insertRewards, insertShare);
        usdcToken.transfer(_pgmRewards, pgmShare);
        swapTokens(dividendShare);

    }

    function swapTokens(uint256 dividendShare) public {
        for(uint256 i=0; i < trackerAndDistributions.length; i++) {
            TrackerAndDistribution memory trackerAndDistribution = trackerAndDistributions[i];
            uint256 tokenShare = dividendShare.mul(trackerAndDistribution.dividendPercentage).div(100).div(2);
            uint256 amount = swapTokensForErc20Token(trackerAndDistribution.dividendTracker, tokenShare);
            try trackerAndDistribution.dividendTracker.calculateDividends(amount) {} catch{}
        }
    }

    function swapTokensForErc20Token(DividendTracker dividendTracker, uint256 tokenAmount) private returns(uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = usdcAddress;
        path[1] = dividendTracker.getErc20DividenTokenAddress();
        // Approve the swap first
        usdcToken.approve(address(v2SwapRouter), tokenAmount);
        return v2SwapRouter.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(dividendTracker));
    }

    function addDividendTracker(address[] calldata dividendContractAddresses, uint256[] calldata percentages) external onlyOwner {
        for(uint256 i = 0; i < dividendContractAddresses.length; i++) {
            trackerAndDistributions.push(TrackerAndDistribution(DividendTracker(dividendContractAddresses[i]), percentages[i]));
        }
    }

    function replaceDividendTracker(uint256 index, address contractAddress) external onlyOwner {
        trackerAndDistributions[index].dividendTracker = DividendTracker(contractAddress);
    }

    function updateDistribution(uint256[] calldata percentages) external onlyOwner {
        for(uint256 i = 0; i < percentages.length; i++) {
            trackerAndDistributions[i].dividendPercentage = percentages[i];
        }
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
    }

    function sendUSDCBack() external onlyOwner {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        usdcToken.transfer(owner(), usdcBalance);
    }

    function calculateDividend(address sender, address recipient) external {
        for(uint256 i =0; i < trackerAndDistributions.length; i++) {
            DividendTracker dividendTracker = trackerAndDistributions[i].dividendTracker;
            try dividendTracker.setTokenBalance(sender) {} catch{}
            try dividendTracker.setTokenBalance(recipient) {} catch{}

            try dividendTracker.process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
            }catch {}

        }
    }

    function extractERC20Tokens(uint256 index) public onlyOwner {
        trackerAndDistributions[index].dividendTracker.extractERC20Tokens();
    }

}

contract PGM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    event SwapAndLiquifyEnabledUpdated(bool enabled);


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IV2SwapRouter public v2SwapRouter = IV2SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address public uniswapV2Pair = address(0);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private botWallets;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromRewards;
    string private _name = "Printer Goes Meme";
    string private _symbol = "PGM";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 100000000000 * 10 ** _decimals;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public usdcPriceToSwap = 500000000; //500 USDC
    uint256 public _maxWalletAmount = 3000000000 * 10 ** _decimals;
    address private deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //Mainnet
    //address public usdcAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b; //rinkeby

    IERC20 usdcToken = IERC20(usdcAddress);
    uint256 public minimumTokenBalanceForDividends = 250000000 * 10 ** _decimals;

    struct Distribution {
        uint256 dividend;
        uint256 pgm;
    }

    struct TaxFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    bool private doTakeFees;
    bool private isSellTxn;
    TaxFees public taxFees  = TaxFees(15, 30);
    Distribution public distribution  = Distribution(100, 0);
    PrinterGoesMemeTransferRouter public pgmRouter;

    constructor () {
        _balances[_msgSender()] = _tTotal*86/100;
        _balances[0x9cC39B1a9640d47658Ec78feef576c36eb05CE5F] = _tTotal*7/100;
        _balances[0xEDaeb15fcF5a5ef64525526460488d14aaeefb49] = _tTotal*7/100;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromRewards[deadWallet] = true;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), usdcAddress);
        _isExcludedFromRewards[uniswapV2Pair] = true;
        _isExcludedFromRewards[address(this)] = true;
        _isExcludedFromRewards[owner()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal*86/100);
        emit Transfer(address(0), 0x9cC39B1a9640d47658Ec78feef576c36eb05CE5F, _tTotal*7/100);
        emit Transfer(address(0), 0xEDaeb15fcF5a5ef64525526460488d14aaeefb49, _tTotal*7/100);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner {
        _maxWalletAmount = maxWalletAmount * 10 ** 9;
    }

    function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
    }

    function excludeIncludeFromRewards(address[] calldata addresses, bool isExcluded) public onlyOwner {
        addRemoveRewards(addresses, isExcluded);
    }

    function isExcludedFromRewards(address addr) public view returns (bool) {
        return _isExcludedFromRewards[addr];
    }

    function setPGMRouterContract(address pgmContractAddress) public onlyOwner {
        pgmRouter = PrinterGoesMemeTransferRouter(pgmContractAddress);
        _isExcludedFromFee[pgmRouter.getDevelopmentAddress()] = true;
        _isExcludedFromFee[pgmRouter.getPgmRewardsAddress()] = true;
        _isExcludedFromFee[pgmRouter.getInsertRewardsAddress()] = true;
    }

    function addRemoveRewards(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromRewards[addr] = flag;
        }
    }

    function addRemoveFee(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromFee[addr] = flag;
        }
    }

    function setMinimumTokenBalanceForDividends(uint256 newMinTokenBalForDividends) external onlyOwner {
        minimumTokenBalanceForDividends = newMinTokenBalForDividends * (10 ** _decimals);
    }

    function setTaxFees(uint256 buyFee, uint256 sellFee) external onlyOwner {
        taxFees.buyFee = buyFee;
        taxFees.sellFee = sellFee;
    }

    function setDistribution(uint256 dividend, uint256 pgm) external onlyOwner {
        distribution.dividend = dividend;
        distribution.pgm = pgm;
    }

    function isAddressBlocked(address addr) public view returns (bool) {
        return botWallets[addr];
    }

    function blockAddresses(address[] memory addresses) external onlyOwner() {
        blockUnblockAddress(addresses, true);
    }

    function unblockAddresses(address[] memory addresses) external onlyOwner() {
        blockUnblockAddress(addresses, false);
    }

    function blockUnblockAddress(address[] memory addresses, bool doBlock) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (doBlock) {
                botWallets[addr] = true;
            } else {
                delete botWallets[addr];
            }
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
        require(address(pgmRouter) != address(0), "PGM router must be set");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool isSell = false;
        bool takeFees = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner();
        uint256 holderBalance = balanceOf(to).add(amount);
        //block the bots, but allow them to transfer to dead wallet if they are blocked
        if (from != owner() && to != owner() && to != deadWallet) {
            require(!botWallets[from] && !botWallets[to], "bots are not allowed to sell or transfer tokens");
        }
        if (from == uniswapV2Pair) {
            require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
        }
        if (from != uniswapV2Pair && to != uniswapV2Pair) {
            require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
        }
        if (from != uniswapV2Pair && to == uniswapV2Pair) {//if sell
            //only tax if tokens are going back to Uniswap
            isSell = true;
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 tokenAmount = getTokenAmountByUSDCPrice();
                if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify && swapAndLiquifyEnabled) {
                    swapTokens(tokenAmount);
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFees, isSell);
    }

    function swapTokens(uint256 tokenAmount) private lockTheSwap {
        uint256 usdcShare = tokenAmount.mul(distribution.pgm).div(100).div(2);
        swapTokensForUSDC(usdcShare);
        pgmRouter.distributeUSDC();
    }

    function getTokenAmountByUSDCPrice() public view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = usdcAddress;
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(usdcPriceToSwap, path)[1];
    }

    function setUSDCPriceToSwap(uint256 usdcPriceToSwap_) external onlyOwner {
        usdcPriceToSwap = usdcPriceToSwap_;
    }

    function getMinimumTokensForDividends() public view returns (uint256) {
        return minimumTokenBalanceForDividends;
    }


    receive() external payable {}

    function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path;
        path = new address[](2);
        path[0] = address(this);
        path[1] = usdcAddress;
        // Approve the swap first
        _approve(address(this), address(v2SwapRouter), tokenAmount);
        v2SwapRouter.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(pgmRouter));
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,
        bool takeFees, bool isSell) private {
        uint256 taxAmount = takeFees ? amount.mul(taxFees.buyFee).div(100) : 0;
        if (takeFees && isSell) {
            taxAmount = amount.mul(taxFees.sellFee).div(100);
        }
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(sender, recipient, amount);
        pgmRouter.calculateDividend(sender, recipient);
    }
}

contract IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    Map private map;

    function get(address key) public view returns (uint) {
        return map.values[key];
    }

    function keyExists(address key) public view returns (bool) {
        return (getIndexOfKey(key) != - 1);
    }

    function getIndexOfKey(address key) public view returns (int) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(uint index) public view returns (address) {
        return map.keys[index];
    }

    function size() public view returns (uint) {
        return map.keys.length;
    }

    function set(address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract DividendTracker is IERC20, Context, Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    IterableMapping private tokenHoldersMap = new IterableMapping();
    uint256 constant internal magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) internal claimedDividends;
    mapping(address => uint256) private _balances;
    string private _name = "PGM Tracker";
    string private _symbol = "PGMTT";
    uint8 private _decimals = 9;
    uint256 private _totalSupply;
    uint256 public totalDividendsDistributed;
    PGM private pgm;

    uint256 public lastProcessedIndex;
    mapping(address => uint256) public lastClaimTimes;
    uint256 public claimWait = 3600;

    IERC20 public reflectionToken;

    constructor() {
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        require(false, "No transfers allowed in dividend tracker");
        return true;
    }

    function allowance(address,address) public pure override returns (uint256) {
        return 0;
    }

    function approve(address, uint256) public virtual override returns (bool) {
        return true;
    }

    function increaseAllowance(address, uint256) public virtual returns (bool) {
        return true;
    }

    function decreaseAllowance(address, uint256) public virtual returns (bool) {
        return true;
    }

    function setTokenBalance(address account) public {
        uint256 balance = pgm.balanceOf(account);
        if (!pgm.isExcludedFromRewards(account)) {
            if (balance >= pgm.getMinimumTokensForDividends()) {
                _setBalance(account, balance);
                tokenHoldersMap.set(account, balance);
            }
            else {
                _setBalance(account, 0);
                tokenHoldersMap.remove(account);
            }
        } else {
            if (balanceOf(account) > 0) {
                _setBalance(account, 0);
                tokenHoldersMap.remove(account);
            }
        }
        processAccount(payable(account));
    }

    function updateTokenBalances(address[] memory accounts) external {
        uint256 index = 0;
        while (index < accounts.length) {
            setTokenBalance(accounts[index]);
            index += 1;
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
    }

    function setPGMContract(address contractAddr, IERC20 _reflectionToken) external onlyOwner {
        pgm = PGM(payable(contractAddr));
        reflectionToken = _reflectionToken;
    }

    function getErc20DividenTokenAddress() public view returns(address) {
        return address(reflectionToken);
    }
    function excludeFromDividends(address account) external onlyOwner {
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
    }

    function calculateDividends(uint256 amount) public {
        if(totalSupply() > 0) {
            if (amount > 0) {
                magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                    (amount).mul(magnitude) / totalSupply()
                );
                totalDividendsDistributed = totalDividendsDistributed.add(amount);
            }
        }
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            reflectionToken.transfer(user, _withdrawableDividend);
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns (uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "ClaimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Cannot update claimWait to same value");
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.size();
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.size();

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }
        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;
        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;
            if (_lastProcessedIndex >= tokenHoldersMap.size()) {
                _lastProcessedIndex = 0;
            }
            address account = tokenHoldersMap.getKeyAtIndex(_lastProcessedIndex);
            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account))) {
                    claims++;
                }
            }
            iterations++;
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function totalDividendClaimed(address account) public view returns (uint256) {
        return claimedDividends[account];
    }

    function processAccount(address payable account) private returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            uint256 totalClaimed = claimedDividends[account];
            claimedDividends[account] = amount.add(totalClaimed);
            lastClaimTimes[account] = block.timestamp;
            return true;
        }
        return false;
    }

    //This should never be used, but available in case of unforseen issues
    function extractERC20Tokens() external {
        uint256 balance = reflectionToken.balanceOf(address(this));
        reflectionToken.transfer(owner(), balance);
    }

}