//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981.sol";

contract CryptoGemAlliance is ERC721Enumerable, ERC2981, Ownable{
  uint public constant MAX_UNITS = 10000000;
  string public constant BASE_TOKEN_URI = "http://geml2.com/tokenData?";

  // Optional mapping for token URIs
  mapping (uint256 => string) private _tokenURISuffixes;    //&userId=[user_id]&sessionId=[sessionId]
  mapping (string => address) private _usedSessions;        //Used session ids

  event Mint(address to, uint256 tokenId, string sessionId);

  constructor() ERC721("CryptoGemAlliance", "CGA")  {

  }

  modifier saleIsOpen{
    require(totalSupply() < MAX_UNITS, "Sale end");
    _;
  }

  function mintTokens(address _to, uint _count, uint _maxSupply, uint _maxMint, uint _price, bool _canMint, string memory _sessionId, bytes memory _signature) public payable saleIsOpen {
    // verify the signature, it should be from owner
    address signer = owner();
    bool verified = verify(signer, _to, _maxSupply, _maxMint, _price, _canMint, _sessionId, _signature);
    require(verified, "Unable to verify the signature");

    require(totalSupply() + _count <= _maxSupply, "Max limit");
    require(totalSupply() < _maxSupply, "Sale end");
    require(_canMint, "This user is not allowed to mint");
    require(_count < _maxMint, "User can not mint more than maximum allowed at once");

    // Check used sessions
    require(_usedSessions[_sessionId] == address(0), "Duplicated session id");

    // Check the price
    require(msg.value >= _count * _price, "Sent value below price");

    // Assign to used sessions
    _usedSessions[_sessionId] = _to;

    for(uint i = 0; i < _count; i++){
      uint256 newTokenId = totalSupply();
      _safeMint(_to, newTokenId);
      // Set token suffix after mint
      string memory tokenURISuffix = string(abi.encodePacked("&userId=", Strings.toHexString(uint256(uint160(_to))), "&sessionId=", _sessionId));
      _setTokenURISuffix(newTokenId, tokenURISuffix);

      // Emit mint event
      emit Mint(_to, newTokenId, _sessionId);
    }
  }

  /**
   * Supports ERC165, Rarible Secondary Sale Interface, and ERC721
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * ERC2981 Royalties Standards (Mintable)
   */
  function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external view override returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData) {
    return (owner(), _value / 10, _data);
  }

  /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory _tokenURISuffix = _tokenURISuffixes[tokenId];

    if (bytes(_tokenURISuffix).length > 0) {
      return string(abi.encodePacked(BASE_TOKEN_URI, "id=", Strings.toString(tokenId), _tokenURISuffix));
    }

    return BASE_TOKEN_URI;
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURISuffix(uint256 tokenId, string memory _tokenURISuffix) internal virtual {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    _tokenURISuffixes[tokenId] = _tokenURISuffix;
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 tokenId) public onlyOwner {
    super._burn(tokenId);

    if (bytes(_tokenURISuffixes[tokenId]).length != 0) {
      delete _tokenURISuffixes[tokenId];
    }
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(_msgSender()).send(address(this).balance));
  }

  function getMessageHash(address userId, uint maxSupply, uint maxMint, uint price, bool canMint, string memory sessionId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(userId, maxSupply, maxMint, price, canMint, sessionId));
  }

  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    /*
    Signature is produced by signing a keccak256 hash with the following format:
    "\x19Ethereum Signed Message\n" + len(msg) + msg
    */
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  function verify(
    address _signer,
    address _userId, uint _maxSupply, uint _maxMint, uint _price, bool _canMint, string memory _sessionId,
    bytes memory _signature
  )
  public pure returns (bool)
  {
    bytes32 messageHash = getMessageHash(_userId, _maxSupply, _maxMint, _price, _canMint, _sessionId);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, _signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v)
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
    /*
    First 32 bytes stores the length of the signature

    add(sig, 32) = pointer of sig + 32
    effectively, skips first 32 bytes of signature

    mload(p) loads next 32 bytes starting at the memory address p into memory
    */
    // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
    // second 32 bytes
      s := mload(add(sig, 64))
    // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }
    // implicitly return (r, s, v)
  }
}