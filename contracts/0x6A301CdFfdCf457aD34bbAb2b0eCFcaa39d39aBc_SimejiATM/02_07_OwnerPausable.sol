// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OwnerPausable is Ownable, Pausable {
    function pause() external onlyOwner {
        Pausable._pause();
    }

    function unpause() external onlyOwner {
        Pausable._unpause();
    }
}