// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {
    ERC721,
    ERC721Enumerable,
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IBrewlabsFlaskNft is IERC721Enumerable {
    function rarityOf(uint256 tokenId) external view returns (uint256);
}

contract BrewlabsMirrorNft is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for address;

    IBrewlabsFlaskNft public originNft;
    address public admin;
    string private _tokenBaseURI = "";

    string[5] rarityNames = ["Common", "Uncommon", "Rare", "Epic", "Legendary"];
    string[5] featureAccesses = ["Basic", "Improved", "Brewer", "Premium", "Premium Brewer"];
    uint256[5] feeReductions = [5, 10, 15, 20, 30];

    event BaseURIUpdated(string uri);
    event SetAdmin(address addr);

    constructor(IBrewlabsFlaskNft _nft) ERC721("Brewlabs Flask Mirror Nft", "mBLF") {
        originNft = _nft;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == admin, "Caller is not admin");
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == admin, "Caller is not admin");
        _burn(tokenId);
    }

    function rarityOf(uint256 tokenId) public view returns (uint256) {
        uint256 rarity = originNft.rarityOf(tokenId);
        return rarity < 6 ? rarity : 5;
    }

    function tBalanceOf(address owner) external view returns (uint256) {
        return balanceOf(owner) + originNft.balanceOf(owner);
    }

    function tTokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        if (index < balanceOf(owner)) {
            return tokenOfOwnerByIndex(owner, index);
        }
        return originNft.tokenOfOwnerByIndex(owner, index - balanceOf(owner));
    }

    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0x0), "Invalid address");
        admin = newAdmin;
        emit SetAdmin(newAdmin);
    }

    function setTokenBaseUri(string memory _uri) external onlyOwner {
        _tokenBaseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
        internal
        virtual
        override
    {
        require(from == address(0x0) || to == address(0x0), "Cannot transfer");

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BrewlabsMirrorNft: URI query for nonexistent token");

        string memory base = _baseURI();
        string memory description = string(
            abi.encodePacked(
                '"description": "Brewlabs Flask Mirror NFT represents your staked Brewlabs Flask NFT and allows Brewlabs ecosystem to attribute your wallet the correct benefits while your Brewlabs Flask Mirror NFT is held within the NFT staking contract."'
            )
        );

        uint256 rarity = rarityOf(tokenId) - 1;
        string memory rarityName = rarityNames[rarity];

        string memory attributes = '"attributes":[';
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Network", "value":"Ethereum"}, {"trait_type":"Rarity", "value":"',
                rarityName,
                '"}, {"trait_type":"Fee Reduction", "value":"',
                feeReductions[rarity].toString(),
                '.00%"}, {"trait_type":"Feature Access", "value":"',
                featureAccesses[rarity],
                '"}]'
            )
        );

        // If both are set, concatenate the baseURI (via abi.encodePacked).
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                name(),
                " #",
                tokenId.toString(),
                '", ',
                description,
                ', "external_url": "https://earn.brewlabs.info/nft"',
                ', "image": "',
                base,
                "/",
                rarityName,
                '.png", ',
                attributes,
                "}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", _base64(bytes(metadata))));
    }

    function _base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}