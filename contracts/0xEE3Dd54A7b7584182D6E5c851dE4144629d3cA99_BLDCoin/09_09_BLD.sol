// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BLDCoin is ERC20, Ownable {
    uint256 public constant PhaseLimitSupply = 10000000;
    
    uint256 public swapRatio = 1000;
    address public claimer;

    constructor() ERC20("BLDCoin", "BLD") {
    }

    function holderClaim(address holder, uint64 amount) external {
        require(claimer == msg.sender, "BLD: Not Claimer");
        uint256 swapNum = amount * swapRatio;
        _mint(holder, swapNum);
    }

    function setSwapRatio(uint256 _swapRatio) external onlyOwner {
      swapRatio = _swapRatio;
    }

    function setClaimer(address _claimer) external onlyOwner {
      claimer = _claimer;
    }
}