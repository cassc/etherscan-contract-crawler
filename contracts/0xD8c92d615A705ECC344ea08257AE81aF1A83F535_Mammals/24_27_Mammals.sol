// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Mammals is DefaultOperatorFilterer, ERC721Enumerable, Pausable, Ownable, RoyaltiesV2Impl {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_ELEMENTS = 8888;
    uint256 public constant PRICE = 0.01 ether;

    bool public publicMintOpen = true;
    string baseUri;
    string contractUri;
    uint96 percentageBasisPoints;
    address payable public controllerAddress;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    
    mapping(uint256 => string) public provenance;
    mapping(uint256 => bool) public pausedList;

    constructor(
      string memory _baseUri, 
      string memory _contractUri, 
      uint96 _percentageBasisPoints, 
      address payable _controllerAddress
    ) ERC721("Mammals", "MAMM") {
      baseUri = _baseUri;
      contractUri = _contractUri;
      percentageBasisPoints = _percentageBasisPoints;
      controllerAddress = _controllerAddress;
      _tokenIdCounter.increment(); // start at 1
    }

    modifier onlyController() {
        require(controllerAddress == msg.sender, "Caller must be the Controller");
        _;
    }

    // Base / Contract URI

    function updateBaseUri(string memory _baseUri) external onlyController {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function updateContractUri(string memory _contractUri) external onlyController {
        contractUri = _contractUri;
    }

    function contractURI() public view returns (string memory) { // storefront for OpenSea
        return contractUri;
    }

    // Provenance

    function setProvenance(uint256[] memory _tokenIds, string[] memory _provenances) public onlyController() {
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(provenanceIsSet(_tokenIds[i]) == false, "Cannot modify provenance once set.");
            provenance[_tokenIds[i]] = _provenances[i];
        }
    }

    function getProvenance(uint256 tokenId) public view returns (string  memory) {
      return provenance[tokenId];
    }

    function provenanceIsSet(uint256 tokenId) private view returns(bool) {
      bytes memory whatBytes = bytes (provenance[tokenId]);
      if ( whatBytes.length > 0 ) {
        return true;
      }
      return false;
    } 

    // Tokens and minting

    function price() public pure returns (uint256) {
        return PRICE;
    }

    function tokenCounter() public view returns(uint256) {
      return _tokenIdCounter.current();
    }

    function editMintWindow( bool _publicMintOpen) external onlyController {
        publicMintOpen = _publicMintOpen;
    }

    function publicMint() public payable {
        require(publicMintOpen, "Public Mint Closed");
        require(msg.value == PRICE, "Not Enough Funds");
        internalMint();
    }

    function internalMint() internal {
        require(tokenCounter() < MAX_ELEMENTS, "We Sold Out!"); // total of 888 nfts can be minted
        uint256 tokenId = _tokenIdCounter.current();
        require(provenanceIsSet(tokenId), "Artist must set provenance before minting more"); // Provenance must be set before minting, this ensures the media is ready
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setRoyalties(tokenId, controllerAddress, percentageBasisPoints); // once a token is minted, set its royalties to default
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Transfers

    function updateController(address payable _controllerAddress) external onlyOwner {
      controllerAddress = _controllerAddress;
    }

    function withdraw() external onlyController {
        uint256 balalnce = address(this).balance;
        payable(controllerAddress).transfer(balalnce);
    }

    function transferAnyERC20Token(address _erc20Contract, uint _amount) public onlyController returns (bool success) {
        return IERC20(_erc20Contract).transfer(controllerAddress, _amount);
    }

    fallback() external { // reject any naked ether deposits
        revert();
    }

    // Royalties 
    // Set royalties automatically upon minting
    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        internalSetRoyalties(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }
    
    // Controller may adjust royalties on a per token basis
    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyController {
        internalSetRoyalties(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }

    function internalSetRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    // Enforce Royalties by Blacklisting other competing platforms (Open seas protocol here...)
    function setApprovalForAll(address operator, bool approved) public override (IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override (IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override (IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Controller may pause a particular NFT, for instance, when in state of noncompliance
    function pauseItem(uint256 _tokenId) external onlyController {
        pausedList[_tokenId] = true;
    }

    function resumeItem(uint256 _tokenId) external onlyController {
        pausedList[_tokenId] = false;
    }

    function itemIsPaused(uint256 _tokenId) public view returns (bool) {
      if (pausedList[_tokenId] == true) {
        return true;
      }
      return false;
    }

    // utils 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) 
        internal whenNotPaused override(ERC721Enumerable) {
        require(!itemIsPaused(tokenId), "This NFT in particular is paused, please contact us.");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) { // rarible
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}