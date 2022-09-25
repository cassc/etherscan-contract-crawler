//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";

contract ClokiesAirdrop is Ownable {
    address[] public recipients;
    uint256[] public entitlements;
    IERC721A private clokiesContract;

    constructor(address _clokiesContractAddress) {
       clokiesContract = IERC721A(_clokiesContractAddress);
    }

    function updateTargetContract(address _clokiesContractAddress)  external onlyOwner {
       clokiesContract = IERC721A(_clokiesContractAddress);
    }

    function seedAirdrop(address[] memory _recipients, uint256[] memory _entitlements) external onlyOwner {
        recipients = _recipients;
        entitlements = _entitlements;
    }

    function airdrop(uint256 startTokenId) external onlyOwner {
        uint256 sendTokenId = startTokenId;
        for (uint i = 0; i < recipients.length; i++) {
            address addr = address(recipients[i]);
            uint256 entitlement = entitlements[i];

            for (uint j = 0; j < entitlement; j++) {
                clokiesContract.safeTransferFrom(address(this), addr, sendTokenId);
                sendTokenId += 1;
            }
        }
    }

    function airdropToAddress(uint startTokenId, uint endTokenId, address receiver) external onlyOwner {
        for (uint i = startTokenId; i < endTokenId; i++) {
            clokiesContract.safeTransferFrom(address(this), address(receiver), i);
        }
    }

    function withdrawMany(uint startTokenId, uint endTokenId) external onlyOwner {
        for (uint i = startTokenId; i < endTokenId; i++) {
            clokiesContract.safeTransferFrom(address(this), address(msg.sender), i);
        }
    }

    function withdraw(uint tokenId) external onlyOwner {
        clokiesContract.safeTransferFrom(address(this), address(msg.sender), tokenId);
    }
}