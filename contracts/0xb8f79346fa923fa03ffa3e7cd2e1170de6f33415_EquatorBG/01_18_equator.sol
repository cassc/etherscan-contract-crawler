//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./EIP2981/ERC2981PerTokenRoyalties.sol";


contract EquatorBG is ERC721, Ownable, ERC721Enumerable, ERC2981PerTokenRoyalties {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;   

    // The base link that leads to the image of the token
    string public baseTokenURI;
    
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;
    // each use only purchase a nft
    mapping(address => bool) private _firstbuyers;

    event LogSelfDestruct(address sender, uint amount);

    // team address
    address private teamAddr = 0x721CD264821D0Ff07299Bcf61a7C60E889152843;


    constructor(string memory __baseURI, address payable _receiver) ERC721("Samuros Judgement Background","SAMUROBG"){
        setBaseURI(__baseURI);
        teamAddr = _receiver;
    } 

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns(string memory){
        return baseTokenURI;
    }  

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _mintSingleNFT() private{
        uint newTokenID = _tokenIds.current();
        _setTokenRoyalty(_tokenIds.current(), teamAddr, 1000);
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

     /// @dev Reserve NFT. The contract owner can mint NFTs regardless of the minting start and end time.
    function reserve(address _to, uint256 _amount) external onlyOwner {
          for(uint i =0; i < _amount; i++){
            _setTokenRoyalty(_tokenIds.current(), teamAddr, 1000);
            uint newTokenID = _tokenIds.current();
            _safeMint(_to, newTokenID);
            _tokenIds.increment();
        }
        _firstbuyers[_to]  = true;
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory){

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i=0; i< tokenCount;i++){
            tokensId[i]= tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    //only owner can update teamAddr
    function updateTeamAddr(address payable _receiver) public onlyOwner {
          teamAddr = _receiver;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI,baseExtension));
        } 
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, Strings.toString(tokenId),
            baseExtension));
    }

    function ownerKill() public onlyOwner {
        emit LogSelfDestruct(msg.sender, address(this).balance);
        selfdestruct(payable(owner()));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal  override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}