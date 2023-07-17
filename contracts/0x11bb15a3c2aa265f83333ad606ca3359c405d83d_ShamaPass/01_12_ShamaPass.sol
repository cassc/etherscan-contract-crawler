// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {mapping(address => OwnableDelegateProxy) public proxies;}

interface ShamanzsV2 {
    function PASSES_REDEEMED(address) external returns(uint256);
}

contract ShamaPass is ERC721, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bool public PAUSED = true;
    bool public PUBLIC = false;
    string public BASEURI;
    string public BASE_EXTENSION = ".json";
    uint256 public MAX_SUPPLY = 2038;
    uint256 public MAX_MINT_AMOUNT = 1;
    uint256 public PRICE = 1 ether;

    ///@notice Open Sea proxy address
    address public PROXY_REGISTRY_ADDRESS;
    address public SHAMAPASS_ADDRESS;

    mapping(address => bool) public AIRDROPPED;

        ///@notice events
    event ShamaPassSent(address _to, uint256 _passes);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyAddress
    ) payable ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        PROXY_REGISTRY_ADDRESS = _proxyAddress;
    }

    function buyShamaPass(uint256 _mintAmount) external payable {
        require(!PAUSED, "paused");
        require(PUBLIC, "Passes are not available for sell");
        require(_mintAmount > 0, "0 mint amount");
        require(_mintAmount <= MAX_MINT_AMOUNT, "Max mint amount exceeded");
        require(msg.value >= PRICE * _mintAmount, "Price not meet");
        require(totalSupply() + _mintAmount < MAX_SUPPLY, "Max supply reached");
        mint(msg.sender, _mintAmount);
    }

    ///@notice Mint for whitelisted Shamanzs
    function claimShamaPass() external payable {
        require(!PAUSED, "Contract paused");
        require(!AIRDROPPED[msg.sender], "Already airdropped ShamaPass");
        uint256 shamapasses = ShamanzsV2(SHAMAPASS_ADDRESS).PASSES_REDEEMED(msg.sender);
        require(shamapasses > 0, "No Shamapasses to redeem");
        require(totalSupply() + shamapasses <= MAX_SUPPLY, "Max supply reached");
        AIRDROPPED[msg.sender] = true;
        mint(msg.sender, shamapasses);
    }

    /**
    @dev utility functions
    */

    ///@notice Get baseUri
    function _baseURI() internal view virtual override returns (string memory) {
        return BASEURI;
    }

    ///@notice mint
    ///@dev all mints end calling this method
    function mint(address _to, uint256 _mintAmount) private {
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
        emit ShamaPassSent(_to, _mintAmount);
    }

    ///@dev returns the token´s URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId));
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), BASE_EXTENSION)) : "";
    }

    ///@dev mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    ///@dev rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(owner)) == operator) return true;
        return super.isApprovedForAll(owner, operator);
    }

    ///@dev returns IDs of tokens owned by address
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    ///@notice Total supply of collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    ///@dev onlyOwner options

    ///@notice mint only for the owner
    function ownerMint(address _to, uint _mintAmount) public onlyOwner {
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= MAX_SUPPLY);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
        emit ShamaPassSent(_to, _mintAmount);
    }

    ///@notice Set the base URL of the collection
    ///@dev AWS or IPFS urls
    ///@param _newBaseURI the new BASE URL
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        BASEURI = _newBaseURI;
    }

    ///@notice Set the base extension of the NFT
    ///@dev usually json, you can send empty string for api calls
    ///@param _newBaseExtension the new extension.
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        BASE_EXTENSION = _newBaseExtension;
    }

    ///@notice Pause the contract
    ///@param _state true or false
    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    ///@notice Change Supply of collection
    ///@param _supply The new supply
    function setSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    ///@notice set the Open Sea Proxy Address
    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        PROXY_REGISTRY_ADDRESS = proxyAddress;
    }

    ///@notice Set the price
    ///@param _price true or false
    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    ///@notice set public
    function setPublic(bool _public) public onlyOwner {
        PUBLIC = _public;
    }

    ///@notice set shamapass address
    function setShamaPassAddress(address _address) public onlyOwner {
        SHAMAPASS_ADDRESS = _address;
    }

    ///@notice Withdraw funds from the contract
    function withdraw() public onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

}