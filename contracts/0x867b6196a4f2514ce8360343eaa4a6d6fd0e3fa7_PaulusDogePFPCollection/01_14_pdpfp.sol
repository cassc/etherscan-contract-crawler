// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract PaulusDogePFPCollection is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    // Welcome to the Paulus Doge (@paulusdoge) Interactive PFP collection
    // PFPs can switch between colored and black/white mode via a function call!

    // tokens start at 1
    uint256 tokenCounter = 1;
    uint256 maxTokens = 18;
    uint256 maxPerWallet = 3;
    uint256 price = 8 * 10**15;
    mapping(address => uint256) mintedPerWallet;
    mapping(uint256 => bool) blackAndWhite;

    string baseURIbw = "ipfs://QmURAxz5jzPjNXr1k9QuXdT2R3xZV9enjCQsYSKDLzmmy3";
    string baseURIco = "ipfs://QmcLgN2ZgyayadCGLAfqPNV6HoU6tdwaNVNi22ZVodEcpF";

    constructor() ERC721("P. Doge Interactive PFP Collection", "PPFP")
    {
    }

    function updateBaseURIs(string memory bw, string memory co) public onlyOwner
    {
        baseURIbw = bw;
        baseURIco = co;
    }

    function mint () public payable 
    {
        require(tokenCounter <= maxTokens, "Sorry, all tokens have already been minted.");
        require(mintedPerWallet[msg.sender] < maxPerWallet, "You cannot mint that many for yourself!");
        require(price <= msg.value, "Minting a P. Doge PFP will cost you 0.008 eth!");


        _safeMint(msg.sender, tokenCounter);
        mintedPerWallet[msg.sender] += 1;
        _setTokenURI(tokenCounter, createTokenURI(tokenCounter, baseURIco));
        tokenCounter += 1;
    }

    function createTokenURI(uint256 tokenID, string memory base) private pure returns (string memory)
    {
        return string.concat(base, "/", Strings.toString(tokenID), ".json");
    }

    function switchColorMode(uint256 tokenId) public
    {
        require(ownerOf(tokenId) == msg.sender, "You can only change the color of your own tokens!");

        if (blackAndWhite[tokenId])
        {
            _setTokenURI(tokenId, createTokenURI(tokenId, baseURIco));
            blackAndWhite[tokenId] = false;
        }
        else
        {
            _setTokenURI(tokenId, createTokenURI(tokenId, baseURIbw));
            blackAndWhite[tokenId] = true;
        }
    }

    function withdraw() public onlyOwner
    {
        (bool result,)= payable(owner()).call{value: address(this).balance }("");
        require(result, "Withdrawal failed");
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}