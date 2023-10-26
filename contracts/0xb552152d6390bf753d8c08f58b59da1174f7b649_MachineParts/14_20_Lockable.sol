// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Lockable is Ownable {
    bool public isMintLocked;
    bool public isBurnLocked;
    bool public isMetadataLocked;

    modifier mintIsNotLocked() {
        require(isMintLocked == false, "Lockable: mint is locked");

        _;
    }

    modifier burnIsNotLocked() {
        require(isBurnLocked == false, "Lockable: burn is locked");

        _;
    }

    modifier metadataIsNotLocked() {
        require(isMetadataLocked == false, "Lockable: metadata is locked");

        _;
    }

    function lockMint() external onlyOwner {
        isMintLocked = true;
    }

    function lockBurn() external onlyOwner {
        isBurnLocked = true;
    }

    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }
}