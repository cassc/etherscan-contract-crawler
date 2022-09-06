//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract PlanetKryptoOrigins is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdTracker;
    mapping (uint256 => string) private _tokenURIs;

    address private constant KoalaMintDevAddress = 0xD17237307b93b104c50d6F83CF1e2dB99f7a348a;
    address private constant CreatorAddress = 0xd75DbeA0657dc54a8292ab87615191a7fbdb1d69;
    address private constant SignerAddress = 0x4AeA7b69ABb482e34BDd1D8C7A6B8dcA44F65775;

    string private baseURIextended;
    uint256 private constant min_price = 0.03 ether;
    uint256 private maxSupply = 501;

    event KoalaMintMinted(uint256 indexed tokenId, address owner, address to, string tokenURI);
    event KoalaMintTransfered(address to, uint value);

    constructor(string memory _baseURIextended) ERC721("Planet Krypto Origins", "PKO"){
        baseURIextended = _baseURIextended;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function revealCollection(string memory _baseURIextended) public onlyOwner {
        require(keccak256(bytes(baseURIextended)) != keccak256(bytes(_baseURIextended)), "Collection already revealed");
        setBaseURI(_baseURIextended);
    }

    function setBaseURI(string memory _baseURIextended) private onlyOwner {
        baseURIextended = _baseURIextended;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        return string(abi.encodePacked(base, _tokenURI));
    }

    function signatureSignerMint(address _to, string memory _tokenURI, uint256 _timestamp, uint8 v, bytes32 r, bytes32 s) public view virtual returns (address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_to, _tokenURI, _timestamp)))), v, r, s);
    }

    function mint(address _to, string[] memory _tokensURI, uint256 _timestamp, uint8 v, bytes32 r, bytes32 s) public payable {
        require(msg.value >= min_price.mul(_tokensURI.length), "Value below price");
        require(maxSupply >= _tokenIdTracker.current() + _tokensURI.length, "SoldOut");
        require(_tokensURI.length > 0, "Minimum count");

        address signerMint = signatureSignerMint(_to, _tokensURI[0], _timestamp, v, r, s);
        require(signerMint == SignerAddress, "Not authorized to mint");

        require(_timestamp >= block.timestamp - 300, "Out of time");

        for (uint8 i = 0; i < _tokensURI.length; i++){
            _mintAnElement(_to, _tokensURI[i]);
        }
        
        uint256 _feeCreator = msg.value.mul(5).div(100);

        transfer(KoalaMintDevAddress, _feeCreator);
        transfer(CreatorAddress, msg.value - _feeCreator);
    }

    function _mintAnElement(address _to, string memory _tokenURI) private {
        uint256 _tokenId = _tokenIdTracker.current();
        
        _tokenIdTracker.increment();
        _tokenId = _tokenId + 1;
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        emit KoalaMintMinted(_tokenId, CreatorAddress, _to, _tokenURI);
    }

    function transfer(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
        emit KoalaMintTransfered(to, value);
    }
}