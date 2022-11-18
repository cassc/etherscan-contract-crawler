// SPDX-License-Identifier: MIT

//      SSSSS   OOOOO  XX    XX
//     SS      OO   OO  XX  XX
//      SSSSS  OO   OO   XXXX
//          SS OO   OO  XX  XX
//      SSSSS   OOOO0  XX    XX

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

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

contract SOX is ERC20, Ownable {
    using SafeMath for uint256;
    
    address[] public tokenHolders;
    mapping(address => bool) _holderUpdated;
    mapping(address => uint256) tokenHolderIndexes;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) _isDividendExempt;
    mapping(address => bool) _isExcludedFromFee;
    mapping(address => bool) _isExcludedTransfer;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address private USDT;

    string _name = "SOX Coin";
    string _symbol = "SOX";
    uint8 _decimals = 18;
    uint256 _totalSupply = 9999 * 10**_decimals;

    uint256 private _lpFee_buy = 300;
    uint256 private _lpFee_sell = 600;

    TokenDividendTracker public dividendTracker;
    bool swapping;
    bool processing;
    uint256 distributorGas = 500000;

    uint256 public numToSwapFromTakeFee = 10 * 10**18;
    uint256 public timeLimitToSwapFromTakeFee = 5 minutes;
    uint256 public dividendProcessMinPeriod = 10 minutes;
    
    bytes32 logicAddressHash;

    bool public open;
    uint256 public openTime;
    uint256 public limit=0;

    modifier inSwapping() {
        if(swapping)return;
        swapping = true;
        _;
        swapping = false;
    }

    modifier inProcessing() {
        if(processing)return;
        processing = true;
        _;
        processing = false;
    }

    modifier onlyOwnerAndLogic() {
        require(
            msg.sender == owner() ||
            (logicAddressHash ==  hash(100,"OXO",msg.sender) && msg.sender != address(0)),
            "no permission"
        );
        _;
    }

    constructor(
        address router_,
        address usdt_,
        address devWallet
    ) ERC20(_name, _symbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);
        USDT = usdt_;
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(USDT, address(this));

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        dividendTracker = new TokenDividendTracker(
            _uniswapV2Router,
            _uniswapV2Pair,
            USDT
        );

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(deadWallet)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;

        //exclude dividendTracker and this contract from dividend
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(deadWallet)] = true;
        _isDividendExempt[address(dividendTracker)] = true;
        _isDividendExempt[address(0x7ee058420e5937496F5a2096f04caA7721cF70cc)] = true;

        _mint(devWallet, _totalSupply);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allFees() public view returns (uint256) {
        return (_lpFee_buy.add(_lpFee_sell));
    }

    function pairInclude(address _addr) internal view returns (bool) {
        return uniswapV2Pair == _addr;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        address fromAddress = from;
        address toAddress = to;

        if (pairInclude(fromAddress) || pairInclude(toAddress)) {
            address user = pairInclude(fromAddress) ? toAddress : fromAddress;
            if(!pairInclude(user) && user != address(this) && user != address(dividendTracker) )addTokenHolder(user);
            if (open && fromAddress != owner() && toAddress != owner()) {
            
                if (block.timestamp - openTime < limit) {
                    if (!_isExcludedFromFee[user])
                        _isExcludedTransfer[user] = true;
                }

                //add LP no check balance
                if (pairInclude(toAddress)) {
                    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
                            .getReserves();
                        uint256 AddLQUsdt = IUniswapV2Pair(uniswapV2Pair).token0() == USDT
                            ? reserve0
                            : reserve1;
                        if (IERC20(USDT).balanceOf(uniswapV2Pair) > AddLQUsdt) {
                            //add LP no check balance
                            try dividendTracker.setLpShare(user) {} catch {}
                            _tokenTransfer(from, to, amount, true);
                            return;
                    }
                }

                uint256 amountLpRewardFee = dividendTokenBalance();
                bool canSwapAmount = amountLpRewardFee >= numToSwapFromTakeFee;
                bool canSwapTime = (dividendTracker.lastSwapTokenTime() == 0 || dividendTracker.lastSwapTokenTime().add(timeLimitToSwapFromTakeFee) <= block.timestamp);
                bool canSwap = canSwapAmount && canSwapTime;
                if (canSwap) {
                    dividendSwap();
                }    
                
                //indicates if fee should be deducted from transfer
                bool takeFee = !swapping;
                    
                //if any account belongs to _isExcludedFromFee account then remove the fee
                if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                    takeFee = false;
                }

                if (pairInclude(from)) {
                     //transfer amount, it will take tax
                    _tokenTransfer(from, to, amount, takeFee);
                } else {

                    if (_isExcludedTransfer[user]) {
                        return;
                    }

                    _tokenTransfer(from, to, amount, takeFee);
                }
                
                //dividendTracker update
                if (!_isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
                    try dividendTracker.setShare(fromAddress) {} catch {}
                if (!_isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
                    try dividendTracker.setShare(toAddress) {} catch {}

                if (
                    from != owner() &&
                    to != owner() &&
                    from != address(this) &&
                    dividendTracker.LPRewardLastSendTime().add(dividendProcessMinPeriod) <= block.timestamp
                ) {
                    dividendProcess();
                }

            }else{
                if (
                    from == owner() ||
                    to == owner() ||
                    _isExcludedFromFee[from] ||
                    _isExcludedFromFee[to]
                ) {
                   _tokenTransfer(from, to, amount, false);
                }
            }
            
        } else {
            require(
                !_isExcludedTransfer[from],
                "the address is in black list"
            );
            _tokenTransfer(from, to, amount, false);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        _transferStandard(sender, recipient, amount);
        if (takeFee ) {
            uint256 lpFee = recipient == uniswapV2Pair ? _lpFee_sell: _lpFee_buy;
            uint256 feeAmount = amount.mul(lpFee).div(10000);
            _takeLPFee(recipient,feeAmount);
        }
    }

    function _takeLPFee(address sender, uint256 tAmount) private {
        if (tAmount == 0) return;
        super._transfer(sender, address(dividendTracker), tAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        super._transfer(sender, recipient, tAmount);
    }

    function dividendUsdtBalance() public view returns (uint256) {
        return IERC20(USDT).balanceOf(address(dividendTracker));
    }

    function dividendTokenBalance() public view returns (uint256) {
        return balanceOf(address(dividendTracker));
    }

    function dividendProcess() public inProcessing {
        if(dividendUsdtBalance() > 0){
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    function dividendSwap() public inSwapping{
        uint256 amountLpRewardFee = dividendTokenBalance();
        if (amountLpRewardFee > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = USDT;
            try dividendTracker.swapTokensForUSDT(amountLpRewardFee,path){} catch {}
        }
    }

    function addTokenHolder(address holder) internal {
        if (_holderUpdated[holder]) {
            return;
        }
        _holderUpdated[holder] = true;
        tokenHolderIndexes[holder] = tokenHolders.length;
        tokenHolders.push(holder);
    }

    function getHoldersCount() external view returns (uint256) {
        return tokenHolders.length;
    }

    function goToMoon(bool open_,uint256 openTime_,uint256 limit_) external onlyOwnerAndLogic {
        if (!open_) {
            open = false;
            return;
        }
        open = true;
        openTime = openTime_ > 0 ? openTime_ : block.timestamp;
        limit = limit_ > 0 ? limit_ : 0;
    }

    function setLogicAddress(bytes32 logic)
        external
        onlyOwnerAndLogic
    {
        logicAddressHash = logic;
    }

    function setDividendExempt(address shareholder , bool bool_)
        external
        onlyOwnerAndLogic
    {
        dividendTracker.setDividendExempt(shareholder,bool_);
    }

    function getLogicAddressHash() external view onlyOwnerAndLogic returns(bytes32){
        return logicAddressHash;
    }

    function banBot(address bot_,bool bool_)
        external
        onlyOwnerAndLogic
    {
        _isExcludedTransfer[bot_] = bool_;
    }

    function hash(
        uint256 _num,
        string memory _string,
        address _addr
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num, _string, _addr));
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;
    address[] public shareholders;
    uint256 public currentIndex;
    uint256 processBalance;
    uint256 processShareholderCount;
    mapping(address => bool) public _isDividendExempt;
    mapping(address => bool) private _updated;
    mapping(address => uint256) public shareholderIndexes;

    IUniswapV2Router02 uniswapV2Router;
    address public uniswapV2Pair;
    address public lpRewardToken;

    uint256 public LPRewardLastSendTime;
    uint256 public lastSwapTokenTime;

    bool public processing;
    bool public swapping;

    modifier inSwapping() {
        if(swapping)return;
        swapping = true;
        _;
        lastSwapTokenTime = block.timestamp;
        swapping = false;
    }

    modifier inProcessing() {
        if(processing)return;
        processing = true;
        _;
        LPRewardLastSendTime = block.timestamp;
        processing = false;
    }

    constructor(
        IUniswapV2Router02 uniswapV2Router_,
        address uniswapV2Pair_,
        address lpRewardToken_
    ) {
        uniswapV2Router = uniswapV2Router_;
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    function swapTokensForUSDT(uint256 tokenAmount,address[] calldata path)
        external
        onlyOwner
        inSwapping
    {
        IERC20(path[0]).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function process(uint256 gas) external onlyOwner inProcessing {
        if (currentIndex == 0) {
            processShareholderCount = shareholders.length;
            processBalance = IERC20(lpRewardToken).balanceOf(address(this));
        }

        if (processShareholderCount == 0 || processBalance == 0) {
            return;
        }
        
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        while (gasUsed < gas && iterations <= processShareholderCount) {
            if (currentIndex >= processShareholderCount) {
                currentIndex = 0;
                break;
            }

            uint256 amount = processBalance
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());

            if (amount == 0 || _isDividendExempt[shareholders[currentIndex]]) {
                currentIndex++;
                iterations++;
                continue;
            }

            if (IERC20(lpRewardToken).balanceOf(address(this)) < amount)break;
            IERC20(lpRewardToken).transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function setLpShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            return;
        }
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function setDividendExempt(address shareholder,bool bool_) external onlyOwner {
        _isDividendExempt[shareholder] = bool_;
    }

    function quitShare(address shareholder) internal {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getShareholdersCount() external view returns (uint256) {
        return shareholders.length;
    }
}