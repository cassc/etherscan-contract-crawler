// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessControlV is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address[] public minterAddresses;
    mapping(address => uint256) internal addressMintCount;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantMinterRole(msg.sender);
    }

    function _selectNextMinter() internal view returns (address payable) {
        address nextMinter;
        uint256 lowestMintCount = 0;
        for (uint256 index = 0; index < minterAddresses.length; index++) {
            address tempAddress = minterAddresses[index];
            uint256 tempCount = addressMintCount[minterAddresses[index]];
            if (index == 0) {
                nextMinter = tempAddress;
                lowestMintCount = tempCount;
            } else if (tempCount < lowestMintCount) {
                nextMinter = tempAddress;
                lowestMintCount = tempCount;
            }
        }
        return payable(nextMinter);
    }

    function grantMinterRole(address minter)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, minter);
        minterAddresses.push(minter);
        _resetMinterCount();
    }

    function revokeMinterRole(address minter)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, minter);
        uint256 index;
        for (index = 0; index < minterAddresses.length; index++) {
            if (minter == minterAddresses[index]) {
                minterAddresses[index] = minterAddresses[
                    minterAddresses.length - 1
                ];
                break;
            }
        }
        minterAddresses.pop();
        _resetMinterCount();
    }

    function _resetMinterCount() internal {
        for (uint256 index = 0; index < minterAddresses.length; index++) {
            address minter = minterAddresses[index];
            addressMintCount[minter] = 0;
        }
    }
}