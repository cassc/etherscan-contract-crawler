// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract IDO is Ownable {
    using SafeERC20 for IERC20;

    address public GameBoyAddr = 0x95697B2c78A32aE47cc172ccf91648ceE169Ef81;
    address public USDTAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public eyewitness = 0x6f9990411b0c0596129784D8681f79272aC9D9a6;

    uint public lowerLimit = 200 * 10 ** 6;
    uint public upperLimit = 2000 * 10 ** 6;

    mapping (uint8 => mapping(address => uint)) public amountLimit;

    IERC20 public USDT;
    IERC20 public GameBoy;

    event IDOEvent(address indexed user, uint USDTAmount, uint GameBoyAmount);

    constructor() {
        USDT = IERC20(USDTAddr);
        GameBoy = IERC20(GameBoyAddr);
    }

    function ido(uint amount_, uint8 nonce_, uint8 v, bytes32 r, bytes32 s) public {
        require(amount_ >= lowerLimit, "Invalid amount");
        require(upperLimit-amountLimit[nonce_][msg.sender] >= amount_, "Insufficient quota");
        require(ecrecover(keccak256(abi.encodePacked(nonce_, amount_, msg.sender)), v, r, s) == eyewitness, 'INVALID_SIGNATURE');
        amountLimit[nonce_][msg.sender] += amount_;
        USDT.safeTransferFrom(msg.sender, address(this), amount_);
        USDT.safeTransfer(owner(), amount_);
        uint gameBoyAmount = amount_ * 100 * 10 / 4;
        GameBoy.safeTransferFrom(owner(), msg.sender, gameBoyAmount);
        emit IDOEvent(msg.sender, amount_, gameBoyAmount);
    }

    function setTokenAddr(address usdt_, address gameboy_) public onlyOwner {
        GameBoy = IERC20(gameboy_);
        USDT = IERC20(usdt_);
    }

    function setEyewitness(address addr) public onlyOwner {
        require(addr != address(0), "addr is 0");
        eyewitness = addr;
    }

    function setLimit(uint lowerLimit_, uint upperLimit_) public onlyOwner {
        require(upperLimit_ >= lowerLimit_ && upperLimit_ > 0, "Invalid limit");
        lowerLimit = lowerLimit_;
        upperLimit = upperLimit_;
    }
}