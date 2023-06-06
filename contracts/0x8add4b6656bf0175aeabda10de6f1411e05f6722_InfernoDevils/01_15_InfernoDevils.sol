// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*

  _________                           __  .__              _____                __  .__             ________              .__.__          
 /   _____/__.__. _____ ___________ _/  |_|  |__ ___.__. _/ ____\___________  _/  |_|  |__   ____   \______ \   _______  _|__|  |   ______
 \_____  <   |  |/     \\____ \__  \\   __\  |  <   |  | \   __\/  _ \_  __ \ \   __\  |  \_/ __ \   |    |  \_/ __ \  \/ /  |  |  /  ___/
 /        \___  |  Y Y  \  |_> > __ \|  | |   Y  \___  |  |  | (  <_> )  | \/  |  | |   Y  \  ___/   |    `   \  ___/\   /|  |  |__\___ \ 
/_______  / ____|__|_|  /   __(____  /__| |___|  / ____|  |__|  \____/|__|     |__| |___|  /\___  > /_______  /\___  >\_/ |__|____/____  >
        \/\/          \/|__|       \/          \/\/                                      \/     \/          \/     \/                  \/ 

I see you nerd! ⌐⊙_⊙
*/

contract InfernoDevils is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    string public provenance;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        //
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}