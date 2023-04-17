//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract JAY is ERC20Burnable, Ownable, ReentrancyGuard {
    address payable private FEE_ADDRESS;

    uint256 public constant MIN = 1000;
    uint256 public MAX = 1 * 10 ** 28;

    uint16 public SELL_FEE = 900;
    uint16 public BUY_FEE = 900;
    uint16 public constant FEE_BASE_1000 = 1000;

    uint8 public constant FEES = 33;

    bool public start = false;

    uint128 public constant ETHinWEI = 1 * 10 ** 18;

    event Price(uint256 time, uint256 recieved, uint256 sent);
    event MaxUpdated(uint256 max);
    event SellFeeUpdated(uint256 sellFee);
    event buyFeeUpdated(uint256 buyFee);

    constructor() payable ERC20("JayPeggers", "JAY") {
        _mint(msg.sender, msg.value * MIN);
        transfer(0x000000000000000000000000000000000000dEaD, 10000);
    }
    
    function setStart() public onlyOwner {
        start = true;
    }

    //Will be set to 100m eth value after 1 hr
    function setMax(uint256 _max) public onlyOwner {
        MAX = _max;
        emit MaxUpdated(_max);
    }

    // Sell Jay
    function sell(uint256 jay) external nonReentrant {
        require(jay > MIN, "must trade over min");

        // Total Eth to be sent
        uint256 eth = JAYtoETH(jay);

        // Burn of JAY
        _burn(msg.sender, jay);

        // Payment to sender
        sendEth(msg.sender, (eth * SELL_FEE) / FEE_BASE_1000);

        // Team fee
        sendEth(FEE_ADDRESS, eth / FEES);

        emit Price(block.timestamp, jay, eth);
    }

    // Buy Jay
    function buy(address reciever) external payable nonReentrant {
        require(start);
        require(msg.value > MIN && msg.value < MAX, "must trade over min");

        // Mint Jay to sender
        uint256 jay = ETHtoJAY(msg.value);
        _mint(reciever, (jay * BUY_FEE) / FEE_BASE_1000);

        // Team fee
        sendEth(FEE_ADDRESS, msg.value / FEES);

        emit Price(block.timestamp, jay, msg.value);
    }

    function JAYtoETH(uint256 value) public view returns (uint256) {
        return (value * address(this).balance) / totalSupply();
    }

    function ETHtoJAY(uint256 value) public view returns (uint256) {
        return (value * totalSupply()) / (address(this).balance - value);
    }

    function sendEth(address _address, uint256 _value) internal {
        (bool success, ) = _address.call{value: _value}("");
        require(success, "ETH Transfer failed.");
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0));
        FEE_ADDRESS = payable(_address);
    }

    function setSellFee(uint16 amount) external onlyOwner {
        require(amount <= 969);
        require(amount > SELL_FEE);
        SELL_FEE = amount;
        emit SellFeeUpdated(amount);
    }

    function setBuyFee(uint16 amount) external onlyOwner {
        require(amount <= 969 && amount >= 10);
        BUY_FEE = amount;
        emit buyFeeUpdated(amount);
    }

    //utils
    function getBuyJay(uint256 amount) external view returns (uint256) {
        return
            (amount * (totalSupply()) * (BUY_FEE)) /
            (address(this).balance) /
            (FEE_BASE_1000);
    }

    function getSellJay(uint256 amount) external view returns (uint256) {
        return
            ((amount * address(this).balance) * (SELL_FEE)) /
            (totalSupply()) /
            (FEE_BASE_1000);
    }

    function deposit() public payable {}

    receive() external payable {}

    fallback() external payable {}
}