// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/INiftyKit.sol";
import "./interfaces/IBaseCollection.sol";

abstract contract BaseCollection is IBaseCollection, AccessControl {
    using Address for address;

    address internal _treasury;
    INiftyKit internal _niftyKit;

    constructor(address treasury_, address niftyKit_) {
        _treasury = treasury_;
        _niftyKit = INiftyKit(niftyKit_);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        uint256 fees = _niftyKit.getFees(address(this));

        _niftyKit.addFeesClaimed(fees);
        Address.sendValue(payable(address(_niftyKit)), fees);
        Address.sendValue(payable(_treasury), balance - fees);
    }

    function setTreasury(address newTreasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _treasury = newTreasury;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }
}