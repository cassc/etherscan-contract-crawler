// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Contract for DTTD Diamond NFT
/// @author irreverent.eth @ DTTD
/// @notice https://dttd.io/

//    ___    _____   _____    ___   
//   |   \  |_   _| |_   _|  |   \  
//   | |) |   | |     | |    | |) | 
//   |___/   _|_|_   _|_|_   |___/  
// _|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract DTTDDiamondContract is ERC721A, Ownable {
    uint256 constant public MAX_SUPPLY = 8888;
    string private baseTokenURI;

    mapping(bytes32 => bool) public tidMinted;

    constructor() ERC721A("DTTD Diamond", "DTTDDIAMOND") {
        baseTokenURI = "https://dot.dttd.group/DTTDDIAMOND/";
        _mint(msg.sender, 1);
    }

    // Modifiers

    modifier tidCheck(bytes32 tid) {
        require (tidMinted[tid] == false, "Already minted: tid");
        _;
    }

    modifier maxSupplyCheck(uint256 amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Insufficient remaining supply");
        _;
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Airdrop

    function airdrop(bytes32 tid, address recipient, uint256 amount) external onlyOwner tidCheck(tid) maxSupplyCheck(amount) {
        require(amount > 0, "Airdrop amount must be greater than 0");
        tidMinted[tid] = true;
        _mint(recipient, amount);
    }
}