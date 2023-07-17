// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MineopolyMining is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    using Counters for Counters.Counter;
    Counters.Counter public  _tokenIds;
   
    
    bool public RevealedActive = true;

    uint256 public Price = 420 * 10 ** 6;
 
    address adminWallet = 0xD1d6629585f2C631081CBbE45334bdd4bf5a33D2;

    IERC20 public USDToken;
    IERC721 public MemberNFT;
    
    constructor(string memory _BaseURI, string memory _NotRevealedUri)
        ERC721("Mineopoly Mining", "MPLY")
    {
        USDToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        MemberNFT = IERC721(0xa62ee4117D7124250AD3a0561E1bf459C0c375b5);
        setURIBase(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
    }

    function updatePrice() internal {
        if (_tokenIds.current() >= 2250) {
            Price = 430 * 10 ** 6;
        }
        if (_tokenIds.current() >= 4500) {
            Price = 440 * 10 ** 6;
        }
        if (_tokenIds.current() >= 6750) {
            Price = 450 * 10 ** 6;
        }
        if (_tokenIds.current() >= 9000) {
            Price = 460 * 10 ** 6;
        }
        if (_tokenIds.current() >= 13500) {
            Price = 470 * 10 ** 6;
        }
        if (_tokenIds.current() >= 15750) {
            Price = 480 * 10 ** 6;
        }
        if (_tokenIds.current() >= 18000) {
            Price = 490 * 10 ** 6;
        }
        if (_tokenIds.current() >= 20250) {
            Price = 500 * 10 ** 6;
        }
    }

    function mintNFT() public {
        require( MemberNFT.balanceOf(msg.sender) >= 1, "You arent member");
        require( USDToken.transferFrom(msg.sender, adminWallet, Price), "Failed to transfer Admin fee" );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        updatePrice();
    }
  

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setAdmin (address _newadminWallet) public onlyOwner {
        adminWallet = _newadminWallet;
    }

    function Reveal() public onlyOwner {
        RevealedActive = true;
    }
}