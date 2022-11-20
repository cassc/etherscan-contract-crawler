//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/utils/Strings.sol";

interface EightiesBabies {
  function ownerOf(uint256 tokenID) external returns (address);
}

contract EightiesMiladys is ERC721A, Owned {
    using Strings for uint256;

    string public baseURI;
    bool public mintActive;
    uint public maxSupply = 1000;

    mapping(uint256 => bool) claimed;
    EightiesBabies eightiesBabies = EightiesBabies(0x0c142fDCF12AAA6ed06202DE2FC1D17fCEd7571A);

    constructor()ERC721A("Eighties Miladys", "80MILADY")Owned(msg.sender){
        // exec mint bitchz
      _safeMint(msg.sender, 10);
    }   

    /// @notice Mint Eighties Miladys with Eighties Babies. Token IDs elidgible: 0-999
    /// @param tokenID Token ID of eighties babies NFT
    function mint(uint tokenID) external {
        require(tokenID <= 999, "Only Eighties Babies tokenIDs up to 999 can mint!");
        require(eightiesBabies.ownerOf(tokenID) == msg.sender, "Must be owner of token ID");
        require(!claimed[tokenID], "Milady already claimed!");
        require(mintActive, "Minting is not active");
        require(totalSupply() + 1 <= maxSupply, "Max supply reached");

        claimed[tokenID] = true;
        _safeMint(msg.sender, 1);
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function flipMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "This token does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }
}