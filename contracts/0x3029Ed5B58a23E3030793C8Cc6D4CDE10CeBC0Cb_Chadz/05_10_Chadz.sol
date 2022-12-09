// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Chadz is DefaultOperatorFilterer, ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    mapping(address => uint256) public publicMinted;

    string public uriPrefix = "ipfs://";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    string public uriContract = "ipfs://QmaLarczYvJ48qHUjTqMqMZ8C7UZMA3JZwNxEphMvgx6Wf";

    uint256 public price = 0.003 ether;
    uint256 public maxSupply = 4269;
    uint256 public publicMintTxLimit = 10;
    uint256 public maxPublicMintAmount = 20;
    uint256 public freeMintTxLimit = 10;
    uint256 public maxFreeMintAmount = 20;
    uint256 public internalMintAmount = 20;

    bool public paused = true;
    bool public revealed = false;

    address[] public internalAccounts = [
    0x831Fc358124D5899B731472Ebe2a4BF1cD6C3e1e,
    0xAE0C0E1E098a1c5F711A78AfeC0286CCd79169bc,
    0xd01161a8C437ee941E80415d74E1b3311356F44b,
    0x1e2c490B5F94b2e7a79C7b6a3C6995dfc97009B7
    ];

    constructor() ERC721A("Chadz", "CHDZ") {
        setHiddenMetadataUri("ipfs://QmPwphM4xyH9dkxnMMhEhvoxvpmBgCiJd249bBQUpFMroT");
        for (uint256 i = 0; i < internalAccounts.length; i++) {
            _safeMint(internalAccounts[i], internalMintAmount);
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
    
    modifier airDropCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        _;
    }

    modifier freeMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = totalSupply() + _mintAmount;
        require(requestedAmount <= 1000, "FREE MINT HAS ENDED");
        require(_mintAmount > 0 && _mintAmount <= freeMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(publicMinted[msg.sender] + _mintAmount <= maxFreeMintAmount, "You have already minted your limit");
        require(!paused, "Minting is not currently allowed!");
        _;
    }

    function mint(uint256 _mintAmount) public payable publicMintCompliance(_mintAmount) nonReentrant {
        publicMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function airDrop(uint256 _mintAmount, address _receiver) public airDropCompliance(_mintAmount) onlyOwner nonReentrant {
        _safeMint(_receiver, _mintAmount);
    }

    function freeMint(uint256 _mintAmount, address _receiver) public freeMintCompliance(_mintAmount) nonReentrant {
        publicMinted[msg.sender] += _mintAmount;
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
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
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

    function checkPublicMintAvailableToMe() public view returns (uint256) {
        return (maxPublicMintAmount - publicMinted[msg.sender]);
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setPublicMintTxLimit(uint256 _publicMintTxLimit) public onlyOwner {
        publicMintTxLimit = _publicMintTxLimit;
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
        uint256 withdrawAmount = (address(this).balance * 333 / 1000);
        (bool dude, ) = payable(0x831Fc358124D5899B731472Ebe2a4BF1cD6C3e1e).call{value: withdrawAmount}("");
        require(dude);
        (bool man, ) = payable(0xAE0C0E1E098a1c5F711A78AfeC0286CCd79169bc).call{value: withdrawAmount}("");
        require(man);
        (bool guy, ) = payable(0x61D4Df42ba5298f48C0c67c6c283eD72A480Cebc).call{value: address(this).balance}("");
        require(guy);
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