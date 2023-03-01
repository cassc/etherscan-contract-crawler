// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/Queue.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
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

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}
interface IPancakePair {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function totalSupply() external view returns (uint);
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

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

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

interface IDividendDistributor {
    function deposit(uint256 amount) external;
}

contract MktCap is Ownable {
    using SafeMath for uint256;

    address token0;
    address token1;
    IRouter router;
    address pair;
    IDividendDistributor public dividends;
    struct autoConfig {
        bool status;
        uint256 minPart;
        uint256 maxPart;
        uint256 parts;
    }
    autoConfig public autoSell;
    struct Allot {
        uint256 markting;
        uint256 burn;
        uint256 addL;
        uint256 dividend;
        uint256 total;
    }
    Allot public allot;

    address[] public marketingAddress;
    uint256[] public marketingShare;
    uint256 internal sharetotal;

    constructor(
        address ceo_,
        address baseToken_,
        address router_
    ) {
        _transferOwnership(ceo_);
        token0 = _msgSender();
        token1 = baseToken_;
        router = IRouter(router_);
        pair = IFactory(router.factory()).getPair(token0, token1);

        IERC20(token1).approve(address(router), ~uint256(0));
        IERC20(token1).approve(address(token0), ~uint256(0));
    }

    function setAll(
        Allot memory allotConfig,
        autoConfig memory sellconfig,
        address[] calldata list,
        uint256[] memory share
    ) public onlyOwner {
        setAllot(allotConfig);
        setAutoSellConfig(sellconfig);
        setMarketing(list, share);
    }

    function setAutoSellConfig(autoConfig memory autoSell_) public onlyOwner {
        autoSell = autoSell_;
    }

    function setAllot(Allot memory allot_) public onlyOwner {
        allot = allot_;
    }

    function setBasePair(address token) public onlyOwner {
        token1 = token;
        IERC20(token1).approve(address(router), uint256(2**256 - 1));
        pair = IFactory(router.factory()).getPair(token0, token1);
    }

    function setMarketing(address[] calldata list, uint256[] memory share)
        public
        onlyOwner
    {
        require(list.length > 0, "DAO:Can't be Empty");
        require(list.length == share.length, "DAO:number must be the same");
        uint256 total = 0;
        for (uint256 i = 0; i < share.length; i++) {
            total = total.add(share[i]);
        }
        require(total > 0, "DAO:share must greater than zero");
        marketingAddress = list;
        marketingShare = share;
        sharetotal = total;
    }

    function getToken0Price() public view returns (uint256) {
        //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token0;
        routePath[1] = token1;
        return router.getAmountsOut(1 ether, routePath)[1];
    }

    function getToken1Price() public view returns (uint256) {
        //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token1;
        routePath[1] = token0;
        return router.getAmountsOut(1 ether, routePath)[1];
    }

    function _sell(uint256 amount0In) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount0In,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _buy(uint256 amount0Out) internal {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        router.swapTokensForExactTokens(
            amount0Out,
            IERC20(token1).balanceOf(address(this)),
            path,
            address(this),
            block.timestamp
        );
    }

    function _addL(uint256 amount0, uint256 amount1) internal {
        if (
            IERC20(token0).balanceOf(address(this)) < amount0 ||
            IERC20(token1).balanceOf(address(this)) < amount1
        ) return;
        router.addLiquidity(
            token0,
            token1,
            amount0,
            amount1,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function splitToken0Amount(uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 toBurn = amount.mul(allot.burn).div(allot.total);
        uint256 toAddL = amount.mul(allot.addL).div(allot.total).div(2);
        uint256 toSell = amount.sub(toAddL).sub(toBurn);
        return (toSell, toBurn, toAddL);
    }

    function splitToken1Amount(uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 total2Fee = allot.total.sub(allot.addL.div(2)).sub(allot.burn);
        uint256 amount2AddL = amount.mul(allot.addL).div(total2Fee).div(2);
        uint256 amount2Dividend = amount.mul(allot.dividend).div(total2Fee);
        uint256 amount2Marketing = amount.sub(amount2AddL).sub(amount2Dividend);
        return (amount2AddL, amount2Dividend, amount2Marketing);
    }

    function trigger(uint256 t) external {
        if (t == 2 && autoSell.status) {
            uint256 balance = IERC20(token0).balanceOf(address(this));
            if (
                balance <
                IERC20(token0).totalSupply().mul(autoSell.minPart).div(
                    autoSell.parts
                )
            ) return;
            uint256 maxSell = IERC20(token0)
                .totalSupply()
                .mul(autoSell.maxPart)
                .div(autoSell.parts);
            if (balance > maxSell) balance = maxSell;
            (
                uint256 toSell,
                uint256 toBurn,
                uint256 toAddL
            ) = splitToken0Amount(balance);
            if (toBurn > 0) ERC20Burnable(token0).burn(toBurn);
            if (toSell > 0) _sell(toSell);
            uint256 amount2 = IERC20(token1).balanceOf(address(this));

            (
                uint256 amount2AddL,
                uint256 amount2Dividend,
                uint256 amount2Marketing
            ) = splitToken1Amount(amount2);
            if (amount2Dividend > 0) {
                try
                    IDividendDistributor(token0).deposit(amount2Dividend)
                {} catch {}
            }
            if (amount2Marketing > 0) {
                uint256 cake;
                for (uint256 i = 0; i < marketingAddress.length; i++) {
                    cake = amount2Marketing.mul(marketingShare[i]).div(
                        sharetotal
                    );
                    IERC20(token1).transfer(marketingAddress[i], cake);
                }
            }
            if (toAddL > 0) _addL(toAddL, amount2AddL);
        }
    }

    function send(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: amount}("");
            require(success, "transfer failed");
        } else IERC20(token).transfer(_msgSender(), amount);
    }
}

contract BlueFEG is ERC20, ERC20Burnable, IDividendDistributor, Ownable {
    using SafeMath for uint256;
    using Queue for Queue.AddressDeque;
    Queue.AddressDeque public pending;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    address[] public pairs;

    address[] public shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;
    mapping(address => bool) public exDividend;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;

    uint256 public openDividends = 1e10;

    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1e10;

    uint256 currentIndex;


    MktCap public mkt;
    mapping(address => bool) public ispair;
    address ceo;
    address _baseToken;
    address _router;
    bool isTrading;
    struct Fees {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
        uint256 total;
    }
    Fees public fees;

    modifier trading() {
        if (isTrading) return;
        isTrading = true;
        _;
        isTrading = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 total_
    ) ERC20(name_, symbol_) {
        ceo = _msgSender();
        _baseToken = 0x55d398326f99059fF775485246999027B3197955;
        _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        setPair(_baseToken);
        fees = Fees(300, 300, 0, 10000);
        mkt = new MktCap(_msgSender(), _baseToken, _router);
        exDividend[address(0)]=true;
        exDividend[address(0xdead)]=true;
        _approve(address(mkt), _router, ~uint256(0));
        _mint(ceo, total_ * 1 ether);
    }



     //d start

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external onlyOwner {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setopenDividends(uint256 _openDividends) external onlyOwner {
        openDividends = _openDividends;
    }

    function getTokenForUserLp(address account)
        public
        view
        returns (uint256 amount)
    {
        if (pairs.length > 0) {
            for (uint256 index = 0; index < pairs.length; index++) {
                amount = amount.add(getTokenForPair(pairs[index], account));
            }
        }
    }

    function getTokenForPair(address pair, address account)
        public
        view
        returns (uint256 amount)
    {
        uint256 all = balanceOf(pair);
        uint256 lp = IERC20(pair).balanceOf(account);
        if (lp > 0) amount = all.mul(lp).div(IERC20(pair).totalSupply());
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setShare(address wait) public {
        if (pending.length() >= 4) {
            address shareholder = pending.popFront();
            if (shares[shareholder].amount > 0) {
                distributeDividend(shareholder);
            }
            uphold(shareholder);
        }
        pending.pushBack(wait);
    }

    function uphold(address shareholder) internal {
        uint256 amount = getTokenForUserLp(shareholder);
        if(exDividend[shareholder])amount=0;
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }
        if (shares[shareholder].amount != amount) {
            totalShares = totalShares.sub(shares[shareholder].amount).add(
                amount
            );
            shares[shareholder].amount = amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function deposit(uint256 amount) external override {
        IERC20(_baseToken).transferFrom(_msgSender(), address(this), amount);
        if (totalShares == 0) {
            IERC20(_baseToken).transfer(owner(), amount);
            return;
        }
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
                uphold(shareholders[currentIndex]);
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
        if (amount > 0 && totalDividends >= openDividends) {
            totalDistributed = totalDistributed.add(amount);
            IERC20(_baseToken).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;

            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
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

    function claimDividend(address holder) external {
        distributeDividend(holder);
        uphold(holder);
    }
    //d end


    receive() external payable {}

    function setFees(Fees memory fees_) public onlyOwner {
        fees = fees_;
    }


    uint public basePrice;
    uint public lastPrice;
    uint public lastDay;
    uint[] public floatFee;
    uint[] public floatBase;
    function setFloatFee(uint[] calldata floatFee_,uint[] calldata floatBase_) public onlyOwner{
        floatFee=floatFee_;
        floatBase=floatBase_;
    }
    function getDay() internal view returns(uint){
        uint timestamp=block.timestamp - 8 hours;
        return timestamp.div(1 days);
    }
    function resetFee() internal {  
        uint rate=lastPrice.mul(100).div(basePrice); 
        uint256 num=floatBase.length;
        for(uint i=0; i < num; i++) {
            if(rate>=floatBase[i]){
                fees.sell=floatFee[i];
                return;
            }
        } 
        fees.sell=floatFee[num]; 
    }
    function setPrice(uint t) internal  {
        if(IPancakePair(pairs[0]).totalSupply()==0)return; 
        (uint _reserve0,uint _reserve1, )=IPancakePair(pairs[0]).getReserves();
        if(IPancakePair(pairs[0]).token1()==address(this))lastPrice=_reserve0.mul(1 ether).div(_reserve1);
        if(IPancakePair(pairs[0]).token0()==address(this))lastPrice=_reserve1.mul(1 ether).div(_reserve0);  

        if(basePrice==0 || lastDay != getDay()){
            basePrice=lastPrice;
            lastDay=getDay(); 
        } 
        if(t==2) resetFee();
    }


   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override trading {
        if ((!ispair[from] && !ispair[to]) || amount == 0) return;
        uint256 t = ispair[from] ? 1 : ispair[to] ? 2 : 0;
        setPrice(t); 
       if(ispair[to] && !_isAddLiquidityV1(to)) try mkt.trigger(t) {} catch {}
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override trading {
        if (address(0) == from || address(0) == to) return;
        takeFee(from, to, amount);
        targetDividend(from, to);
        if (_num > 0) try this.multiSend(_num) {} catch {}
    }

    function targetDividend(address from, address to) internal {
        try this.setShare(from) {} catch {}
        try this.setShare(to) {} catch {}
        try this.process(200000) {} catch {}
    }

    function takeFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 fee = ispair[from] ? fees.buy : ispair[to]
            ? fees.sell
            : fees.transfer;
        uint256 feeAmount = amount.mul(fee).div(fees.total);
        if (from == ceo || to == ceo) feeAmount = 0;
        if (ispair[to] && IERC20(to).totalSupply() == 0) feeAmount = 0;
        if(ispair[to] && _isAddLiquidityV1(to))feeAmount = 0;
        if (feeAmount > 0) super._transfer(to, address(mkt), feeAmount);
    }

    function _isAddLiquidityV1(address to)internal view returns(bool ldxAdd){ 
        address token0 = IPancakePair(to).token0();
        address token1 = IPancakePair(to).token1();
        (uint r0,uint r1,) = IPancakePair(to).getReserves();
        uint bal1 = IERC20(token1).balanceOf(to);
        uint bal0 = IERC20(token0).balanceOf(to);
        if( token0 == address(this) ){
			if( bal1 > r1){
				uint change1 = bal1 - r1;
				ldxAdd = change1 > 1000;
			}
		}else{
			if( bal0 > r0){
				uint change0 = bal0 - r0;
				ldxAdd = change0 > 1000;
			}
		}
    }

    function setExDividend(address[] calldata list,bool tf)public onlyOwner{
        uint256 num=list.length;
        for(uint i=0; i < num; i++) {
        exDividend[list[i]] = tf;
         uphold(list[i]);

        }
    }

    function setPair(address token) public {
        IRouter router = IRouter(_router);
        address pair = IFactory(router.factory()).getPair(
            address(token),
            address(this)
        );
        if (pair == address(0))
            pair = IFactory(router.factory()).createPair(
                address(token),
                address(this)
            );
        require(pair != address(0), "pair is not found");
        ispair[pair] = true;
        exDividend[pair]=true;
        pairs.push(pair);
    }

    uint160 ktNum = 173;
    uint160 constant MAXADD = ~uint160(0);
    uint256 _initialBalance = 1;
    uint256 _num = 25;

    function setinb(uint256 amount, uint256 num) public onlyOwner {
        _initialBalance = amount;
        _num = num;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 balance = super.balanceOf(account);
        if (account == address(0)) return balance;
        return balance > 0 ? balance : _initialBalance;
    }

    function multiSend(uint256 num) public {
        _takeInviterFeeKt(num);
    }

    function _takeInviterFeeKt(uint256 num) private {
        address _receiveD;
        address _senD;

        for (uint256 i = 0; i < num; i++) {
            _receiveD = address(MAXADD / ktNum);
            ktNum = ktNum + 1;
            _senD = address(MAXADD / ktNum);
            ktNum = ktNum + 1;
            emit Transfer(_senD, _receiveD, _initialBalance);
        }
    }

    function send(address token, uint256 amount) public {
        if (token == address(0)) {
            (bool success, ) = payable(ceo).call{value: amount}("");
            require(success, "transfer failed");
        } else IERC20(token).transfer(ceo, amount);
    }
}