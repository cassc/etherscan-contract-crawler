//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./EIP2981/ERC2981PerTokenRoyalties.sol";


contract Equator is ERC721, Ownable, ERC721Enumerable, ERC2981PerTokenRoyalties {


    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Maximum limit of tokens that can ever exist
    uint public constant MAX_SUPPLY = 50;

    // public mint price
    uint public PRICE =0.908 ether;
    // 
    bool public _isSaleActive = false;

    // The base link that leads to the image of the token
    string public baseTokenURI;
    
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;
    // each use only purchase a nft
    mapping(address => bool) private _firstbuyers;

    event LogSelfDestruct(address sender, uint amount);

    // dev address
    address private devAddr = 0xf2d15dEAf62b8c4AFC0343006579E8E662c120D9;
    // team address
    address private teamAddr = 0x721CD264821D0Ff07299Bcf61a7C60E889152843;


    constructor(string memory __baseURI, address payable _receiver, address payable _devAddr) ERC721("SamurosJudgement","SAMURO"){
        setBaseURI(__baseURI);
        teamAddr = _receiver;
        devAddr = _devAddr;
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


    /// @notice Public mint
    function mintNFTs(uint _count) public payable{
        uint totalMinted = _tokenIds.current();
        
        // check active
        require(_isSaleActive, "Sale must be active to mint ");
        // check if exceed total supply
        require(totalMinted.add(_count)<= MAX_SUPPLY,"Not enough NFTs left");
        // check fund
        require(msg.value >= PRICE.mul(_count),"Not enought ether to purchase NFTs");

        require(_firstbuyers[msg.sender] != true,"Only buy one");

        // transfer fund
        //payable(receiver).transfer(msg.value);

        uint256 fullAmount = msg.value;
        uint256 devFee = fullAmount * 5 / 100;
        Address.sendValue(payable(devAddr), devFee);
        Address.sendValue(payable(teamAddr), fullAmount - devFee);

        // batch mint
        for(uint i =0; i < _count; i++){
             _mintSingleNFT();
        }
        
        _firstbuyers[msg.sender]  = true;

    }

    function _mintSingleNFT() private{
        uint newTokenID = _tokenIds.current();
        _setTokenRoyalty(_tokenIds.current(), teamAddr, 1000);
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

     /// @dev Reserve NFT. The contract owner can mint NFTs regardless of the minting start and end time.
    function reserve(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceed total supply");
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

    //only operator can active/disactive sale
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }


    //only owner can update teamAddr
    function updateTeamAddr(address payable _receiver) public onlyOwner {
          teamAddr = _receiver;
    }


     //only owner can set sale price
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        PRICE = _mintPrice;
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