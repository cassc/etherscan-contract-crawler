// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Fauna is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public preMinted;
    mapping(address => uint256) public publicMinted;

    string public uriPrefix = "ipfs://";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    string public uriContract = "ipfs://QmfJg1gMxLnh2TJeeoiaLzmAR6GPaSD5kBZLMgrnQRnH8p";

    uint256 public price = 0.069 ether;
    uint256 public maxSupply = 444;
    uint256 public preMintTxLimit = 2;
    uint256 public publicMintTxLimit = 5;
    uint256 public maxPreMintAmount = 2;
    uint256 public maxPublicMintAmount = 5;

    bool public preMintPaused = true;
    bool public paused = true;
    bool public revealed = false;

    address[] public internalAccounts = [
        0x831Fc358124D5899B731472Ebe2a4BF1cD6C3e1e,
        0xAE0C0E1E098a1c5F711A78AfeC0286CCd79169bc,
        0xd01161a8C437ee941E80415d74E1b3311356F44b
    ];

    constructor() ERC721("Fauna", "FNA") {
        setHiddenMetadataUri("ipfs://QmQgmiKstiWbff47HUAzdcnoAMp2zuR9Dh4oL97nrdNEiF");
        for (uint256 i = 0; i < internalAccounts.length; i++) {
            address _receiver = internalAccounts[i];
            for (uint256 j= 0; j < 8; j++) {
                supply.increment();
                _safeMint(_receiver, supply.current());
            }
        }
    }

    modifier publicMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = supply.current() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= publicMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(publicMinted[msg.sender] + _mintAmount <= maxPublicMintAmount, "You have already minted your limit");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!paused, "Minting is not currently allowed!");
        require(msg.value >= price * _mintAmount, "You did not send enough ETH");
        _;
    }

    modifier preMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = supply.current() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= preMintTxLimit, "You have exceeded the limit of mints per transaction");
        require(preMinted[msg.sender] + _mintAmount <= maxPreMintAmount, "This transaction exceeds your whitelist mint limit");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!preMintPaused, "Minting is not currently allowed!");
        require(msg.value >= price * _mintAmount, "You did not send enough ETH");
        _;
    }
    
    modifier airDropCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = supply.current() + _mintAmount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        _;
    }

    function preMint( uint256  _mintAmount) public payable preMintCompliance(_mintAmount) nonReentrant {
        require(whitelist[msg.sender], "You are not on the list");
        preMinted[msg.sender] += _mintAmount;
        _mintLoop(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable publicMintCompliance(_mintAmount) nonReentrant {
        publicMinted[msg.sender] += _mintAmount;
        _mintLoop(msg.sender, _mintAmount);
    }

    function airDrop(uint256 _mintAmount, address _receiver) public airDropCompliance(_mintAmount) onlyOwner nonReentrant {
        _mintLoop(_receiver, _mintAmount);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
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
        uint256 currentTokenId = 1;
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

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function checkPreMintAvailableToMe() public view returns (uint256) {
        if(!whitelist[msg.sender]){
            return 0;
        }else{
            return (maxPreMintAmount - preMinted[msg.sender]);
        }
    }
    
    function checkPublicMintAvailableToMe() public view returns (uint256) {
        return (maxPublicMintAmount - publicMinted[msg.sender]);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function contractURI() public view returns (string memory) {
        return uriContract;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        uriContract = _contractURI;
    }

    function createWhiteList(address[] calldata _users) public onlyOwner{
        for(uint256 i = 0; i < _users.length; i++){
            whitelist[_users[i]] = true;
        }
    }

    function withdraw() public onlyOwner nonReentrant{
        uint256 withdrawAmount = (address(this).balance * 333 / 1000);
        (bool dev, ) = payable(0x831Fc358124D5899B731472Ebe2a4BF1cD6C3e1e).call{value: withdrawAmount}("");
        require(dev);
        (bool artist, ) = payable(0xAE0C0E1E098a1c5F711A78AfeC0286CCd79169bc).call{value: withdrawAmount}("");
        require(artist);
        (bool marketing, ) = payable(0xd01161a8C437ee941E80415d74E1b3311356F44b).call{value: address(this).balance}("");
        require(marketing);
    }
}