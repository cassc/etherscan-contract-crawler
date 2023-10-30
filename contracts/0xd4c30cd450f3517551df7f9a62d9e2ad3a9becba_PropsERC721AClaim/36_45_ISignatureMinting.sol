// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISignatureMinting {

    struct SignatureMintCart {
       SignatureMintCartItem[] items;
   }

    struct SignatureClaimCart {
       SignatureMintCartItem[] items;
       address minting_wallet;
       address delegated_wallet;
       address receiving_wallet;
       bytes  signature;
       uint256  expirationTime;
   }

   struct SignatureMintCartItem{
        string  uid;
        uint256  quantity;
        uint256  price;
        uint256  allocation;
        uint256  expirationTime;
        uint256  maxSupply;
        bytes  signature;
   }

   struct RelayMint{
        address _to;
        uint256 _quantity;
        address _minting_wallet;
        address _delegated_wallet;
        string _uid;
        uint256 _allocation;
        uint256 _max_supply;
        uint256 _pricePerUnit;
        uint256 _expirationTime;
        bytes  _signature;
   }

    struct CartMint {
        address _minting_wallet;
        address _delegated_wallet;
        address _receiving_wallet;
        uint256 _quantity;
        uint256 _cost;
    }

    struct MintSignature {
       address wallet_address;
       string uid;
       uint256 quantity;
       uint256 price;
       uint256 allocation;
       uint256 startTime;
       uint256 endTime;
   }

   struct Version {
       uint256 major;
       uint256 minor;
       uint256 patch;
   }
}