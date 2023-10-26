// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // only needs allowance and transferfrom

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
 █████╗ ██╗ ██████╗ ██████╗  ██████╗ ██████╗ 
██╔══██╗██║██╔════╝██╔═══██╗██╔════╝██╔═══██╗
███████║██║██║     ██║   ██║██║     ██║   ██║
██╔══██║██║██║     ██║   ██║██║     ██║   ██║
██║  ██║██║╚██████╗╚██████╔╝╚██████╗╚██████╔╝
╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝ 

*** BURN COCO TO MINT NFTs max 5 per transaction

 */

contract AiCoco is DefaultOperatorFilterer, ERC721Enumerable, Pausable, Ownable, RoyaltiesV2Impl {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IERC20 coco;
    string contractUri;
    string public baseUri;
    uint256 public pricePerNft;
    uint256 public totalBurned;
    address public cocoContract;
    uint96 percentageBasisPoints;
    bool public publicMintOpen = false;
    uint16 public constant MAX_SUPPLY = 420; // 420
    address payable public controllerAddress;
    address burn = 0x000000000000000000000000000000000000dEaD;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public cidLength = 1; // cid issued from tokenId1
    mapping(uint256 => string) private cids; // tokenId, cids
    mapping(uint256 => bool) public pausedList; // tokenId, paused

    constructor(
      string memory _baseUri, 
      string memory _contractUri, 
      uint96 _percentageBasisPoints, 
      address payable _controllerAddress,
      uint256 _newPrice,
      address _cocoContractAddress
    ) ERC721("AiCoco", "AICOCO") {
      baseUri = _baseUri;
      contractUri = _contractUri;
      controllerAddress = _controllerAddress;
      percentageBasisPoints = _percentageBasisPoints;
      pricePerNft = _newPrice;
      _tokenIdCounter.increment(); // start at 1
      coco = IERC20(_cocoContractAddress);
      cocoContract = _cocoContractAddress;
    }

    modifier onlyController() {
        require(controllerAddress == msg.sender, "onlyController");
        _;
    }

    // Cids - (mapping) cids: pointers to the data on ipfs per token. 

    // Here we add new cid to the mapping at the end of the array
    // This should be the "standard approach" to loading in new cids
    function setCids(string[] memory _cids) public onlyController() {
        for (uint i = 0; i < _cids.length; i++) {
            cids[cidLength] = _cids[i];
            cidLength = cidLength + 1;
        }
    }

    // Upgradeable NFTs mean changing the cids to point to new data
    // Although possible, Traits will NOT be updated using this method
    // The cid is the provenance. Only the controller may change the cid. (for upgrade purposes)
    // Update a single CID, used for replacing a cid that has existential issues
    function setACid(string memory _cid, uint256 _tokenId) public onlyController() {
        require(cidIsSet(_tokenId), "cidUnset");
        cids[_tokenId] = _cid;
    }

    // Allow upgrade of graphics and metadata for multiple CIDs of specific tokenIds
    // Takes a 1:1 dual array, arrays must be equal length
    function updateCids(string[] memory _cids, uint256[] memory _tokenIds) public onlyController() {
        require(_tokenIds.length == _cids.length, "equalArrays");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(cidIsSet(_tokenIds[i]), "cdUnset");
            cids[_tokenIds[i]] = _cids[i];
        }
    }

    // Check if a particular tokenId has had its cid set
    function cidIsSet(uint256 tokenId) private view returns(bool) {
      bytes memory whatBytes = bytes (cids[tokenId]);
      if ( whatBytes.length > 0 ) {
        return true;
      }
      return false;
    } 

    // Base / Contract URI public accessor for token and contract data
    function updateBaseUri(string memory _baseUri) external onlyController {
        baseUri = _baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, cids[tokenId])) : "";
    }

    function updateContractUri(string memory _contractUri) external onlyController {
        contractUri = _contractUri;
    }

    function contractURI() public view returns (string memory) { // storefront for OpenSea
        return contractUri;
    }

    // Totals

    // Amount of tokens available and cid is set
    // you can assume that there are cidLength - _tokenIdCounter.current() available to mint

    // Tokens and minting 
    // Returns the next token Id to be minted. 
    // You can assume that there have been this minus one tokens minted
    function tokenCounter() public view returns(uint256) {
      return _tokenIdCounter.current();
    }

    // Knobs
    function setMinting(bool _minting) external onlyController {
      publicMintOpen = _minting;
    }

    // Depending on the current price of coco the intention is to 
    // keep the price somewhere between 5 and 10 dollars
    function setPrice(uint256 _newPrice) public onlyController() {
      pricePerNft = _newPrice;
    }

    // Minting
    function publicMint() external payable {
      uint256 allowance = coco.allowance(msg.sender, address(this));
      require(allowance >= pricePerNft, "Must approve the contract to spend tokens");
      require(publicMintOpen, "Public Mint Closed");
      coco.transferFrom(msg.sender, burn, pricePerNft);
      totalBurned = totalBurned + pricePerNft;
      internalMint(msg.sender);
    }

    function publicMintMulti(uint128 _numOfTokens) external payable {
        require(_numOfTokens <= 5, "Mint 5 tokens per call MAX");
        uint256 total = _numOfTokens * pricePerNft;
        uint256 allowance = coco.allowance(msg.sender, address(this));
        require(allowance >= total, "Must approve the contract to spend tokens");
        require(publicMintOpen, "Public Mint Closed");
        coco.transferFrom(msg.sender, burn, total);
        totalBurned = totalBurned + total;
        for (uint i = 0; i < _numOfTokens; i++) { 
          internalMint(msg.sender);
        }
    }

    function internalMint(address _account) internal {
        require(tokenCounter() < MAX_SUPPLY + 1, "We Sold Out!");
        uint256 tokenId = _tokenIdCounter.current();
        require(cidIsSet(tokenId), "Out of available tokens, check later..."); // Cid must be set before minting, this ensures the media is ready
        _tokenIdCounter.increment();
        _safeMint(_account, tokenId);
        _setRoyalties(tokenId, controllerAddress, percentageBasisPoints); // once a token is minted, set its royalties to default
    }

    // Allows you to poll for all NFTs owned by a specific account
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

    // Allow controller to remove erroneously sent ERC20 tokens
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

    // Open Sea: Enforce Royalties (by Blacklisting other competing platforms)
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
    // pause / unpause the entire contract
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