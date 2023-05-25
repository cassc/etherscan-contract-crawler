// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IOmniFusionBurn.sol";

contract OmnimorphsSoulShardMarket is ERC1155Holder, ERC721Holder, Ownable {
   event ObtainedERC1155(address sender, address contractAddress, uint id, uint amount, uint[] soulShards);
   event ObtainedERC721(address sender, address contractAddress, uint id, uint[] soulShards);

   using ECDSA for bytes32;

   IOmniFusionBurn public omniFusion;

   IERC1155 public omniFusionERC1155;

   bool public active = false;

   address private _signer;

   constructor(address initialSigner, address omniFusionAddress) {
      _signer = initialSigner;
      omniFusion = IOmniFusionBurn(omniFusionAddress);
      omniFusionERC1155 = IERC1155(omniFusionAddress);
   }

   // PUBLIC

   function obtainERC1155(
      address contractAddress,
      uint id,
      uint amount,
      uint[] calldata soulShards,
      bytes32 hash,
      bytes memory signature
   ) external {
      _canObtainCheck(contractAddress, id, amount, soulShards, hash, signature);

      IERC1155 erc1155Contract = IERC1155(contractAddress);

      require(erc1155Contract.balanceOf(address(this), id) >= amount, "OmnimorphsSoulShardMaket: Not enough tokens to obtain.");

      _burnSoulShards(soulShards);

      erc1155Contract.safeTransferFrom(address(this), msg.sender, id, amount, "");

      emit ObtainedERC1155(msg.sender, contractAddress, id, amount, soulShards);
   }

   function obtainERC721(
      address contractAddress,
      uint id,
      uint[] calldata soulShards,
      bytes32 hash,
      bytes memory signature
   ) external {
      _canObtainCheck(contractAddress, id, 1, soulShards, hash, signature);

      IERC721 erc721Contract = IERC721(contractAddress);

      require(erc721Contract.ownerOf(id) == address(this), "OmnimorphsSoulShardMaket: Token not owned by the market contract.");

      _burnSoulShards(soulShards);

      erc721Contract.safeTransferFrom(address(this), msg.sender, id);

      emit ObtainedERC721(msg.sender, contractAddress, id, soulShards);
   }

   // OWNER

   function setSigner(address newSigner) external onlyOwner {
      _signer = newSigner;
   }

   function setActive(bool newActive) external onlyOwner {
      active = newActive;
   }

   function returnERC1155Tokens(address to, address contractAddress, uint id, uint amount) external onlyOwner {
      IERC1155 erc1155Contract = IERC1155(contractAddress);

      erc1155Contract.safeTransferFrom(address(this), to, id, amount, "");
   }

   function returnERC721Token(address to, address contractAddress, uint id) external onlyOwner {
      IERC721 erc721Contract = IERC721(contractAddress);

      erc721Contract.safeTransferFrom(address(this), to, id);
   }

   // INTERNAL

   function _canObtainCheck(
      address contractAddress,
      uint id,
      uint amount,
      uint[] calldata soulShards,
      bytes32 hash,
      bytes memory signature
   ) private view {
      require(active, "OmnimorphsSoulShardMaket: Market is not active");
      require(soulShards.length > 0, "OmnimorphsSoulShardMaket: Cannot obtain for 0 Soul Shards");
      require(_matchAddressSigner(hash, signature), "OmnimorphsSoulShardMaket: Direct minting is not allowed");
      require(_hashTransaction(msg.sender, contractAddress, id, amount, soulShards) == hash, "OmnimorphsSoulShardMaket: Hash mismatch");
   }

   function _burnSoulShards(uint[] calldata soulShards) private {
      for (uint i = 0; i < soulShards.length; i++) {
         require(omniFusionERC1155.balanceOf(msg.sender, soulShards[i]) == 1, "OmnimorphsSoulShardMaket: Soul Shard is not owned by sender");

         omniFusion.burn(msg.sender, soulShards[i], 1);
      }
   }

   function _hashTransaction(address sender, address contractAddress, uint id, uint amount, uint[] calldata soulShards) private pure returns(bytes32) {
      return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, contractAddress, id, amount, soulShards)))
      );
   }

   function _matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
      return _signer == hash.recover(signature);
   }
}