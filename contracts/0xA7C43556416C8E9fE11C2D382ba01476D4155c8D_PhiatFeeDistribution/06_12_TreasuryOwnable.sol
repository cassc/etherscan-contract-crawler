// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../openzeppelin/contracts/Context.sol";

abstract contract TreasuryOwnable is Context {
    address private _treasury;

    event TreasuryTransferred(
        address indexed previousTreasury,
        address indexed newTreasury
    );

    /**
     * @dev Initializes the contract setting the given account (`treasury_`) as the initial treasury.
     */
    constructor(address treasury_) {
        _treasury = treasury_;
        emit TreasuryTransferred(address(0), treasury_);
    }

    /**
     * @dev Returns the address of the current treasury.
     */
    function treasury() public view virtual returns (address) {
        return _treasury;
    }

    /**
     * @dev Throws if called by any account other than the treasury.
     */
    modifier onlyTreasury() {
        require(
            treasury() == _msgSender(),
            "TreasuryOwnable: caller is not the treasury"
        );
        _;
    }

    /**
     * @dev Transfers treasury of the contract to a new account (`newTreasury`).
     * Can only be called by the current treasury.
     */
    function transferTreasury(address newTreasury)
        external
        virtual
        onlyTreasury
    {
        require(
            newTreasury != address(0),
            "TreasuryOwnable: new treasury is the zero address"
        );
        _transferTreasury(newTreasury);
    }

    function _transferTreasury(address newTreasury) internal virtual {
        emit TreasuryTransferred(_treasury, newTreasury);
        _treasury = newTreasury;
    }
}