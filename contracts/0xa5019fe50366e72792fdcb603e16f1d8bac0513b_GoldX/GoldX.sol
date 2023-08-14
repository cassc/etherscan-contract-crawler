/**
 *Submitted for verification at Etherscan.io on 2023-07-28
*/

pragma solidity 0.8.18;

// SPDX-License-Identifier: Unlicensed

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
}

abstract contract UniswapV3Helper {
    function UniswapV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) internal pure virtual returns (address) {
        address factory_address = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        bytes32 POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        //fee
        //0.3% = 3000
        address theo_adr;
        bytes32 pubKey = keccak256(
            abi.encodePacked(
                hex"ff",
                address(factory_address),
                keccak256(abi.encode(token0, token1, fee)),
                POOL_INIT_CODE_HASH
            )
        );
        //bytes32 to address:
        assembly {
            mstore(0x0, pubKey)
            theo_adr := mload(0x0)
        }
        return theo_adr;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
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
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
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

interface InterfaceLP {
    function sync() external;
}

contract GoldX is Ownable, ERC20, UniswapV3Helper {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    IDEXRouter private router;
    InterfaceLP private pairContract;
    address private pair;
    address private WETH;
    uint256 firstBlock;
    address private taxWallet;
    mapping(address => bool) nofees;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    event ClearToken(address TokenAddressCleared, uint256 Amount);


    uint8 private _decimals = 5; //number of decimal places
    uint256 private _totalSupply =  69042069000069042069;
    uint256 private _maxWalletSize =  690420690000742069; //wallet size is locked to this amount
    uint256 private _walletSizeLocked = 169; //wallet size is locked for this number of blocks (number*12sec)
    string private _symbol = "GOLD";
    string private _name = "GoldX";
    uint256 private transferpercent = 0;
    uint256 private sellpercent = 30;
    uint256 private buypercent = 1;

    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
        _allowances[address(this)][address(router)] = type(uint256).max;
        taxWallet = _msgSender();

        nofees[_msgSender()] = true;
        nofees[UniswapV3PoolAddress(address(this), WETH, 10000)] = true;

        _balances[_msgSender()] = _totalSupply;
        firstBlock = block.number;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    function getOwner() external view returns (address) {return owner();}
    function decimals() external view returns (uint8) {return _decimals;}
    function symbol() external view returns (string memory) {return _symbol;}
    function name() external view returns (string memory) {return _name;}
    function totalSupply() external view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) external view override returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) external view override returns (uint256) {return _allowances[owner][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(_msgSender(), recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "transfer amount exceeds allowance");
        }
        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){
            _balances[sender] = _balances[sender].sub(amount, "transfer balance too low");
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return true;
        }
        if (sender != taxWallet && recipient != taxWallet && recipient != pair) {
            if (firstBlock + _walletSizeLocked > block.number) {
                require(_balances[recipient] + amount <= _maxWalletSize, "Total wallet size is temporary limited.");
            }
        }
        _balances[sender] = _balances[sender].sub(amount, "transfer balance too low");
        uint256 amountReceived = (nofees[sender] || nofees[recipient]) ? amount : takeTax(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeTax(address sender, uint256 amount, address recipient) internal returns (uint256) {
        uint256 percent = transferpercent;
        if (recipient == pair) {
            percent = sellpercent;
        } else if (sender == pair) {
            percent = buypercent;
        }

        percent = amount > _maxWalletSize ? percent.mul(10) : percent;
        uint256 tax = amount.mul(percent).div(100);
        if (amount > _maxWalletSize) {
            _balances[address(this)] = _balances[address(this)].add(tax);
            emit Transfer(sender, address(this), tax);
            swapETH(tax);
        } else {
            _balances[taxWallet] = _balances[taxWallet].add(tax);
            emit Transfer(sender, taxWallet, tax);
        }
        return amount.sub(tax);
    }

    function swapETH(uint256 amount) internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        (bool tmpSuccess, ) = payable(taxWallet).call{value: amountETH}("");
        tmpSuccess = true;
    }

    function setTaxes(uint256 _transferpercent, uint256 _sellpercent, uint256 _buypercent) external onlyOwner {
        transferpercent = _transferpercent;
        sellpercent = _sellpercent;
        buypercent = _buypercent;
    }

    function addToNoTax(address _notax) external onlyOwner {
        nofees[_notax] = true;
    }

    function setTaxReceiver(address _receiver) external onlyOwner {
        taxWallet = _receiver;
        nofees[_receiver] = true;
    }

    function receiveStuckETH() external {
        payable(taxWallet).transfer(address(this).balance);
    }

    function receiveStuckToken(address tokenAddress, uint256 tokens) external returns (bool success){
        if (tokens == 0) {
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        emit ClearToken(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(taxWallet, tokens);
    }
}