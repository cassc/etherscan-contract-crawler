//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "base64-sol/base64.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract DiscoERC721 is ERC721, AccessControl {
  using Strings for uint256;
  bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

  // Private
  uint256 private _idCounter = 0;
  uint256 private _numberOfImages;
  string private _baseTokenURI;
  ContractURI private _contractURI;

  struct ContractURI {
    string name;
    string description;
    string image;
    string externalLink;
    string sellerFeeBasisPoints;
    string feeRecipient;
  }

  mapping(address => uint256) private _tokenOwner;

  /// @notice Map to track tokenId to block timestamp when minted
  mapping(uint256 => uint256) public _tokenIdToTimestamp;

  constructor(
    string memory name,
    string memory symbol,
    string memory _baseTokenURI_,
    ContractURI memory _contractURI_,
    address admin,
    uint256 _numberOfImages_
  ) ERC721(name, symbol) {
    _idCounter++;
    _baseTokenURI = _baseTokenURI_;
    _contractURI = _contractURI_;
    _numberOfImages = _numberOfImages_;
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function totalSupply() external view returns (uint256) {
    return _idCounter - 1;
  }

  /**
   * @notice Mints a new token to the given address
   * @param to address - Address to mint to`
   */
  function mint(address to) external {
    require(hasRole(MINTER_BURNER_ROLE, _msgSender()), "DiscoERC721:unauthorized");
    unchecked {
      uint256 nextId = _idCounter++;
      _tokenOwner[to] = nextId;
      _tokenIdToTimestamp[nextId] = block.timestamp;
      _mint(to, nextId);
    }
  }

  /**
   * @notice Burns a token
   * @param tokenId uint256 - Token ID to burn
   */
  function burn(uint256 tokenId) external {
    require(hasRole(MINTER_BURNER_ROLE, _msgSender()), "DiscoERC721:unauthorized");
    _burn(tokenId);
  }

  /**
   * @notice Grants the MINTER_BURNER_ROLE to the given address
   * @param _minterBurner address - Address to grant the role to
   */
  function grantMinterBurnerRole(address _minterBurner) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DiscoERC721:unauthorized");
    grantRole(MINTER_BURNER_ROLE, _minterBurner);
  }

  /**
   * @notice Revokes the MINTER_BURNER_ROLE from the given address
   * @param _minterBurner address - Address to revoke the role from
   */
  function revokeMinterBurner(address _minterBurner) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DiscoERC721:unauthorized");
    revokeRole(MINTER_BURNER_ROLE, _minterBurner);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory baseURI_) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DiscoERC721:unauthorized");
    _baseTokenURI = baseURI_;
  }

  /**
   * @notice Override: returns the the tokens uri metadata based on the timestamp minted
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    // _requireMinted(tokenId);
    // get the image id based on the minted timestamp - +1 since tokenid starts at 1
    uint256 imageId = (_tokenIdToTimestamp[tokenId] % _numberOfImages) + 1;
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, imageId.toString(), ".json"))
        : "";
  }

  function contractURI() external view returns (string memory uri) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":',
                '"',
                _contractURI.name,
                '",',
                '"description":',
                '"',
                _contractURI.description,
                '",',
                '"image":',
                '"',
                _contractURI.image,
                '",',
                '"externalLink":',
                '"',
                _contractURI.externalLink,
                '",',
                '"sellerFeeBasisPoints":',
                '"',
                _contractURI.sellerFeeBasisPoints,
                '",',
                '"feeRecipient":',
                '"',
                _contractURI.feeRecipient,
                '"',
                "}"
              )
            )
          )
        )
      );
  }

  function transferAdmin(address account) external {
    grantRole(DEFAULT_ADMIN_ROLE, account);
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
}