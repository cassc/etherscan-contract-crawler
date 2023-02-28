// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract AmberIslandKey is ERC721, Ownable, ERC721Royalty {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 _mintPrice = 0.15 ether;
    uint256 _teamMints = 0;
    uint256 _maxTeamMints = 5;
    uint256 _maxPerWallet = 5;
    uint256 _totalSupply = 999;
    uint256 _whitelistDuration = 86400;
    uint256 _mintStart =  1670857200;
    string _baseUri = "";
    mapping(address => bool) whitelistMinted;
    enum MintPhase { Pending, Whitelist, Open, Finished }
    address whitelistSigner = 0x4A23581959129BC2c667C916F1f9Edf22c295BF5;
    address feeRecipient = 0x8b375C1488cf58524Bacc962a2BE732189906739;

    event PermanentURI(string _value, uint256 indexed _id); 

    constructor() ERC721("AmberIslandKey", "AIK") {
        _setDefaultRoyalty(msg.sender, 500);
    }

     modifier onlyWhitelisted(uint _amount, uint8 _v, bytes32 _r, bytes32 _s) 
    {
        require(isWhitelisted(msg.sender, _amount, _v, _r, _s), "AIK: You are not whitelisted");
        _;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        _baseUri = uri;
    }

    function getMintPrice() public view returns (uint256 price) {
        return _mintPrice;
    }

    function getCurrentTokenId() public view returns (uint256 current) {
        return _tokenIdCounter.current();
    }

    function getTotalSupply() public view returns (uint256 totalSupply) {
        return _totalSupply;
    }

    function getMintPhase() public view returns (MintPhase phase) {
        if(block.timestamp < _mintStart) return MintPhase.Pending;
        else if(block.timestamp > _mintStart + _whitelistDuration) return MintPhase.Open;
        else if(block.timestamp > _mintStart) return MintPhase.Whitelist;
        else if(_tokenIdCounter.current() >= _totalSupply) return MintPhase.Finished;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function publicMint(address to, uint256 amount) public payable {
        require(getMintPhase() == MintPhase.Open, "AIK: Not in Public Mint Phase");
        require(msg.value == _mintPrice * amount, "AIK: Invalid amount sent");
        require(balanceOf(address(to)) + amount <= _maxPerWallet, "AIK: Mint amount exceeds max allowed tokens per wallet");

        for(uint8 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < _totalSupply, "AIK: All tokens minted!");
            _safeMint(to, tokenId);
            _tokenIdCounter.increment();
        }

        (bool sent, bytes memory data) = feeRecipient.call{value: msg.value}("");
        require(sent, "AIK: Failed to send Ether");
    }

    function whitelistMint(uint8 _v, bytes32 _r, bytes32 _s) public payable onlyWhitelisted(1, _v, _r, _s) {
        require(!whitelistMinted[msg.sender], "AIK: Whitelist Mint already used");
        require(getMintPhase() == MintPhase.Whitelist, "AIK: Not in Whitelist Phase");
        require(msg.value == _mintPrice, "AIK: Invalid amount sent");

        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < _totalSupply, "AIK: All tokens minted!");

        _safeMint(msg.sender, tokenId);
        whitelistMinted[msg.sender] = true;
        _tokenIdCounter.increment();

        (bool sent, bytes memory data) = feeRecipient.call{value: msg.value}("");
        require(sent, "AIK: Failed to send Ether");
    }

    function teamMint(address to) public onlyOwner {
        require(_teamMints < _maxTeamMints, "AIK: Team Mints exhausted");

        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        _teamMints = _teamMints + 1;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory uri)
    {
        _requireMinted(tokenId);

        string memory tokenString = tokenId.toString();
        return string(abi.encodePacked(_baseURI(), "/", tokenString, ".json"));
    }

    function withdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function isWhitelisted(
        address _address,
        uint _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
    view public returns (bool)
    {
        bytes32 message = keccak256(abi.encodePacked(this, _address, _amount));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        return whitelistSigner == ecrecover(prefixedHash, _v, _r, _s);
    }

    function setMintStart(uint256 timestamp) public onlyOwner {
        _mintStart = timestamp;
    }

    function setWhitelistSigner(address _signer) public onlyOwner {
        whitelistSigner = _signer;
    }

    function setFeeRecipient(address _recipient) public onlyOwner {
        feeRecipient = _recipient;
        _setDefaultRoyalty(_recipient, 500);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {}
}