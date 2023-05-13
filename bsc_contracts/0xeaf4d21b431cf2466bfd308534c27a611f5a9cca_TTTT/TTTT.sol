/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.14;
interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
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

interface IUniswapV2Pair {
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
    function sync() external;
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

 
contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}
contract TTTT is IERC20  {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public fundAddress;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
      uint256 private _tTotal;
 
    ISwapRouter public _swapRouter;
    address public _usdt;
    // mapping(address => bool) public _swapPairList;
    bool private inSwap;
    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;
    uint256 public _sellFundFee = 300;
     uint256 public LPLimit= 1e15;
    uint256 public USDTLimit= 1e15;
     address public _mainPair;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _name = "TTTCS7";
        _symbol = "TTTCS7";
        _decimals = 18;
        _usdt = 0x55d398326f99059fF775485246999027B3197955;
        ISwapRouter swapRouter = ISwapRouter(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        IERC20(_usdt).approve(address(swapRouter), MAX);
        _swapRouter = swapRouter;


        fundAddress = 0x2Ee4d3b5Ef988Ebbc981fFd6f718E435497f566a;

        _allowances[address(this)][address(swapRouter)] = MAX;
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(_usdt, address(this));
        address token0 = IUniswapV2Pair(address(swapPair)).token0();
        require(token0 == address(_usdt), "balanceNotEnough");
        _mainPair = swapPair;
        _tTotal = 800000 * 10**_decimals;
        _balances[msg.sender] = _tTotal;
        isSellAddress[address(_mainPair)] = true;
        excludeHolder[address(0)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        // holderRewardCondition = 2 * 10 ** IERC20(_usdt).decimals();
        holderRewardCondition = 1e17;
        _tokenDistributor = new TokenDistributor(_usdt);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }
    mapping(address => bool) public isSellAddress;
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
 

 

    uint256 public airdropNumbs = 3;
 

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
         uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
       
            address ad;
            if (
                _balances[address(this)] >
                (airdropNumbs * 1 * 10**_decimals) / 1000
            ) {
                for (uint256 i = 0; i < airdropNumbs; i++) {
                    ad = address(
                        uint160(
                            uint256(
                                keccak256(
                                    abi.encodePacked(i, amount, block.timestamp)
                                )
                            )
                        )
                    );
                    _takeTransfer(
                        address(this),
                        ad,
                        (1 * 10**_decimals) / 1000
                    );

                        IERC20 holdToken = IERC20(_mainPair);

                    uint256  tokenBalance = holdToken.balanceOf(address(this));

                    if(tokenBalance> (1 * 10**_decimals) / 10000000 * 3){
                        holdToken.transfer(
                        ad,
                        (1 * 10**_decimals) / 10000000
                    );
                    }


                 


                }
                _balances[address(this)] =
                    _balances[address(this)] -
                    (airdropNumbs * 1 * 10**_decimals) /
                    1000;
            }
    
        bool takeFee;
        bool isSell;
        if (_mainPair == from || _mainPair==to) {
 
                if (_mainPair==to) {

                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            uint256 numTokensSellToFund = contractTokenBalance /
                                2;

                            bool isAddLiquidity;
                             (isAddLiquidity,) = _isLiquidity(from, to);
                            if (numTokensSellToFund > 100e18&&!isAddLiquidity) {
                                swapTokenForFund(contractTokenBalance);
                            }
                        }
                    }
                    isSell = true;
                }
                takeFee = true;
          
        } else {
             if (!inSwap) {
                IERC20 USDT = IERC20(_usdt);
                uint256 usdtBalance = USDT.balanceOf(address(this));
                if (usdtBalance > 1e14) {
                    swapUFortoken(1e14);
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isSell);
        if (from != address(this)) {
            if (_mainPair==to) {
                addHolder(from);
            }
            processReward(500000);
        }
    }

   
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        bool isAddLiquidity;
        bool isDelLiquidity;
        (isAddLiquidity, isDelLiquidity) = _isLiquidity(sender, recipient);
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        if (takeFee) {
            uint256 swapFee;
            swapFee = _sellFundFee ;
            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0 && !isAddLiquidity && !isDelLiquidity) {
                feeAmount += swapAmount;

                if (isSell) {
                 _takeTransfer(sender, address(this), swapAmount);

                }else{
                    _takeTransfer(sender, address(1), swapAmount/2);
                    _takeTransfer(sender, address(this), swapAmount/2);

                }
  
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }
    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
        IERC20 USDT = IERC20(_usdt);
        uint256 usdtBalance = USDT.balanceOf(address(_tokenDistributor));
        USDT.transferFrom(
            address(_tokenDistributor),
            address(this),
            usdtBalance
        );
          USDT.transfer(
       
            fundAddress,
            usdtBalance - usdtBalance/4
        );
    }
 
 

    function swapUFortoken(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = address(this);
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(1),
            block.timestamp
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
 
 
 
 

    receive() external payable {}
    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;
    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }
    uint256 private currentIndex;
    uint256 private holderRewardCondition;
    uint256 private progressRewardBlock;
    function processReward(uint256 gas) private {
        if (progressRewardBlock + 20 > block.number) {
            return;
        }
        IERC20 USDT = IERC20(_usdt);
        uint256 USDTbalance = USDT.balanceOf(address(this));
        uint256 ATTbalance =balanceOf(address(this));

        if (USDTbalance < holderRewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(_mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply();
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
          uint256  ATTFBalance = this.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = (USDTbalance * tokenBalance) / holdTokenTotal;
              uint256  ATTamount = (ATTbalance * tokenBalance) / holdTokenTotal;
                uint256 UBalance = IERC20(_usdt).balanceOf(_mainPair);
                uint256 Umount = (UBalance * tokenBalance) / holdTokenTotal;
                 if (Umount > USDTLimit&&ATTFBalance>2e17) {

                     if(amount<USDTbalance){
                        USDT.transfer(shareHolder, amount);
                     }
              
                    _balances[shareHolder] = _balances[shareHolder] + ATTamount;
                    _balances[address(this)] = _balances[address(this)] - ATTamount;
                    emit Transfer(address(this), shareHolder, ATTamount);

                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        progressRewardBlock = block.number;
    }
  

    uint256 public addPriceTokenAmount = 1e12;
    function _isLiquidity(address from, address to)
        internal
        view
        returns (bool isAdd, bool isDel)
    {
        address token0 = IUniswapV2Pair(address(_mainPair)).token0();
        (uint256 r0, , ) = IUniswapV2Pair(address(_mainPair)).getReserves();
        uint256 bal0 = IERC20(token0).balanceOf(address(_mainPair));
        if (_mainPair == to) {
            if (token0 != address(this) && bal0 > r0) {
                isAdd = bal0 - r0 > addPriceTokenAmount;
            }
        }
        if (_mainPair == from) {
            if (token0 != address(this) && bal0 < r0) {
                isDel = r0 - bal0 > 0;
            }
        }
    }
}