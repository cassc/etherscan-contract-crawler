// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "../implementations/Erc721/LazyMintByTokenId.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title A Lazy minting contract for to sachs COA release with Avant Arte
 * @author Liron Navon
 * @dev This contract is using URIMetaData and uri to generate dynamic metadata file encoded with base64.
 */
contract TomSachsCoa is LazyMintByTokenId {
    struct URIMetaData {
        string name;
        string description;
    }

    URIMetaData public metaData;

    constructor(
        string memory _name,
        string memory _imageUri,
        string memory _symbol,
        address _minter,
        address royaltiesReciever,
        uint256 royaltiesFraction,
        URIMetaData memory _metaData
    )
        LazyMintByTokenId(
            _name,
            _imageUri,
            _symbol,
            _minter,
            royaltiesReciever,
            royaltiesFraction
        )
    {
        metaData = _metaData;
    }

    function setMetaData(URIMetaData calldata _metadata) public onlyOwner {
        metaData = _metadata;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "',
            metaData.name,
            " #",
            Strings.toString(tokenId),
            '",',
            '"description": "',
            metaData.description,
            '",',
            '"image": "',
            uri,
            '"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}