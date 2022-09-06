// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PaymentSplitter is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    address private _owner = 0xC0fbEEfa715979E415eDd0446a4E6FB9560699Dc;
    address private _owner2 = 0x28A30587D461E4B44882deBB693115001e62D95F;
    address private _owner3 = 0x1428e005C8c0235135Fa1f608cDaA8749D4087Ff;

    receive() external payable {}

    constructor() {}

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 split1 = balance / 100 * 33;
        uint256 split2 = balance / 100 * 33;
        uint256 split3 = balance - split1 - split2;
        (bool s1, ) = _owner.call{value: split1}("");
        (bool s2, ) = _owner2.call{value: split2}("");
        (bool s3, ) = _owner3.call{value: split3}("");
    }
}