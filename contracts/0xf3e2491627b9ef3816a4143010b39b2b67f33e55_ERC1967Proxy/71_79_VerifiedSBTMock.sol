// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../VerifiedSBT.sol";

contract VerifiedSBTMock is VerifiedSBT {
    function burn(uint256 tokenId_) external onlyOwner {
        _burn(tokenId_);
    }
}