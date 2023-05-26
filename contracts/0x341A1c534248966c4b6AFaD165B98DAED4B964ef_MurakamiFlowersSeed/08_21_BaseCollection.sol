// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INiftyKit.sol";

abstract contract BaseCollection is Ownable {
    using Address for address;

    address internal _treasury;

    INiftyKit internal _niftyKit;

    constructor(address treasury_, address niftyKit_) {
        _treasury = treasury_;
        _niftyKit = INiftyKit(niftyKit_);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        uint256 fees = _niftyKit.getFees(address(this));

        _niftyKit.addFeesClaimed(fees);
        Address.sendValue(payable(address(_niftyKit)), fees);
        Address.sendValue(payable(_treasury), balance - fees);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        _treasury = newTreasury;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }
}