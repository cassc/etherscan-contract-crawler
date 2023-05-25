// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ContractDataStorage.sol";
import "./SvgParser.sol";

contract CyberBrokersMetadata is Ownable {
  using Strings for uint256;

  bool private _useOnChainMetadata = false;

  string private _externalUri = "https://cyberbrokers.io/";
  string private _imageCacheUri = "";

  // Contracts
  ContractDataStorage public contractDataStorage;
  SvgParser public svgParser;

  constructor(
    address _contractDataStorageAddress,
    address _svgParserAddress
  ) {
    // Set the addresses
    setContractDataStorageAddress(_contractDataStorageAddress);
    setSvgParserAddress(_svgParserAddress);
  }

  function setContractDataStorageAddress(address _contractDataStorageAddress) public onlyOwner {
    contractDataStorage = ContractDataStorage(_contractDataStorageAddress);
  }

  function setSvgParserAddress(address _svgParserAddress) public onlyOwner {
    svgParser = SvgParser(_svgParserAddress);
  }


  /**
   * On-Chain Metadata Construction
   **/

  function hasOnchainMetadata(uint256 tokenId) public view returns (bool) {
    return _useOnChainMetadata;
  }

  function setOnChainMetadata(bool _state) public onlyOwner {
    _useOnChainMetadata = _state;
  }

  function setExternalUri(string calldata _uri) public onlyOwner {
    _externalUri = _uri;
  }

  function setImageCacheUri(string calldata _uri) public onlyOwner {
    _imageCacheUri = _uri;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(
        abi.encodePacked(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                getName(tokenId),
                bytes('","description":"'),
                getDescription(tokenId),
                bytes('","external_url":"'),
                getExternalUrl(tokenId),
                bytes('","image":"'),
                getImageCache(tokenId)
            ),
            abi.encodePacked(
                bytes('","attributes":['),
                getAttributes(tokenId),
                bytes(']}')
            )
        )
    );
  }

  function getName(uint256 tokenId) public view returns (string memory) {
    return "Test Name";
  }

  function getDescription(uint256 tokenId) public view returns (string memory) {
    return "Test Description";
  }

  function getExternalUrl(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_externalUri, tokenId.toString()));
  }

  function getImageCache(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_imageCacheUri, tokenId.toString()));
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    return string(
      abi.encodePacked(
        bytes('{"trait_type": "Mind", "value": 30}')
      )
    );
  }


  /**
   * On-Chain Token SVG Rendering
   **/

  function renderData(string memory _key, uint256 _startIndex)
    public
    view
    returns (
      string memory _output,
      uint256 _endIndex
    )
  {
    require(contractDataStorage.hasKey(_key));
    return svgParser.parse(contractDataStorage.getData(_key), _startIndex);
  }

  function render(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    require(_tokenId >= 0 && _tokenId <= 10000, "Can only render valid token ID");
    return string("");
  }


  /**
   * Off-Chain Token SVG Rendering
   **/

  function getTokenData(uint256 _tokenId)
    public
    pure
    returns (string memory)
  {
    require(_tokenId >= 0 && _tokenId <= 10000, "Can only render valid token ID");
    return string("");
  }

  function getOffchainSvgParser()
    public
    view
    returns (
      string memory _output
    )
  {
    string memory _key = 'svg-parser.js';
    require(contractDataStorage.hasKey(_key), "Off-chain SVG Parser not uploaded");
    return string(contractDataStorage.getData(_key));
  }

}