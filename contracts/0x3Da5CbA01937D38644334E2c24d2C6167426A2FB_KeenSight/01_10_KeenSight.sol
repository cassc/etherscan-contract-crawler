// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KeenSight is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    mapping(uint256 => bool) public tokenClaimed;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public preMinted;
    mapping(address => uint256) public publicMinted;
    mapping(address => string) public verifiedOrder;

    string public uriPrefix = "ipfs://";
    string public uriSuffix = ".json";
    string public uriClaimedPrefix = "ipfs://claimed";
    string public uriClaimedSuffix = ".json";
    string public hiddenMetadataUri;
    string public uriContract;

    uint256 public price = 0.042 ether;
    uint256 public maxSupply = 1500;
    uint256 public preMintTxLimit = 1;
    uint256 public publicMintTxLimit = 1;
    uint256 public maxPreMintAmount = 1;
    uint256 public maxPublicMintAmount = 1;
    uint256 public internalMintAmount = 250;

    bool public preMintPaused = true;
    bool public paused = true;
    bool public revealed = false;

    constructor(address[] memory _whiteListAddresses, address[] memory _internalAccounts, string memory _contractURI, string memory _hiddenMetadataURI) ERC721A("KeenSight", "KNST") {
        setHiddenMetadataUri(_hiddenMetadataURI);
        initializeWhiteList(_whiteListAddresses);
        setContractURI(_contractURI);
        for (uint256 i = 0; i < _internalAccounts.length; i++) {
            _safeMint(_internalAccounts[i], internalMintAmount);
        }
    }

    modifier publicMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= publicMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(publicMinted[msg.sender] + _mintAmount <= maxPublicMintAmount, "You have already minted your limit");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!paused, "Minting is not currently allowed!");
        require(msg.value >= price * _mintAmount, "You did not send enough ETH");
        _;
    }

    modifier preMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= preMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(preMinted[msg.sender] + _mintAmount <= maxPreMintAmount, "This transaction exceeds your whitelist mint limit");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!preMintPaused, "Minting is not currently allowed!");
        require(msg.value >= price * _mintAmount, "You did not send enough ETH");
        _;
    }
    
    modifier airDropCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        _;
    }

    function preMint( uint256  _mintAmount) public payable preMintCompliance(_mintAmount) nonReentrant {
        require(whitelist[msg.sender], "You are not on the list");
        preMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable publicMintCompliance(_mintAmount) nonReentrant {
        publicMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function airDrop(uint256 _mintAmount, address _receiver) public airDropCompliance(_mintAmount) onlyOwner nonReentrant {
        _safeMint(_receiver, _mintAmount);
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
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
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        if (tokenClaimed[_tokenId] == false) {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
        }else{
            string memory currentBaseURI = _baseClaimedURI();
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriClaimedSuffix))
            : "";
        }
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

    function checkPreMintAvailableToMe() public view returns (uint256) {
        return (maxPreMintAmount - preMinted[msg.sender]);
    }

    function checkPublicMintAvailableToMe() public view returns (uint256) {
        return (maxPublicMintAmount - publicMinted[msg.sender]);
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
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

    function setUriClaimedPrefix(string memory _uriClaimedPrefix) public onlyOwner {
        uriClaimedPrefix = _uriClaimedPrefix;
    }

    function setUriClaimedSuffix(string memory _uriClaimedSuffix) public onlyOwner {
        uriClaimedSuffix = _uriClaimedSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _baseClaimedURI() internal view virtual returns (string memory) {
        return uriClaimedPrefix;
    }

    function contractURI() public view returns (string memory) {
        return uriContract;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        uriContract = _contractURI;
    }

    function setTokenClaimed(uint256 _tokenId) public onlyOwner {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        tokenClaimed[_tokenId] = true;
    }

    function setTokenUnclaimed(uint256 _tokenId) public onlyOwner {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        tokenClaimed[_tokenId] = false;
    }

    function verifyOrder(string calldata _orderId) public{
        verifiedOrder[msg.sender] = _orderId;
    }

    function createWhiteList(address[] calldata _users) public onlyOwner{
        for(uint256 i = 0; i < _users.length; i++){
            whitelist[_users[i]] = true;
        }
    }

    function initializeWhiteList(address[] memory _users) private{
        for(uint256 i = 0; i < _users.length; i++){
            whitelist[_users[i]] = true;
        }
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