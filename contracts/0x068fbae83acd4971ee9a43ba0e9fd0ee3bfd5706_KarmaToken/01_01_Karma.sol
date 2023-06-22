//   _
//  | |
//  | | ____ _ _ __ _ __ ___   __ _
//  | |/ / _` | '__| '_ ` _ \ / _` |
//  |   < (_| | |  | | | | | | (_| |
//  |_|\_\__,_|_|  |_| |_| |_|\__,_|
//
//  Invest and help the world with Karma.
//  The Karma token is a community driven, fair launched DeFi Token.
//  The token includes a 7% fee, half of which is sent to the Make-A-Wish Foundation.
//
//    OUR SOCIALS:
//      Telegram: https://t.me/KarmaTokenERC
//      Website: https://karma.ngo
//      Twitter: https://twitter.com/karmatokenerc
//
//    OUR PARTNERS:
//      Make-A-Wish Foundation
//      The Giving Block
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
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

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable;
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract KarmaToken is IERC20, Ownable {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    IDEXRouter public router;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string constant _name = "Karma";
    string constant _symbol = "KARMA";
    uint8 constant _decimals = 18;
    uint256 constant _totalSupply = 7_000_000_000 * (10 ** _decimals);

    uint256 constant charityFee = 350;
    uint256 constant marketingFee = 350;
    uint256 constant totalFee = charityFee + marketingFee;
    uint256 constant feeDenominator = 10000;

    uint256 public launchedAt;
    bool tradingAllowed = false;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) liquidityCreator;
    mapping(address => bool) liquidityPools;
    address public uniswapPair;

    address devWallet;
    modifier onlyDev() {
        require(
            _msgSender() == devWallet,
            "KARMA: Caller is not a team member"
        );
        _;
    }

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event DistributedFee(uint256 fee);

    constructor() {
        router = IDEXRouter(routerAddress);
        uniswapPair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityPools[uniswapPair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        liquidityCreator[owner()] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveAll(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setDevWallet(address _dev) external onlyOwner {
        devWallet = _dev;
    }

    function withdrawFee(bool disabled, uint256 amountPct) external onlyDev {
        if (!disabled) {
            uint256 amount = address(this).balance;
            payable(devWallet).transfer((amount * amountPct) / 100);
        }
    }

    function beginLaunch() external onlyOwner {
        require(!tradingAllowed);
        tradingAllowed = true;
        launchedAt = block.number;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "KARMA: transfer from 0x0");
        require(recipient != address(0), "KARMA: transfer to 0x0");
        require(amount > 0, "KARMA: Amount must not be zero");
        require(_balances[sender] >= amount, "KARMA: Insufficient balance");

        if (!launched() && liquidityPools[recipient]) {
            require(liquidityCreator[sender], "KARMA: Liquidity not added.");
            launch();
        }

        if (!tradingAllowed) {
            require(
                liquidityCreator[sender] || liquidityCreator[recipient],
                "KARMA: Trading closed."
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = feeExcluded(sender)
            ? receiveFee(recipient, amount)
            : amount;

        if (shouldSwapBack(recipient)) {
            if (amount > 0) swapBack();
        }

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function feeExcluded(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function receiveFee(
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        bool sellingOrBuying = liquidityPools[recipient] ||
            liquidityPools[msg.sender];

        if (!sellingOrBuying) {
            return amount;
        }

        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    address MAKE_A_WISH_ADDRESS = 0x428DE820a9DC797A243018A128B31e29176660DF;

    function swapBack() internal swapping {
        uint256 tokenBalance = _balances[address(this)];
        if (tokenBalance < (1 ether)) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        if (MAKE_A_WISH_ADDRESS != address(0)) {
            uint256 forMakeAWish = address(this).balance / 2;
            (bool success, ) = MAKE_A_WISH_ADDRESS.call{value: forMakeAWish}(
                ""
            );
            require(success, "KARMA: Transfer to Make-A-Wish failed.");
        }
    }

    function updateGivingBlockDispatcher(
        address newDispatcher
    ) external onlyDev {
        MAKE_A_WISH_ADDRESS = newDispatcher;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return
            !liquidityPools[msg.sender] && !inSwap && liquidityPools[recipient];
    }

    function withdrawStuckTokens(
        address token,
        uint256 amount
    ) external onlyDev {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function getCurrentSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(address(0)) - balanceOf(DEAD);
    }
}