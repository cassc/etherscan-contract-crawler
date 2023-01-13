// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Mint.sol";
import "./MultiMint.sol";
import "./MerkleProof.sol";
import "./Withdraw.sol";
import "./Initialize.sol";

// @author: miinded.com

abstract contract MiindedERC721 is Initialize, ERC721Mint, MultiMint, MerkleProofVerify, Withdraw {

    function init(
        string memory baseURI,
        uint32 maxSupply,
        address reservedTo,
        uint32 reservedCount,
        address royaltiesAddress,
        uint96 feeNumerator,
        address adminAddress,
        MintName[] memory _mintSteps,
        Part[] memory _parts
    ) public onlyOwnerOrAdmins isNotInitialized {
        ERC721Mint.setBaseUri(baseURI);
        ERC721Mint.setMaxSupply(maxSupply);
        ERC721Mint.reserve(reservedTo, reservedCount);
        ERC2981._setDefaultRoyalty(royaltiesAddress, feeNumerator);
        Admins.setAdminAddress(adminAddress, true);

        for(uint256 i = 0; i < _mintSteps.length; i++){
            setMint(_mintSteps[i].name, Mint(_mintSteps[i].start, _mintSteps[i].end, _mintSteps[i].maxPerWallet, _mintSteps[i].maxPerTx, _mintSteps[i].price, _mintSteps[i].paused, true));
        }
        for(uint256 i = 0; i < _parts.length; i++){
            withdrawAdd(_parts[i]);
        }
    }

}