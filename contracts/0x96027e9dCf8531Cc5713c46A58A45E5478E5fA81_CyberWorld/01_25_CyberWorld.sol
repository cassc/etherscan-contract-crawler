// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract CyberWorld is ERC721, ChainlinkClient, ConfirmedOwner {
  using Chainlink for Chainlink.Request;
  using Counters for Counters.Counter;

  Counters.Counter public currentTokenId;
  mapping (uint256 => string) private tokenURIs;

  constructor() ERC721("CyberWorld", "CYBWLD") ConfirmedOwner(msg.sender) {
    setChainlinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    setChainlinkOracle(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434);
  }

  function requestMetadata(string memory _polygonString, string memory _imageCID) public payable returns (bytes32 requestId) {
    Chainlink.Request memory metadataRequest = buildChainlinkRequest('729302da4de94f488205e11ddab325a0', address(this), this.fulfillMint.selector);
    metadataRequest.add('get', string.concat("https://cyberworld.earth/src/php/addLandMetadata.php?&owner-address=", Strings.toHexString(uint160(msg.sender), 20), "&polygon-string=", _polygonString, "&polygon-price=", Strings.toString(msg.value), "&image-cid=", _imageCID));
    metadataRequest.add('path', 'response');

    return sendChainlinkRequest(metadataRequest, 3150000000000000000);
  }

  function fulfillMint(bytes32 _requestId, bytes memory _responseData) public recordChainlinkFulfillment(_requestId) {
    bool responseStatus;
    address responseAddress;
    string memory reponseString;

    (responseStatus, responseAddress, reponseString) = abi.decode(_responseData, (bool, address, string));

    if (responseStatus == true) {
      mintLand(responseAddress, reponseString);
    }
  }

  function mintLand(address _recipient, string memory _uri) private {
    uint256 tokenId = currentTokenId.current();

    _safeMint(_recipient, tokenId);
    tokenURIs[tokenId] = _uri;
    
    currentTokenId.increment(); 
  }

  function _afterTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
    updateLandOwner(_tokenId);
  }

  function updateLandOwner(uint256 _tokenId) private returns (bytes32 requestId) {
    Chainlink.Request memory transferOwnershipRequest = buildChainlinkRequest('4c00403f69984f2b87a2e03ddb4f595b', address(this), this.fulfillOwnerUpdate.selector);
    transferOwnershipRequest.add('get', string.concat("https://cyberworld.earth/src/php/updateLandOwner.php?token-id=", Strings.toString(_tokenId)));
    transferOwnershipRequest.add('path', 'response');

    return sendChainlinkRequest(transferOwnershipRequest, 500000000000000000);
  }

  function fulfillOwnerUpdate(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {}

  function purchaseAsOwner(address _recipient, string memory _imageCID) public onlyOwner {
    mintLand(_recipient, _imageCID);
  }

  function withdrawAmount() public payable onlyOwner {
    require(msg.value <= address(this).balance);
    payable(owner()).transfer(msg.value);
  }

  function withdrawAll() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function withdrawAllLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
  }

  function getLinkBalance() public view returns (uint256) {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    return link.balanceOf(address(this));
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721: invalid token ID");

    return tokenURIs[_tokenId];
  }

  function setTokenURI(uint256 _tokenId, string memory _uri) public onlyOwner {
    tokenURIs[_tokenId] = _uri;
  }
}