//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PEPAY is ERC20Burnable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC721 public JAYNFT;

    IERC20 public immutable backingToken;

    address payable private FEE_ADDRESS;

    uint256 private constant MIN = 1000;

    uint256 public MAX = 1 * 10 ** 28;

    uint16 public SELL_FEE = 9000;
    uint16 public BUY_FEE = 9000;
    uint16 private constant FEE_BASE_1000 = 10000;

    uint16 private constant FEES = 25;

    bool public start;

    uint128 private constant ETHinWEI = 1 * 10 ** 18;

    event Price(uint256 recieved, uint256 sent);
    event MaxUpdated(uint256 max);
    event SellFeeUpdated(uint256 sellFee);
    event buyFeeUpdated(uint256 buyFee);

    constructor(uint256 value, address _backingToken) ERC20("PEPAY", "PEPAY") {
        backingToken = IERC20(_backingToken);
         _mint(msg.sender, value);
    }

    function setJAYNFT(address _nft) external onlyOwner{
        JAYNFT = IERC721(_nft);
    }
    
    function init(uint256 value) external onlyOwner {
        require(!start);
        backingToken.safeTransferFrom(msg.sender, address(this), value);
        transfer(0x000000000000000000000000000000000000dEaD, 1000);
    }

    function setStart() external onlyOwner {    
        start = true;
    }

    //Will be set to 100m eth value after 1 hr
    function setMax(uint256 _max) external onlyOwner {
        MAX = _max;
        emit MaxUpdated(_max);
    }

    // Sell Jay
    function sellNftDiscount(uint256 jay) external nonReentrant {
        require(jay > 0, "must trade over 0");
        uint256 discount = JAYNFT.balanceOf(msg.sender) * 3; 
        if(discount > 300) discount = 300; 
        // Total Eth to be sent
        uint256 eth = JAYtoETH(jay);

        // Burn of JAY
        _burn(msg.sender, jay);

        // Payment to sender
        backingToken.safeTransfer(msg.sender, (eth * (SELL_FEE + discount)) / FEE_BASE_1000);
        // Team fee
        backingToken.safeTransfer(FEE_ADDRESS, eth / FEES);

        emit Price(jay, eth);
    }
    function buyNftDiscount(address reciever, uint256 amount) external nonReentrant {
        require(start);
        require(amount > MIN && amount < MAX, "must trade over min");
        uint256 discount = JAYNFT.balanceOf(msg.sender) * 3; 
        if(discount > 300) discount = 300; 

        // Mint Jay to sender

         uint256 jay = ETHtoJAY(amount);
        _mint(reciever, (jay * (BUY_FEE + discount)) / FEE_BASE_1000);

        backingToken.safeTransferFrom(msg.sender, address(this), amount);
        // Team fee
        backingToken.safeTransfer(FEE_ADDRESS, amount / FEES);

        emit Price(jay, amount);
    }
    function sell(uint256 jay) external nonReentrant {
        // Total Eth to be sent
        require(jay > 0, "must trade over 0");
        uint256 eth = JAYtoETH(jay);

        // Burn of JAY
        _burn(msg.sender, jay);

        // Payment to sender
        backingToken.safeTransfer(msg.sender, (eth * SELL_FEE) / FEE_BASE_1000);
        // Team fee
        backingToken.safeTransfer(FEE_ADDRESS, eth / FEES);

        emit Price(jay, eth);
    }

    // Buy Jay
    function buy(address reciever, uint256 amount) external nonReentrant {
        require(start, "contract not initiated");
        require(amount > MIN, "must trade over min");


        // Mint Jay to sender
        uint256 jay = ETHtoJAY(amount);
        _mint(reciever, (jay * BUY_FEE) / FEE_BASE_1000);

        backingToken.safeTransferFrom(msg.sender, address(this), amount);
        // Team fee
        backingToken.safeTransfer(FEE_ADDRESS, amount / FEES);

        emit Price(jay, amount);
    }

    function JAYtoETH(uint256 value) public view returns (uint256) {
        return (value * backingToken.balanceOf(address(this))) / totalSupply();
    }

    function ETHtoJAY(uint256 value) public view returns (uint256) {
        return (value * totalSupply()) / backingToken.balanceOf(address(this));
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0), "cannot set to 0x0 address");
        FEE_ADDRESS = payable(_address);
    }

    function setSellFee(uint16 amount) external onlyOwner {
        require(amount <= 9290, "cant set less than 3% fee");
        require(amount > SELL_FEE, "cant increase sell fee");
        SELL_FEE = amount;
        emit SellFeeUpdated(amount);
    }

    function setBuyFee(uint16 amount) external onlyOwner {
        require(amount <= 9290 && amount >= 9000, "cant set less than 3% fee or greater than 5%");
        BUY_FEE = amount;
        emit buyFeeUpdated(amount);
    }

    //utils
    function getBuyJay(uint256 amount) external view returns (uint256) {
        return
            (amount * (totalSupply()) * (BUY_FEE)) /
            (backingToken.balanceOf(address(this))) /
            (FEE_BASE_1000);
    }

    function getSellJay(uint256 amount) external view returns (uint256) {
        return
            ((amount * backingToken.balanceOf(address(this))) * (SELL_FEE)) /
            (totalSupply()) /
            (FEE_BASE_1000);
    }
}