// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {Rescuable} from "../utils/Rescuable.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@solmate/tokens/ERC1155.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {ReverseRegistrar} from "@ens/contracts/registry/ReverseRegistrar.sol";

import {OrderParametersLibrary, OrderParameters} from "./lib/OrderParameters.sol";
import {TokenIdentifierLibrary, TokenIdentifier} from "./lib/TokenIdentifier.sol";
import {CrossPostAccount} from "./CrossPostAccount.sol";
import {IOmniAccount} from "./interfaces/IOmniAccount.sol";

contract OmniAccount is IOmniAccount, CrossPostAccount, Rescuable, ERC721TokenReceiver, ERC1155TokenReceiver {
  using OrderParametersLibrary for OrderParameters;
  using TokenIdentifierLibrary for TokenIdentifier;

  // Maps TokenIdentifierHash to its OrderParameterHash
  mapping(bytes32 => bytes32) public orders;

  // Maps TokenIdentifierHash to owner address for recieved nfts
  mapping(bytes32 => address) public owners;
  
  // ReverseRegistrar public registrar;
  
  constructor(address oracleSigner) {
    setOmniOracleSigner(oracleSigner);
    // registrar = ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    emit AccountCreated(address(this), msg.sender);
  }

  // function setName(string memory name) external onlyOwner {
  //   registrar.setName(name);
  // }

  // Requires the auction state to match an auction identified by `auctionId`.
  modifier onlyValidParameters(OrderParameters[] calldata parameters) {
    for (uint256 i; i < parameters.length; ) {
      if (orders[parameters[i].idHash()] != parameters[i].hash() || owners[parameters[i].idHash()] != msg.sender) {
        revert InvalidOrder();
      }

      unchecked {
        ++i;
      }
    }

    _;
  }

  function createOrder(OrderParameters[] memory parameters) external whenNotPaused {
    for (uint256 i; i < parameters.length; ) {
      OrderParameters memory params = parameters[i];
      params.validate();

      ERC721 collection = ERC721(params.collection);

      collection.safeTransferFrom(msg.sender, address(this), params.id);

      orders[params.idHash()] = params.hash();

      unchecked {
        ++i;
      }
    }

    emit OrdersCreated(address(this), msg.sender, parameters);
  }

  function updateOrder(OrderParameters[] calldata existingParameters, OrderParameters[] calldata newParameters)
    external
    whenNotPaused
    onlyValidParameters(existingParameters)
  {
    if (existingParameters.length != newParameters.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < existingParameters.length; ) {
      OrderParameters memory existingParams = existingParameters[i];
      OrderParameters memory newParams = newParameters[i];

      newParams.validate();
      existingParams.validateUpdate(newParams);

      orders[newParams.idHash()] = newParams.hash();
      unchecked {
        ++i;
      }
    }
    emit OrdersUpdated(address(this), msg.sender, existingParameters, newParameters);
  }

  function withdraw(OrderParameters[] calldata parameters) external onlyValidParameters(parameters) {
    for (uint256 i; i < parameters.length; ) {
      if (parameters[i].owner != msg.sender) {
        revert Unauthorized();
      }

      ERC721 collection = ERC721(parameters[i].collection);
      collection.safeTransferFrom(address(this), msg.sender, parameters[i].id);
      delete orders[parameters[i].idHash()];

      unchecked {
        ++i;
      }
    }

    emit OrdersWithdrawn(address(this), msg.sender, parameters);
  }

  function createOrderForReceivedItems(OrderParameters[] calldata parameters) external {
    for (uint256 i; i < parameters.length; ) {
      if (owners[parameters[i].idHash()] != msg.sender) {
        revert Unauthorized();
      }

      OrderParameters memory params = parameters[i];
      params.validate();

      ERC721 collection = ERC721(params.collection);

      if (collection.ownerOf(params.id) != address(this)) {
        revert InvalidOrder();
      }

      orders[params.idHash()] = params.hash();

      unchecked {
        ++i;
      }
    }

    emit OrdersCreated(address(this), msg.sender, parameters);
  }

  function setOwnersForItems(TokenIdentifier[] calldata tokens, address[] calldata ownerArray) external onlyOwner {
    if (tokens.length != ownerArray.length) {
      revert MismatchedInputLength();
    }

    for (uint256 i; i < tokens.length; ) {
      if (owners[tokens[i].hash()] != address(0)) {
        revert Unauthorized();
      }

      ERC721 collection = ERC721(tokens[i].collection);

      if (collection.ownerOf(tokens[i].id) != address(this)) {
        revert InvalidOrder();
      }

      owners[tokens[i].hash()] = ownerArray[i];
      unchecked {
        ++i;
      }
    }
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external virtual override returns (bytes4) {
    ERC721 collection = ERC721(msg.sender);
    if (collection.supportsInterface(type(IERC721).interfaceId)) {
      owners[TokenIdentifier({collection: address(collection), id: tokenId}).hash()] = from;
      delete orders[TokenIdentifier({collection: address(collection), id: tokenId}).hash()];
    }
    return ERC721TokenReceiver.onERC721Received.selector;
  }

  function setPause(bool shouldPause) external onlyOwner {
    if (shouldPause) {
      _pause();
    } else {
      _unpause();
    }
  }

  function withdrawERC721(ERC721 token, uint256[] calldata ids, address recipient) external override onlyOwner {
    for (uint256 i; i < ids.length; ) {
      delete orders[TokenIdentifier({collection: address(token), id: ids[i]}).hash()];
      delete owners[TokenIdentifier({collection: address(token), id: ids[i]}).hash()];

      token.safeTransferFrom(address(this), recipient, ids[i]);
      unchecked {
        ++i;
      }
    }
  }

  receive() external payable {}

  fallback() external payable {}
}