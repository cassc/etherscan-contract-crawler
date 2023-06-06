// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MightyTeenDragons is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public fireCost = 30 ether;
    uint256 public maxSupply = 10000;
    bool public paused = true;
    mapping(uint256 => bool) public babyDragonUsed;
    address public mightyBabyDragonsAddress;
    address public fireAddress;
    event TeenDragonMinted(address to);

    constructor( string memory _name, string memory _symbol, string memory _initBaseURI ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint( address _to, uint256[] memory _babyDragons ) public {
        require(!paused, "Contract is paused");
        require(_babyDragons.length > 0, "Mint amount must be at least 1");
        require(totalSupply() + _babyDragons.length <= maxSupply, "Total supply reached");
        
        for (uint256 i = 0; i < _babyDragons.length; i++) {
            require(ERC721(mightyBabyDragonsAddress).ownerOf(_babyDragons[i]) == msg.sender, "You are not the owner of this Dragon" );
            require( babyDragonUsed[_babyDragons[i]] != true, "Baby Dragon can only Breed once" );
        }

        require(IERC20(fireAddress).transferFrom(msg.sender, owner(), _babyDragons.length * fireCost), "Must have allowance");
        
        for (uint256 i = 0; i < _babyDragons.length; i++) {
            babyDragonUsed[_babyDragons[i]] = true;
            supply.increment();
            _safeMint(_to, supply.current());
        }

        emit TeenDragonMinted(_to);
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while ( ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension ) ) : "";
    }

    //only owner
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function setFireCost(uint256 _newCost) public onlyOwner {
        fireCost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setMightyBabyDragonsAddress(address _mightybabyDragonsAddress) public onlyOwner {
        mightyBabyDragonsAddress = _mightybabyDragonsAddress;
        return;
    }

    function setFireAddress(address _fireAddress) public onlyOwner {
        fireAddress = _fireAddress;
        return;
    }
}