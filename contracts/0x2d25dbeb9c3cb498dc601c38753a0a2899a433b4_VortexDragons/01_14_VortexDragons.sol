// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {mapping(address => OwnableDelegateProxy) public proxies;}

contract VortexDragons is ERC721, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    bool public PAUSED = true;
    uint256 public MAX_SUPPLY = 5000;
    string public BASEURI;
    string public BASE_EXTENSION = ".json";
    uint256 public MINIMUM_DRAGONS_FOR_MINT = 2;

    ///@notice address of teen dragons contract
    address public TEEN_DRAGONS_ADDRESS;

    ///@notice Open Sea proxy address
    address public PROXY_REGISTRY_ADDRESS;

    ///@notice track who minted
    mapping(uint256 => bool) public TEEN_DRAGONS_REDEEMED;

    ///@notice events
    event vortexDragonMinted(address _to, uint256 _mintAmount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyAddress,
        address _teenDragonsAddress
    ) payable ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        PROXY_REGISTRY_ADDRESS = _proxyAddress;
        TEEN_DRAGONS_ADDRESS = _teenDragonsAddress;
    }

    ///@notice Redeem Vortex Dragons
    ///@param _teenDragons Teen dragons array
    function redeemVortexDragon(uint256[] memory _teenDragons) public nonReentrant {

        require(!PAUSED, "Contract paused");
        require(_teenDragons.length%2 == 0, "Must send a correct number of teen dragons to redeem (even)");
        require(totalSupply() + _teenDragons.length / MINIMUM_DRAGONS_FOR_MINT <= MAX_SUPPLY, "Max supply reached");
        uint256 _mintAmount = _teenDragons.length / MINIMUM_DRAGONS_FOR_MINT;

        for(uint256 i = 0; i < _teenDragons.length; i++) {
            require(ERC721(TEEN_DRAGONS_ADDRESS).ownerOf(_teenDragons[i]) == msg.sender, "Sender do not own this teen dragon" );
            require(!TEEN_DRAGONS_REDEEMED[_teenDragons[i]], "Some teen dragons are already redeemed");
            TEEN_DRAGONS_REDEEMED[_teenDragons[i]] = true;
        }

        mint(msg.sender, _mintAmount);

    }

    /** 
    @dev utility functions
    */

    ///@dev mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(_owner)) == _operator) return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    ///@notice mint
    ///@dev all mints end calling this method
    function mint(address _to, uint256 _mintAmount) private {
        for (uint256 i = 1; i <= _mintAmount; i++) { 
            supply.increment(); 
            _safeMint(_to, supply.current());
        }
        emit vortexDragonMinted(_to, _mintAmount);
    }

    ///@notice Get baseUri
    function _baseURI() internal view virtual override returns (string memory) {
        return BASEURI;
    }

    ///@dev returns the token´s URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId));
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), BASE_EXTENSION ) ) : "";
    }

    ///@dev returns IDs of tokens owned by address
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while ( ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY ) {
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

    ///@notice set minimum teen dragons to mint
    function setMinimumTeenDragonsToMint(uint256 _newMinimum) public onlyOwner {
        MINIMUM_DRAGONS_FOR_MINT = _newMinimum;
    }

    ///@notice Withdraw funds from the contract
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function ownerMint(address _to, uint _mintAmount) public onlyOwner {
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= MAX_SUPPLY);
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
        emit vortexDragonMinted(_to, _mintAmount);
    }

    ///@notice set shamapass address
    function setTeenDragonsAddress(address _address) public onlyOwner {
        TEEN_DRAGONS_ADDRESS = _address;
    }
}