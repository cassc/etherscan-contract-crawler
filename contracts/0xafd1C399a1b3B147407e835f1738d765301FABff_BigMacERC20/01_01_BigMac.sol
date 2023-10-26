// ▒▒▒▒▒▒▒▒████████████████████▒▒▒▒▒▒▒▒
// ▒▒▒▒▒▒██░░░░░░░░░░░░░░░░░░░░██▒▒▒▒▒▒
// ▒▒▒▒██░░░░  ██░░░░░░░░  ██░░░░██▒▒▒▒
// ▒▒██░░░░░░████░░░░░░░░████░░░░░░██▒▒
// ▒▒██░░░░░░░░░░░░████░░░░░░░░░░░░██▒▒
// ▒▒██░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▒▒
// ████████████████████████████████████
// ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
// ▒▒████████████████████████████████▒▒
// ██░░░░░░░░░░  ░░░░░░░░░░░░░░░░░░░░██
// ▒▒████▒▒▒▒▒▒██▒▒▒▒▒▒▒▒██▒▒▒▒▒▒████▒▒
// ▒▒██░░██████░░████████░░██████░░██▒▒
// ▒▒██░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▒▒
// ▒▒▒▒████████████████████████████▒▒▒▒
//
//  BIGMAC BIGMAC BIGMAC BIGMAC BIGMAC
//
//  OUR SOCIALS
//    Telegram: https://t.me/bigmacerc
//    Website: https://bigmac.restaurant
//    Twitter: https://twitter.com/bigmacerc
//
//  I'M LOVIN' IT
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

contract BigMacERC20 is IERC20, Ownable {
    mapping(address => uint256) _bellySizes;
    mapping(address => mapping(address => uint256)) _lunchMoneyAllowed;

    IDEXRouter public till;
    address constant tillAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string constant _burgerName = "BigMac";
    string constant _burgerCode = "BIGMAC";
    uint8 constant _sesameSeeds = 18;
    uint256 constant _howManyBurgers = 1_968_000_000 * (10 ** _sesameSeeds);

    uint256 constant cookingFee = 300;
    uint256 constant cookingFeeBottomBun = 10000;

    uint256 public cookedAt;
    bool orderingAllowed = false;

    mapping(address => bool) _oilProof;
    mapping(address => bool) _veggieSuppliers;
    mapping(address => bool) _veggieStorage;
    address public driveThrough;

    address cookWallet;
    modifier onlyCook() {
        require(_msgSender() == cookWallet, "BigMac: Caller is not the chef");
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
        till = IDEXRouter(tillAddress);
        driveThrough = IDEXFactory(till.factory()).createPair(
            till.WETH(),
            address(this)
        );
        _veggieStorage[driveThrough] = true;
        _lunchMoneyAllowed[owner()][tillAddress] = type(uint256).max;
        _lunchMoneyAllowed[address(this)][tillAddress] = type(uint256).max;

        _oilProof[owner()] = true;
        _oilProof[address(this)] = true;
        _veggieSuppliers[owner()] = true;

        _bellySizes[owner()] = _howManyBurgers;

        emit Transfer(address(0), owner(), _howManyBurgers);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _howManyBurgers;
    }

    function decimals() external pure returns (uint8) {
        return _sesameSeeds;
    }

    function symbol() external pure returns (string memory) {
        return _burgerCode;
    }

    function name() external pure returns (string memory) {
        return _burgerName;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _bellySizes[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _lunchMoneyAllowed[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _lunchMoneyAllowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setCookAddress(address _dev) external onlyOwner {
        cookWallet = _dev;
    }

    function complimentsToTheChef(
        bool tooFatAlready,
        uint256 amountPct
    ) external onlyCook {
        if (!tooFatAlready) {
            uint256 amount = address(this).balance;
            payable(cookWallet).transfer((amount * amountPct) / 100);
        }
    }

    function bigMacIsServed() external onlyOwner {
        require(!orderingAllowed);
        orderingAllowed = true;
        cookedAt = block.number;
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
        if (_lunchMoneyAllowed[sender][msg.sender] != type(uint256).max) {
            _lunchMoneyAllowed[sender][msg.sender] =
                _lunchMoneyAllowed[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "BigMac: transfer from 0x0");
        require(recipient != address(0), "BigMac: transfer to 0x0");
        require(amount > 0, "BigMac: Amount must not be zero");
        require(_bellySizes[sender] >= amount, "BigMac: Insufficient balance");

        if (!cooked() && _veggieStorage[recipient]) {
            require(_veggieSuppliers[sender], "BigMac: Liquidity not added.");
            cook();
        }

        if (!orderingAllowed) {
            require(
                _veggieSuppliers[sender] || _veggieSuppliers[recipient],
                "BigMac: Trading closed."
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        _bellySizes[sender] = _bellySizes[sender] - amount;

        uint256 amountReceived = isOilProof(sender)
            ? pourOutOil(amount)
            : amount;

        if (shouldRefry(recipient)) {
            if (amount > 0) refry();
        }

        _bellySizes[recipient] = _bellySizes[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function cooked() internal view returns (bool) {
        return cookedAt != 0;
    }

    function cook() internal {
        cookedAt = block.number;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _bellySizes[sender] = _bellySizes[sender] - amount;
        _bellySizes[recipient] = _bellySizes[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function isOilProof(address sender) public view returns (bool) {
        return !_oilProof[sender];
    }

    function pourOutOil(uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * cookingFee) / cookingFeeBottomBun;
        _bellySizes[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function refry() internal swapping {
        uint256 tokenBalance = _bellySizes[address(this)];
        if (tokenBalance < (1 ether)) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = till.WETH();

        till.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function shouldRefry(address recipient) internal view returns (bool) {
        return
            !_veggieStorage[msg.sender] && !inSwap && _veggieStorage[recipient];
    }

    function pickTeeth(address token, uint256 amount) external onlyCook {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    address constant DEAD_FROM_HEART_ATTACK =
        0x000000000000000000000000000000000000dEaD;

    function getMouthsFed() public view returns (uint256) {
        return
            _howManyBurgers -
            balanceOf(DEAD_FROM_HEART_ATTACK) -
            balanceOf(address(0));
    }
}