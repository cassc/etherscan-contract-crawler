// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "../utils/Context.sol";
import "./SecurityDTOs.sol";

abstract contract Ownable is Context {
    mapping(address => bool) public owners;
    address private _company;
    uint public totalOwners;

    event CompanyTransferred(address indexed previousCompany, address indexed newCompany);

    event AddOwner(address indexed newOwner);
    event RemoveOwner(address indexed ownerToRemove);

    modifier onlyOwner() {
        require(owners[_msgSender()], "Security: caller is not the owner");
        _;
    }

    function removeOwner(address ownerToRemove) internal {
        require(owners[ownerToRemove], "Security: now owner");

        owners[ownerToRemove] = false;
        totalOwners--;
        emit RemoveOwner(ownerToRemove);
    }

    function addOwner(address newOwner) internal {
        require(newOwner != address(0), "Security: new owner is the zero address");
        require(!owners[newOwner], "Security: already owner");

        owners[newOwner] = true;
        totalOwners++;
        emit AddOwner(newOwner);
    }



    /**
     * @dev Returns the address of the current company.
     */
    function company() public view virtual returns (address) {
        return _company;
    }

    /**
     * @dev Throws if called by any account other than the company.
     */
    modifier onlyCompany() {
        require(company() == _msgSender(), "Security: caller is not the company");
        _;
    }

    /**
     * @dev Transfers company rights of the contract to a new account (`newCompany`).
     * Can only be called by the current owner.
     */
    function transferCompany(address newCompany) internal {
        require(newCompany != address(0), "Security: new company is the zero address");

        emit CompanyTransferred(_company, newCompany);
        _company = newCompany;
    }

}