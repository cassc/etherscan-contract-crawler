// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Boxcatrecipt is Ownable, ERC721A {
    uint256 public immutable collectionSize = 10000;

    address public minter;

    // metadata URI
    string private _baseTokenURI;

    constructor() ERC721A("Receipt", "RT") {}

    // Public Mint
    // *****************************************************************************
    // Public Functions
    function mint(address to, uint256 quantity) public {
        require(msg.sender == minter, "Can only mint by minter");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );

        _safeMint(to, quantity);
    }

    // Owner Controls

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    // Internal Functions
    // *****************************************************************************

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(from == address(0), "cannot be transfered");
    }
}