// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./openzeppelin/MerkleProof.sol";

library Library {
    struct Pass {
        bool publicSale;
        bool preSale;
        uint16 maxSupply;
        uint16 totalMinted;
        uint8 maxMint;
        uint24 stakingPoints;
        bytes32 whitelistMerkleRoot;
        uint256 passId;
        uint256 mintPrice;
        uint256 whitelistPrice;
        uint256 hodlersPrice;
    }

    /**
    *   Public sale validation
    *   Mint price -> For anyone in the public sale
    *   Mint price with discount -> If you hold the ark, you get starting 3% + 3% per held token-type
    */

    function ValidatePublicMint(
        Pass memory pass,
        uint16 _amount,
        uint16 _hodls
    ) public view returns (bool){
        require(pass.maxSupply >= (_amount + pass.totalMinted), "Exceeds available supply");
        //          0.01        0.01 * 1                    0.01          *     90 / 1000
        require(msg.value == ((pass.mintPrice * _amount) - ((pass.mintPrice * (_hodls * 30)) / 1000)), "Invalid tx amount");
        require(_amount <= pass.maxMint, "Too many mints");
        return true;
    }

    /**
    *   Presale validation
    *   Hodlers price -> For holders of all preceding moments
    *   Whitelist price -> For people in the whitelist
    */

    function ValidatePresaleMint(
        Pass memory pass,
        uint16 _amount,
        bool _whitelisted,
        bytes32[] calldata merkleProof
    ) public view returns (bool){
        require(pass.maxSupply >= (_amount + pass.totalMinted), "Exceeds available supply");
        require(_amount <= pass.maxMint, "Too many mints");
        if (_whitelisted) {
            require(MerkleProof.verify(
                    merkleProof, pass.whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))
                ), "Invalid proof");
            require(msg.value == pass.whitelistPrice * _amount, "Invalid tx amount");
        } else {
            require(msg.value == pass.hodlersPrice * _amount, "Invalid tx amount");
        }
        return true;
    }
}