// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {IERC721Permit} from '../../interfaces/periphery/IERC721Permit.sol';

import {DeadlineValidation} from './DeadlineValidation.sol';

/// @title Interface for verifying contract-based account signatures
/// @notice Interface that verifies provided signature for the data
/// @dev Interface defined by EIP-1271
interface IERC1271 {
  /// @notice Returns whether the provided signature is valid for the provided data
  /// @dev MUST return the bytes4 magic value 0x1626ba7e when function passes.
  /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
  /// MUST allow external calls.
  /// @param hash Hash of the data to be signed
  /// @param signature Signature byte array associated with _data
  /// @return magicValue The bytes4 magic value 0x1626ba7e
  function isValidSignature(bytes32 hash, bytes memory signature)
    external
    view
    returns (bytes4 magicValue);
}

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721Permit is DeadlineValidation, ERC721Enumerable, IERC721Permit {
  /// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
  bytes32 public constant override PERMIT_TYPEHASH =
    0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

  /// @dev The hash of the name used in the permit signature verification
  bytes32 private immutable nameHash;

  /// @dev The hash of the version string used in the permit signature verification
  bytes32 private immutable versionHash;

  /// @return The domain seperator used in encoding of permit signature
  bytes32 public immutable override DOMAIN_SEPARATOR;

  /// @notice Computes the nameHash and versionHash
  constructor(
    string memory name_,
    string memory symbol_,
    string memory version_
  ) ERC721(name_, symbol_) {
    bytes32 _nameHash = keccak256(bytes(name_));
    bytes32 _versionHash = keccak256(bytes(version_));
    nameHash = _nameHash;
    versionHash = _versionHash;
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
        _nameHash,
        _versionHash,
        _getChainId(),
        address(this)
      )
    );
  }

  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override onlyNotExpired(deadline) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(PERMIT_TYPEHASH, spender, tokenId, _getAndIncrementNonce(tokenId), deadline)
        )
      )
    );
    address owner = ownerOf(tokenId);
    require(spender != owner, 'ERC721Permit: approval to current owner');

    if (Address.isContract(owner)) {
      require(
        IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e,
        'Unauthorized'
      );
    } else {
      address recoveredAddress = ecrecover(digest, v, r, s);
      require(recoveredAddress != address(0), 'Invalid signature');
      require(recoveredAddress == owner, 'Unauthorized');
    }

    _approve(spender, tokenId);
  }

  /// @dev Gets the current nonce for a token ID and then increments it, returning the original value
  function _getAndIncrementNonce(uint256 tokenId) internal virtual returns (uint256);

  /// @dev Gets the current chain ID
  /// @return chainId The current chain ID
  function _getChainId() internal view returns (uint256 chainId) {
    assembly {
      chainId := chainid()
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, IERC721Permit)
    returns (bool)
  {
    return
      interfaceId == type(ERC721Enumerable).interfaceId ||
      interfaceId == type(IERC721Permit).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}