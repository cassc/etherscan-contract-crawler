// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlayerCardNFT is ERC721A, Ownable {
    bool public openTransfer;

    address public gameContract;

    string public baseURI;

    // string public defaultURI;

    modifier onlyBegin() {
        require(
            openTransfer == true,
            "The transfer has not yet begun"
        );
        _;
    }

    constructor() ERC721A("Ballciaga Player Card", "BPC") {}

    function mintTo(address to, uint256 quantity) external {
        require(msg.sender == gameContract, 'You do not have mint permission');
        _mint(to, quantity);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyBegin {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyBegin {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override onlyBegin {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return bytes(uri).length != 0 ? string(abi.encodePacked(uri, '.json')) : '';
    }
   
    function setOpenTransfer(bool _open) onlyOwner public {
        openTransfer = _open;
    }

    function setGameContract(address _addr) onlyOwner public {
        gameContract = _addr;
    }

    function setBaseURI(string memory _uri) onlyOwner public {
        baseURI = _uri;
    }
}