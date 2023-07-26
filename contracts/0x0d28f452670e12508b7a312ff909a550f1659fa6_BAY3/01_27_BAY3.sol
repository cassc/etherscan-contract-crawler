//
//
//* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ***
//* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ***
//
//
//   .;_____________________________________________________;.
//    |                                                      \
//    |            ______, ______, __   __ _____,            |
//    |            |_____] |_____\   \_/    ____\            |
//    |            |_____].|     |.;  /.   _____],.          |
//    |           /                                          io
//   _\_____________________________________________________//
//
//                   -- Ethereum Marketplace --
//
//   dApp: bay3.io
//   Description: Buy and sell ERC20, ERC721 and ERC1155 tokens
//
//
//* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ***
//* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ***
//
//
//
//
// SPDX-License-Identifier: MIT


pragma solidity 0.8.20;


import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";


import {
  ORDER_TYPEHASH,
  PAYMENT_TYPEHASH,
  FEES_TYPEHASH,
  NATIVE_ETH,
  INVERSE_BASIS,
  INTERFACE_ID_ERC721,
  INTERFACE_ID_ERC1155,
  INTERFACE_ID_ERC2981,
  AssetType,
  OrderType,
  Collection,
  Payment,
  Order,
  Executable,
  Permit_ERC20
} from "./BAY3structs.sol";



contract BAY3 is Ownable2Step, Pausable, ReentrancyGuard, EIP712 {


    mapping(address => Collection) public collectionDetails;
    mapping(bytes32 => bool) public orderMap;


    uint256 public marketPoints;
    address public marketRecipient;


    event CollectionAdded(address indexed collection, AssetType indexed asset_type);

    event OrderExecuted(address indexed seller, address indexed buyer, Executable executable, bytes32 indexed orderHash);

    event OrderCancelled(address indexed maker, bytes32 indexed orderHash);

    event NewMarketPoints(uint256 points);

    event NewMarketRecipient(address recipient);

    event NewCollectionRoyalties(address collection, uint256 points, address receiver);

    event NewApprovedCollectionOwner(address collection, address collectionOwner);


    constructor(address _marketRecipient, uint256 _marketPoints) EIP712("BAY3", "1.1") {
      marketRecipient = _marketRecipient;
      marketPoints = _marketPoints;
    }




    // - - - - - - - - - - - - Getter functions - - - - - - - - - - - - - //


    function isExecuted(bytes32 orderHash) external view returns (bool) {
      return orderMap[orderHash];
    }


    function getCollectionDetails(address collection) external view returns (Collection memory) {
      return collectionDetails[collection];
    }


    function getTransferRoyalties(address collection, uint256 tokenId) external view returns (address receiver, uint256 royaltyAmount) {
      if (ERC165Checker.supportsInterface(collection, INTERFACE_ID_ERC2981)) {
        return IERC2981(collection).royaltyInfo(tokenId, INVERSE_BASIS);
      } else {
        return _getTransferRoyalties(collection, tokenId);
      }
    }


    function _getTransferRoyalties(address collection, uint256 tokenId) internal view returns (address receiver, uint256 royaltyAmount) {
      if (collectionDetails[collection].supports2981) {
        // Get royalties directly from ERC2981
        return IERC2981(collection).royaltyInfo(tokenId, INVERSE_BASIS);
      } else if (collectionDetails[collection].royalty_points > 0) {
        // Get royalties set by collection in the marketplace
        return (collectionDetails[collection].royalty_receiver, collectionDetails[collection].royalty_points);
      } else {
        // No royalties were found
        return (address(0), 0);
      }
    }





    // - - - - - - - - - - - - EIP712 Hash - - - - - - - - - - - - - //


    function _packPayments(Payment[] calldata paymentMethods) internal pure returns (bytes32) {
      bytes32[] memory paymentHashes = new bytes32[](paymentMethods.length);
      for (uint256 i = 0; i < paymentMethods.length; ++i) {
        paymentHashes[i] = keccak256(abi.encode(PAYMENT_TYPEHASH, paymentMethods[i].token, paymentMethods[i].amount));
      }
      return keccak256(abi.encodePacked(paymentHashes));
    }


    function _hashOrder(Order calldata order) internal view returns (bytes32) {
      return _hashTypedDataV4(keccak256(abi.encode(
          ORDER_TYPEHASH,
          order.maker,
          order.collection,
          order.tokenId,
          order.amount,
          order.expiry,
          keccak256(abi.encode(FEES_TYPEHASH, order.fees.royaltyPoints, order.fees.marketPoints, order.fees.slippageTolerance)),
          _packPayments(order.paymentMethods),
          order.paymentsCombined,
          order.order_type,
          order.salt
        )
      ));
    }






    // - - - - - - - - - - - - Save & Check Collection Info - - - - - - - - - - - - - //


    function checkCollection(address collection) public returns (AssetType) {
      if (collectionDetails[collection].asset_type != AssetType.UNCHECKED) {
        return collectionDetails[collection].asset_type;
      } else {
        if (ERC165Checker.supportsInterface(collection, INTERFACE_ID_ERC721)) {
          collectionDetails[collection].asset_type = AssetType.ERC721;
          collectionDetails[collection].supports2981 = ERC165Checker.supportsERC165InterfaceUnchecked(collection, INTERFACE_ID_ERC2981);
          emit CollectionAdded(collection, AssetType.ERC721);
          return AssetType.ERC721;
        } else if (ERC165Checker.supportsInterface(collection, INTERFACE_ID_ERC1155)) {
          collectionDetails[collection].asset_type = AssetType.ERC1155;
          collectionDetails[collection].supports2981 = ERC165Checker.supportsERC165InterfaceUnchecked(collection, INTERFACE_ID_ERC2981);
          emit CollectionAdded(collection, AssetType.ERC1155);
          return AssetType.ERC1155;
        } else {
          (bool success, bytes memory result) = collection.staticcall(abi.encodeWithSignature("totalSupply()"));
          require((success && result.length > 0), "Unknown contract");
          // Assume ERC20
          collectionDetails[collection].asset_type = AssetType.ERC20;
          emit CollectionAdded(collection, AssetType.ERC20);
          return AssetType.ERC20;
        }
      }
    }







    // - - - - - - - - - - - - Transfer Helpers - - - - - - - - - - - - - //


    function _transferETH(address to, uint256 amount) internal {
      if (amount > 0) {
        require(to != address(0), "Transfer to zero address");
        (bool sent, ) = payable(to).call{ value: amount }("");
        require(sent, "Ether transfer failed");
      }
    }


    function _transferERC20(address token, address from, address to, uint256 amount) internal {
      if (amount > 0) {
        bool sent = IERC20(token).transferFrom(from, to, amount);
        require(sent, "ERC20 transfer failed");
      }
    }


    function _transferPayment(address royaltyReciever, uint256 royaltyPoints, Payment calldata payment, address buyer, address seller) internal {
      require(payment.amount > 0, "Invalid price");

      // Calculate transfer amounts;
      uint256 amountProtocol = (payment.amount * marketPoints) / INVERSE_BASIS;
      uint256 amountRoyalties = (payment.amount * royaltyPoints) / INVERSE_BASIS;
      require(payment.amount >= (amountProtocol + amountRoyalties), "Fees are more than price");
      uint256 amountSeller = payment.amount - amountProtocol - amountRoyalties;

      // Transfer funds
      if (payment.token == NATIVE_ETH) {
        _transferETH(royaltyReciever, amountRoyalties);
        _transferETH(marketRecipient, amountProtocol);
        _transferETH(seller, amountSeller);
      } else {
        _transferERC20(payment.token, buyer, royaltyReciever, amountRoyalties);
        _transferERC20(payment.token, buyer, marketRecipient, amountProtocol);
        _transferERC20(payment.token, buyer, seller, amountSeller);
      }
    }


    function _transferAssets(address collection, uint256 tokenId, uint256 amount, address seller, address buyer, AssetType asset_type) internal {
      if (asset_type == AssetType.ERC721) {
        IERC721(collection).safeTransferFrom(seller, buyer, tokenId);
      } else if (asset_type == AssetType.ERC1155) {
        IERC1155(collection).safeTransferFrom(seller, buyer, tokenId, amount, "");
      } else {
        _transferERC20(collection, seller, buyer, amount);
      }
    }


    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
      require(signature.length == 65, "Invalid signature length");
      assembly {
          r := mload(add(signature, 32))
          s := mload(add(signature, 64))
          v := byte(0, mload(add(signature, 96)))
      }
      if (v < 27) v += 27;
    }


    function _useERC20permits(Permit_ERC20[] calldata erc20permits) internal {
      for (uint256 i = 0; i < erc20permits.length; ++i) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(erc20permits[i].signature);
        IERC20Permit(erc20permits[i].token).permit(erc20permits[i].owner, address(this), erc20permits[i].value, erc20permits[i].deadline, v, r, s);
      }
    }






    // - - - - - - - - - - - - Executing orders - - - - - - - - - - - - - //


    function _executeOrder(Executable calldata e) internal {
      require(e.order.maker != address(0), "No maker");
      bytes32 orderHash = _hashOrder(e.order);
      require(orderMap[orderHash] == false, "Order is executed");
      require(SignatureChecker.isValidSignatureNow(e.order.maker, orderHash, e.signature), "Invalid Signature");
      require(e.order.expiry > block.timestamp, "Order expired");
      require(e.order.paymentMethods.length > 0, "No payments");
      require(e.paymentIndex < e.order.paymentMethods.length, "Invalid payment method");
      require(e.order.maker != msg.sender, "You are the order creator");


      // Set order as executed in mapping
      orderMap[orderHash] = true;


      // Get seller and buyer
      (address buyer, address seller) = (e.order.order_type == OrderType.LISTING) ? (msg.sender, e.order.maker) : (e.order.maker, msg.sender);


      // Get the tokenId
      uint256 _tokenId = (e.order.order_type == OrderType.COLLECTION_OFFER) ? e.collectionOfferTokenId : e.order.tokenId;


      // Get collection asset type
      AssetType asset_type = checkCollection(e.order.collection);


      // Get the transfer royalties
      (address royaltyReciever, uint256 royaltyPoints) = _getTransferRoyalties(e.order.collection, _tokenId);


      // Check that the fees at the time of listing are still within slippageTolerance
      if (e.order.order_type == OrderType.LISTING) {
        if ((royaltyPoints + marketPoints) > (e.order.fees.royaltyPoints + e.order.fees.marketPoints)) {
          require(((royaltyPoints + marketPoints) - (e.order.fees.royaltyPoints + e.order.fees.marketPoints)) <= e.order.fees.slippageTolerance, "Fees out of range");
        }
      }


      // Transfer payment for assets
      if (e.order.paymentsCombined) {
        for (uint256 i = 0; i < e.order.paymentMethods.length; ++i) {
          if (e.order.order_type != OrderType.LISTING) {
            require(e.order.paymentMethods[i].token != NATIVE_ETH, "Offer cannot contain ETH");
          }
          _transferPayment(royaltyReciever, royaltyPoints, e.order.paymentMethods[i], buyer, seller);
        }
      } else {
        if (e.order.order_type != OrderType.LISTING) {
          require(e.order.paymentMethods[e.paymentIndex].token != NATIVE_ETH, "Offer cannot contain ETH");
        }
        _transferPayment(royaltyReciever, royaltyPoints, e.order.paymentMethods[e.paymentIndex], buyer, seller);
      }


      // Transfer assets to buyer
      _transferAssets(e.order.collection, _tokenId, e.order.amount, seller, buyer, asset_type);


      // Emit event executed
      emit OrderExecuted(
        seller,
        buyer,
        e,
        orderHash
      );
    }



    function _nativeEthRequired(Payment[] calldata paymentMethods, uint256 paymentIndex, bool paymentsCombined) internal pure returns (uint256) {
      uint256 ethRequired = 0;
      if (paymentsCombined) {
        for (uint256 j = 0; j < paymentMethods.length; ++j) {
          if (paymentMethods[j].token == NATIVE_ETH) {
            ethRequired += paymentMethods[j].amount;
          }
        }
      } else {
        if (paymentMethods[paymentIndex].token == NATIVE_ETH) {
          ethRequired = paymentMethods[paymentIndex].amount;
        }
      }
      return ethRequired;
    }



    function execute(Executable calldata executable, Permit_ERC20[] calldata erc20permits) external payable nonReentrant whenNotPaused {
      if (executable.order.order_type == OrderType.LISTING) {
        require(msg.value == _nativeEthRequired(executable.order.paymentMethods, executable.paymentIndex, executable.order.paymentsCombined), "Incorrect ETH sent");
      } else {
        require(msg.value == 0, "Do not send ETH");
      }

      // If provided, use permits to increase the allowance used for payments
      _useERC20permits(erc20permits);

      // Execute order
      _executeOrder(executable);
    }



    function bulkExecute(Executable[] calldata executables, Permit_ERC20[] calldata erc20permits) external payable nonReentrant whenNotPaused {
      uint256 totalEthRequired = 0;

      // If provided, use permits to increase the allowance used for payments
      _useERC20permits(erc20permits);

      for (uint256 i = 0; i < executables.length; ++i) {
        if (executables[i].order.order_type == OrderType.LISTING) {
          totalEthRequired += _nativeEthRequired(executables[i].order.paymentMethods, executables[i].paymentIndex, executables[i].order.paymentsCombined);
        }
        _executeOrder(executables[i]);
      }

      require(msg.value == totalEthRequired, "Incorrect ETH sent");
    }



    function cancelOrders(Order[] calldata orders) external {
      bytes32 orderHash;
      for (uint256 i = 0; i < orders.length; ++i) {
        require(orders[i].maker == msg.sender, "Not maker");
        orderHash = _hashOrder(orders[i]);
        require(orderMap[orderHash] == false, "Order is executed");
        orderMap[orderHash] = true;
        emit OrderCancelled(msg.sender, orderHash);
      }
    }





    // - - - - - - - - - - - - Admin - - - - - - - - - - - - - //


    function pause() external onlyOwner {
      _pause();
    }


    function unpause() external onlyOwner {
      _unpause();
    }


    function setMarketPoints(uint256 _marketPoints) external onlyOwner {
      require(_marketPoints <= 250, "2.5% max");
      marketPoints = _marketPoints;
      emit NewMarketPoints(_marketPoints);
    }


    function setMarketRecipient(address _marketRecipient) external onlyOwner {
      marketRecipient = _marketRecipient;
      emit NewMarketRecipient(_marketRecipient);
    }





    // - - - - - - - - - - - - Non ERC2981 NFT Royalties - - - - - - - - - - - - - //


    function setApprovedCollectionOwner(address collection, address collectionOwner) external onlyOwner {
      collectionDetails[collection].approvedCollectionOwner = collectionOwner;
      emit NewApprovedCollectionOwner(collection, collectionOwner);
    }


    function setCollectionRoyalties(address collection, uint256 points, address receiver) external {
      AssetType asset_type = checkCollection(collection);
      require(asset_type != AssetType.ERC20, "No ERC20");
      require(!collectionDetails[collection].supports2981, "Supports ERC2981");

      if (collectionDetails[collection].approvedCollectionOwner != address(0)) {
        require(collectionDetails[collection].approvedCollectionOwner == msg.sender, "You are not approved");
      } else {
        (bool success, bytes memory result) = collection.staticcall(abi.encodeWithSignature("owner()"));
        require(success && (abi.decode(result, (address)) == msg.sender), "Not owner");
      }

      require(receiver != address(0), "Address 0");
      require(points <= 1000, "10% max");
      collectionDetails[collection].royalty_points = points;
      collectionDetails[collection].royalty_receiver = receiver;

      emit NewCollectionRoyalties(collection, points, receiver);
    }


}