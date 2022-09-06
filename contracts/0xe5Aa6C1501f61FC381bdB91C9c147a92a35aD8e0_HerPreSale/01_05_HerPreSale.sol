pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract HerPreSale is Ownable {
    using ECDSA for bytes32;

    address public signerAddress;
    uint256 public wlPrice;

    uint256 constant WL_LIMIT = 5000;
    mapping(address => uint256) public preSaleRecord;
    uint256 public preSaleCounter;
    uint256 public preSaleAddress;

    event PreSale(address user, uint256 amount);

    modifier human() {
        require(tx.origin == msg.sender, "only human");
        _;
    }

    constructor(address signer_, uint256 price) {
        signerAddress = signer_;
        wlPrice = price;
    }

    function preSale(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable human {
        address user = msg.sender;
        require(
            keccak256(abi.encodePacked(user)).toEthSignedMessageHash().recover(v, r, s) == signerAddress,
            "preSale:INVALID SIGNATURE."
        );
        require(msg.value >= amount * wlPrice, "payment not enough");
        uint256 userRecord = preSaleRecord[user];
        require(userRecord + amount <= 2, "limit two per address");
        if (userRecord == 0) {
            preSaleAddress += 1;
        }
        require(preSaleAddress <= WL_LIMIT, "out of limit");
        preSaleCounter += amount;
        preSaleRecord[user] += amount;
        emit PreSale(user, amount);
    }

    function withdraw(uint256 amount, address receiver) external onlyOwner {
        (bool success, ) = receiver.call{value: amount}(new bytes(0));
        require(success, "fail");
    }

    function setPrice(uint256 price) external onlyOwner {
        wlPrice = price;
    }
}