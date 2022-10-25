// SPDX-License-Identifier: MIT
        pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

         contract FuckTheRest is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {

                                    
// Property valiables //

using Counters for Counters.Counter;

Counters.Counter private _tokenIdCounter;


// Mint details. If you see this line of code, you will notice that we (the Owners) would be able to change the MAX_SUPPLY. We have no intend of doing so, but who knows what the future brings for FTR. It could be a useful tool to regulate supply and demand later on. Anyway, if we ever gonna change the MAX_SUPPLY, we are going to announce it on our Socials. //

uint256 public MINT_PRICE = 0.12 ether;
uint256 public TOTAL_SUPPLY = 0;
uint256 public MAX_SUPPLY = 10000;
uint256 public MAX_PER_WALLET = 5;
bool public MINT_ENABLED;
mapping(address => uint256) public WALLET_MINTS;


constructor() payable ERC721("Fuck The Rest", "FTR") {            


// Start Token ID at one instead of zero. //

_tokenIdCounter.increment ();
    }

 // Withdraw Function. This part of code is necessary to get the funds on the owner adress. Otherwise we would not be able to invest back into FTR. //
   
    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "Balance is zero");
        payable(owner()).transfer(address(this).balance);
    } 

// Activate Mint. //
    function setMINT_ENABLED(bool MINT_ENABLED_) external onlyOwner {
        MINT_ENABLED = MINT_ENABLED_;
    }

    function mint(uint256 quantity_) public payable {
        require(MINT_ENABLED, "minting not enabled.");
        require(msg.value == quantity_ * MINT_PRICE, "wrong mint value.");
        require(TOTAL_SUPPLY + quantity_ <= MAX_SUPPLY, "SOLD OUT!");
        require(WALLET_MINTS[msg.sender] + quantity_ <= MAX_PER_WALLET, "exceed max wallet.");

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = TOTAL_SUPPLY + 1;
            TOTAL_SUPPLY++;
            _safeMint(msg.sender, newTokenId);
        }
    }



 // Pausable function. This function let us (the owners) pause every transaction depending Tallman, Hang Loose & Rock'n'love. This is for security reasons.  //

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


// Minting function. Make sure to have enough ETH on your wallet to cover the minting price and the gas fees before minting your NFT //

    function safeMint(address to) public payable {
        require(totalSupply() < MAX_SUPPLY, "SOLD OUT!");
        require(msg.value >= MINT_PRICE, "Not enough ether sent.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }


// DNA creation. You can put `https://ipfs.io/ipfs//QmX35UNK9p69L9agXKbpkhgbJCxWW54GgVmQZ4GewKK7UB/hidden.gif` in a browser window and see the current `Preview` picture. After we sold out we gonna change the CID to the NFT Metadata, so all of you get to see their NFTs. We count on our community, to get the new CID ASAP! // 

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs/QmX35UNK9p69L9agXKbpkhgbJCxWW54GgVmQZ4GewKK7UB/hidden.gif";

    }


// Transfer function //

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    

// The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}