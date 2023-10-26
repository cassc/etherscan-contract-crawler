// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract XBridgeVerifyingPayment is Ownable, ReentrancyGuard {

    address public collector;
    uint256 public verifyingFee;

    struct tokenInfo {
        address token;
        string chain;
    }
    event Deposited(address indexed user, address indexed token1, address indexed token2, string baseChain, string destChan, uint256 amount, string email, string website, string twitter);

    constructor(address _collector, uint256 _verifyingFee) {
        collector = _collector;
        verifyingFee = _verifyingFee;
    }

    function deposit(tokenInfo memory baseToken, tokenInfo memory correspondingToken, string memory email, string memory website, string memory twitter) external payable nonReentrant {
        require(msg.value >= verifyingFee, "FEE_TOO_LOW");
        if(verifyingFee > 0) {
            (bool success, ) = payable(collector).call{value: msg.value}("");
            require(success, "TRANSFER_UNSUCCESSFUL");

            emit Deposited(msg.sender, baseToken.token, correspondingToken.token, baseToken.chain, correspondingToken.chain, msg.value, email, website, twitter);
        }
    }

    function setCollector(address _newCollector) external onlyOwner {
        require(_newCollector != address(0) && _newCollector != collector, "INVALID");
        collector = _newCollector;

    }

    function setVerifyingFee(uint256 _newFee) external onlyOwner {
        verifyingFee = _newFee;
    }
}