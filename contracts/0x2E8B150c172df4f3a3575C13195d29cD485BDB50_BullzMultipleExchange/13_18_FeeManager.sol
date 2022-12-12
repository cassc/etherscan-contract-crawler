// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./interfaces/IFeeManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is IFeeManager, Ownable {
    // Each offer has a dedicated share for plateform holder
    mapping(uint256 => uint256) public shares;

    constructor() {
        shares[1] = 1;
        shares[2] = 1;
        shares[3] = 1;
        shares[4] = 1;
        shares[5] = 1;
        shares[6] = 1;
        shares[7] = 1;
        shares[8] = 1;
    }

    function setFeeTo(uint256 index, uint256 newFee)
        external
        override
        onlyOwner
    {
        require(newFee <= 100, "Market Fee must be >= 0 and <= 100");
        shares[index] = newFee;
        emit SetFeeTo(index, newFee);
    }

    function getFeebyIndex(uint256 index) internal view returns (uint256) {
        return shares[index];
    }
}