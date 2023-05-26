// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProtectedMint is Ownable {
    address[] public minterAddresses;

    modifier onlyMinter() {
        bool isAllowed;

        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == msg.sender) {
                isAllowed = true;

                break;
            }
        }

        require(isAllowed, "Minter: caller is not an allowed minter");

        _;
    }

    /**
     * @dev Adds an address that is allowed to mint
     */
    function addMinterAddress(address _minterAddress) external onlyOwner {
        minterAddresses.push(_minterAddress);
    }

    /**
     * @dev Removes
     */
    function removeMinterAddress(address _minterAddress) external onlyOwner {
        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] != _minterAddress) {
                continue;
            }

            minterAddresses[i] = minterAddresses[minterAddresses.length - 1];

            minterAddresses.pop();
        }
    }
}