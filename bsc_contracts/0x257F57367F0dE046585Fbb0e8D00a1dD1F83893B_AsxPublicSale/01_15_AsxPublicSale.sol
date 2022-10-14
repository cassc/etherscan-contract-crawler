// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "./Whitelist.sol";
import "./PinkLock02.sol";

contract AsxPublicSale is Ownable, Whitelist {
    struct PaymentToken {
        address tokenAddress;
        address priceFeedAddress;
    }

    mapping(address => uint256) public balances;
    mapping(address => uint256) public bonuses;
    mapping (address => bool) private paymentTokens;
    mapping (address => AggregatorInterface) internal priceFeed;

    uint256 private MIN_DEPOSIT = 990 * 10 ** 18;
    uint256 private MAX_DEPOSIT = 20000 * 10 ** 18;
    uint256 private LISTING_PRICE = 0.05 * 10 ** 18;
    uint256 public TOTAL_SALES = 0;
    uint256 public TOTAL_BONUS = 0;
    uint256 public PRESALE_BONUS = 0;
    uint256 private TGE_DATE;
    address private USDT_TOKEN;
    address private ASX_TOKEN;
    address private LOCKER;
    address private RECEIVER;
    
    event Deposit(address sender, uint amount, address token, uint256 asxAmount, uint256 bonus, uint256 vestingId);
    event UpdateBonus(uint256 bonus);

    receive() external payable {}

    constructor(
        address _usdtToken,
        address _asxToken,
        address _receiver,
        address _locker,
        uint256 _tgeDate,
        PaymentToken[] memory _paymentTokens
    ) Whitelist() {
        USDT_TOKEN = _usdtToken;
        TGE_DATE = _tgeDate;
        LOCKER = _locker;
        ASX_TOKEN = _asxToken;
        RECEIVER = _receiver;

        for (uint i; i < _paymentTokens.length; i++) {
            PaymentToken memory _paymentToken = _paymentTokens[i];
            paymentTokens[_paymentToken.tokenAddress] = true;
            priceFeed[_paymentToken.tokenAddress] = AggregatorInterface(_paymentToken.priceFeedAddress);
        }
    }

    function getLatestPrice(address token) public view returns (uint256) {
        return uint256(priceFeed[token].latestAnswer() * 1e10);
    }

    function updateBonus(uint256 bonus) public onlyOwner {
        require(bonus > 0 && bonus < 100, "Invalid amount");
        PRESALE_BONUS = bonus;
        emit UpdateBonus(bonus);
    }

    function depositETH() public payable {
        require(msg.value > 0, "Invalid amount");
        require(block.timestamp < TGE_DATE, "Sale completed");
        uint256 asxAmount = ethToAsx(msg.value);
        uint256 bonus = getBonus(asxAmount);
        asxAmount = SafeMath.add(asxAmount, bonus);
        uint256 balance = SafeMath.add(balances[msg.sender], asxAmount);

        require(IERC20(ASX_TOKEN).balanceOf(address(this)) >= asxAmount, "No available ASX token.");
        require(isMember(msg.sender), "Address not whitelisted.");
        require(balance >= MIN_DEPOSIT, "Invalid min deposit");
        require(balance <= MAX_DEPOSIT, "Invalid max deposit");

        uint256 vestingId = createVesting(asxAmount);

        balances[msg.sender] = balance;
        bonuses[msg.sender] = SafeMath.add(bonuses[msg.sender], bonus);
        TOTAL_SALES = SafeMath.add(TOTAL_SALES, asxAmount);
        TOTAL_BONUS = SafeMath.add(TOTAL_BONUS, bonus);

        emit Deposit(msg.sender, msg.value, address(0), asxAmount, bonus, vestingId);
    }

    function depositToken(address token, uint256 amount) public {
        require(amount > 0, "Invalid amount");
        require(block.timestamp < TGE_DATE, "Sale completed");
        
        uint256 asxAmount = tokenToAsx(token, amount);
        uint256 bonus = getBonus(asxAmount);
        asxAmount = SafeMath.add(asxAmount, bonus);
        uint256 balance = SafeMath.add(balances[msg.sender], asxAmount);

        require(IERC20(ASX_TOKEN).balanceOf(address(this)) >= asxAmount, "No available ASX token.");
        require(paymentTokens[token], "Payment token not allowed.");
        require(isMember(msg.sender), "Address not whitelisted.");
        require(balance >= MIN_DEPOSIT, "Invalid min deposit");
        require(balance <= MAX_DEPOSIT, "Invalid max deposit");

        ERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 vestingId = createVesting(asxAmount);

        balances[msg.sender] = balance;
        bonuses[msg.sender] = SafeMath.add(bonuses[msg.sender], bonus);
        TOTAL_SALES = SafeMath.add(TOTAL_SALES, asxAmount);
        TOTAL_BONUS = SafeMath.add(TOTAL_BONUS, bonus);

        emit Deposit(msg.sender, amount, token, asxAmount, bonus, vestingId);
    }

    function createVesting(uint256 amount) internal returns (uint256 id) {
        IERC20(ASX_TOKEN).approve(LOCKER, amount);
        return PinkLock02(LOCKER).vestingLock(
            msg.sender,
            ASX_TOKEN, 
            false, 
            amount, 
            TGE_DATE, 
            1000, 
            2592000, 
            750, 
            "Public Sale Vesting"
        );
    }

    function ethToAsx(uint256 amount) public view returns(uint256) {
        uint256 ethPrice = SafeMath.mul(getLatestPrice(address(0)), amount);
        return SafeMath.div(ethPrice, LISTING_PRICE);
    }

    function getBonus(uint256 amount) internal view returns(uint256) {
        return SafeMath.mul(SafeMath.div(amount, 100), PRESALE_BONUS);
    }

    function tokenToAsx(address token, uint256 amount) public view returns(uint256) {
        if (token == USDT_TOKEN) {
            return SafeMath.div(amount, LISTING_PRICE) * 10 ** 18;
        }

        uint256 tokenPrice = SafeMath.mul(getLatestPrice(token), amount);
        return SafeMath.div(tokenPrice, LISTING_PRICE);
    }

    function withdraw() public onlyOwner {
        address payable to = payable(RECEIVER);
        require(address(this).balance > 0, "Insufficient balance");
        to.transfer(address(this).balance);
    }

    function withdrawToken(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        token.transfer(RECEIVER, balance);
    }
}