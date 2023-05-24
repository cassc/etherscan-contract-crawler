// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Proxy.sol";
import "./utils/RoyaltySplitter.sol";
import "./UnitLondonMarketplace.sol";

interface INFTV2 {
  function mint(uint256 tokenId, address user) external;

  function mint(uint256 tokenId, uint256 amount, address user) external;

  function transferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function initialize(string calldata _name, string calldata _symbol) external;

  function transferOwnership(address newOwner) external;
}

interface IMetadata {
  function metadata() external view returns (string memory);
}

contract UnitLondonMarketplaceV2 is UnitLondonMarketplace {
  mapping(address => mapping(uint256 => address)) onChainMetadatas;

  function addOnChain(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic, // amount - 0 for 721, N for 1155
    uint256 price,
    uint256 startDate,
    address metadata
  ) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price == 0, "Invalid token");

    require(collections[collection].splitter != address(0), "Invalid on-chain");
    onChainMetadatas[collection][tokenId] = metadata;

    data.amount = tokenLogic;
    data.price = price;
    data.startDate = startDate;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateOnChainMetadata(address collection, uint256 tokenId, address metadata) external {
    require(onlyGrant() || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData memory data = tokens[collection][tokenId];

    require(onChainMetadatas[collection][tokenId] != address(0), "Invalid on-chain");
    onChainMetadatas[collection][tokenId] = metadata;

    emit TokenUpdated(collection, tokenId, data);
  }

  function buy(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic // amount - 0 for 721, N for 1155
  ) external payable override {
    address user = msg.sender;
    uint256 value = msg.value;
    TokenData storage tokenData = tokens[collection][tokenId];

    CollectionData memory collectionData = collections[collection];
    uint256 fee = (value * collectionData.mintFeePlatform) / RATIO;
    payable(platform).transfer(fee);
    payable(collectionData.artist).transfer(value - fee);

    // require(tokenData.price > 0, "Invalid token");
    require(tokenData.startDate < block.timestamp, "Invalid sale");
    if (tokenLogic == 0) {
      // ERC721
      require(tokenData.price == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFTV2(collection).transferFrom(address(this), user, tokenId);
      } else {
        INFTV2(collection).mint(tokenId, user);
      }
      tokenLogic = 1;
    } else {
      // ERC1155
      require(tokenData.price * tokenLogic == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFTV2(collection).safeTransferFrom(address(this), user, tokenId, tokenLogic, "");
      } else {
        tokenData.amount = tokenData.amount - tokenLogic;
        INFTV2(collection).mint(tokenId, tokenLogic, user);
      }
    }
    emit TokenSold(collection, tokenId, tokenLogic, value);
  }

  function airdrop(address collection, uint256 tokenId, address[] calldata redeemers) external override {
    require(onlyGrant(), "Invalid permission");
    TokenData storage data = tokens[collection][tokenId];
    // require(data.price > 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFTV2(collection).safeTransferFrom(address(this), redeemers[i], tokenId, 1, "");
        }
      } else {
        // ERC721
        INFTV2(collection).transferFrom(address(this), redeemers[0], tokenId);
      }
    } else {
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        data.amount = data.amount - tokenLogic;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFTV2(collection).mint(tokenId, 1, redeemers[i]);
        }
      } else {
        // ERC721
        INFTV2(collection).mint(tokenId, redeemers[0]);
      }
    }
    emit TokenAirdropped(collection, tokenId, redeemers);
  }

  function redeem(
    address collection,
    uint256 tokenId,
    address[] calldata redeemers,
    uint256[] calldata prices
  ) external override {
    require(onlyTrdparty());
    TokenData storage data = tokens[collection][tokenId];
    // require(data.price > 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFTV2(collection).safeTransferFrom(address(this), redeemers[i], tokenId, 1, "");
        }
      } else {
        // ERC721
        INFTV2(collection).transferFrom(address(this), redeemers[0], tokenId);
      }
    } else {
      if (collections[collection].logicIndex > 0) {
        // ERC1155
        uint256 tokenLogic = redeemers.length;
        data.amount = data.amount - tokenLogic;
        for (uint256 i = 0; i < tokenLogic; i++) {
          INFTV2(collection).mint(tokenId, 1, redeemers[i]);
        }
      } else {
        // ERC721
        INFTV2(collection).mint(tokenId, redeemers[0]);
      }
    }
    emit TokenRedeemed(collection, tokenId, redeemers, prices);
  }

  function tokenURI(address collection, uint256 tokenId) external view returns (string memory) {
    if (onChainMetadatas[collection][tokenId] == address(0)) {
      return tokens[collection][tokenId].metadata;
    } else {
      return IMetadata(onChainMetadatas[collection][tokenId]).metadata();
    }
  }
}