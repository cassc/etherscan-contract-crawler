/**
 *Submitted for verification at BscScan.com on 2022-10-08
 */

// SPDX-License-Identifier: MIT
import "hardhat/console.sol";

pragma solidity ^0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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

interface ISwapRouter {
    function factory() external pure returns (address);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    address public _owner;

    constructor(address token0, address routerAdd, address pairAdd) {
        _owner = msg.sender;
        IERC20(token0).approve(msg.sender, uint(~uint256(0)));
        IERC20(token0).approve(routerAdd, uint(~uint256(0)));
        IERC20(token0).approve(pairAdd, uint(~uint256(0)));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "not owner");
        IERC20(token).transfer(to, amount);
    }

    function addLiquidity(
        address routerAdd,
        address pairAdd,
        address usdt,
        address ukf
    ) external {
        require(msg.sender == _owner, "not owner");
        console.log("addLiquidity-------------begin-----------------");
        uint256 balance = IERC20(ukf).balanceOf(address(this));
        /* if (balance < 2 * 10 ** _decimals) {
            return;
        } */
        (uint256 reserve0, uint256 reserve1, ) = ISwapPair(pairAdd)
            .getReserves();
        address token0 = ISwapPair(pairAdd).token0();
        uint256 tokenAmount;
        if (token0 == ukf) {
            tokenAmount = (balance * reserve1) / (reserve0 + reserve1);
        } else {
            tokenAmount = (balance * reserve0) / (reserve0 + reserve1);
        }
        address[] memory path = new address[](2);
        path[0] = ukf;
        path[1] = usdt;
        ISwapRouter(routerAdd)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp + 600
            );
        uint256 amountA = balance - tokenAmount;
        uint256 amountB = IERC20(usdt).balanceOf(address(this));
        ISwapRouter(routerAdd).addLiquidity(
            ukf,
            usdt,
            amountA,
            amountB,
            0,
            0,
            address(this),
            block.timestamp + 600
        );
        console.log("addLiquidity--------------end-----------------");
    }
}

abstract contract BaseToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;
    address public _mintPool;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 public constant MAX = ~uint256(0);

    uint256 public _buyDestroyFee = 50;
    uint256 public _buyFundFee = 100;
    uint256 public _buyNodeFee = 100;
    uint256 public _buyLPRewardFee = 100;
    uint256 public _buyOneGenerationFee = 50;
    uint256 public _buyTwoGenerationFee = 50;
    uint256 public _buyThreeGenerationFee = 30;
    uint256 public _buyFourGenerationFee = 10;
    uint256 public _buyFiveGenerationFee = 10;
    uint256 public _buyAddLiquidityFee = 100;

    uint256 public _sellDestroyFee = 50;
    uint256 public _sellFundFee = 100;
    uint256 public _sellNodeFee = 100;
    uint256 public _sellLPRewardFee = 100;
    uint256 public _sellAddLiquidityFee = 100;
    uint256 public _sellOneGenerationFee = 50;
    uint256 public _sellTwoGenerationFee = 50;
    uint256 public _sellThreeGenerationFee = 30;
    uint256 public _sellFourGenerationFee = 10;
    uint256 public _sellFiveGenerationFee = 10;

    address public _mainPair;

    TokenDistributor public _tokenDistributor;
    TokenDistributor public _tokenDistributorToAddLP;
    uint256 public _minTotal;

    uint256 public _dynamicRewardAccessLimit;

    mapping(address => address) public _boundAddress;
    mapping(address => bool) public _isBounded;

    address[] public nodes;
    mapping(address => uint256) public nodeIndexs;

    bool handTransferFee;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address RouterAddress,
        address USDTAddress,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address FundAddress,
        address ReceiveAddress,
        uint256 MinTotal
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _allowances[address(this)][RouterAddress] = MAX;

        _usdt = USDTAddress;
        _swapRouter = swapRouter;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), USDTAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;
        _tokenDistributor = new TokenDistributor(
            USDTAddress,
            RouterAddress,
            swapPair
        );
        _allowances[address(_tokenDistributor)][address(this)] = MAX;
        _allowances[address(_tokenDistributor)][swapPair] = MAX;
        _allowances[address(_tokenDistributor)][RouterAddress] = MAX;
        _tokenDistributorToAddLP = new TokenDistributor(
            USDTAddress,
            RouterAddress,
            swapPair
        );
        _allowances[address(_tokenDistributorToAddLP)][address(this)] = MAX;
        _allowances[address(_tokenDistributorToAddLP)][swapPair] = MAX;
        _allowances[address(_tokenDistributorToAddLP)][RouterAddress] = MAX;

        _minTotal = MinTotal * 10 ** Decimals;
        _dynamicRewardAccessLimit = 200 * 10 ** Decimals;

        _feeWhiteList[address(_tokenDistributor)] = true;
        _feeWhiteList[address(_tokenDistributorToAddLP)] = true;
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        //  LP Reward
        holderRewardCondition = 1 * 10 ** _decimals;
        excludeHolder[address(0)] = true;
        excludeHolder[address(this)] = true;
        excludeHolder[address(_tokenDistributor)] = true;
        excludeHolder[address(_tokenDistributorToAddLP)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        // node Reward
        nodeRewardCondition = 1 * 10 ** IERC20(USDTAddress).decimals();

        // add liquidity
        IERC20(USDTAddress).approve(RouterAddress, MAX);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function validTotal() public view returns (uint256) {
        return
            _tTotal -
            balanceOf(address(0)) -
            balanceOf(address(0x000000000000000000000000000000000000dEaD));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        console.log(
            "transfer-------------------------------begin-----------------------------------------------------------------"
        );
        _transfer(msg.sender, recipient, amount);
        console.log(
            "_transfer-------------------------------begin----------------------------------------------------------------"
        );
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        console.log(
            "transferFrom----------------------------------begin----------------------------------------------------"
        );
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        console.log(
            "transferFrom----------------------------------end------------------------------------------------------"
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        console.log("_transfer----------------begin--------------------");
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        bool normalTransfer;
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount = (balance * 9999) / 10000;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }
        if (!_swapPairList[from] && !_swapPairList[to]) {
            normalTransfer = true;
            if (!_isBounded[to] && amount >= 1 * 10 ** (_decimals - 1)) {
                _isBounded[to] = true;
                _boundAddress[to] = from;
            }
        }
        bool takeFee;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
                if (_swapPairList[to]) {
                    if (_isAddLiquidity()) {
                        takeFee = false;
                    }
                } else {
                    if (_isRemoveLiquidity()) {
                        takeFee = false;
                    }
                }
            }
        }
        _tokenTransfer(from, to, amount, takeFee);
        if (normalTransfer) {
            console.log("_transfer----------------end----------------------");
            return;
        }
        if (
            from != address(this) &&
            from != address(_tokenDistributor) &&
            from != address(_tokenDistributorToAddLP)
        ) {
            if (_swapPairList[to]) {
                addHolder(from);
            }
            if (IERC20(_mainPair).totalSupply() == 0) {
                console.log(
                    "_transfer----------------end----------------------"
                );
                return;
            }
            if (_swapPairList[to]) {
                if (_isAddLiquidity()) {
                    console.log(
                        "_transfer----------------end----------------------"
                    );
                    return;
                }
            } else if (_swapPairList[from]) {
                if (_isRemoveLiquidity()) {
                    console.log(
                        "_transfer----------------end----------------------"
                    );
                    return;
                }
            }

            //distribure LP holder reward
            if (!inSwap) {
                processReward(500000);
            }
            uint256 blockNum = block.number;
            //distribute node reward
            if (processRewardBlock != blockNum) {
                if (!inSwap) {
                    processNodeReward(500000);
                }
            }
        }
        console.log("_transfer----------------end----------------------");
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        console.log(
            "_tokenTransfer-----------------------begin---------------------"
        );
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        if (takeFee) {
            handTransferFee = true;
            if (_swapPairList[sender]) {
                //Buy
                feeAmount = handBuyFee(sender, tAmount);
            } else {
                //Sell
                feeAmount = handSellFee(sender, tAmount);
            }
            handTransferFee = false;
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
        console.log(
            "_tokenTransfer----------------------end-----------------------"
        );
    }

    function handBuyFee(
        address sender,
        uint256 tAmount
    ) private returns (uint256) {
        console.log("handBuyFee----------begin-------------");
        uint256 feeAmount;
        uint256 destroyFeeAmount = (_buyDestroyFee * tAmount) / 10000;
        if (destroyFeeAmount > 0) {
            uint256 destroyAmount = destroyFeeAmount;
            uint256 currentTotal = validTotal();
            uint256 maxDestroyAmount;
            if (currentTotal > _minTotal) {
                maxDestroyAmount = currentTotal - _minTotal;
            }
            if (destroyAmount > maxDestroyAmount) {
                destroyAmount = maxDestroyAmount;
            }
            if (destroyAmount > 0) {
                feeAmount += destroyAmount;
                _takeTransfer(
                    sender,
                    address(0x000000000000000000000000000000000000dEaD),
                    destroyAmount
                );
            }
        }

        uint256 swapFee = _buyFundFee + _buyNodeFee;
        uint256 swapAmount = (tAmount * swapFee) / 10000;
        if (swapAmount > 0) {
            feeAmount += swapAmount;
            _takeTransfer(sender, address(this), swapAmount);
        }
        uint256 lpRewardAmount = (tAmount * _buyLPRewardFee) / 10000;
        feeAmount += lpRewardAmount;
        _takeTransfer(sender, address(_tokenDistributor), lpRewardAmount);
        uint256 dynamicFeeAmount = processDynamicReward(sender, tAmount, true);
        feeAmount += dynamicFeeAmount;
        uint256 addLiquidityAmount = (tAmount * _buyAddLiquidityFee) / 10000;
        feeAmount += addLiquidityAmount;
        _takeTransfer(
            sender,
            address(_tokenDistributorToAddLP),
            addLiquidityAmount
        );
        console.log("handBuyFee--------------end------------------");
        return feeAmount;
    }

    function handSellFee(
        address sender,
        uint256 tAmount
    ) private returns (uint256) {
        console.log("handSellFee-----------------begin-----------------");
        uint256 feeAmount;
        uint256 destroyFeeAmount = (_sellDestroyFee * tAmount) / 10000;
        if (destroyFeeAmount > 0) {
            uint256 destroyAmount = destroyFeeAmount;
            uint256 currentTotal = validTotal();
            uint256 maxDestroyAmount;
            if (currentTotal > _minTotal) {
                maxDestroyAmount = currentTotal - _minTotal;
            }
            if (destroyAmount > maxDestroyAmount) {
                destroyAmount = maxDestroyAmount;
            }
            if (destroyAmount > 0) {
                feeAmount += destroyAmount;
                _takeTransfer(
                    sender,
                    address(0x000000000000000000000000000000000000dEaD),
                    destroyAmount
                );
            }
        }

        uint256 swapFee = _sellFundFee + _sellNodeFee;
        uint256 swapAmount = (tAmount * swapFee) / 10000;
        if (swapAmount > 0) {
            feeAmount += swapAmount;
            _takeTransfer(sender, address(this), swapAmount);
        }
        if (!inSwap) {
            uint256 contractTokenBalance = balanceOf(address(this));
            swapTokenForFund(contractTokenBalance, swapFee, _sellFundFee);
        }
        uint256 lpRewardAmount = (tAmount * _sellLPRewardFee) / 10000;
        feeAmount += lpRewardAmount;
        _takeTransfer(sender, address(_tokenDistributor), lpRewardAmount);
        uint256 dynamicFeeAmount = processDynamicReward(sender, tAmount, false);
        feeAmount += dynamicFeeAmount;
        uint256 addLiquidityAmount = (tAmount * _sellAddLiquidityFee) / 10000;
        feeAmount += addLiquidityAmount;
        _takeTransfer(
            sender,
            address(_tokenDistributorToAddLP),
            addLiquidityAmount
        );
        if (!inSwap) {
            inSwap = true;
            _tokenDistributorToAddLP.addLiquidity(
                address(_swapRouter),
                _mainPair,
                _usdt,
                address(this)
            );
            inSwap = false;
        }
        console.log("handSellFee-----------------end------------------");
        return feeAmount;
    }

    function processDynamicReward(
        address sender,
        uint256 tAmount,
        bool buy
    ) private returns (uint256) {
        address nextAddress = sender;
        uint256 feeAmount;
        if (buy) {
            for (uint i = 0; i < 5; i++) {
                nextAddress = _boundAddress[nextAddress];
                if (nextAddress == address(0)) {
                    break;
                }
                uint256 dynamicRewardAmount;
                if (i == 0) {
                    dynamicRewardAmount =
                        (tAmount * _buyOneGenerationFee) /
                        10000;
                }
                if (i == 1) {
                    dynamicRewardAmount =
                        (tAmount * _buyTwoGenerationFee) /
                        10000;
                }
                if (i == 2) {
                    dynamicRewardAmount =
                        (tAmount * _buyThreeGenerationFee) /
                        10000;
                }
                if (i == 3) {
                    dynamicRewardAmount =
                        (tAmount * _buyFourGenerationFee) /
                        10000;
                }
                if (i == 4) {
                    dynamicRewardAmount =
                        (tAmount * _buyFiveGenerationFee) /
                        10000;
                }
                if (balanceOf(nextAddress) > 200 * 10 ** _decimals) {
                    _takeTransfer(sender, nextAddress, dynamicRewardAmount);
                    feeAmount += dynamicRewardAmount;
                }
            }
        } else {
            for (uint i = 0; i < 5; i++) {
                nextAddress = _boundAddress[nextAddress];
                if (nextAddress == address(0)) {
                    break;
                }
                uint256 dynamicRewardAmount;
                if (i == 0) {
                    dynamicRewardAmount =
                        (tAmount * _sellOneGenerationFee) /
                        10000;
                }
                if (i == 1) {
                    dynamicRewardAmount =
                        (tAmount * _sellTwoGenerationFee) /
                        10000;
                }
                if (i == 2) {
                    dynamicRewardAmount =
                        (tAmount * _sellThreeGenerationFee) /
                        10000;
                }
                if (i == 3) {
                    dynamicRewardAmount =
                        (tAmount * _sellFourGenerationFee) /
                        10000;
                }
                if (i == 4) {
                    dynamicRewardAmount =
                        (tAmount * _sellFiveGenerationFee) /
                        10000;
                }
                if (balanceOf(nextAddress) > 200 * 10 ** _decimals) {
                    _takeTransfer(sender, nextAddress, dynamicRewardAmount);
                    feeAmount += dynamicRewardAmount;
                }
            }
        }
        return feeAmount;
    }

    function swapTokenForFund(
        uint256 tokenAmount,
        uint256 swapFee,
        uint256 fundFee
    ) private lockTheSwap {
        console.log(
            "swapTokenForFund--------------begin-----------------------"
        );
        if (0 == tokenAmount) {
            console.log(
                "swapTokenForFund--------------end------------------------"
            );
            return;
        }
        address usdt = _usdt;
        address tokenDistributor = address(_tokenDistributor);
        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalance = USDT.balanceOf(tokenDistributor);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            tokenDistributor,
            block.timestamp + 600
        );
        usdtBalance = USDT.balanceOf(tokenDistributor) - usdtBalance;
        uint256 fundUsdt = (usdtBalance * fundFee) / swapFee;
        USDT.transferFrom(tokenDistributor, fundAddress, fundUsdt);
        console.log(
            "swapTokenForFund--------------end------------------------"
        );
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function setBuyFee(uint256[] memory fees) external onlyOwner {
        require(fees.length == 10, "set fee error");
        _buyDestroyFee = fees[0];
        _buyFundFee = fees[1];
        _buyNodeFee = fees[2];
        _buyLPRewardFee = fees[3];
        _buyAddLiquidityFee = fees[4];
        _buyOneGenerationFee = fees[5];
        _buyTwoGenerationFee = fees[6];
        _buyThreeGenerationFee = fees[7];
        _buyFourGenerationFee = fees[8];
        _buyFiveGenerationFee = fees[9];
    }

    function setSellFee(uint256[] memory fees) external onlyOwner {
        require(fees.length == 10, "set fee error");
        _sellDestroyFee = fees[0];
        _sellFundFee = fees[1];
        _sellNodeFee = fees[2];
        _sellLPRewardFee = fees[3];
        _sellAddLiquidityFee = fees[4];
        _sellOneGenerationFee = fees[5];
        _sellTwoGenerationFee = fees[6];
        _sellThreeGenerationFee = fees[7];
        _sellFourGenerationFee = fees[8];
        _sellFiveGenerationFee = fees[9];
    }

    function setDynamicRewardLimit(uint256 limit) external onlyOwner {
        _dynamicRewardAccessLimit = limit * 10 ** _decimals;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    function claimContractToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _tokenDistributor.claimToken(token, fundAddress, amount);
        }
    }

    receive() external payable {}

    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;

    function getLPHolderLength() external view returns (uint256) {
        return holders.length;
    }

    function addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                uint256 size;
                assembly {
                    size := extcodesize(adr)
                }
                if (size > 0) {
                    return;
                }
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public processRewardBlock;
    uint256 public processRewardBlockDebt = 200;

    function processReward(uint256 gas) public lockTheSwap {
        if (processRewardBlock + processRewardBlockDebt > block.number) {
            return;
        }
        address sender = address(_tokenDistributor);
        uint256 balance = balanceOf(sender);
        if (balance < holderRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = (balance * tokenBalance) / holdTokenTotal;
                if (amount > 0) {
                    transferFrom(sender, shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        processRewardBlock = block.number;
    }

    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    function setProcessRewardBlockDebt(uint256 blockDebt) external onlyOwner {
        processRewardBlockDebt = blockDebt;
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }

    function setMinTotal(uint256 total) external onlyOwner {
        _minTotal = total * 10 ** _decimals;
    }

    function batchSetFeeWhiteList(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function addNode(address adr) external onlyOwner {
        if (0 == nodeIndexs[adr]) {
            if (0 == nodes.length || nodes[0] != adr) {
                nodeIndexs[adr] = nodes.length;
                nodes.push(adr);
            }
        }
    }

    function getNodeLength() public view returns (uint256) {
        return nodes.length;
    }

    mapping(address => bool) public excludeNodeReward;

    uint256 public currentNodeIndex;
    uint256 public nodeRewardCondition;
    uint256 public processNodeRewardBlock;
    uint256 public processNodeRewardBlockDebt = 200;

    function processNodeReward(uint256 gas) public lockTheSwap {
        if (
            processNodeRewardBlock + processNodeRewardBlockDebt > block.number
        ) {
            return;
        }

        address sender = address(_tokenDistributor);
        uint256 balance = IERC20(_usdt).balanceOf(sender);
        if (balance < nodeRewardCondition) {
            return;
        }

        uint256 amount;
        address shareHolder;

        uint256 shareholderCount = nodes.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentNodeIndex >= shareholderCount) {
                currentNodeIndex = 0;
            }
            shareHolder = nodes[currentNodeIndex];
            if (!excludeNodeReward[shareHolder]) {
                amount = balance / shareholderCount;
                if (amount > 0) {
                    IERC20(_usdt).transferFrom(sender, shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentNodeIndex++;
            iterations++;
        }

        processNodeRewardBlock = block.number;
    }

    function setNodeRewardCondition(uint256 amount) external onlyOwner {
        nodeRewardCondition = amount;
    }

    function setProcessNodeRewardDebt(uint256 blockDebt) external onlyOwner {
        processNodeRewardBlockDebt = blockDebt;
    }

    function setExcludeNodeReward(address add, bool enable) external onlyOwner {
        excludeNodeReward[add] = enable;
    }

    function _isAddLiquidity() internal view returns (bool isAdd) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
}

contract UKF_9 is BaseToken {
    constructor()
        BaseToken(
            //SwapRouter
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
            //USDT
            address(0x55d398326f99059fF775485246999027B3197955),
            "UFK-9",
            "UFK-9",
            18,
            39000,
            //Fund
            address(0xEB597BB06EC912dFf4af7C384DE6669555fdFe8f),
            //Receive
            address(0x8c2A1d70Ec41FacE8e4B3Bb3dE4Adf0DcFfD910b),
            0
        )
    {}
}