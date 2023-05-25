pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IJackpot.sol";
import "../interfaces/ERC20.sol";
import "../interfaces/ICamelotRouter.sol";
import "../interfaces/ICamelotFactory.sol";
import "../interfaces/IWETH.sol";

contract AIBabyDoge is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Trade(address user, address pair, uint256 amount, uint side, uint256 circulatingSupply, uint timestamp);

    bool public luckyDropEnabled = false;

    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public canAddLiquidityBeforeLaunch;

    uint256 private totalFee;
    uint256 public feeDenominator = 10000;

    // Buy Fees
    uint256 public totalFeeBuy = 1500; // 15%
    // Sell Fees
    uint256 public totalFeeSell = 1500;

    // Fees receivers
    address private bonusWallet;
    IJackpot public jackpotWallet;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    EnumerableSet.AddressSet private _pairs;
    ICamelotFactory private factory;
    IWETH private WETH;
    bool private initialized;

    constructor(address _factory, address _weth) ERC20("AIBABYDOGE", "AIBABYDOGE") {
        uint256 _totalSupply = 420_000_000_000_000_000 * 1e6;
        canAddLiquidityBeforeLaunch[_msgSender()] = true;
        canAddLiquidityBeforeLaunch[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        factory = ICamelotFactory(_factory);
        WETH = IWETH(_weth);
        _mint(_msgSender(), _totalSupply);
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        address pair = factory.createPair(address(WETH), address(this));
        _pairs.add(pair);
        initialized = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _babydogTransfer(_msgSender(), to, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _babydogTransfer(sender, recipient, amount);
    }

    function _babydogTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
            _transfer(sender, recipient, amount);
            return true;
        }
        if (!canAddLiquidityBeforeLaunch[sender]) {
            require(launched(), "Trading not open yet");
        }

        bool shouldTakeFee = (!isFeeExempt[sender] && !isFeeExempt[recipient]) && launched();
        uint side = 0;
        address user = sender;
        address pair = recipient;
        // Set Fees
        if (isPair(sender)) {
            buyFees();
            side = 1;
            user = recipient;
            pair = sender;
            if (luckyDropEnabled) try jackpotWallet.tradeEvent(sender, amount) {} catch {}
        } else if (isPair(recipient)) {
            sellFees();
            side = 2;
        } else {
            shouldTakeFee = false;
        }

        uint256 amountReceived = shouldTakeFee ? takeFee(sender, amount) : amount;
        _transfer(sender, recipient, amountReceived);

        if (side > 0) {
            emit Trade(user, pair, amount, side, getCirculatingSupply(), block.timestamp);
        }
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function buyFees() internal {
        totalFee = totalFeeBuy;
    }

    function sellFees() internal {
        totalFee = totalFeeSell;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _transfer(sender, address(bonusWallet), feeAmount);
        return amount - feeAmount;
    }

    function rescueToken(address tokenAddress) external {
        IERC20(tokenAddress).safeTransfer(address(bonusWallet), IERC20(tokenAddress).balanceOf(address(this)));
    }

    function clearStuckEthBalance() external {
        uint256 amountETH = address(this).balance;
        (bool success, ) = payable(address(bonusWallet)).call{value: amountETH}(new bytes(0));
        require(success, "AIBABYDOGE: ETH_TRANSFER_FAILED");
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /*** ADMIN FUNCTIONS ***/
    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setBuyFees(uint256 _totalFeeBuy) external onlyOwner {
        totalFeeBuy = _totalFeeBuy;
    }

    function setSellFees(uint256 _totalFeeSell) external onlyOwner {
        totalFeeSell = _totalFeeSell;
    }

    function setFeeReceivers(address _bonusWallet, address _jackpotWallet) external onlyOwner {
        bonusWallet = _bonusWallet;
        jackpotWallet = IJackpot(_jackpotWallet);
        isFeeExempt[_bonusWallet] = true;
        isFeeExempt[_jackpotWallet] = true;
    }

    function setIsFeeExempt(address[] memory holder, bool exempt) external onlyOwner {
        for (uint256 i = 0; i < holder.length; i++) {
            isFeeExempt[holder[i]] = exempt;
        }
    }

    function setLuckyDropEnabled(bool _enabled) external onlyOwner {
        luckyDropEnabled = _enabled;
    }

    function isPair(address account) public view returns (bool) {
        return _pairs.contains(account);
    }

    function addPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "AIBABYDOGE: pair is the zero address");
        return _pairs.add(pair);
    }

    function delPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "AIBABYDOGE: pair is the zero address");
        return _pairs.remove(pair);
    }

    function getMinterLength() public view returns (uint256) {
        return _pairs.length();
    }

    function getPair(uint256 index) public view returns (address) {
        require(index <= _pairs.length() - 1, "AIBABYDOGE: index out of bounds");
        return _pairs.at(index);
    }

    receive() external payable {}
}