// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Osiris is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    mapping(address => uint256) public preMinted;
    mapping(address => uint256) public publicMinted;

    string public uriPrefix;
    string public uriSuffix = "";
    string public uriContract;

    uint256 public maxSupply = 10000;
    uint256 public preMintTxLimit = 1;
    uint256 public publicMintTxLimit = 1;
    uint256 public maxPreMintAmount = 1;
    uint256 public maxPublicMintAmount = 1;
    uint256 public maxInternalMintAmount = 13;

    bool public preMintPaused = false;
    bool public paused = false;

    constructor(address[] memory _internalAccounts, string memory _prefix, string memory _contractURI) ERC721A("Osiris Pass", "OSRS") {
        setUriPrefix(_prefix);
        setContractURI(_contractURI);
        for (uint256 i = 0; i < _internalAccounts.length; i++) {
            _safeMint(_internalAccounts[i], maxInternalMintAmount);
        }
    }

    modifier publicMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= publicMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(publicMinted[msg.sender] + _mintAmount <= maxPublicMintAmount, "You have already minted your limit");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!paused, "Minting is not currently allowed!");
        _;
    }

    modifier preMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= preMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(preMinted[msg.sender] + _mintAmount <= maxPreMintAmount, "You are not on the whitelist or have already used your whitelist mint");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!preMintPaused, "Minting is not currently allowed!");
        _;
    }

    modifier airDropCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        _;
    }

    function preMint(uint256  _mintAmount) public preMintCompliance(_mintAmount) nonReentrant {
        preMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public publicMintCompliance(_mintAmount) nonReentrant {
        publicMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function airDrop(uint256 _mintAmount, address _receiver) public airDropCompliance(_mintAmount) onlyOwner nonReentrant {
        _safeMint(_receiver, _mintAmount);
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, uriSuffix))
        : "";
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply <= 5000, "CAN NOT INCREASE SUPPLY");
        maxSupply = _maxSupply;
    }

    function setPreMintTxLimit(uint256 _preMintTxLimit) public onlyOwner {
        preMintTxLimit = _preMintTxLimit;
    }

    function setPublicMintTxLimit(uint256 _publicMintTxLimit) public onlyOwner {
        publicMintTxLimit = _publicMintTxLimit;
    }

    function setMaxPreMintAmount(uint256 _maxPreMintAmount) public onlyOwner {
        maxPreMintAmount = _maxPreMintAmount;
    }

    function setMaxPublicMintAmount(uint256 _maxPublicMintAmount) public onlyOwner {
        maxPublicMintAmount = _maxPublicMintAmount;
    }

    function setPreMintPaused(bool _state) public onlyOwner {
        preMintPaused = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function contractURI() public view returns (string memory) {
        return uriContract;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        uriContract = _contractURI;
    }

    function withdraw() public onlyOwner nonReentrant{
        (bool owner, ) = payable(owner()).call{value: address(this).balance}("");
        require(owner);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}