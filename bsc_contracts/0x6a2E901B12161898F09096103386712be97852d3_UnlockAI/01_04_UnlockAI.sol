// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UnlockAI is Ownable {
    using SafeMath for uint256;

    bool public unlockActive = false;

    // Addresses that can unlock
    address[] public ADMIN_ADDRESS;

    mapping(uint256 => bool) public aiUnlocked; // Token ID => unlocked
    event Unlock(uint256[] tokenIds);

    function unlockAI(uint256[] calldata _tokenIds) external {
        require(unlockActive, "Unlocking not active!");
        require(isAdmin(address(msg.sender)), "Sender does not have admin rights!");

        // Unlock AI
        _unlock(_tokenIds);
    }

    function _unlock(uint256[] calldata _unlockTokenIds) private {
        for (uint256 i = 0; i < _unlockTokenIds.length; i++) {
            require(!aiUnlocked[_unlockTokenIds[i]], "One of the token IDs is already unlocked!");
            require(_unlockTokenIds[i] >= 1 && _unlockTokenIds[i] <= 11111, "One of the token IDs is not part of the collection!");
            aiUnlocked[_unlockTokenIds[i]] = true;
        }
        emit Unlock(_unlockTokenIds);
    }

    // Add admin ability to manipulate rewards balance
    function setAdmin(address _addr, uint256 _index) external onlyOwner {
        ADMIN_ADDRESS[_index] = _addr;
    }

    // Give a new address admin rights to edit wallet balances
    function addAdmin(address _addr) external onlyOwner {
        ADMIN_ADDRESS.push(_addr);
    }

    // Remove admin access for address
    function removeAdmin(address _addr) external onlyOwner {
        for (uint256 i = 0; i < ADMIN_ADDRESS.length; i++) {
            if (ADMIN_ADDRESS[i] == _addr) {
                ADMIN_ADDRESS[i] = ADMIN_ADDRESS[ADMIN_ADDRESS.length - 1];
                ADMIN_ADDRESS.pop();
            }
        }
    }

    // Returns true if the address _addr has admin rights to edit credit balance.
    function isAdmin(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < ADMIN_ADDRESS.length; i++) if (ADMIN_ADDRESS[i] == _addr) return true;
        return false;
    }

    // Activate/deactivate unlocking
    function setUnlockActive(bool _val) external onlyOwner {
        unlockActive = _val;
    }

    // Returns a bool array on the unlocked status of the respective token IDs in _tokenIds
    function getUnlockedStatus(uint256[] calldata _tokenIds) public view returns (bool[] memory) {
        bool[] memory _queriedIDs = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) _queriedIDs[i] = aiUnlocked[_tokenIds[i]];
        return _queriedIDs;
    }
}