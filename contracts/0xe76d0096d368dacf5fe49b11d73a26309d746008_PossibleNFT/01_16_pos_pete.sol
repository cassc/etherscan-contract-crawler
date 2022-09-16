// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


pragma solidity ^0.8.0;

contract PossibleNFT is ERC721, AccessControl, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    string private _baseTokenURI;
    // The total number that have ever been minted.
    Counters.Counter private totalMinted;

    constructor(
    
    ) ERC721("POSsible NFT", "POSNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

     function mint(
    ) external payable nonReentrant {
        uint256 nextTokenId = totalMinted.current() + 1;
        _mint(msg.sender, nextTokenId);     

        totalMinted.increment();
    }

    function getTotalMintCount() public view returns (uint256) {
        return totalMinted.current();
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    string[] private layer2 = [
        "Arbitrum",
        "Optimism",
        "zkSync",
        "StarkNet",
        "Polygon"
    ];
    
    string[] private ogDesignation = [
        "DAO Hack Survivor",
        "First Cycler",
        "Second Cycler",
        "Third Cycler",
        "Pre-miner",
        "Just got here"
    ];
    
    string[] private walletChoice = [
        "Ledger wallet",
        "Metamask wallet",
        "Coinbase wallet",
        "Rainbow wallet",
        "1inch wallet",
        "Loopring wallet",
        "Argent wallet",
        "My memory is my wallet"
    ];
    
    string[] private yourSize = [
        "0.001 eth",
        "0.01 eth",
        "0.1 eth",
        "1 eth",
        "2 eth",
        "5 eth",
        "10 eth",
        "25 eth",
        "50 eth",
        "100 eth",
        "1,000 eth",
        "10,000 eth",
        "100,000 eth"
    ];

    string[] private social = [
        "Crypto Twitter",
        "Discord",
        "Telegram",
        "Signal",
        "WhatsApp",
        "Slack",
        "IRC"
    ];
    
    string[] private setup = [
        "Home staker",
        "Staking Service",
        "Hot Wallet",
        "Cold Wallet",
        "CEX"
    ];
    
    string[] private dex = [
        "Uniswap",
        "Sushiswap",
        "1inch",
        "Curve",
        "Matcha",
        "PancakeSwap",
        "CEX Only"
    ];
    
    string[] private data = [
        "Etherscan",
        "Dune Analytics",
        "Alchemy",
        "Infura"
    ];
    
    string[] private prefixes = [
        ""
    ];
    
    string[] private namePrefixes = [
        "" 
    ];
    
    string[] private nameSuffixes = [
        ""
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getLayer2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LAYER_2", layer2);
    }
    
    function getogDesignation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OG_DESIGNATION", ogDesignation);
    }
    
    function getwalletChoice(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WALLET", walletChoice);
    }
    
    function getyourSize(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SIZE", yourSize);
    }

    function getsocial(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SOCIAL", social);
    }
    
    function getsetup(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SETUP", setup);
    }
    
    function getdex(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DEX", dex);
    }
    
    function getdata(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DATA", data);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(prefixes[rand % prefixes.length], " ", output));
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: monospace; font-size: 14px; }</style><rect width="100%" height="100%" fill="#00458f" /><text x="10" y="20" class="base">';

        parts[1] = getLayer2(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getogDesignation(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getwalletChoice(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getyourSize(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getsocial(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getsetup(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getdex(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getdata(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "POS Merge Box #', toString(tokenId), '", "description": "POSsible NFTs are randomized on chain ''loot box'' NFTs to represent the ethereum merge which happend in September of 2022. Feel free to use how you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}