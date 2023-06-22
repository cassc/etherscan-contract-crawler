// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title Soulbound ERC721 contract with signature-based minting
contract ERC721SoulboundTokenImpl is
  EIP712Upgradeable,
  ReentrancyGuardUpgradeable
{
  /// @notice Emitted when calling any transfer related function
  error Soulbound();

  /// @notice Emitted when user tries to mint more than once
  error AlreadyClaimed();

  /// @notice Emitted when trying to set `trustedAddress` to zero address, or if signature verification fails during mint()
  error InvalidAddress();

  /// @notice Emitted when user tries to mint beyond maxSupply
  error ExceedsMaxSupply();

  /// @notice Emitted when `msg.value` does not equal to `MINT_FEE` during `mint()`
  error InvalidFee();

  /// @notice Emitted when ether transfer reverted
  error TransferFailed();

  /// @notice Emitted when mint fee is paid during mint
  /// @param mintFee mint fee paid
  /// @param mintFeePayer token minter who paid mintFee
  /// @param mintFeeRecipient mint fee recipient
  event MintFeePaid(
    uint256 mintFee,
    address mintFeePayer,
    address mintFeeRecipient
  );

  /// @dev Emits when ownership changes. Used only during mint since soulbound
  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  /// @notice Mint Fee
  uint256 public immutable MINT_FEE;

  /// @notice Mint Fee Recipient
  address payable public immutable MINT_FEE_RECIPIENT;

  /// @dev Counter for the next tokenID, defaults to 1 for better gas on first mint
  uint256 public nextTokenId;

  /// @notice Token name
  string public name;

  /// @notice Token symbol
  string public symbol;

  /// @notice Token contractURI
  string internal _contractURI;

  /// @notice Token URI
  string internal _tokenURI;

  /// @notice Max allowed token amount
  uint256 public maxSupply;

  /// @notice Get the owner of a certain tokenID
  mapping(uint256 => address) public ownerOf;

  /// @notice Get how many tokens a certain user owns
  mapping(address => uint256) public balanceOf;

  /// @notice The owner of this contract (set to the deployer)
  address public owner;

  /// @dev Address used for signatures
  address internal trustedAddress;

  /// @notice Check if NFT has been claimed before
  mapping(address => uint256) public claims;

  bytes32 private constant _MINT_TYPEHASH = keccak256("Mint(address to)");

  constructor(uint256 _mintFee, address payable _mintFeeRecipient) {
    _disableInitializers();

    MINT_FEE = _mintFee;
    MINT_FEE_RECIPIENT = _mintFeeRecipient;
  }

  /// @dev Initialize after deploying clone
  /// @param _name Token name
  /// @param _symbol Token symbol
  /// @param contractURI_ Token contract metadata URI
  /// @param tokenURI_ Token metadata URI
  /// @param _owner Owner of token contract
  /// @param _trustedAddress Address used for signatures
  /// @param _maxSupply Max allowed token amount
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory contractURI_,
    string memory tokenURI_,
    address _owner,
    address _trustedAddress,
    uint256 _maxSupply
  ) public initializer {
    /* if (_trustedAddress == address(0)) revert InvalidAddress(); */

    assembly {
      if iszero(_trustedAddress) {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    __EIP712_init(_name, "1.0");

    nextTokenId = 1;
    name = _name;
    symbol = _symbol;
    _contractURI = contractURI_;
    _tokenURI = tokenURI_;
    owner = _owner;
    trustedAddress = _trustedAddress;
    maxSupply = _maxSupply;
  }

  /// @notice Public signature-based mint function
  /// @dev Verifies submitted signature to be from `trustedAddress`
  function mint(bytes32 r, bytes32 s, uint8 v) external payable nonReentrant {
    if (claims[msg.sender] != 0) {
      /* revert AlreadyClaimed(); */
      assembly {
        mstore(0x00, 0x646cf558) // AlreadyClaimed()
        revert(0x1c, 0x04)
      }
    }

    if (msg.value != MINT_FEE) {
      /* revert InvalidFee(); */
      assembly {
        mstore(0x00, 0x58d620b3) // InvalidFee()
        revert(0x1c, 0x04)
      }
    }

    uint256 tokenId = nextTokenId;

    bytes32 digest = _hashTypedDataV4(
      keccak256(abi.encode(_MINT_TYPEHASH, msg.sender))
    );
    if (ECDSAUpgradeable.recover(digest, v, r, s) != trustedAddress) {
      /* revert InvalidAddress(); */
      assembly {
        mstore(0x00, 0xe6c4247b) // InvalidAddress()
        revert(0x1c, 0x04)
      }
    }

    _mintToken(msg.sender, tokenId);

    _payMintFee();
  }

  /// @notice Get contract-level metadata URI
  /// @return URI to fetch contract-level metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /// @notice Return token media URI
  function tokenURI(uint256) public view virtual returns (string memory) {
    return _tokenURI;
  }

  /// @notice Disabled ERC721 "approve" method
  function approve(address, uint256) public virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "isApprovedForAll" method
  function isApprovedForAll(address, address) public view virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "getApproved" method
  function getApproved(uint256) public view virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "getApproved" method
  function setApprovalForAll(address, bool) public virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "transferFrom" method
  function transferFrom(address, address, uint256) public virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "safeTransferFrom" method
  function safeTransferFrom(address, address, uint256) public virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @notice Disabled ERC721 "safeTransferFrom" method
  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual {
    /* revert Soulbound(); */
    assembly {
      mstore(0x00, 0xa4420a95) // Soulbound()
      revert(0x1c, 0x04)
    }
  }

  /// @dev Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    /* return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata */

    bool result;
    assembly {
      let _interfaceId := shr(224, interfaceId)
      result := or(
        or(eq(_interfaceId, 0x01ffc9a7), eq(_interfaceId, 0x80ac58cd)), // ERC165, ERC721
        eq(_interfaceId, 0x5b5e139f) // ERC721Metadata
      )
    }
    return result;
  }

  /// @dev Internal mint function.
  ///      Reverts if exceeds max supply
  /// @param to Destination address
  /// @param tokenId Token Id
  function _mintToken(address to, uint256 tokenId) internal {
    if (tokenId > maxSupply) {
      /* revert ExceedsMaxSupply(); */
      assembly {
        mstore(0x00, 0xc30436e9) // ExceedsMaxSupply()
        revert(0x1c, 0x04)
      }
    }

    unchecked {
      ++balanceOf[to];
      ++nextTokenId;
    }

    ownerOf[tokenId] = to;
    claims[msg.sender] = tokenId;

    /* emit Transfer(address(0), to, tokenId); */
    assembly {
      log4(
        0x00,
        0x00, // no data
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, // Transfer(address,address,uint256)
        0, // from
        to, // to
        tokenId // id
      )
    }
  }

  /// @dev Internal function to pay mint fee
  ///      Reverts if ether transfer fails
  ///      Emits MintFeePaid
  function _payMintFee() internal {
    (bool success, ) = MINT_FEE_RECIPIENT.call{value: MINT_FEE}("");
    /* if (!success) revert TransferFailed(); */
    assembly {
      if iszero(success) {
        mstore(0x00, 0x90b8ec18) // TransferFailed()
        revert(0x1c, 0x04)
      }
    }

    emit MintFeePaid(MINT_FEE, msg.sender, MINT_FEE_RECIPIENT);
  }
}