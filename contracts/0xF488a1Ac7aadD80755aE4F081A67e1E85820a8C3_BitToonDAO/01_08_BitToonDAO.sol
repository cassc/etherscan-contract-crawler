// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BitToonDAO is ERC721A, Ownable {

    using Strings for uint256;

    address public minter;

    string private baseURI;
    uint256 public maxSupply;

    event SetMinter(address indexed caller, address indexed minter);
    event SetBaseURI(string OldBaseURI, string NewBaseURI);
    event SetMaxSupply(address indexed caller, uint256 maxSupply);

    modifier onlyMinter() {
        require(msg.sender == minter, "You are not a minter");
        _;
    }

    constructor(
        string memory _initBaseURI,
        uint256 _maxSupply
    ) ERC721A("BitToon DAO", "BTD") {

        setMaxSupply(_maxSupply);
        setBaseURI(_initBaseURI);
        setMinter(msg.sender);        
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
        emit SetMinter(msg.sender, minter);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
      maxSupply = _maxSupply;
      emit SetMaxSupply(msg.sender, maxSupply);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        string memory _oldBaseURI = baseURI;
        baseURI = _newBaseURI;

        emit SetBaseURI(_oldBaseURI, baseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) 
        : "";
    }
 
    function safeMint(address to,uint amount) public onlyMinter {
        require(totalSupply() + amount <= maxSupply, "Over max supply");
        _safeMint(to, amount);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}