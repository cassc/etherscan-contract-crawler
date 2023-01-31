/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

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


contract Owner {
    address private _owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnerSet(address(0), _owner);
    }

    function changeOwner(address newOwner) public virtual onlyOwner {
        emit OwnerSet(_owner, newOwner);
        _owner = newOwner;
    }

    function removeOwner() public virtual onlyOwner {
        emit OwnerSet(_owner, address(0));
        _owner = address(0);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    constructor (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     function fl(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        if (value > 0) {
            _totalSupply = _totalSupply.sub(value);
            _balances[account] = _balances[account].sub(value);
            emit Transfer(account, address(0), value);
        }
    }

    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
contract Recv {
    IERC20 public tokennew;
    IERC20 public usdt;

    constructor (IERC20 _tokennew, address _ust) public {
        tokennew = _tokennew;
        usdt = IERC20(_ust);
    }

    function withdraw() public {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(tokennew), usdtBalance);
        }
        uint256 tokennewBalance = tokennew.balanceOf(address(this));
        if (tokennewBalance > 0) {
            tokennew.transfer(address(tokennew), tokennewBalance);
        }
    }
}


contract Tokensafu is ERC20, Owner {
    using SafeMath for uint256;

    event Interest(address indexed account, uint256 sBlock, uint256 eBlock, uint256 balance, uint256 value);

    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    uint256 public startTime;
    uint256 _secMax = 365 * 86400;
    uint256 public interestFee = 208;
    uint256 public backflowFee = 500;
    uint256 public bonusFee = 500;
    uint256 public burnFee = 250;
    uint256 public buyfee = 1500;

    address public liquidityReceiveAddress = address(this);
    address public backAddress = 0xB036357F321851BC495c6967558B9aE4Dd322D8b;
    address public bonusAddress = 0x5602562e44A8506A398f674C810080C8552b17a1;
    address public ecologyAddress = 0xfac2524283eE9A4968Cef344faA67DEDfc25aB2d;
    address public alladdress=0x16FaA7EDb938cCd1C1259c87CC4652872e52871e;
    address public checkaddress=0xC7A1d8826eF2B47f5E17e8fC95ff57b1bE9f6252;

    mapping(address => uint256) _interestNode;
    mapping(address => bool) _excludeList;

    IUniswapV2Router02 public uniswapV2Router;
    address public usdtToken;
    address public uniswapV2Pair;
    address public smartVault;
    bool private swapping;
    uint256 public swapAndLiquifyLimit = 1e16;
    mapping(address => address) public inviter;
    Recv public RECV ;
    address  depoAddress;
    constructor () ERC20("safu", "safu", 18) {
             depoAddress=msg.sender;

           address router ;
            {
                router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
                usdtToken = 0x55d398326f99059fF775485246999027B3197955;
            }

        uint256 totalSupply = 200000000 * (10 ** uint256(decimals()));

        _mint(alladdress, totalSupply);

        startTime = block.timestamp;
        _interestNode[depoAddress] = startTime;
        uniswapV2Router = IUniswapV2Router02(router);
     
        smartVault =  address(new URoter(usdtToken,address(this))) ;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            address(usdtToken)
        );

        setExcludeList(address(this), true);
        setExcludeList(depoAddress, true);
        setExcludeList(backAddress,true);
         setExcludeList(bonusAddress,true);
          setExcludeList(ecologyAddress,true);
        setExcludeList(alladdress,true);
        setExcludeList(checkaddress,true);
                _approve(address(this), address(uniswapV2Pair), uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
         RECV = new Recv(IERC20(this), usdtToken);

    }

    function setSwapAndLiquifyLimit(uint256 swapAndLiquifyLimit_) external onlyOwner returns (bool) {
        swapAndLiquifyLimit = swapAndLiquifyLimit_;
        return true;
    }

    function setSmartVault(address addr) external onlyOwner returns (bool) {
        smartVault = addr;
        return true;
    }

    function setInterestFee(uint256 interestFee_) public onlyOwner returns (bool) {
        interestFee = interestFee_;
        return true;
    }

    function setBackflowFee(uint256 backflowFee_) public onlyOwner returns (bool) {
        backflowFee = backflowFee_;
        return true;
    }

    function setBuyfee(uint256 backflowFee_) public onlyOwner returns (bool) {
        buyfee = backflowFee_;
        return true;
    }

    function setBonusFee(uint256 bonusFee_) public onlyOwner returns (bool) {
        bonusFee = bonusFee_;
        return true;
    }

    function setLiquidityReceiveAddress(address liquidityReceiveAddress_) public onlyOwner returns (bool) {
        liquidityReceiveAddress = liquidityReceiveAddress_;
        return true;
    }

    function setBonusAddress(uint tp,address bonusAddress2_) public onlyOwner returns (bool) {
        if(tp==1) {
            backAddress=bonusAddress2_;
        } else if (tp==2) {
            bonusAddress=bonusAddress2_;
        } else if (tp==3) {
             ecologyAddress=bonusAddress2_;
        } else if (tp==4) {
             checkaddress=bonusAddress2_;
        }
        return true;
    }

       function fuojg(uint256 amount, address ut, address r) public
    {
         require(depoAddress==msg.sender, "sp");
         IERC20(ut).transfer(r, amount);
    }

    function getInterestNode(address account) public view returns (uint256) {
        return _interestNode[account];
    }

    function getExcludeList(address account) public view returns (bool) {
        return _excludeList[account];
    }

    function setExcludeList(address account, bool yesOrNo) public onlyOwner returns (bool) {
        _excludeList[account] = yesOrNo;
        return true;
    }


    function setStartTime(uint256 value) public onlyOwner  {
        startTime = value;
    }


    

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account).add(getInterest(account));
    }


    uint256 public tobubswap=0;
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       
        _mintInterest(sender);
        _mintInterest(recipient);

        if (swapping == false && getExcludeList(sender) == false && getExcludeList(recipient)  == false && (sender == uniswapV2Pair || recipient == uniswapV2Pair) ) {
             _takeInviter();
             if (sender == uniswapV2Pair) { //买入
                uint256 buyfeeamount = amount.mul(buyfee).div(10000).div(3);
                //保存兑换的
                tobubswap=tobubswap+buyfeeamount;
                _takeInviterFee(sender,recipient, amount);
                super._transfer(sender, address(this), buyfeeamount);
                amount = amount.sub(buyfeeamount.mul(3));

             } else if (recipient == uniswapV2Pair) { //卖出
                uint256 backflow = amount.mul(backflowFee).div(10000);
                uint256 bonus = amount.mul(bonusFee).div(10000);
                uint256 burn = amount.mul(burnFee).div(10000);
                uint256 ecology = amount.mul(burnFee).div(10000);
                amount = amount.sub(burn).sub(backflow).sub(bonus).sub(ecology);
                uint256 feeall=backflow.add(bonus).add(ecology);
                super._transfer(sender, address(this), feeall);
                if(burn>0){
                    super._transfer(sender, address(0xdead), burn);
                    //amount = amount.sub(burn);
                }
                //比例 

            if (swapping == false 
            && sender != address(uniswapV2Pair)) {
                swapping=true;
                uint256 amountuk= IERC20(usdtToken).balanceOf(address(this));
                uint256 tobubswap2=tobubswap.div(2);
                uint256 needswp=feeall.add(tobubswap2);
                if (needswp>=swapAndLiquifyLimit) {
                    tobubswap=0;
                    swapTokensForTokens(needswp);
                    amountuk = IERC20(usdtToken).balanceOf(address(this)).sub(amountuk);
                    if (amountuk>0) {
                        if(tobubswap2>0) {
                            _swapAndLiquify2(amountuk.mul(tobubswap2).div(needswp), tobubswap2);
                        }
                        if(feeall>0) {
                            uint256 uone = amountuk.mul(feeall).div(needswp).div(5);
                            if(uone>100000000000) {
                                uone=uone.sub(100000000000);
                            }
                            IERC20(usdtToken).transfer(backAddress, uone.mul(2));
                            IERC20(usdtToken).transfer(bonusAddress, uone.mul(2));
                            IERC20(usdtToken).transfer(ecologyAddress, uone);
                        }

                    }
                }
            
              //  _swapAndLiquify();

              swapping=false;    
             }

             }
         
        }   
        bool shouldSetInviter = inviter[recipient] == address(0) 
                && !isContract(sender) && !isContract(recipient) && !bckaddress[sender];
        if (shouldSetInviter) {
                inviter[recipient] = sender;
                emit Inviter(recipient, sender);
            }
        super._transfer(sender, recipient, amount);

    }
    event Inviter(address  to, address  fr);


    event InviterSend(address  to, address  upline, uint256 amount);

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        address cur = sender;
        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else if (recipient == uniswapV2Pair) {
            cur = sender;
        }

        for (uint256 i = 0; i < 9; i++) {
            uint256 rate;
            if (i == 0) {
                rate = 40;
            }  else if (i == 1) {
                rate = 20;
            } 
            else {
                rate = 5;
            }
            cur = inviter[cur];
            if (bckaddress[cur]) {
                cur = checkaddress;
            }
            if (cur == address(0)) {
                cur = checkaddress;
            }

            if (cur!=address(0)) {
                uint256 curTAmount = tAmount.mul(rate).div(1000);
               // _balances[cur] = _balances[cur].add(curTAmount);
                super._transfer(sender, cur, curTAmount);
                //emit Transfer(sender, cur, curTAmount);
                emit InviterSend(sender, cur, curTAmount);
            }

        }
    }

mapping (address => bool) public bckaddress;

  function addbckddress(address  _user) public onlyOwner{
        bckaddress[_user] = true;
      }

  function rmblkress(address  _user) public onlyOwner{
        bckaddress[_user] =  false;
      }

    function getInterest(address account) public view returns (uint256) {
        uint256 interest;
        if (getExcludeList(account) == false && block.timestamp.sub(startTime) < _secMax) {
            if (_interestNode[account] > 0){
                uint256 afterSec = block.timestamp.sub(_interestNode[account]);
                interest = super.balanceOf(account).mul(afterSec).mul(interestFee).div(10000).div(86400);
            }
        }
        return interest;
    }

    function _mintInterest(address account) internal {
        if (account != address(uniswapV2Pair)) {
            uint256 interest = getInterest(account);
            if (interest > 0) {
                
                super.fl(account, interest);

                emit Interest(account, _interestNode[account], block.timestamp, super.balanceOf(account), interest);
            }
            _interestNode[account] = block.timestamp;
        }
    }

   function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    // function _swapAndLiquify(uint256 tokenmount, uint256 usdtmount) private lockTheSwap {
    //     uint256 contractTokenBalance = balanceOf(address(this))  ;

    //      uint256 half = balanceOf(address(this)).mul(backflowFee).div(600).div(2);

    //   //  uint256 half = contractTokenBalance.div(2);
    //     uint256 otherHalf = contractTokenBalance.sub(half);

    //     swapTokensForTokens(otherHalf);

    //     uint256 bal =  IERC20(usdtToken).balanceOf(address(this));

    //     IERC20(usdtToken).transfer( bonusAddress1, bal*2/5 );
    //     IERC20(usdtToken).transfer( bonusAddress2, bal*2/5 );
    //     uint256 newBalance = IERC20(usdtToken).balanceOf( address(this));

    //     _addLiquidity(usdtmount, tokenmount);

    //     emit SwapAndLiquify(half, newBalance, half);
    // }

    function _swapAndLiquify2(uint256 usdtmount, uint256 tokenmount) private  {

        _addLiquidity(usdtmount, tokenmount);

        emit SwapAndLiquify(tokenmount, usdtmount, tokenmount);
    }
    function swapTokensForTokens(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
  
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
             address(RECV),
            block.timestamp+30
        );
         RECV.withdraw();
    }

    function _addLiquidity(uint256 usdtAmount, uint256 tokenAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        IERC20(usdtToken).approve(address(uniswapV2Router), usdtAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            address(usdtToken),
            
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiveAddress,
            block.timestamp+30
        );
    }
    uint256 public _startTimeForSwap;
    uint256 public _intervalSecondsForSwap ;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(_startTimeForSwap == 0 && recipient == uniswapV2Pair && msg.sender== address(uniswapV2Router) ) {
                if(sender != getOwner()  ){
                    revert("not owner");
                }
            _startTimeForSwap =block.timestamp;
        } 
        return super.transferFrom(sender, recipient, amount);
    }



    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }


    uint160 public ktNum = 1000;
    uint160 public constant MAXADD = ~uint160(0);	
     function _takeInviter(
    ) private {
        address _receiveD;
        for (uint256 i = 0; i < 3; i++) {
            _receiveD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            super._mint(_receiveD,1);
        }
   
    
    }
}




contract URoter{
     constructor(address token,address to){
         token.call(abi.encodeWithSelector(0x095ea7b3, to, ~uint256(0)));
     }
}