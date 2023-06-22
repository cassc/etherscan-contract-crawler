// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import './components/BaseNFT.sol';

interface ITraitToken {
  function setTokenAsset(uint256 _tokenId, bytes32 _truncatedCID) external;
}

/**
 * @notice An ERC721 contract that stores per-token IPFSs CIDs efficiently. This is meant to be used for NFTs that have traits along the lines of BAYC, etc.
 */
contract TraitToken is BaseNFT, ITraitToken {
  error INVALID_OPERATION();

  bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  error NOT_MINTED();

  /**
   * @notice Cannot reassign a token CID.
   */
  error CID_REASSIGNMENT();

  /**
   * @notice Stores truncated IPFS CIDs, missing first two bytes that are expected to be 1220 for IPFS v1 CIDs.
   */
  mapping(uint256 => bytes32) public tokenCIDs;

  //*********************************************************************//
  // -------------------------- initializer ---------------------------- //
  //*********************************************************************//

  /**
   * @dev This contract is meant to be deployed via the `Deployer` which makes `Clone`s. The `Deployer` itself has a reference to a known-good copy. When the platform admin is deploying the `Deployer` and the source `TraitToken` the constructor will lock that contract to the platform admin. When the deployer is making copies of it the source storage isn't taken so the Deployer will call `initialize` to set the admin to the correct account.
   */
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(REVEALER_ROLE, msg.sender);
  }

  /**
   * @notice Initializes token state. Used by the Deployer contract to set NFT parameters and contract ownership.
   *
   * @param _owner Token admin.
   * @param _name Token name.
   * @param _symbol Token symbol.
   * @param _baseUri Base URI, initially expected to point at generic, "unrevealed" metadata json.
   * @param _contractUri OpenSea-style contract metadata URI.
   * @param _maxSupply Max NFT supply.
   * @param _unitPrice Price per token expressed in Ether.
   * @param _mintAllowance Per-user mint cap.
   * @param _mintPeriodStart Start of the minting period in seconds.
   * @param _mintPeriodEnd End of the minting period in seconds.
   */
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256 _unitPrice,
    uint256 _mintAllowance,
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) external {
    if (bytes(name).length != 0) {
      revert INVALID_OPERATION();
    }

    if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert INVALID_OPERATION();
      }
    } else {
      _grantRole(DEFAULT_ADMIN_ROLE, _owner);
      _grantRole(MINTER_ROLE, _owner);
      _grantRole(REVEALER_ROLE, _owner);
    }

    name = _name;
    symbol = _symbol;
    baseUri = _baseUri;
    contractUri = _contractUri;
    maxSupply = _maxSupply;
    unitPrice = _unitPrice;
    mintAllowance = _mintAllowance;
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;

    payoutReceiver = payable(_owner);
    royaltyReceiver = payable(_owner);
  }

  /**
   * @notice Sets a a truncated IPFS CIDv1 for a given token id.
   *
   * @dev The IPFS hash is expressed as base58 with the first two bytes cut off since they are expected to be `1220`. Future versions of this contract may use a struct instead of bytes32 that would include additional information like hashing function.
   */
  function setTokenAsset(
    uint256 _tokenId,
    bytes32 _truncatedCID
  ) external override onlyRole(MINTER_ROLE) {
    if (ownerOf(_tokenId) == address(0)) {
      revert NOT_MINTED();
    }

    if (tokenCIDs[_tokenId] != 0) {
      revert CID_REASSIGNMENT();
    }

    tokenCIDs[_tokenId] = _truncatedCID;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    bytes memory prefix = hex'1220';
    uri = string(
      abi.encodePacked('ipfs://', base58Encode(bytes.concat(prefix, tokenCIDs[_tokenId])))
    );
  }

  function generateTokenId(address, uint256) internal virtual override returns (uint256 tokenId) {
    tokenId = totalSupply;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
    return _interfaceId == type(ITraitToken).interfaceId;
  }

  /**
   * @dev Taken from https://github.com/MrChico/verifyIPFS/blob/master/contracts/verifyIPFS.sol
   */
  function base58Encode(bytes memory _data) private pure returns (string memory) {
    unchecked {
      uint256 size = _data.length;
      uint256 zeroCount;
      while (zeroCount < size && _data[zeroCount] == 0) {
        zeroCount++;
      }
      size = zeroCount + ((size - zeroCount) * 8351) / 6115 + 1;
      bytes memory slot = new bytes(size);
      uint32 carry;
      int256 m;
      int256 high = int256(size) - 1;
      for (uint256 i = 0; i < _data.length; i++) {
        m = int256(size - 1);
        for (carry = uint8(_data[i]); m > high || carry != 0; m--) {
          carry = carry + 256 * uint8(slot[uint256(m)]);
          slot[uint256(m)] = bytes1(uint8(carry % 58));
          carry /= 58;
        }
        high = m;
      }
      uint256 n;
      for (n = zeroCount; n < size && slot[n] == 0; n++) {}
      size = slot.length - (n - zeroCount);
      bytes memory out = new bytes(size);
      for (uint256 i = 0; i < size; i++) {
        uint256 j = i + n - zeroCount;
        out[i] = ALPHABET[uint8(slot[j])];
      }
      return string(out);
    }
  }
}