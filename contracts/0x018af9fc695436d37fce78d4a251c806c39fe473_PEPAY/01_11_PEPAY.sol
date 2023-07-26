//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PEPAY is ERC20Burnable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable pepeToken;

    address private FEE_ADDRESS;

    uint256 public constant MIN = 1000;
    uint256 public MAX = 1 * 10 ** 28;

    uint16 public SELL_FEE = 900;
    uint16 public BUY_FEE = 900;
    uint16 public REST_FEE = 100;
    uint16 public constant FEE_BASE_1000 = 1000;

    bool public start = false;

    event Price(uint256 time, uint256 recieved, uint256 sent);
    event MaxUpdated(uint256 max);
    event SellFeeUpdated(uint256 sellFee);
    event buyFeeUpdated(uint256 buyFee);
    event FeeAddressChanged(address feeAddress);

    constructor(
        uint256 _initialValue,
        address _pepeToken
    ) payable ERC20("PEPAY", "PEPAY") {
        _mint(msg.sender, _initialValue * MIN);
        transfer(0x000000000000000000000000000000000000dEaD, 10000);
        pepeToken = IERC20(_pepeToken);
    }

    function setStart() external onlyOwner {
        start = true;
    }

    function setMax(uint256 _max) external onlyOwner {
        MAX = _max;
        emit MaxUpdated(_max);
    }

    function sell(uint256 pepay) external nonReentrant {
        require(pepay > MIN, "must trade over min");

        uint256 pepe = PEPAYtoPEPE(pepay);

        _burn(msg.sender, pepay);

        sendToken(msg.sender, (pepe * SELL_FEE) / FEE_BASE_1000);

        // Split fee
        sendToken(FEE_ADDRESS, (pepe * REST_FEE) / FEE_BASE_1000);

        emit Price(block.timestamp, pepay, pepe);
    }

    // Buy PEPAY
    function buy(uint256 pepe) external nonReentrant {
        require(start);
        require(pepe > MIN && pepe < MAX, "must trade over min");

        uint256 pepay = PEPEtoPEPAY(pepe);
        _mint(msg.sender, (pepay * BUY_FEE) / FEE_BASE_1000);

        // Split fee
        sendToken(FEE_ADDRESS, (pepe * REST_FEE) / FEE_BASE_1000);

        emit Price(block.timestamp, pepe, pepay);
    }

    function PEPAYtoPEPE(uint256 value) public view returns (uint256) {
        uint256 contractBalance = pepeToken.balanceOf(address(this));
        return (value * contractBalance) / totalSupply();
    }

    function PEPEtoPEPAY(uint256 value) public view returns (uint256) {
        uint256 contractBalance = pepeToken.balanceOf(address(this));
        return (value * totalSupply()) / (contractBalance);
    }

    function sendToken(address _address, uint256 _value) internal {
        pepeToken.safeTransfer(_address, _value);
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0));
        FEE_ADDRESS = _address;
        emit FeeAddressChanged(_address);
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

    function getBuyPepay(uint256 amount) external view returns (uint256) {
        uint256 contractBalance = pepeToken.balanceOf(address(this));
        return
            (amount * (totalSupply()) * (BUY_FEE)) /
            (contractBalance) /
            (FEE_BASE_1000);
    }

    function getSellPepay(uint256 amount) external view returns (uint256) {
        uint256 contractBalance = pepeToken.balanceOf(address(this));
        return
            ((amount * contractBalance) * (SELL_FEE)) /
            (totalSupply()) /
            (FEE_BASE_1000);
    }
}