// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CSClub is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    bool public saleIsActive = true;
    string public baseTokenURI = "";
    uint256 public price = 313000000000000000000;

    constructor() ERC721("CS Club", "CSC") {}

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(address _receiver) public onlyOwner returns (uint256) {
        supply.increment();
        uint256 newItemId = supply.current();
        _mint(_receiver, newItemId);
        return newItemId;
    }

    function buy() public payable virtual returns (uint256) {
        require(saleIsActive, "CSClub: Sale is not active.");
        require(msg.value >= price, "CSClub: Not enough ETH sent check price");
        supply.increment();
        uint256 newItemId = supply.current();
        _mint(_msgSender(), newItemId);
        return newItemId;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) ||
                _msgSender() == owner(),
            "CSClub: Caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setSaleIsActive(bool _saleIsActive) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId > 0, "CSClub: Token Id does not exists.");
        return baseTokenURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Needed for Pausable to work
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}