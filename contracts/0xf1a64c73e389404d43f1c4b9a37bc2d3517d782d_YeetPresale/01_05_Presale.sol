// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract YeetPresale is Ownable {
    bool public presaleStarted;
    bool public presaleEnded;

    mapping(address => uint256) public amountPurchased;
    uint256 public totalPurchased;
    address[] public participants;

    uint256 public walletLimit = 0.1 ether;
    uint256 public tokensPerEth = 85_000e18;
    uint256 public hardCap = 5 ether;
    address public tokenAddress;

    event BoughtPresale (address indexed participant, uint ethAmount);
    event Claimed (address indexed participant, uint tokenAmount);

    function buyPresale() external payable {
        require(presaleStarted, "Presale not started yet");
        require(!presaleEnded, "Presale ended");
        require(msg.value > 0, "Zero amount");
        require(amountPurchased[msg.sender] + msg.value <= walletLimit, "Over wallet limit");
        require(totalPurchased + msg.value <= hardCap, "Amount over limit");
        if (amountPurchased[msg.sender] == 0) participants.push(msg.sender);
        amountPurchased[msg.sender] += msg.value;
        totalPurchased += msg.value;
        emit BoughtPresale(msg.sender, msg.value);
    }

    function claim() external {
        require(presaleEnded, "Not claimable");
        require(amountPurchased[msg.sender] > 0, "No amount claimable");
        require(tokenAddress != address(0), "Nothing to claim yet");
        uint256 amount = amountPurchased[msg.sender] * tokensPerEth / 1e18;
        amountPurchased[msg.sender] = 0;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function startPresale(bool hasStarted) external onlyOwner {
        presaleStarted = hasStarted;
    }

    function endPresale(bool hasEnded) external onlyOwner {
        presaleEnded = hasEnded;
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setWalletLimit(uint256 _walletLimit) external onlyOwner {
        walletLimit = _walletLimit;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setTokensPerEth(uint256 _tokensPerEth) external onlyOwner {
        tokensPerEth = _tokensPerEth;
    }

    function withdrawEth() external onlyOwner {
        uint256 totalAmount = address(this).balance;
        (bool success,) = owner().call{value: totalAmount}("");
        require(success);
    }

    function withdrawTokens(uint amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function refundEth() external onlyOwner {
        uint256 participantCount = participants.length;
        for (uint256 i = 0; i < participantCount;) {
            uint256 ethAmount = amountPurchased[participants[i]];
            amountPurchased[participants[i]] = 0;
            (bool success,) = participants[i].call{value: ethAmount}("");
            require(success);
            unchecked {
                i++;
            }
        }
    }
}