// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/*
STACK                               
    */


contract Stacker is ERC721URIStorage, Ownable, IERC721Receiver {
    using Strings for uint256;
    event MintStack (address indexed sender, uint256 startWith);

    //uints 
    
    uint256 public totalCount = 2999;
    uint256 public maxBatch = 10;
    uint256 public totalToadz;
    address public unstackedToadAddress;
    string public baseURI;

    //bool
    bool private started;

    //constructor args 
    constructor(string memory name_, string memory symbol_, address _unstackedAddress, string memory baseURI_) ERC721(name_, symbol_) {
        unstackedToadAddress = _unstackedAddress;
        baseURI = baseURI_;
    }
    function totalSupply() public view virtual returns (uint256) {
        return totalToadz;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxBatch = _newBatch;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setTokenURI(uint256 _tokenIds, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenIds, _tokenURI);
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
    function devMint(uint256 _times) public onlyOwner {
        emit MintStack(_msgSender(), totalToadz+1);
        for(uint256 i=0; i<_times; i++) {
            _mint(_msgSender(), 1 + totalToadz++);
        }
    }

    function stack(uint256[] calldata _tokenIds) public {
        require(started, "not started");
        require(IERC721(unstackedToadAddress).isApprovedForAll(_msgSender(), address(this)), "unstackedToadz not approved for spending");
        require(_tokenIds.length == 3, "you need 3 unstacked toads to stack");
        require(totalToadz + 1 <= totalCount, "not enough toadz");
        for (uint256 i; i < _tokenIds.length; i++) {
          IERC721(unstackedToadAddress).safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }
        emit MintStack(_msgSender(), totalToadz+1); //emit a MintStackEvent
        _mint(_msgSender(), 1 + totalToadz++);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}