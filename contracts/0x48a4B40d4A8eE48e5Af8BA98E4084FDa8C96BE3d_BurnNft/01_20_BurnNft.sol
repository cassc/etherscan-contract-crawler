// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
    @title BurnNft will burn TOKEN and mint an NFT to represent the burned token
    @author Toshi - http://github.com/toshiSat
    @notice This will allow you to burn the erc20 set inside TOKEN and creates an NFT that represents the amount that is burnt
*/
contract BurnNft is ERC721URIStorage, Ownable {
    using SafeERC20 for ERC20Burnable;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public immutable TOKEN;
    mapping(uint256 => Attr) public attributes;
    string public baseUri;

    event Burn(
        uint256 indexed itemId,
        uint256 amountVoted,
        string coinGeckoIdentifier
    );

    event BaseUriChanged(string oldUri, string newUri);

    struct Attr {
        uint256 amountVoted;
        string coinGeckoIdentifier;
    }

    /**
        @notice constructor when initializing contract
        @param _token - address of TOKEN contract
        @param _baseUri - initial baseUri for images
    */
    constructor(address _token, string memory _baseUri) ERC721("Burned KODI", "bKODI") {
        TOKEN = _token;
        baseUri = _baseUri;
    }

    /**
        @notice changes base uri of ipfs server
        @param _baseUri - new base uri of the ipfs server
    */
    function changeBaseUri(string memory _baseUri) public onlyOwner {
        emit BaseUriChanged(baseUri, _baseUri);
        baseUri = _baseUri;
    }

    /**
        @notice creates and adds metadata to NFT on chain
        @param _tokenId - token id of the NFT
        @return - returns base64 encoded string that contains metadata for NFT
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        string memory image = string.concat(Strings.toString(_tokenId), ".png");
        // encodes nft metadata to base64 using OZ library
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        attributes[_tokenId].coinGeckoIdentifier,
                        '",',
                        '"image": "',
                        string.concat(
                            baseUri,
                            image
                        ),
                        '",',
                        '"attributes": [{"trait_type": "Token To Implement", "value": "',
                        attributes[_tokenId].coinGeckoIdentifier,
                        '"',
                        "},",
                        '{"trait_type": "Amount Voted", "value": "',
                        Strings.toString(attributes[_tokenId].amountVoted),
                        '"',
                        "}",
                        "]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
        @notice burns erc20 Token and creates Nft to represent what that token is voting for and amount burned
        @dev Burn event fired with tokenId, amount voted, and coingecko identifier
        @param _amountVoted - amount of Token to burn
        @param _coinGeckoIdentifier - coingecko identifier for asset to vote for ex: ethereum from - https://www.coingecko.com/en/coins/ethereum
        @return - returns uint with the nft token id
    */
    function mintNFT(uint256 _amountVoted, string memory _coinGeckoIdentifier)
        public
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();

        ERC20Burnable(TOKEN).burnFrom(msg.sender, _amountVoted); // burn erc20 token
        emit Burn(newItemId, _amountVoted, _coinGeckoIdentifier);

        _safeMint(msg.sender, newItemId); // mint nft
        attributes[newItemId] = Attr(_amountVoted, _coinGeckoIdentifier); // record attributes on chain
        _tokenIds.increment();
        return newItemId;
    }
}