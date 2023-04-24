/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

pragma solidity 0.8;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

contract AbsToken is Ownable, IERC20, IERC20Metadata {

    

    mapping(address => uint256) private _userBalances; 
    mapping(address => mapping(address => uint256)) private _allowances; 

    address private immutable _whiteListCreatorAddress; 
    address private immutable _marketWalletAddress; 

    address private immutable _swapRouterAddress;

    uint256 private _totalSupply; 
    uint8 private constant _decimals = 18; 
    string private _name;
    string private _symbol;
    uint256 private constant _blackHoleAndInviteRewardUpperLimitMultiple = 3;

    uint256 private _directDestroyTotal; 
    uint256 private _tradeFeeDestroyTotal; 
    uint256 private _transferFeeDestroyTotal; 

    mapping(address => uint256) private _userDirectDestroyAmount; 
    mapping(address => uint256) private _userLPFeeDestroyAmount; 
    mapping(address => uint256) private _userTransferFeeDestroyAmount; 
    mapping(address => uint256) private _userTxAndBlackHoleAndInviteRewardAmount;


    mapping(address => uint256) private _userLPMiningSum; 
    mapping(address => uint256) private _userLastMiningTime; 
    mapping(address => bool) private _isExcludedTxFee; 
    mapping(address => bool) private _isExcludedTransferFee; 
    mapping(address => bool) private _isExcludedReward; 
    mapping(address => bool) private _isMiner; 
    mapping(address => uint256) private _userInviteCount; 
    mapping(address => uint256) private _userMinerCount; 

    mapping(address => mapping(address => bool)) private _tempInviter; 
    mapping(address => address) private _userInviter; 

    

    uint256 private constant _denominator = 10000;
    uint256 private constant _transferFee = 2000; 
    uint256 private constant _txDestroyFee = 200; 
    uint256 private constant _txMarketFee = 100; 

    uint256 private  constant _minDestroyTokenAmount = 2000 * 10 ** 18; 

    IUniswapV2Router02 private uniswapV2Router;
    address private immutable tokenUsdtPair;
    address private constant dead = 0x000000000000000000000000000000000000dEaD;
    address private immutable usdt; 

    uint256 private constant _codeActiveMiner = 10000000000000000;
    uint256 private constant _one = 1000000000000000000;

    uint256 private constant _miningInterval = 1 * 1 hours;
    uint256 private constant _miningIntervalMaxTimes = 72; 
    uint256 private constant _miningOneDayTimes = 24;

    
    
    
    
    
    
    
    event OnTryActiveMiner(address indexed user, uint256 code);

    
    
    
    
    
    
    
    

    event Log(string message);



    constructor(
        address usdtAddress,
        address swapRouterAddress,
        address whitelistAddress,
        address marketWalletAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply
    ) {

        require(usdtAddress != address(0));
        require(swapRouterAddress != address(0));
        require(whitelistAddress != address(0));
        require(marketWalletAddress != address(0));
        require(bytes(tokenName).length > 0);
        require(bytes(tokenSymbol).length > 0);
        require(supply > 0);

        usdt = usdtAddress;
        _name = tokenName;

        _symbol = tokenSymbol;
        _whiteListCreatorAddress = whitelistAddress;
        _marketWalletAddress = marketWalletAddress;

        _swapRouterAddress = swapRouterAddress;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapRouterAddress);

        
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapV2Router.factory());
        address pair = factory.createPair(address(this), usdtAddress);
        tokenUsdtPair = pair;

        

        uniswapV2Router = _uniswapV2Router;

        _isExcludedTxFee[msg.sender] = true;
        _isExcludedTxFee[address(this)] = true;
        _isExcludedTxFee[dead] = true;
        _isExcludedTxFee[address(0)] = true;
        _isExcludedTxFee[whitelistAddress] = true;
        _isExcludedTxFee[swapRouterAddress] = true;
        _isExcludedTxFee[pair] = true;

        _isExcludedTransferFee[msg.sender] = true;
        _isExcludedTransferFee[address(this)] = true;
        _isExcludedTransferFee[dead] = true;
        _isExcludedTransferFee[address(0)] = true;
        _isExcludedTransferFee[whitelistAddress] = true;
        _isExcludedTransferFee[swapRouterAddress] = true;
        _isExcludedTransferFee[pair] = true;

        _isExcludedReward[msg.sender] = true;
        _isExcludedReward[address(this)] = true;
        _isExcludedReward[dead] = true;
        _isExcludedReward[address(0)] = true;
        _isExcludedReward[whitelistAddress] = true;
        _isExcludedReward[swapRouterAddress] = true;
        _isExcludedReward[pair] = true;

        uint256 _total;

    unchecked{
        _total = supply * (10 ** decimals());
    }

        
        _mint(msg.sender, _total);
    }


    function _mint(address account, uint256 amount) internal virtual {
    unchecked{
        _totalSupply = _totalSupply + amount;
        _userBalances[account] = _userBalances[account] + amount;
    }

        emit Transfer(address(0), account, amount);
    }


    function name() public view virtual override returns (string memory) {return _name;}

    function symbol() public view virtual override returns (string memory) {return _symbol;}

    function decimals() public view virtual override returns (uint8) {return _decimals;}

    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _userBalances[account];
    }

    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }
        return true;
    }

    
    function _bind(address _from, address _to) internal {

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        


        if (_from != tokenUsdtPair && _to != tokenUsdtPair && !_tempInviter[_from][_to]) {

            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            

            _tempInviter[_from][_to] = true;
        }

        if (_from != tokenUsdtPair && _tempInviter[_to][_from] && _userInviter[_from] == address(0) && _userInviter[_to] != _from) {


        unchecked{
            
            if (_isMiner[_from]) {
                _userMinerCount[_to] += 1;
            }

            _userInviter[_from] = _to;
            
            _userInviteCount[_to] += 1;
        }

        }
    }


    address _lastMaybeAddLPAddress;
    
    uint256 _lastMaybeAddLPTokenAmount;
    
    mapping(address => uint256) private _userLPAmount; 
    mapping(address => uint256) private _userLPTTAmount; 

    address _lastMaybeRemoveLPAddress; 
    uint256 _lastMaybeRemoveLPTokenAmount; 

    uint256 _ksjyk = 0; 

    
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "from zero");
        require(to != address(0), "to zero");
        require(amount > 0, "zero amount");
        require(_userBalances[from] >= amount, "exceeds balance");


        
        _doAddLp();

        
        _doRemoveLp();

        
        if (from == _whiteListCreatorAddress) {
            
            if (to == address(tokenUsdtPair)) {
                _transferStandard(from, to, amount);
                return;
            }
            else {
                _doCreateWhiteList(from, to, amount);
                return;
            }

        }

        
        if (to == address(this) || to == _whiteListCreatorAddress) {
            _transferStandard(from, to, amount);
            emit Transfer(from, to, amount);
            return;
        }

        
        if (to == dead) {
            
            bool modifyStatus = _doTransferToDead(from, to, amount);
            
            if (!modifyStatus) {
                _doMiningAll(from);
            }
            return;
        }

        uint256 realTransferAmount = amount;
        bool takeFee = true;

        if (from == tokenUsdtPair || to == tokenUsdtPair) {
            if (0 == _ksjyk) {
                _ksjyk = block.number;
            } else {
                
                require(block.number > _ksjyk + 20);
            }
        }

        
        if (to == tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[from];

                if (takeFee) {
                    realTransferAmount = _takeTxFeeReward(from, amount);
                }
            }
        }

        if (from == tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[to];
                if (takeFee) {
                    realTransferAmount = _takeTxFeeReward(to, amount);
                }
            }
        }

        
        if (from != tokenUsdtPair && to != tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[from] && !_isExcludedTxFee[to];

                if (takeFee) {
                    realTransferAmount = _takeTransferFeeReward(from, amount);
                }
            }
        }

        
        
        
        
        

        
        _transferStandard(from, to, realTransferAmount);
        
        _bind(from, to);
        
        if (amount > realTransferAmount) {
            _userBalances[from] = _userBalances[from] - (amount - realTransferAmount);
        }
        
        


        if (from != address(this)) {
            
            if (to == tokenUsdtPair) {

                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPTokenAmount = realTransferAmount;

            }

        }

        if (to != address(this)) {

            
            if (from == tokenUsdtPair) {

                _lastMaybeRemoveLPAddress = to;
                _lastMaybeRemoveLPTokenAmount = realTransferAmount;

            }
        }
    }





    
    function _takeTxFeeReward(address user, uint256 amount) private returns (uint256 realTransferAmount) {
        uint256 txDestroyFeeAmount = (amount * _txDestroyFee) / _denominator;
        uint256 txMarketFeeAmount = (amount * _txMarketFee) / _denominator;

        if (txMarketFeeAmount > 0) {

        unchecked {

            
            _tradeFeeDestroyTotal += txDestroyFeeAmount;

            
            _userTransferFeeDestroyAmount[user] += txDestroyFeeAmount;

            
            _userBalances[_marketWalletAddress] += txMarketFeeAmount;

            
            _decreaseTotalSupply(txMarketFeeAmount);

        }


            
            realTransferAmount = amount - txDestroyFeeAmount - txMarketFeeAmount;

        }
        return realTransferAmount;
    }


    
    function _takeTransferFeeReward(address user, uint256 amount) private returns (uint256 realTransferAmount) {
        uint256 txTransferFeeAmount = (amount * _transferFee) / _denominator;

        
        _transferFeeDestroyTotal += txTransferFeeAmount;

        
        _userTransferFeeDestroyAmount[user] += txTransferFeeAmount;

        
        _decreaseTotalSupply(txTransferFeeAmount);

        realTransferAmount = amount - txTransferFeeAmount;

        return realTransferAmount;

    }

    
    function _doTransferToDead(address from, address to, uint256 amount) private returns (bool modifyStatus) {

        
        if (_codeActiveMiner == amount) {
            _tryActivateMiner(from);

            emit Transfer(from, to, amount);

            
            modifyStatus = true;
            return modifyStatus;

        }


        
        if (amount > _one) {
            
            _transferStandard(from, to, amount);
            
            _increaseUserDestroyAmount(from, amount);
            
            _decreaseTotalSupply(amount);
        }
        else{
            
            emit Transfer(from, to, amount);
        }

        
        modifyStatus = _tryDeActiveMiner(from);


    }


    
    
    
    
    
    
    function _doCreateWhiteList(address from, address to, uint256 amount) private {
        
        _increaseUserDestroyAmount(to, amount);
        
        _decreaseTotalSupply(amount);
        
        _decreaseUserBalance(from, amount);
        
        
        
    }



    
    function _doAddLp() private {
        address user = _lastMaybeAddLPAddress;
        
        if (user == address(0)) {
            return;
        }

        
        _lastMaybeAddLPAddress = address(0);

        
        uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);

        
        if (lpBalanceInChain > 0) {
            uint256 lpAmountInContract = _userLPAmount[user];
            
            if (lpBalanceInChain > lpAmountInContract) {
                
            unchecked{
                _userLPTTAmount[user] += _lastMaybeAddLPTokenAmount;
            }
                
            }
            _userLPAmount[user] = lpBalanceInChain;
        } else {
            
            _userLPTTAmount[user] = 0;
            _userLPAmount[user] = 0;

            
        }

        _lastMaybeAddLPTokenAmount = 0;
        _userLastMiningTime[user] = block.timestamp;
    }

    
    function _doRemoveLp() private {

        address user = _lastMaybeRemoveLPAddress;
        
        if (user == address(0)) {return;}

        
        _lastMaybeRemoveLPAddress = address(0);


        uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);

        
        if (lpBalanceInChain > 0) {

            
            uint256 lpAmountInContract = _userLPAmount[user];

            
            
            if (lpAmountInContract <= 0) {
                
                _userLPTTAmount[user] = 0;
                _userLPAmount[user] = 0;

            } else {
                
                if (_userLPTTAmount[user] > _lastMaybeRemoveLPTokenAmount) {


                unchecked{
                    _userLPTTAmount[user] -= _lastMaybeRemoveLPTokenAmount;
                }

                    _userLPAmount[user] = lpBalanceInChain;
                } else {
                    _userLPTTAmount[user] = 0;
                    _userLPAmount[user] = 0;

                }
            }


        } else {
            
            _userLPTTAmount[user] = 0;
            _userLPAmount[user] = 0;
        }

        _lastMaybeRemoveLPTokenAmount = 0;
        _userLastMiningTime[user] = block.timestamp;
    }



    
    function _doMiningAll(address user) private {

        
        if (_isExcludedReward[user]) {
            return;
        }

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        

        (uint256 total,, uint256 blackHoleMiningAmount) = _getEstimateNextMiningReward(user);

        if (total == 0) return;

        _userLastMiningTime[user] = block.timestamp;

        if (blackHoleMiningAmount > 0) {
        unchecked{
            _userTxAndBlackHoleAndInviteRewardAmount[user] += blackHoleMiningAmount;
        }
        }

        _transferThisTo(user, total);

        
        _distributeInviteReward(user, total);
    }

    
    function getEstimateNextMiningReward(address user) public view returns (uint256 total, uint256 lpMiningAmount, uint256 blackHoleMiningAmount){
        return _getEstimateNextMiningReward(user);
    }

    
    function _getEstimateNextMiningReward(address user) private view returns (uint256 total, uint256 lpMiningAmount, uint256 blackHoleMiningAmount){

        
        if (_isExcludedReward[user]) {
            total = 0;
            lpMiningAmount = 0;
            blackHoleMiningAmount = 0;
            return (total, lpMiningAmount, blackHoleMiningAmount);
        }


        (uint256 nextMiningTime,uint256 miningTimes) = getNextMiningTime(user);

        
        if (nextMiningTime == 0) {
            total = 0;
            lpMiningAmount = 0;
            blackHoleMiningAmount = 0;
            return (total, lpMiningAmount, blackHoleMiningAmount);
        }


        
        if (block.timestamp < nextMiningTime) {
            total = 0;
            lpMiningAmount = 0;
            blackHoleMiningAmount = 0;
            return (total, lpMiningAmount, blackHoleMiningAmount);
        }


        
        lpMiningAmount = _doLPMining(user);

        if (_isMiner[user]) {
            blackHoleMiningAmount = _doBlackHoleMining(user);
        }

        if (lpMiningAmount == 0 && blackHoleMiningAmount == 0) {
            total = 0;
            lpMiningAmount = 0;
            blackHoleMiningAmount = 0;
            return (total, lpMiningAmount, blackHoleMiningAmount);
        }


    unchecked{

        if (lpMiningAmount != 0) {
            
            lpMiningAmount = lpMiningAmount * miningTimes / _miningOneDayTimes;
        }

        if (blackHoleMiningAmount != 0) {
            
            blackHoleMiningAmount = blackHoleMiningAmount * miningTimes / _miningOneDayTimes;
        }

        total = lpMiningAmount + blackHoleMiningAmount;
    }
        if (total == 0) {
            total = 0;
            lpMiningAmount = 0;
            blackHoleMiningAmount = 0;
            return (total, lpMiningAmount, blackHoleMiningAmount);
        }

        
        
        

        return (total, lpMiningAmount, blackHoleMiningAmount);

    }

    
    function _doBlackHoleMining(address user) private view returns (uint256) {

        if (!_isMiner[user]) {
            return 0;
        }

        uint256 userDestroyAmount = _userDirectDestroyAmount[user];

        
        uint256 ratio = getBlackHoleMiningRatio();

    unchecked{
        uint256 currentBlackHoleMiningAmount = userDestroyAmount * ratio / _denominator;

        
        uint256 canMiningAmount = _getUserRemainTxAndBlackHoleAndInviteRewardAmount(user, currentBlackHoleMiningAmount);

        
        if (canMiningAmount == 0) {
            return 0;
        }

        return canMiningAmount;
    }

    }

    
    uint256 private constant _blackHoleMiningRatioStep = 50000000 * 10 ** 18;

    
    function getBlackHoleMiningRatio() private view returns (uint256) {
        uint256 total = _directDestroyTotal;
        if (total <= _blackHoleMiningRatioStep) {
            return 100;
            
        }

        
        
        
        
        
        
        
        

    unchecked{
        uint256 step = total / _blackHoleMiningRatioStep;
        if (step >= 7) {
            return 30;
            
        }

        uint256 ratio = 100 - step * 10;
        return ratio;
    }

    }

    
    function _doLPMining(address user) private view returns (uint256) {

        
        
        uint256 lpTT = _userLPTTAmount[user];

        if (lpTT == 0) {
            return 0;
        }

    unchecked{
        uint256 miningAmount = lpTT * 5 / 1000;
        return miningAmount;
    }
    }

    
    function _distributeInviteReward(address user, uint256 amount) private {

        if (0 == amount) {return;}

        



        uint256 total = 0;
        address currentUser = user;
        uint256 currentReward;
        uint256 ratio;
        uint256 denominator = 100000;

        for (uint8 i = 0; i < 9;) {

            
        unchecked{
            ++i;
        }

            currentUser = _userInviter[currentUser];
            if (address(0) == currentUser) {
                break;
            }

            
            
            if (!_isMiner[currentUser]) {
                continue;
            }


            
            
            
            if (_userMinerCount[currentUser] < i) {
                continue;
            }

            if (1 == i) {
                ratio = 5000;
            } else if (2 == i) {
                ratio = 4000;
            } else if (3 == i) {
                ratio = 3000;
            } else if (4 == i) {
                ratio = 2000;
            } else if (5 == i) {
                ratio = 1000;
            } else if (6 == i) {
                ratio = 500;
            } else if (7 == i) {
                ratio = 250;
            } else if (8 == i) {
                ratio = 125;
            } else if (9 == i) {
                ratio = 3000;
            } else {
                
                ratio = 1;
            }


        unchecked {
            currentReward = amount * ratio / denominator;
        }

            
            if (currentReward > 0) {


                
                
                uint256 canMiningAmount = _getUserRemainTxAndBlackHoleAndInviteRewardAmount(currentUser, currentReward);
                if (canMiningAmount > 0) {
                unchecked{
                    total += canMiningAmount;
                    _userTxAndBlackHoleAndInviteRewardAmount[currentUser] += canMiningAmount;
                    _userBalances[currentUser] += canMiningAmount;
                }
                    emit Transfer(address(this), currentUser, canMiningAmount);
                }
            }

        }

        
        if (total > 0) {
            _decreaseThisBalance(total);
        }

    }



    
    function _getUserRemainTxAndBlackHoleAndInviteRewardAmount(address user, uint256 currentReward) private view returns (uint256) {

        if (currentReward == 0) return 0;

        
        uint256 userTotalDirectDestroyAmount = _userDirectDestroyAmount[user];

        
        uint256 userTotalReward = _userTxAndBlackHoleAndInviteRewardAmount[user];

    unchecked {

        
        uint256 maxReward = userTotalDirectDestroyAmount * _blackHoleAndInviteRewardUpperLimitMultiple;

        
        if (maxReward <= userTotalReward) {
            return 0;
        }

        
        uint256 remain = maxReward - userTotalReward;
        
        if (remain >= currentReward) {
            return currentReward;
        }
        
        return remain;
    }

    }

    
    function _increaseUserDestroyAmount(address user, uint256 amount) private {
    unchecked{
        _userDirectDestroyAmount[user] += amount;
        _directDestroyTotal += amount;

    }
    }

    
    function _increaseTransferDestroyAmount(uint256 amount) private {
    unchecked{
        _transferFeeDestroyTotal = _transferFeeDestroyTotal + amount;
    }
    }

    
    function getTransferFee() public pure returns (uint256) {
        return _transferFee;
    }

    
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    
    function getNextMiningTime(address user) public view returns (uint256 nextMiningTime, uint256 times) {

        
        uint256 lastMiningTime = _userLastMiningTime[user];
        if (0 == lastMiningTime) {
            
            nextMiningTime = 0;
            times = _miningOneDayTimes;
            return (nextMiningTime, times);
        }

        
    unchecked{
        
        
        nextMiningTime = lastMiningTime + _miningInterval;
        times = (block.timestamp - lastMiningTime) / _miningInterval;
        if (times > _miningIntervalMaxTimes) {
            times = _miningIntervalMaxTimes;
        }
        return (nextMiningTime, times);
    }

    }

    
    function _decreaseTotalSupply(uint256 amount) private {
        if (_totalSupply > amount) {
        unchecked {
            _totalSupply = _totalSupply - amount;
        }
        } else {
            _totalSupply = 0;
        }
    }

    
    function _decreaseThisBalance(uint256 amount) private {
        _decreaseUserBalance(address(this), amount);
    }

    
    function _decreaseUserBalance(address user, uint256 amount) private {
        if (_userBalances[user] > amount) {
        unchecked {
            _userBalances[user] = _userBalances[user] - amount;
        }
        } else {
            _userBalances[user] = 0;
        }

    }

    
    function getTransferFeeDestroyTotal() public view returns (uint256) {
        return _transferFeeDestroyTotal;
    }

    
    function getDirectDestroyTotal() public view returns (uint256) {
        return _directDestroyTotal;
    }

    
    function getTradeFeeDestroyTotal() public view returns (uint256) {
        return _tradeFeeDestroyTotal;
    }

    
    function getIsExcludedTransferFee(address account) public view returns (bool) {
        return _isExcludedTxFee[account];
    }

    
    function getUserDestroyAmount(address user) public view returns (uint256) {
        return _userDirectDestroyAmount[user];
    }

    
    function getIsMiner(address user) public view returns (bool){
        return _isMiner[user];
    }

    
    function getUserLiquidityContractTokenAmount(address user) public view returns (uint256) {
        return _userLPTTAmount[user];
    }

    
    function getUserInviteCount(address user) public view returns (uint256) {
        return _userInviteCount[user];
    }

    
    function getUserMinerCount(address user) public view returns (uint256) {
        return _userMinerCount[user];
    }

    
    function getUserTxAndBlackHoleAndInviteRewardAmount(address user) public view returns (uint256) {
        return _userTxAndBlackHoleAndInviteRewardAmount[user];
    }

    
    function getUserLastMiningTime(address user) public view returns (uint256){
        return _userLastMiningTime[user];
    }

    
    function getUserInviter(address user) public view returns (address) {
        return _userInviter[user];
    }


    
    function _transferStandard(address from, address to, uint256 amount) internal virtual {
        uint256 fromBalance = _userBalances[from];
        require(fromBalance >= amount, "exceeds balance");

    unchecked {
        _userBalances[from] = fromBalance - amount;
        _userBalances[to] = _userBalances[to] + amount;
    }

        emit Transfer(from, to, amount);
    }

    function _transferThisTo(address to, uint256 amount) internal virtual {
        _transferStandard(address(this), to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    
    function _tryActivateMiner(address user) private {

        
        if (_isExcludedReward[user]) {return;}

        if (_isMiner[user]) {
            emit OnTryActiveMiner(user, 14);
            return;
        }

        
        uint256 userTotalDirectDestroyAmount = _userDirectDestroyAmount[user];

        
        bool canMiner = userTotalDirectDestroyAmount >= _minDestroyTokenAmount;
        if (!canMiner) {
            emit OnTryActiveMiner(user, 11);
            return;
        }

        
        if (canMiner) {

            
            uint256 userTotalReward = _userTxAndBlackHoleAndInviteRewardAmount[user];

            
            
        unchecked {
            
            uint256 maxReward = userTotalDirectDestroyAmount * _blackHoleAndInviteRewardUpperLimitMultiple;
            canMiner = maxReward > userTotalReward;


        }
        }
        if (!canMiner) {
            emit OnTryActiveMiner(user, 13);
            return;
        }

        
        uint256 lpTT = _userLPTTAmount[user];
        if (lpTT == 0) {
            canMiner = false;
        } else {
            
            uint256 minTT = userTotalDirectDestroyAmount / 10;
            canMiner = lpTT >= minTT;
        }
        if (!canMiner) {
            emit OnTryActiveMiner(user, 10);
            return;
        }

        
        if (canMiner) {
            
            
            uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);
            if (lpBalanceInChain == 0) {
                canMiner = false;
            }
            else {
                
                uint256 lpBalanceInContract = _userLPAmount[user];
                if (lpBalanceInContract > lpBalanceInChain) {
                    canMiner = false;
                }
            }
        }

        if (!canMiner) {
            emit OnTryActiveMiner(user, 12);
            return;
        }

        
        _activeMiner(user);

    unchecked{_userMinerCount[_userInviter[user]] += 1;}
        emit OnTryActiveMiner(user, 1);
    }

    function _activeMiner(address user) private {
        _isMiner[user] = true;
        
        _userLastMiningTime[user] = block.timestamp;
    }


    
    function _tryDeActiveMiner(address user) private returns (bool modifyStatus) {

        modifyStatus = false;
        
        if (_isExcludedReward[user]) {return modifyStatus;}

        
        if (!_isMiner[user]) {return modifyStatus;}

        
        uint256 userTotalDirectDestroyAmount = _userDirectDestroyAmount[user];

        
        bool canMiner = userTotalDirectDestroyAmount >= _minDestroyTokenAmount;

        
        if (canMiner) {

            
            uint256 userTotalReward = _userTxAndBlackHoleAndInviteRewardAmount[user];

            
            
        unchecked {
            
            uint256 maxReward = userTotalDirectDestroyAmount * _blackHoleAndInviteRewardUpperLimitMultiple;
            canMiner = maxReward > userTotalReward;

            
        }
        }

        
        if (canMiner) {
            uint256 lpTT = _userLPTTAmount[user];
            if (lpTT == 0) {
                canMiner = false;
            } else {
                
            unchecked{
                uint256 minTT = userTotalDirectDestroyAmount / 10;
                canMiner = lpTT >= minTT;
            }
            }
        }


        
        if (canMiner) {
            
            
            uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);
            if (lpBalanceInChain == 0) {
                
                
                _userLPAmount[user] = 0;
                _userLPTTAmount[user] = 0;
                canMiner = false;
            }
            else {
                
                uint256 lpBalanceInContract = _userLPAmount[user];
                if (lpBalanceInContract > lpBalanceInChain) {
                    
                    
                    _userLPAmount[user] = 0;
                    _userLPTTAmount[user] = 0;
                    canMiner = false;
                }
            }
        }

        
        if (canMiner) {
            modifyStatus = false;
            return modifyStatus;
        }

        
        _isMiner[user] = false;
        if (_userMinerCount[_userInviter[user]] > 0) {
        unchecked {
            _userMinerCount[_userInviter[user]] -= 1;
        }
        } else {
            _userMinerCount[_userInviter[user]] = 0;
        }
        modifyStatus = true;
    }

}

contract TTToken is AbsToken {
    constructor() AbsToken(

       
       
       
       
       
       
       address( 0x55d398326f99059fF775485246999027B3197955 ),

        
        
        
        
        
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),

        
        
        
        
        address(0x1202435599023F19A306a0D037535659204a2873),

        
        
        
        
        address(0xCc0D80Ca8B7A3115802cd0a08226F8c58e3041AB),

        "TITAN",
        "TT",


        
        
        

        500000000  

    ){
        

    }
}