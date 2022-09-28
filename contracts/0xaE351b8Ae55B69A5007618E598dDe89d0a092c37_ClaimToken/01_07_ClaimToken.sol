// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ProxyOwnable } from "./ProxyOwnable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Errors } from "./library/errors/Errors.sol";

enum MintWindow {
  CLOSED,
  WINDOW1,
  WINDOW2,
  PUBLIC
}

contract ClaimToken is ERC721A, ProxyOwnable {
  string private _metadataRoot;
  string private _contractMetadata;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  bytes32 private _primaryRoot;
  bytes32 private _window1Root;
  bytes32 private _window2Root;

  MintWindow private _mintWindow;

  uint256 private _primaryAllocation;
  mapping(address => bool) private _mintSpent;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory metadataRoot_,
    string memory contractMetadata_
  ) ERC721A(name_, symbol_) {
    _metadataRoot = metadataRoot_;
    _contractMetadata = contractMetadata_;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataRoot;
  }

  function setBaseURI(string memory uri) onlyOwner public {
    _metadataRoot = uri;
  }

  function contractURI() public view returns(string memory) {
    return _contractMetadata;
  }

  function setContractURI(string memory uri) onlyOwner public {
    _contractMetadata = uri;
  }

  function setAuthRoots(bytes32 primaryRoot, bytes32 window1Root, bytes32 window2Root) onlyAuthorized public {
    _primaryRoot = primaryRoot;
    _window1Root = window1Root;
    _window2Root = window2Root;
  }

  function setMintWindow(MintWindow window) public {
    _mintWindow = window;
  }

  function currentMintWindow() public view returns (MintWindow) {
    return _mintWindow;
  }

  function mint(
    uint256 primaryQuantity,
    bytes32[] memory primaryProof,
    uint256 authQuantity,
    bytes32[] memory authProof
  ) public {
    address sender = _msgSenderERC721A();
    MintWindow window = _mintWindow;
    verifyAndMark(sender);

    if (window == MintWindow.WINDOW1) {
      // geeks and window1 combined allocation
      (uint256 newPrimaryQuantity, uint256 newAuthQuantity) = verifyAndAllocate(
        sender, window, primaryQuantity, primaryProof, authQuantity, authProof
      );
      unchecked{
        // if this can overflow, we've done an EXTREMELY poor job of setting up the merkle list
        _mint(sender, newPrimaryQuantity + newAuthQuantity);
      }

    } else if (window == MintWindow.WINDOW2) {
      // geeks and window2 quantity 1
      (uint256 newPrimaryQuantity, uint256 newAuthQuantity) = verifyAndAllocate(
        sender, window, primaryQuantity, primaryProof, authQuantity, authProof
      );

      // we will either mint 1 or 0 here
      _mint(sender, newPrimaryQuantity + newAuthQuantity);
    } else if (window == MintWindow.PUBLIC) {
      uint256 quantity = checkQuantity(1, 10000);
      _mint(sender, quantity);
    } else {
      // minting closed
      revert Errors.MintingClosed();
    }
  }

  function adminMint(address[] memory recipients, uint256 quantity) onlyAuthorized public {
    for (uint i = 0; i < recipients.length;) {
      _adminMint(recipients[i], quantity);

      unchecked {
        ++i;
      }
    }
  }

  function _adminMint(address recipient, uint256 quantity) internal {
    uint256 newQuantity = checkQuantity(quantity, 10000);
    if (newQuantity != 0) {
      _mint(recipient, newQuantity);
    }
  }

  function totalMinted() public view returns(uint) {
    return _totalMinted();
  }

  function hasMinted(address minter) public view returns(bool) {
    return _mintSpent[minter];
  }

  function primaryAllocation() public view returns(uint256) {
    return _primaryAllocation;
  }

  function burn(uint256 token) onlyAuthorized public {
    _burn(token);
  }

  function batchBurn(uint256[] calldata tokens) onlyAuthorized public {
    for (uint i = 0; i < tokens.length;) {
      _burn(tokens[i]);

      unchecked {
        ++i;
      }
    }
  }

  function delegateOperator(address operator, bool auth) onlyOwner public {
    _operatorApprovals[address(this)][operator] = auth;
    emit ApprovalForAll(address(this), operator, auth);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
      _operatorApprovals[_msgSenderERC721A()][operator] = approved;
      emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      return _operatorApprovals[owner][operator];
    }

  function verifyAndMark(address minter) internal {
    if (_mintSpent[minter]) {
      revert Errors.AllocationSpent();
    }
    _mintSpent[minter] = true;
  }

  function verifyAndAllocate(
    address minter,
    MintWindow window,
    uint256 primaryQuantity,
    bytes32[] memory primaryProof,
    uint256 authQuantity,
    bytes32[] memory authProof
  ) internal returns (uint256 newPrimaryQuantity, uint256 newAuthQuantity) {
    if (primaryQuantity > 0) {
      bytes32 leaf = keccak256(abi.encodePacked(minter, primaryQuantity));
      if (!MerkleProof.verify(primaryProof, _primaryRoot, leaf)) {
        revert Errors.UserPermissions();
      }

      if (window == MintWindow.WINDOW1) {
        newPrimaryQuantity = checkQuantity(primaryQuantity, 10000);
        unchecked {
          // if this can overflow, we've done an EXTREMELY poor job of setting up the merkle list
          // we're only counting toward the reserved allocation during window 1
          _primaryAllocation += newPrimaryQuantity;
        }
      } else {
        // this is window 2 then
        newPrimaryQuantity = checkQuantity(1, 10000);
      }
    }

    if (authQuantity > 0) {
      if (window == MintWindow.WINDOW1) {
        bytes32 root = _window1Root;
        bytes32 leaf = keccak256(abi.encodePacked(minter, authQuantity));
        if (!MerkleProof.verify(authProof, root, leaf)) {
          revert Errors.UserPermissions();
        }
        unchecked {
          newAuthQuantity = checkQuantity(authQuantity, 10000 - newPrimaryQuantity);
        }
      } else {
        if (newPrimaryQuantity == 0) {
          // this is window 2 then, skip this check if we've already passed the primary check above
          bytes32 root = _window2Root;
          bytes32 leaf = keccak256(abi.encodePacked(minter, authQuantity));
          if (!MerkleProof.verify(authProof, root, leaf)) {
            revert Errors.UserPermissions();
          }
          newAuthQuantity = checkQuantity(1, 10000);
        }
      }
    }
  }

  function checkQuantity(uint256 quantity, uint256 limit) internal view returns (uint256 newQuantity) {
    unchecked {
      if (_totalMinted() + quantity > limit) {
        newQuantity = limit - _totalMinted();
      } else {
        newQuantity = quantity;
      }
    }
  }
}