// SPDX-License-Identifier: MIT
// ✦✦✦
pragma solidity ^0.8.19;

import "./deps/Owned.sol";
import "./deps/LibString.sol";
import "erc721a/contracts/ERC721A.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract NigaNegros is ERC721A, Owned {

    using LibString for uint;

    uint public constant MAX_SUPPLY = 20000;

    uint public etherMintPrice = 0.01 ether;

    string public baseURI;
    
    address public miladyMaker;
    address public pepeLiberationArmy;

    mapping (address => mapping(uint => bool)) public usedNFTs;


    constructor(
        address _owner,
        address _miladyMaker,
        address _pepeLiberationArmy
    ) ERC721A("NigaNegros", "NN") Owned(_owner) {
        miladyMaker = _miladyMaker;
        pepeLiberationArmy = _pepeLiberationArmy;
    }

    receive() external payable {
        uint amount = msg.value / etherMintPrice;
        mintWithEther(amount);
    }

    

    /// @notice Mints NFTs, uses ether to pay for tokens.
    /// @param paidAmount The amount of tokens, paid for with ether, to mint.
    function mintWithEther(uint paidAmount) public payable {
        require(msg.value == etherMintPrice * paidAmount, "Not enough ether sent");
        require(_totalMinted() + paidAmount <= MAX_SUPPLY, "Not enough supply left");
        _mint(msg.sender, paidAmount);
    }

    /// @notice Mints NFTs for free, if the minter is a holder of an NFT from 4 different collections.
    /// @param nfts The addresses of the NFT collections that the minter is a holder of.
    /// @param tokenIds The token IDs of the NFTs that the minter is a holder of.   
    function mintWithNFT(address[] memory nfts, uint[][] memory tokenIds) external {
        uint freeAmount = ownerCheck(nfts, tokenIds);
        require(_totalMinted() + freeAmount <= MAX_SUPPLY, "Not enough supply left");
        _mint(msg.sender, freeAmount);
    }

    /// @notice Mints NFTs, uses ether to pay for tokens, and also allows the minter to mint free tokens if they are a holder of NFTs from 4 different collections.
    /// @param nfts The addresses of the NFT collections that the minter is a holder of.
    /// @param tokenIds The token IDs of the NFTs that the minter is a holder of.
    /// @param paidAmount The amount of tokens, paid for with ether, to mint.
    function mintWithNFTEther(address[] memory nfts, uint[][] memory tokenIds, uint paidAmount) external payable {
       require(msg.value == etherMintPrice * paidAmount, "Not enough ether sent");
       uint freeAmount = ownerCheck(nfts, tokenIds);
       require(_totalMinted() + paidAmount + freeAmount <= MAX_SUPPLY, "Not enough supply left");
        _mint(msg.sender, paidAmount + freeAmount);
    }

    /// @notice Checks if the minter is a holder of NFTs from 4 possible different collections
    /// @param nfts The addresses of the NFT collections that the minter is a holder of.
    /// @param tokenIds The token IDs of the NFTs that the minter is a holder of.
    /// @return freeAmount amount of free tokens the minter is eligible for.
    function ownerCheck(address[] memory nfts, uint[][] memory tokenIds) internal returns (uint){
        uint freeAmount;
        for(uint i = 0; i < nfts.length; i++) {
            address localNFT;
            if(nfts[i] == pepeLiberationArmy){
                localNFT = pepeLiberationArmy;
            } else if(nfts[i] == miladyMaker){
                localNFT = miladyMaker;
            } else {
                revert("Invalid NFT address");
            }
            for(uint j = 0; j < tokenIds[i].length; j++) {
                uint tokenId = tokenIds[i][j];
                require(usedNFTs[localNFT][tokenId] == false, "Token ID already used");
                require(IERC721(localNFT).ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
                usedNFTs[localNFT][tokenId] = true;
                freeAmount++;
            }
        }
        return freeAmount;
    }

    /// @notice Returns the URI for a given token ID.
    /// @param tokenID The token ID to return the URI for.
    /// @return The URI of `tokenID`.
    /// @dev Reverts if the token ID does not exist.
    function tokenURI(uint tokenID) public view override returns (string memory){
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
    }

    /// @notice Owner function to set the base URI for all tokens.
    /// @param _baseURI The base URI to set.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Owner function to set the price for minting tokens with ether.
    function setEtherMintPrice(uint _etherMintPrice) external onlyOwner {
        etherMintPrice = _etherMintPrice;
    }

    /// @notice Owner function to withdraw all ether from the contract to the owner's address.
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}