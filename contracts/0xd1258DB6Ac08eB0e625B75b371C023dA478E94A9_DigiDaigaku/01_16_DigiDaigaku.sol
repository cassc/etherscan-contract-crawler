// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title DigiDaigaku contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation
contract DigiDaigaku is ERC721, Ownable, EIP712, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string public baseTokenURI = "";
  string public suffixURI = ".json";

  uint256 public constant maxSupply = 2022;

  mapping(address => bool) public addressMinted;

  address public signer;

  /// @dev Emitted when royalty is set.
  event RoyaltySet(address _receiver, uint96 _feeNumerator);

  /// @dev Emitted when signer is set.
  event SignerSet(address _signer);

  /// @dev Emitted when base URI is set.
  event BaseURISet(string _baseTokenURI);

  /// @dev Emitted when suffix URI is set.
  event SuffixURISet(string _suffixURI);

  constructor() ERC721("DigiDaigaku", "DIDA") EIP712("DigiDaigaku", "1") {}

  /// @notice Owner mint to reserve DigiDaigaku
  function mintFromOwner(uint256 _quantity, address _receiver) external onlyOwner {
    require(_tokenIdCounter.current() + _quantity <= maxSupply, "Exceeds max supply");

    for (uint256 i = 0; i < _quantity; i++) {
      _tokenIdCounter.increment();
      _safeMint(_receiver, _tokenIdCounter.current());
    }
  }

  /// @notice Public mint with valid signature
  function mintPublic(bytes calldata _signature) external {
    require(!addressMinted[_msgSender()], "Exceeds claimed amount");
    require(_tokenIdCounter.current() < maxSupply, "Exceeds max supply");

    _verifySignature(_signature);

    _tokenIdCounter.increment();
    addressMinted[_msgSender()] = true;

    _safeMint(_msgSender(), _tokenIdCounter.current());
  }

  /// @dev Verify signature 
  function _verifySignature(bytes calldata _signature) internal view
  {
    bytes32 hash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          keccak256(
              "Approved(address wallet)"
          ),
          _msgSender()
        )
      )
    );

    require(
      signer == ECDSA.recover(hash, _signature),
      "Invalid signer"
    );
  }

  /// @dev Required to return baseTokenURI for tokenURI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @notice Sets base URI
  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;

    emit BaseURISet(_baseTokenURI);
  }

  /// @notice Sets suffix URI
  function setSuffixURI(string memory _suffixURI) external onlyOwner {
    suffixURI = _suffixURI;

    emit SuffixURISet(_suffixURI);
  }

  /// @notice Returns tokenURI if baseURI is set
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), suffixURI))
      : "";
  }

  /// @notice Sets signer
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;

    emit SignerSet(_signer);
  }

  /// @notice Sets royalty information
  function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);

    emit RoyaltySet(_receiver, _feeNumerator);
  }

  /// @notice Returns the current total supply
  function totalSupply() external view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function supportsInterface(bytes4 _interfaceId) public view virtual override (ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }
}