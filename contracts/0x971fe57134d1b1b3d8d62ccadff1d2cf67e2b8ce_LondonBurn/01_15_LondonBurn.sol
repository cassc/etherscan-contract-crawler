// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./utils/Signature.sol";

contract LondonBurn is Ownable, ERC721, Signature {

    address public mintingAuthority;
    address public minter;
    string public contractURI;

    mapping(uint256 => string) public tokenIdToUri;
    mapping(uint256 => uint256) public tokenTypeSupply;

    mapping(bytes32 => uint256) contentHashToTokenId;

    string public baseMetadataURI;

    struct MintCheck {
      address to;
      uint256 tokenType;
      string[] uris;
      bytes signature;
    }

    struct ModifyCheck {
      uint256[] tokenIds;
      string[] uris;
      bytes signature;
    }

    // events
    event MintCheckUsed(uint256 indexed tokenId, bytes32 indexed mintCheck);
    event ModifyCheckUsed(uint256 indexed tokenId, bytes32 indexed modifyCheck);
    
    constructor (
      string memory name_,
      string memory symbol_
    ) ERC721(name_, symbol_) {
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setMintingAuthority(address _mintingAuthority) external onlyOwner {
      mintingAuthority = _mintingAuthority;
    }

    modifier onlyMinter() {
        require(minter == _msgSender(), "Caller is not the minter");
        _;
    }

    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyOwner {
      baseMetadataURI = _baseMetadataURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
      return baseMetadataURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(abi.encodePacked(tokenIdToUri[tokenId]).length != 0, "ERC721Metadata: URI query for nonexistent token URI");

        return string(abi.encodePacked(_baseURI(), tokenIdToUri[tokenId]));
    }

   function getMintCheckHash(MintCheck calldata _mintCheck) public pure returns (bytes32) {
      bytes memory input = abi.encodePacked(_mintCheck.to, _mintCheck.tokenType);
      for (uint i = 0; i < _mintCheck.uris.length; ++i) {
        input = abi.encodePacked(input, _mintCheck.uris[i]);
      }
      return keccak256(input);
    }

    function verifyMintCheck(
      MintCheck calldata _mintCheck
    ) public view returns (bool) {
      bytes32 signedHash = getMintCheckHash(_mintCheck);
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_mintCheck.signature);
      return isSigned(mintingAuthority, signedHash, v, r, s);
    }


    function mintTokenType(MintCheck calldata _mintCheck) external onlyMinter {
      bytes32 mintCheckHash = getMintCheckHash(_mintCheck);
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_mintCheck.signature);
      require(isSigned(mintingAuthority, mintCheckHash, v, r, s), "Mint check is not valid");

      for (uint i = 0; i < _mintCheck.uris.length; ++i) {
        bytes32 contentHash = keccak256(abi.encodePacked(_mintCheck.uris[i]));
        require(contentHashToTokenId[contentHash] == 0, "Mint check has already been used");
        uint tokenId = (_mintCheck.tokenType | ++tokenTypeSupply[_mintCheck.tokenType]);
        _mint(_mintCheck.to, tokenId);
        tokenIdToUri[tokenId] = _mintCheck.uris[i];
        contentHashToTokenId[contentHash] = tokenId;
        emit MintCheckUsed(tokenId, mintCheckHash);
      }
    }

    function getModifyCheckHash(ModifyCheck calldata _modifyCheck) public pure returns (bytes32) {
      bytes memory input = abi.encodePacked("");
      for (uint i = 0; i < _modifyCheck.tokenIds.length; ++i) {
        input = abi.encodePacked(input, _modifyCheck.tokenIds[i]);
      }
      for (uint i = 0; i < _modifyCheck.uris.length; ++i) {
        input = abi.encodePacked(input, _modifyCheck.uris[i]);
      }
      return keccak256(input);
    }

    function verifyModifyCheck(
      ModifyCheck calldata _modifyCheck
    ) public view returns (bool) {
      bytes32 signedHash = getModifyCheckHash(_modifyCheck);
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_modifyCheck.signature);
      return isSigned(mintingAuthority, signedHash, v, r, s);
    }

    function modifyBaseURIByModifyCheck(ModifyCheck calldata _modifyCheck) external {
      require(_modifyCheck.tokenIds.length == _modifyCheck.uris.length, "tokenIds mismatch with uris");
      bytes32 modifyCheckHash = getModifyCheckHash(_modifyCheck);
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_modifyCheck.signature);
      require(isSigned(mintingAuthority, modifyCheckHash, v, r, s), "Modify check is not valid");

      for (uint i = 0; i < _modifyCheck.tokenIds.length; ++i) {
        bytes32 contentHash = keccak256(abi.encodePacked(_modifyCheck.uris[i]));
        require(contentHashToTokenId[contentHash] == 0, "Modify check has already been used");
        require(_exists(_modifyCheck.tokenIds[i]), "Tokenid does not exist");
        tokenIdToUri[_modifyCheck.tokenIds[i]] = _modifyCheck.uris[i];
        contentHashToTokenId[contentHash] = _modifyCheck.tokenIds[i];
        emit MintCheckUsed(_modifyCheck.tokenIds[i], modifyCheckHash);
      }
    }
}