// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

/**
 * @title Ownable
 * @author Alexander Schlindwein
 *
 * @dev Implements only-owner functionality
 */
contract Ownable {

    address _owner;

    event OwnershipChanged(address oldOwner, address newOwner);

    modifier onlyOwner {
        require(_owner == msg.sender, "only-owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        setOwnerInternal(newOwner);
    }

    function setOwnerInternal(address newOwner) internal {
        require(newOwner != address(0), "zero-addr");

        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipChanged(oldOwner, newOwner);
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}