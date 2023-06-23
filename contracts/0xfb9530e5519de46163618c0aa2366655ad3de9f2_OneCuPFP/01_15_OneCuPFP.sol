// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./OneCuPFPToken.sol";

contract OneCuPFP is OneCuPFPToken {
    constructor(
        string memory name,
        string memory symbol,
        string memory _notRevealedUri,
        string memory contractUri,
        uint256 _burnSupply)
    OneCuPFPToken(name, symbol, _notRevealedUri, contractUri, _burnSupply) {}

    /**
    *   Mint function
    */

    function mint(uint256 amount, bool whitelisted, bytes32[] calldata merkleProof) external payable callerIsUser {
        require(mintActive || preMintActive, "No active sales");
        require(ValidateMint(amount, whitelisted, merkleProof));
        for (uint bar = 0; bar < amount; bar++) {
            _safeMint(msg.sender, totalMinted);
            totalMinted += 1;
        }
    }

    function reservedMint(uint256 amount) external onlyOwner {
        require(maxSupply >= (amount + totalMinted), "Exceeds available supply");
        for (uint bar = 0; bar < amount; bar++) {
            _safeMint(msg.sender, totalMinted);
            totalMinted += 1;
        }
    }
}