// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./shared/IUSDT.sol";

contract PrivateSale is Ownable, Initializable {
    mapping(address => uint256) public participants;

    uint256 public totalAmountUSD;
    uint256 public totalAmountSelling;
    uint256 public boughtAmountSelling;

    IUSDT public tokenUSDT;
    IUSDT public tokenSelling;
    address public receiver;
    uint256 public priceInUSD;

    bool public depositOpen;

    struct SetReward {
        address participant;
        uint256 amount;
    }

    event Deposit(address participant, uint256 amount);
    event Reward(address participant, uint256 amount);
    event Take(address token, address to, uint256 amount);
    event DepositOpen(bool value);
    event SetPriceInUSD(uint256 oldPriceInUSD, uint256 priceInUSD);
    event AddSelling(uint256 oldTotalAmountSelling, uint256 newTotalAmountSelling);
    event SetReceiver(address oldReceiver, address receiver);
    event TakeUnsoldSelling(address to, uint256 amount);

    function initialize(
        address _tokenUSDT,
        address _tokenSelling,
        address _receiver,
        uint256 _priceInUSD,
        uint256 _totalAmountSelling
    ) external onlyOwner initializer {
        tokenUSDT = IUSDT(_tokenUSDT);
        tokenSelling = IUSDT(_tokenSelling);
        receiver = _receiver;

        require(_priceInUSD > 0, "price must be > 0");
        priceInUSD = _priceInUSD;

        require(_totalAmountSelling > 0, "_totalAmountSelling must be > 0");
        tokenSelling.transferFrom(msg.sender, address(this), _totalAmountSelling);
        totalAmountSelling = _totalAmountSelling;
    }

    function deposit(uint256 amount) external {
        require(depositOpen, "deposit stopped");
        tokenUSDT.transferFrom(msg.sender, receiver, amount);

        participants[msg.sender] += amount;
        totalAmountUSD += amount;

        uint256 sellingAmount = (amount * priceInUSD) / 10**tokenUSDT.decimals();

        require(sellingAmount <= totalAmountSelling - boughtAmountSelling, "no available Selling");
        boughtAmountSelling += sellingAmount;

        tokenSelling.transfer(msg.sender, sellingAmount);

        emit Deposit(msg.sender, amount);
    }

    function _addSelling(uint256 amount) external onlyOwner {
        require(amount > 0, "amount must be > 0");

        uint256 oldTotalAmountSelling = totalAmountSelling;
        tokenSelling.transferFrom(msg.sender, address(this), amount);
        totalAmountSelling += amount;

        emit AddSelling(oldTotalAmountSelling, totalAmountSelling);
    }

    function _setPriceInUSD(uint256 _priceInUSD) external onlyOwner {
        require(_priceInUSD > 0, "price must be > 0");

        uint256 oldPriceInUSD = priceInUSD;
        priceInUSD = _priceInUSD;

        emit SetPriceInUSD(oldPriceInUSD, _priceInUSD);
    }

    function _setReceiver(address _receiver) external onlyOwner {
        address oldReceiver = receiver;
        receiver = _receiver;
        emit SetReceiver(oldReceiver, _receiver);
    }

    function _takeUnsoldSelling(address to) external onlyOwner {
        uint256 amount = totalAmountSelling - boughtAmountSelling;

        boughtAmountSelling += amount;
        tokenSelling.transfer(to, amount);

        emit TakeUnsoldSelling(to, amount);
    }

    function _take(
        IUSDT token,
        address to,
        uint256 amount
    ) external onlyOwner {
        token.transfer(to, amount);
        emit Take(address(token), to, amount);
    }

    function _setDepositOpen(bool value) external onlyOwner {
        depositOpen = value;
        emit DepositOpen(value);
    }
}