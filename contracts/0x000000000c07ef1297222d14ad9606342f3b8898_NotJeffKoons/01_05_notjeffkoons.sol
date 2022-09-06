//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

interface IBRICKS {
    function balanceOf(address account) external view returns (uint256);
}


contract NotJeffKoons is ERC721A, Owned {
    using Strings for uint256;
    
    string public baseURI;
    bool public claimActive = true;
    address public immutable bricks = 0x6C06FF31156C4db4BE59D2ee4525b7380C9f09cA;
    mapping (address => bool) public claimed;
    uint public maxSupply = 64;

    constructor()ERC721A("NotJeffKoons", "NJK")Owned(msg.sender){}

    receive() external payable {
        claim();
    }

    function claim() public {
        require(!claimed[msg.sender], "Already claimed");
        require(claimActive);
        require(IBRICKS(bricks).balanceOf(msg.sender) > 0, "You need to own a BRICK NFT to claim a NotJeffKoons NFT");
        require(totalSupply() < maxSupply, "All NotJeffKoons NFTs have been claimed");
        claimed[msg.sender] = true;
        _mint(msg.sender, 1);
    }


    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }

    function flipClaimActive() external onlyOwner {
        claimActive = !claimActive;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "This token does not exist.");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}