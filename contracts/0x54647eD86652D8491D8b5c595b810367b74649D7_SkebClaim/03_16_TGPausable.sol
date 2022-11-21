// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "./TGAccessControl.sol";

contract TGPausable is Pausable, TGAccessControl {
    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}