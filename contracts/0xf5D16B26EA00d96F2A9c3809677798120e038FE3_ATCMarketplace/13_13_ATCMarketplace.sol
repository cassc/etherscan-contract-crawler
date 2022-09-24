// contracts/ATCMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ATCMarketplace is ERC721URIStorage, Ownable {
    // Counters used for tokenIds
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Struct to hold arists drop info: arist id, total supply, current total minted, ipfs uri, and boolean
    struct ArtistDrop {
        uint256 id;
        uint256 totalSupply;
        uint256 totalMinted;
        string ipfsURI;
        bool exists;
        uint256 mintPrice;
        address payoutAddress;
    }

    // Mapping from artist drop Id to the artist drop struct
    mapping(uint256 => ArtistDrop) artistDrops;

    // Mapping from token Id to artist drop Id
    mapping(uint256 => uint256) tokenIdToArtistDropId;

    // Mapping from token Id to timestamp of first mint
    mapping(uint256 => uint256) tokenIdToMintTime;

    // Events
    event MintEvent(address to, uint256 tokenId, uint256 artistDropId);
    event BurnEvent(address account, uint256 tokenId, uint256 artistDropId);

    // Constructor function
    constructor() ERC721("Album Trading Cards", "ATC") {}

    // Minting function
    function mintToken(uint256 artistDropId) public payable returns (uint256) {
        // Get struct
        ArtistDrop storage artistDrop = artistDrops[artistDropId];

        // Ensure artist drop id exists
        require(artistDrop.exists, "No artist drop found for given Id.");

        // Ensure transaction fee sent
        require(
            msg.value >= artistDrop.mintPrice,
            "Not enough ETH sent for mint fee."
        );

        // Ensure the artist drop has not reached total supply
        require(
            artistDrop.totalMinted + 1 <= artistDrop.totalSupply,
            "Cannot mint as artist drop total supply reached"
        );

        // Transfer the transaction fee to the artist drop payout address
        payable(artistDrop.payoutAddress).transfer(msg.value);

        // Increment the artist drop total minted value by 1
        artistDrop.totalMinted++;

        // Handle the mint logic
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, artistDrop.ipfsURI);
        _tokenIds.increment();

        // Record the token Id to artist drop id mapping
        tokenIdToArtistDropId[newTokenId] = artistDropId;

        // Record the token Id to time of mint mapping
        tokenIdToMintTime[newTokenId] = block.timestamp;

        // Emit mint event
        emit MintEvent(msg.sender, newTokenId, artistDropId);

        // Return
        return newTokenId;
    }

    // Burning function
    function burn(uint256 tokenId) public {
        // Check the sender can burn that token id
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        // Get the artist drop id
        uint256 artistDropId = tokenIdToArtistDropId[tokenId];

        // Get the artist drop struct
        ArtistDrop storage artistDrop = artistDrops[artistDropId];

        // Decrement the total minted by one
        artistDrop.totalMinted--;

        // Remove the token Id mapping to artist drop Id
        delete tokenIdToArtistDropId[tokenId];

        // Remove the token Id mapping to timestamp of first mint
        delete tokenIdToMintTime[tokenId];

        // Emit the burn event
        emit BurnEvent(msg.sender, tokenId, artistDropId);

        // Handle the burn logic
        _burn(tokenId);
    }

    // Getting artist drop info function
    function getArtistDropInfo(uint256 artistDropId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            string memory,
            uint256
        )
    {
        // Get the artist drop struct
        ArtistDrop memory artistDrop = artistDrops[artistDropId];

        // Return the necessary information
        return (
            artistDrop.id,
            artistDrop.totalSupply,
            artistDrop.totalMinted,
            artistDrop.ipfsURI,
            artistDrop.mintPrice
        );
    }

    // Get the artist drop Id from a token Id function
    function getArtistDropIdFromTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToArtistDropId[_tokenId];
    }

    // Get the time a token was first minted at
    function getTimeTokenMinted(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tokenIdToMintTime[_tokenId];
    }

    // Add a new artist drop function
    function addArtistDrop(
        uint256 _id,
        uint256 _totalSupply,
        uint256 _totalMinted,
        string memory _ipfsURI,
        uint256 _mintPrice,
        address _payoutAddress,
        address[] memory airdropAddresses
    ) public onlyOwner returns (bool) {
        // Create new struct
        ArtistDrop memory newArtistDrop = ArtistDrop({
            id: _id,
            totalSupply: _totalSupply,
            totalMinted: _totalMinted,
            ipfsURI: _ipfsURI,
            exists: true,
            mintPrice: _mintPrice,
            payoutAddress: _payoutAddress
        });

        // Add to mapping
        artistDrops[_id] = newArtistDrop;

        // ensure the amount of airdrop addresses is not longer than the total supply
        require(
            airdropAddresses.length <= _totalSupply,
            "Cannot airdrop more than the total supply"
        );

        // ensure the amount of airdrop addresses is not longer than the upper bound
        require(
            airdropAddresses.length <= _totalMinted,
            "Cannot airdrop more than the total minted requested"
        );

        // airdrop functionality
        uint256 length = airdropAddresses.length;
        for (uint256 i = 0; i < length; i++) {
            // get address
            address airdropAddress = airdropAddresses[i];

            // Handle the mint logic
            uint256 newTokenId = _tokenIds.current();
            _mint(airdropAddress, newTokenId);
            _setTokenURI(newTokenId, _ipfsURI);
            _tokenIds.increment();

            // Record the token Id to artist drop id mapping
            tokenIdToArtistDropId[newTokenId] = _id;

            // Record the token Id to time of mint mapping
            tokenIdToMintTime[newTokenId] = block.timestamp;

            // Emit mint event
            emit MintEvent(msg.sender, newTokenId, _id);
        }

        // transfer any left over to the owner
        uint256 leftOver = _totalMinted - length;
        address owner = owner();
        for (uint256 i = 0; i < leftOver; i++) {
            // Handle the mint logic
            uint256 newTokenId = _tokenIds.current();
            _mint(owner, newTokenId);
            _setTokenURI(newTokenId, _ipfsURI);
            _tokenIds.increment();

            // Record the token Id to artist drop id mapping
            tokenIdToArtistDropId[newTokenId] = _id;

            // Record the token Id to time of mint mapping
            tokenIdToMintTime[newTokenId] = block.timestamp;
        }

        // Return
        return true;
    }
}