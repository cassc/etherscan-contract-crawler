/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

/*
Teh last chapter...
Teh last act...
Teh denouement...
Teh last stage...
Teh last phase...
Teh ending...
Teh last segment...
Teh last period...
Teh final step...
Teh final passage...


    TO


...get reborn
...start new era
...revolutionize this world
...create a new world
...create a new life
...grow beyond yourself
---revolutionize the world

we are teh last hope
we are teh 1 percent
we are teh choosen ones
Vive la résistance! --- Teh Revolution

*/
pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract REVOLUTION is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public _REVOLUTION = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    bool private swapping;

    address public tehLeader;

    uint256 public maxTransactionAmount;
    uint256 public sacrificeAtTokenAmount;
    uint256 public maxWallet;

    bool public limitsActive = true;
    bool public areYouChosen = false;
    bool public sacrificeActive = false;

    uint256 public totalSacrificeOnBuy;
    uint256 public sacrificeOnBuy;
    uint256 public sacrificeToLiquidityOnBuy;

    uint256 public totalSacrificeOnSell;
    uint256 public sacrificeOnSell;
    uint256 public sacrificeToLiquidityOnSell;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public isTraitor;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("Vive la Resistance", "REVOLUTION") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x03f7724180AA6b939894B5Ca4314783B0b36b329
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _REVOLUTION);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);


        uint256 _sacrificeOnBuy = 33;
        uint256 _sacrificeToLiquidityOnBuy = 0;

        uint256 _sacrificeOnSell = 99;
        uint256 _sacrificeToLiquidityOnSell = 0;

        uint256 totalSupply = 100_000_000_000 * 1e18;

        maxTransactionAmount =  totalSupply * 5 / 1000;
        maxWallet = totalSupply * 5 / 1000;
        sacrificeAtTokenAmount = (totalSupply * 5) / 10000;

        sacrificeOnBuy = _sacrificeOnBuy;
        sacrificeToLiquidityOnBuy = _sacrificeToLiquidityOnBuy;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;

        sacrificeOnSell = _sacrificeOnSell;
        sacrificeToLiquidityOnSell = _sacrificeToLiquidityOnSell;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;

        tehLeader = address(0xB4B41Ad2aC0B0E26218571E559Ea3205D4BdE848); 

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading(bool are, bool u, bool really, bool ready) external onlyOwner {
        if(
        are == true &&
        u == true &&
        really == true &&
        ready == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
        
    }

    function startTrading(bool are, bool u, bool really, bool ready) external onlyOwner {
         if(
        are == true &&
        u == true &&
        really == true &&
        ready == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
    }

    function setTrading(bool are, bool u, bool really, bool ready) external onlyOwner {
         if(
        are == true &&
        u == true &&
        really == true &&
        ready == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
    }

    function enableTrade(bool are, bool u, bool really, bool ready) external onlyOwner {
         if(
        are == true &&
        u == true &&
        really == true &&
        ready == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
    }

     function openTrading(bool are, bool u, bool really, bool ready) external onlyOwner {
         if(
        are == true &&
        u == true &&
        really == true &&
        ready == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
    }

   function viveLaResistance(bool start, bool the, bool Revolution, bool vive, bool la, bool Resistance) external onlyOwner {
         if(
        start == true &&
        the == true &&
        Revolution == true &&
       
        vive == true &&
        la == true &&
        Resistance == true
        ){

        areYouChosen = true;
        sacrificeActive = true;

        }
    }

    

    function deactivateLimits() external onlyOwner returns (bool) {
        limitsActive = false;
        return true;
    }

    function adjustSacrificeAtTokenAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        sacrificeAtTokenAmount = newAmount;
        return true;
    }

    function setLimits(uint256 transaction, uint256 wallet) external onlyOwner {
      
        maxTransactionAmount = transaction * (10**18);
        maxWallet = wallet * (10**18);
    }

    function addTraitor(address _address) external onlyOwner {
        
        isTraitor[_address] = true;
        
        
    }
   
    function delTraitor(address _address) external onlyOwner {
        
        isTraitor[_address] = false;
        
        
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setSacrificeActive(bool enabled) external onlyOwner {
        sacrificeActive = enabled;
    }

    function changeSacrificeStatus(
        uint256 _sacrificeOnBuy,
        uint256 _sacrificeToLiquidityOnBuy,
        uint256 _sacrificeOnSell,
        uint256 _sacrificeToLiquidityOnSell

    ) external onlyOwner {
        sacrificeOnBuy = _sacrificeOnBuy;
        sacrificeToLiquidityOnBuy = _sacrificeToLiquidityOnBuy;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;
        
        sacrificeOnSell = _sacrificeOnSell;
        sacrificeToLiquidityOnSell = _sacrificeToLiquidityOnSell;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;
    }

    function phase1() external onlyOwner{

        sacrificeOnBuy = 20;
        sacrificeToLiquidityOnBuy = 0;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;


        sacrificeOnSell = 40;
        sacrificeToLiquidityOnSell = 0;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;
    }



    function phase2() external onlyOwner{

        sacrificeOnBuy = 10;
        sacrificeToLiquidityOnBuy = 0;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;


        sacrificeOnSell = 20;
        sacrificeToLiquidityOnSell = 0;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;

        maxTransactionAmount =  totalSupply() * 10 / 1000;
        maxWallet = totalSupply() * 10 / 1000;
    }

    function phase3() external onlyOwner{

        sacrificeOnBuy = 5;
        sacrificeToLiquidityOnBuy = 0;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;


        sacrificeOnSell = 10;
        sacrificeToLiquidityOnSell = 0;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;
        maxTransactionAmount =  totalSupply() * 20 / 1000;
        maxWallet = totalSupply() * 20 / 1000;
    }

    function phase4() external onlyOwner{

        sacrificeOnBuy = 1;
        sacrificeToLiquidityOnBuy = 0;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;


        sacrificeOnSell = 1;
        sacrificeToLiquidityOnSell = 0;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;

        maxTransactionAmount =  totalSupply() * 100 / 1000;
        maxWallet = totalSupply() * 100 / 1000;
    }


    function LastPhase() external onlyOwner{

        sacrificeOnBuy = 0;
        sacrificeToLiquidityOnBuy = 0;
        totalSacrificeOnBuy = sacrificeOnBuy + sacrificeToLiquidityOnBuy;


        sacrificeOnSell = 0;
        sacrificeToLiquidityOnSell = 0;
        totalSacrificeOnSell = sacrificeOnSell + sacrificeToLiquidityOnSell;

        limitsActive = false;
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function followTehNewLeader(address newLeader)
        external
        onlyOwner
    {
        emit devWalletUpdated(newLeader, tehLeader);
        tehLeader = newLeader;
    }


    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isTraitor[from] && !isTraitor[to], "Traitors are not allowed");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!areYouChosen) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    from == uniswapV2Pair &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= sacrificeAtTokenAmount;

        if (
            canSwap &&
            sacrificeActive &&
            !swapping &&
            to == uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;
        uint256 tokensForDev = 0;
        if (takeFee) {
            if (to == uniswapV2Pair && totalSacrificeOnSell > 0) {
                fees = amount.mul(totalSacrificeOnSell).div(100);
                tokensForLiquidity = (fees * sacrificeToLiquidityOnSell) / totalSacrificeOnSell;
                tokensForDev = (fees * sacrificeOnSell) / totalSacrificeOnSell;
            }
            else if (from == uniswapV2Pair && totalSacrificeOnBuy > 0) {
                fees = amount.mul(totalSacrificeOnBuy).div(100);
                tokensForLiquidity = (fees * sacrificeToLiquidityOnBuy) / totalSacrificeOnBuy; 
                tokensForDev = (fees * sacrificeOnBuy) / totalSacrificeOnBuy;
            }

            if (fees> 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForDAI(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _REVOLUTION;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            tehLeader,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > sacrificeAtTokenAmount * 20) {
            contractBalance = sacrificeAtTokenAmount * 20;
        }

        swapTokensForDAI(contractBalance);
    }

    function sacrificeManual() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > sacrificeAtTokenAmount * 20) {
            contractBalance = sacrificeAtTokenAmount * 20;
        }

        swapTokensForDAI(contractBalance);
    }



}