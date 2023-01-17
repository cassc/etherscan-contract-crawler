// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Token.sol";
import "./utils/Withdrawable.sol";

contract Minter is Ownable, Withdrawable {
    Token public token;

    bytes32 public whitelistRoot;

    uint256 public startTimestamp;

    uint256 public endTimestamp;

    bool public isInMaintenanceMode = true;

    modifier onlyWhitelisted(uint256 tokenId, bytes32[] memory proof) {
        require(MerkleProof.verify(proof, whitelistRoot, keccak256(abi.encode(_msgSender(), tokenId))), "Minter: account mismatch");
        _;
    }

    /* Configuration
     ****************************************************************/

    function schedule(uint256 startTimestamp_, uint256 endTimestamp_) external onlyOwner {
        startTimestamp = startTimestamp_;
        endTimestamp = endTimestamp_;
    }

    function setToken(address token_) external onlyOwner {
        token = Token(token_);
    }

    function setWhitelistRoot(bytes32 whitelistRoot_) external onlyOwner {
        whitelistRoot = whitelistRoot_;
    }

    function disableMaintenanceMode() external onlyOwner {
        isInMaintenanceMode = false;
    }

    /* Domain
     ****************************************************************/

    function mint(uint256 tokenId) external onlyOwner {
        require(isInMaintenanceMode, "Minter: owner cannot mint in production mode");

        token.mint(tokenId, _msgSender());
    }

    function mint(uint256 tokenId, bytes32[] calldata proof) external onlyWhitelisted(tokenId, proof) {
        require(startTimestamp != 0 && block.timestamp >= startTimestamp, "Minter: minting not started");
        require(endTimestamp == 0 || block.timestamp < endTimestamp, "Minter: minting ended");

        token.mint(tokenId, _msgSender());
    }
}