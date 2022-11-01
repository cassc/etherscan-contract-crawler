//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

// Operator Address For Newly created NFT contract operator for managing collections in Opensea
bytes32 constant CONFIG_OPERATPR_ALL_NFT_KEY = keccak256("CONFIG_OPERATPR_ALL_NFT");

//  Mint Settle Address
bytes32 constant CONFIG_DAFAULT_MINT_SETTLE_ADDRESS_KEY = keccak256("CONFIG_DAFAULT_MINT_SETTLE_ADDRESS");

bytes32 constant CONFIG_LICENSE_MINT_FEE_RECEIVER_KEY = keccak256("CONFIG_LICENSE_MINT_FEE_RECEIVER");

// nft edtior
bytes32 constant CONFIG_NFT_EDITOR_KEY = keccak256("CONFIG_NFT_EDITOR_ADDRESS");

// NFT Factory Contract Address
bytes32 constant CONFIG_NFTFACTORY_KEY = keccak256("CONFIG_NFTFACTORY_ADDRESS");

//Default owner address for NFT
bytes32 constant CONFIG_ORI_OWNER_KEY = keccak256("CONFIG_ORI_OWNER_ADDRESS");

// Default Mint Fee 0.00001 ETH
bytes32 constant CONFIG_LICENSE_MINT_FEE_KEY = keccak256("CONFIG_LICENSE_MINT_FEE_BP");

//Default Base url for NFT eg:https://ori-static.particle.network/
bytes32 constant CONFIG_NFT_BASE_URI_KEY = keccak256("CONFIG_NFT_BASE_URI");

//Default Contract URI  for NFT eg:https://ori-static.particle.network/
bytes32 constant CONFIG_NFT_BASE_CONTRACT_URL_KEY = keccak256("CONFIG_NFT_BASE_CONTRACT_URI");


// Max licese Earn Point Para
bytes32 constant CONFIG_MAX_LICENSE_EARN_POINT_KEY = keccak256("CONFIG_MAX_LICENSE_EARN_POINT");

bytes32 constant CONFIG_LICENSE_ERC1155_IMPL_KEY = keccak256("CONFIG_LICENSE_ERC1155_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC721_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC721_IMPL");
bytes32 constant CONFIG_DERIVATIVE_ERC1155_IMPL_KEY = keccak256("CONFIG_DERIVATIVE_ERC1155_IMPL");

// salt=0x0000000000000000000000000000000000000000000000987654321123456789
address constant CONFIG = 0x94745d1a874253760Ca5B47dc3DB8E4185D7b8Dd;

// https://eips.ethereum.org/EIPS/eip-721
bytes4 constant ERC721_METADATA_IDENTIFIER = 0x5b5e139f;
bytes4 constant ERC721_IDENTIFIER = 0x80ac58cd;
// https://eips.ethereum.org/EIPS/eip-1155
bytes4 constant ERC1155_IDENTIFIER = 0xd9b67a26;
bytes4 constant ERC1155_TOKEN_RECEIVER_IDENTIFIER = 0x4e2312e0;