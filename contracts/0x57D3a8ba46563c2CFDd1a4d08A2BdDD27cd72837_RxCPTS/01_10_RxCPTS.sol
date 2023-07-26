// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract RxCPTS is ERC721A, Ownable {
    using Address for address;
    string private _tokenUriBase;

    event mintEvent(
        address indexed user,
        uint256 quantity
    );

    constructor() ERC721A("RxCPTS", "RxCPTS") {
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenBaseURI(string memory tokenUriBase) public onlyOwner {
        _tokenUriBase = tokenUriBase;
    }

    function mintBatch(
        address receiver,
        uint256 quantity
    ) external onlyOwner {
        _safeMint(receiver, quantity);
        emit mintEvent(receiver, quantity);
    }

    function withdrawAll(address recipient) public onlyOwner {
        require(recipient != address(0), "recipient is the zero address");
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawAllViaCall(address payable to) public onlyOwner {
        require(to != address(0), "recipient is the zero address");
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}