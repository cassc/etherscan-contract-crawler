// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DoodlDuckz is ERC721, ReentrancyGuard, Ownable {
    uint256 public MINT_PRICE = 0.05 ether;
    uint256 public TOTAL_SUPPLY = 5555;
    bool public MINTING_ALLOWED = false;
    string private _baseURIextended;
    uint256 private _counter = 0;

    using Strings for uint256;
   
   mapping(uint256 => string) private _tokenURIs;
   
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function contractURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /*
     * Owner can withdraw the contract's ETH to an external address
     */
    function withdrawETH(address ethAddress, uint256 amount) public onlyOwner {
        payable(ethAddress).transfer(amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }


    /*
     * Mint function
     */

    function mint(uint requestedTokens) public payable nonReentrant() {
      require(MINTING_ALLOWED, "Minting is not allowed");

      require(
       requestedTokens <= TOTAL_SUPPLY - _counter,
       "There aren't this many DDZ left."
      );

      require(
       requestedTokens <= 10,
       "Up to 10 tokens allowed in a single minting transaction."
      );

      require(TOTAL_SUPPLY - _counter>0,"DDZ shares are now sold out! Please check OpenSea to purchase DDZ .");


      uint256 totalCost = getMintingCost(requestedTokens);
      require(
       msg.value >= totalCost,
       "Insufficient Gas."
      );
   
        for(uint i = 0; i < requestedTokens; i++) {
           _mint(msg.sender, _counter + 1);
           _setTokenURI(_counter + 1, Strings.toString(_counter + 1));
           _counter++;
        }
        //payable(OWNER).transfer(msg.value);
    }

   //Return minting cost
  function getMintingCost(uint totalItems)
    private
    view
    returns (uint256)
  {
    return totalItems * MINT_PRICE;
  }

    function totalTokensMinted() public view returns (uint256) {
        return _counter;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

   function remainingSupply() public view returns (uint256) {
        return TOTAL_SUPPLY - _counter;
    }


   function setMintPrice(uint256 newPrice) external onlyOwner {
        MINT_PRICE = newPrice;
        MINTING_ALLOWED = false;
    }

    //Set the Base URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setMintingFlag() external onlyOwner {
        MINTING_ALLOWED = !MINTING_ALLOWED;
    }
}