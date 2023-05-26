// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Opensea.sol";

contract Karafuru3d is Ownable, ERC721Opensea {
    bool public SALES_TOGGLE = false;
    address public GENESIS_CONTRACT;
    address public constant BURNER_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    constructor() ERC721("Karafuru x HYPEBEAST x atmos", "KARA-3D") {}

    function openGacha(uint256 tokenId) external {
        require(SALES_TOGGLE, "Sale is closed");
        require(
            ERC721(GENESIS_CONTRACT).ownerOf(tokenId) == msg.sender,
            "Not genesis owner"
        );
        ERC721(GENESIS_CONTRACT).transferFrom(
            msg.sender,
            BURNER_ADDRESS,
            tokenId
        );
        _safeMint(msg.sender, tokenId);
    }

    function setGenesisContract(address contractAddress) external onlyOwner {
        GENESIS_CONTRACT = contractAddress;
    }

    function toggleSales() external onlyOwner {
        SALES_TOGGLE = !SALES_TOGGLE;
    }
}