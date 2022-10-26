// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OTCallable.sol";

interface IOTMint {
    function mint(address to, uint256 amount) external;
}

contract OTNFTBonusIssuer is OTCallable {
    mapping(address => uint256) public bonusAllocation;
    IOTMint public openTownContract;

    event BonusAllocationChanged(
        address indexed by,
        address indexed nftContract,
        uint256 amount
    );
    event BonusIssued(address indexed by, address indexed to, uint256 amount);

    constructor(address otContractAddr) {
        require(otContractAddr != address(0), "Invalid address");
        openTownContract = IOTMint(otContractAddr);
    }

    function setBonusAllocation(address addr, uint256 amount)
        external
        onlyOwner
    {
        bonusAllocation[addr] = amount;
        emit BonusAllocationChanged(msg.sender, addr, amount);
    }

    function mintBonus(address to, uint256 numTokens) external onlyOTCaller {
        uint256 bonusAmount = bonusAllocation[msg.sender] * numTokens;
        require(bonusAmount > 0, "Invalid bonus amount");

        emit BonusIssued(msg.sender, to, bonusAmount);
        openTownContract.mint(to, bonusAmount);
    }
}