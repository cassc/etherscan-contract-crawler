// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract WildWombats is ERC721A, DefaultOperatorFilterer, Ownable

{

    // Storage

    string public uriPrefix = "ipfs://bafybeigtx4jvmwdcurnvdkgawfqltrn5juxfzid34yls2oqvvn74s4bpku/";
    string public uriSuffix = ".json";

    uint256 public cost = 0.003 ether;
    uint256 public maxSupply = 7777;
    uint256 public maxPerWallet = 21;
    uint256 public maxFreePerWallet = 1;

    bool public paused = true;

    constructor() ERC721A("Wild Wombats", "WW") {
        _safeMint(msg.sender, 1);
    }

    // Modifiers

    modifier mintCompliance(uint256 _mintAmount) {
        require(msg.sender == tx.origin, "No contracts allowed!");
        require(_mintAmount > 0, "You can't mint 0!");
        require(
            _numberMinted(_msgSender()) + _mintAmount <= maxPerWallet,
            "You can't mint more than 21 per wallet!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply
            
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 totalCost = cost * _mintAmount;

        if (_numberMinted(_msgSender()) < maxFreePerWallet) {
            totalCost = totalCost - cost;
        }

        require(msg.value >= totalCost, "Hey! You've got to pay for that!");
        _;
    }

    // Main mint function

    function mint(
        uint256 _mintAmount
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, "Come back soon!");

        _safeMint(_msgSender(), _mintAmount);
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
                : "";
    }


    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPerWallet(uint256 max) public onlyOwner {
        maxPerWallet = max;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

  function withdraw() public onlyOwner{
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

    // Opensea OperatorFilterer Overrides

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Internal Overrides

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}