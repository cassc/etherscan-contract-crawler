// SPDX-License-Identifier: MIT

// This contract is used for the Culture Club NFT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CultureClub is ERC721, Ownable {
    /*///////////////////////////////////////////////////////////////
                            TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public tokenPrice;
    string public _tokenUri;
    bool public saleIsActive;

    mapping(address => bool) public friendsList;
    mapping(address => bool) public friendsMinted;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name,
        string memory symbol,
        string memory tokenUri,
        uint256 _tokenPrice
    ) ERC721(name, symbol) {
        _tokenUri = tokenUri;
        tokenPrice = _tokenPrice;
        saleIsActive = false;
    }

    /*///////////////////////////////////////////////////////////////
                            TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint() external payable {
        require(saleIsActive, "Sale is not active");
        require(tokenPrice == msg.value, "Ether value sent is not correct");
        require(friendsList[_msgSender()], "Friends only");
        require(!friendsMinted[_msgSender()], "Friend already minted");
        unchecked {
            ++totalSupply;
        }
        friendsMinted[_msgSender()] = true;
        _safeMint(_msgSender(), totalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                             UTILS
    //////////////////////////////////////////////////////////////*/

    function setTokenURI(string calldata newTokenUri) external onlyOwner {
        _tokenUri = newTokenUri;
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
        return _tokenUri;
    }

    function setSaleIsActive(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function addFriends(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            friendsList[accounts[i]] = true;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}