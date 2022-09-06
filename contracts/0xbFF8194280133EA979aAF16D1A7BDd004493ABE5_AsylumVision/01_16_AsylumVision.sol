// SPDX-License-Identifier: MIT

/*
 ______     ______     __  __     __         __  __     __    __        __   __   __     ______     __     ______     __   __    
/\  __ \   /\  ___\   /\ \_\ \   /\ \       /\ \/\ \   /\ "-./  \      /\ \ / /  /\ \   /\  ___\   /\ \   /\  __ \   /\ "-.\ \   
\ \  __ \  \ \___  \  \ \____ \  \ \ \____  \ \ \_\ \  \ \ \-./\ \     \ \ \'/   \ \ \  \ \___  \  \ \ \  \ \ \/\ \  \ \ \-.  \  
 \ \_\ \_\  \/\_____\  \/\_____\  \ \_____\  \ \_____\  \ \_\ \ \_\     \ \__|    \ \_\  \/\_____\  \ \_\  \ \_____\  \ \_\\"\_\ 
  \/_/\/_/   \/_____/   \/_____/   \/_____/   \/_____/   \/_/  \/_/      \/_/      \/_/   \/_____/   \/_/   \/_____/   \/_/ \/_/ 
                                                                                                                                 
*/

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AsylumVision is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    //collection settings
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    uint256 public maxSupply = 5500;
    bool public revealed = false;

    constructor(string memory _hiddenMetadataUri) 
        ERC721A("The Asylum Vision", "AHB") {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    function rain(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(addresses.length == count.length, "mismatching lengths!");

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }

        require(totalSupply() <= maxSupply, "Exceed MAX_SUPPLY");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI,_tokenId.toString(),uriSuffix))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}