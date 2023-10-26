// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract AstraKey is ERC721, Ownable, ERC721Burnable, ERC721Pausable {
    
    uint256 private _tokenIdTracker;
    
    string public baseTokenURI;

    uint256 public constant MAX_ELEMENTS = 500;

    mapping(address => uint256) public keysClaimed;

    event CreateItem(uint256 indexed id);
    constructor()
    ERC721("AstraKey", "ALK") 
    {
        pause(true);
    }

    modifier saleIsOpen {
        require(_tokenIdTracker <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier noContract() {
        address account = msg.sender;
        require(account == tx.origin, "Caller is a contract");
        require(account.code.length == 0, "Caller is a contract");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    function claim(uint256 _count) public saleIsOpen noContract {
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(canMintAmount(_count), "Sender max claim amount already met");

        for (uint256 i = 0; i < _count; i++) {
            keysClaimed[msg.sender] += 1;
            _mintAnElement(msg.sender);
        }
    }

    function ownerClaim(uint256 _count) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Sale end");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(msg.sender);
        }

    }

    function _mintAnElement(address _to) private {
        uint id = totalSupply();
        _tokenIdTracker += 1;
        _mint(_to, id);
        emit CreateItem(id);
    }

    function canMintAmount(uint256 _count) public view returns (bool) {
        uint256 maxMintAmount = IERC721(0xDA857ba168672b18451ec542d43D2f49f374AEE3).balanceOf(msg.sender);

        return keysClaimed[msg.sender] + _count <= maxMintAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}