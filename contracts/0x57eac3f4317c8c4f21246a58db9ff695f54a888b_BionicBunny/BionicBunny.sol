/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context, Pausable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner whenNotPaused {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner)
        public
        virtual
        onlyOwner
        whenNotPaused
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract BionicBunny is Context, IERC20, IERC20Metadata, Pausable, Ownable {
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) public _isExcludedFromDexFee;

    uint256 private _tTotal = 420000000000 * 10**18;

    string private constant _name = "Bionic Bunny";
    string private constant _symbol = "SEXY";
    uint8 private constant _decimals = 18;

    address public marketingWallet;

    uint256 public marketingFee = 4;
    uint256 private previousTotalSwapFee = marketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address constant UNISWAPV2ROUTER =0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public managerAddress = 0xa5ab12402c31f1Bd777ad9E33b1fC24A19F3AB5f;

    bool public enableFee;
    bool private swapFeeToEth;
    bool public marketingswapEnabled = true;

    //bool public taxDisableInLiquidity;

    uint256 public minimumTokensBeforeSwap = 1000000000 * 10**18;

    event FeeEnabled(bool enableFee);
    event SetMaxTxPercent(uint256 maxPercent);
    event ManagerUpdated(address indexed newManager);
    event SetMarketingFeePercent(uint256 marketingFeePercent);
    event SetMinimumTokensBeforeSwap(uint256 minimumTokensBeforeSwap);
    event SetMarketingSwapEnabled(bool enabled);
    event EnableFees(bool marketingfeeenabled);
    event TokenFromContractTransfered(
        address externalAddress,
        address toAddress,
        uint256 amount
    );
    event EthFromContractTransferred(uint256 amount);

    constructor(address _marketingWallet) {
        _tOwned[_msgSender()] = _tTotal;
        marketingWallet = _marketingWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            UNISWAPV2ROUTER
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _tOwned[account];
    }

    function isExcludedFromDexFee(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromDexFee[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        whenNotPaused
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    modifier onlyManager() {
        require(msg.sender == managerAddress, "Only the manager can call this function.");
        _;
    }

    function setManager(address newManager) external onlyOwner {
        require(newManager != address(0), "Invalid manager address.");
        require(newManager != managerAddress, "New manager address must be different from the current manager address.");
        managerAddress = newManager;
        emit ManagerUpdated(newManager);
    }

    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    function burn(uint256 amount)
        external
        virtual
        override
        onlyOwner
        whenNotPaused
        returns (bool)
    {
        _burn(_msgSender(), amount);
        return true;
    }

    function excludeFromDexFee(address account)
        external
        onlyOwner
        whenNotPaused
    {
        _isExcludedFromDexFee[account] = true;
    }

    function includeInDexFee(address account) external onlyOwner whenNotPaused {
        _isExcludedFromDexFee[account] = false;
    }

    function setMarketingFeePercent(uint256 fee)
        external
        onlyOwner
        whenNotPaused
    {
        marketingFee = fee;
        emit SetMarketingFeePercent(marketingFee);
    }

    function enableswap(bool marketingfeeenabled)
        external
        onlyOwner
        whenNotPaused
    {
        marketingswapEnabled = marketingfeeenabled;
        emit EnableFees(marketingswapEnabled);
    }

    function setMinimumTokensBeforeSwap(uint256 swapLimit)
        external
        onlyOwner
        whenNotPaused
    {
        minimumTokensBeforeSwap = swapLimit;
        emit SetMinimumTokensBeforeSwap(minimumTokensBeforeSwap);
    }

    function setEnableFee(bool enableTax) external onlyOwner whenNotPaused {
        enableFee = enableTax;
        emit FeeEnabled(enableTax);
    }

    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyManager
        whenNotPaused
    {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit TokenFromContractTransfered(_tokenContract, msg.sender, _amount);
    }

    function withdrawETH() external payable onlyManager {
        payable(msg.sender).transfer(address(this).balance);
    }

    //to recieve Eth from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = balanceOf(from);
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        if (!swapFeeToEth && from != uniswapV2Pair) distributeFee();

        // If UniSwap buy sell's only contract should take taxation.
        if (
            enableFee &&
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            (!_isExcludedFromDexFee[from] || !_isExcludedFromDexFee[to])
        ) takeFee = true;

        //transfer amount, it will take tax, burn and charity amount
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(
            amount < balanceOf(account),
            "ERC20: burn amount exceeds balance"
        );

        _tTotal = _tTotal - amount;

        _tOwned[account] = _tOwned[account] - amount;

        emit Transfer(account, address(0), amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal {
        if (!takeFee) removeAllFee();

        _transfermain(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function _transfermain(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal {
        (uint256 tTransferAmount, uint256 tSwapFee) = getTValues(tAmount);

        {
            address from = sender;
            address to = recipient;
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + tTransferAmount;
        }
        takeSwapFee(sender, tSwapFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function getTValues(uint256 amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 tAmount = amount;
        uint256 tSwapFee = calculateSwapFee(tAmount);
        uint256 tTransferAmount = tAmount - tSwapFee;
        return (tTransferAmount, tSwapFee);
    }

    function calculateSwapFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * (marketingFee)) / (10**2);
    }

    function takeSwapFee(address sender, uint256 tSwapFee) internal {
        _tOwned[address(this)] = _tOwned[address(this)] + tSwapFee;

        if (tSwapFee > 0) emit Transfer(sender, address(this), tSwapFee);
    }

    function removeAllFee() internal {
        if (marketingFee == 0) return;

        previousTotalSwapFee = marketingFee;
        marketingFee = 0;
    }

    function restoreAllFee() internal {
        marketingFee = previousTotalSwapFee;
    }

    function distributeFee() internal {
        uint256 initialBalance = address(this).balance;
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= minimumTokensBeforeSwap) {
            bool initialFeeState = enableFee;
            // remove fee if initialFeeState was true
            if (initialFeeState) enableFee = false;
            swapFeeToEth = true;

            // swap tokens in contract address to eth
            swapTokensForEth(contractTokenBalance, address(this));
            uint256 transferredBalance = address(this).balance - initialBalance;

            // Send Eth to Marketing address
            if (marketingswapEnabled)
                transferETHToAddress(
                    payable(marketingWallet),
                    transferredBalance);

            // enable fee if initialFeeState was true
            if (initialFeeState) enableFee = true;
            swapFeeToEth = false;
        }
    }

    function distributeFeeNow() external onlyManager {
        uint256 initialBalance = address(this).balance;
        uint256 contractTokenBalance = balanceOf(address(this));

        bool initialFeeState = enableFee;
        // remove fee if initialFeeState was true
        if (initialFeeState) enableFee = false;

        swapFeeToEth = true;

        // swap tokens in contract address to eth
        swapTokensForEth(contractTokenBalance, address(this));
        uint256 transferredBalance = address(this).balance - initialBalance;

        // Send Eth to Marketing address
         if (marketingswapEnabled)
                transferETHToAddress(
                    payable(marketingWallet),
                    transferredBalance);

        // enable fee if initialFeeState was true
        if (initialFeeState) enableFee = true;
        swapFeeToEth = false;
    }

    function transferETHToAddress(address payable recipient, uint256 amount)
        internal
    {
        recipient.transfer(amount);
    }

    function swapTokensForEth(uint256 tokenAmount, address account) internal {
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
            account,
            block.timestamp
        );
    }
}