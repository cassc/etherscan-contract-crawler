// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OwnersUpgradeable is Initializable {
    address[] public owners;
    mapping(address => bool) public isOwner;

    function __Owners_init() internal onlyInitializing {
        __Owners_init();
    }

    function __Owners_init_unchained() internal onlyInitializing {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
    }

    modifier onlySuperOwner() {
        require(owners[0] == msg.sender, "Owners: Only Super Owner");
        _;
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "Owners: Only Owner");
        _;
    }

    function addOwner(address _new, bool _change) external onlySuperOwner {
        require(!isOwner[_new], "Owners: Already owner");
        isOwner[_new] = true;
        if (_change) {
            owners.push(owners[0]);
            owners[0] = _new;
        } else {
            owners.push(_new);
        }
    }

    function removeOwner(address _new) external onlySuperOwner {
        require(isOwner[_new], "Owners: Not owner");
        require(_new != owners[0], "Owners: Cannot remove super owner");
        for (uint256 i = 1; i < owners.length; i++) {
            if (owners[i] == _new) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        isOwner[_new] = false;
    }

    function getOwnersSize() external view returns (uint256) {
        return owners.length;
    }
}