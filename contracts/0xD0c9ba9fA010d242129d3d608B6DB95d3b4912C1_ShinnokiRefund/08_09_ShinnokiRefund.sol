//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

contract ShinnokiRefund is 
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    mapping (uint256 => bool) private _claimed;
    IERC721AUpgradeable public darumas;

    function initialize(IERC721AUpgradeable _darumas) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        darumas = _darumas;
        _pause();
    }

    receive() external payable {}

    function claim(uint256[] calldata ids) external whenNotPaused nonReentrant {
        uint256 length = ids.length;
        uint256 total;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            require(darumas.ownerOf(current) == msg.sender, "Not Owner");
            if(!_claimed[current]) {
                if(current <= 611) {
                    total += 0.04 ether;
                } else {
                    total += 0.01 ether;
                }
                _claimed[current] = true;
            }
        }
        require(total > 0, "Non claimable");
        AddressUpgradeable.sendValue(payable (msg.sender), total);
    }

    function claimable(uint256[] calldata ids) public view returns (uint256) {
        uint256 length = ids.length;
        uint256 total;
        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids[i];
            if(!_claimed[current]) {
                if(current <= 611) {
                    total += 0.04 ether;
                } else {
                    total += 0.01 ether;
                }
            }
        }
        return total;
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable (owner()), address(this).balance);
    }

    function claimed(uint256 id) public view returns (bool) {
        return _claimed[id];
    }

    function setDarumas(IERC721AUpgradeable _darumas) external onlyOwner {
        darumas = _darumas;
    }

    function togglePause(bool value_) external onlyOwner {
        if(value_) _pause();
        else _unpause();
    }
}