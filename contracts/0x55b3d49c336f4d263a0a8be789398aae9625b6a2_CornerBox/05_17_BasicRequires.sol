// SPDX-License-Identifier: MIT
// Library Traffic Cop Manager v1.0.1
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ExternalContractManager.sol";
import "../ComicStaker.sol";


library BasicRequires {

    using ExternalContractManager for ExternalContractManager.Data;

    function RequiresCheckMint(uint256 _numberOfTokensRequestedForMint, bool isLocked, uint256 totalSupply, uint256 maxSupply, uint256 senderBalance, uint256 walletMax) internal view returns (bool) {
        require(tx.origin == msg.sender, "Caller is contract");
        require(!isLocked, "Contract is locked");
        require(_numberOfTokensRequestedForMint > 0, "Must mint more than 0 tokens");
        require((totalSupply + _numberOfTokensRequestedForMint) <= maxSupply, "Amount exceeds available supply");
        require(senderBalance + _numberOfTokensRequestedForMint <= walletMax, "Amount would exceed amount allowed per wallet");
        return true;
    }

    function RequiresCheckNonOwnerMint(uint256 _numberOfTokensRequestedForMint, bool isPaused, uint256 mintPrice) internal view returns (bool) {
        require(!isPaused, "Minting is currently unavailable");
        require((mintPrice * _numberOfTokensRequestedForMint) <= msg.value, "Ether value is incorrect");
        return true;
    }

     function RequiresCheckBurnedEntranceMint(uint256 redeemedTokenId, ExternalContractManager.Data storage ecm, uint256 thresholdForStake, bytes32[] memory proof, uint256 n) internal view returns (bool) {
         require(ecm._tokenMap[redeemedTokenId]==false, "Token may only be redeemed once");
         require(ComicStaker(ecm._contract).isAddressOwnerOfBurnedToken(msg.sender, redeemedTokenId), string(bytes.concat(bytes("Token "), bytes(Strings.toString(n)), bytes(" not burned"))));
         require(ComicStaker(ecm._contract).isAddressFullyStaked(thresholdForStake, msg.sender, redeemedTokenId), string(bytes.concat(bytes("Token "), bytes(Strings.toString(n)), bytes(" not qualified"))));
         require(MerkleProof.verify(proof, bytes32(ecm._bytes), keccak256(abi.encodePacked(Strings.toString(redeemedTokenId)))), string(bytes.concat(bytes("Invalid Merkle for token "), bytes(Strings.toString(n)))));
        return true;
     }

    
}