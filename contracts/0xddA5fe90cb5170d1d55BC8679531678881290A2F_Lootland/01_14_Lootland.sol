// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lootland is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    mapping(address => uint256) public _claimTimes;
    
    uint256 private _pubTokenId = 4001;

    uint256 private _firstPubTokenId = 0;

    uint256 private _exclTokenId = 1;

    uint256 private _maxExclAllowed = 3999;

    bool private _pubMintPaused = true;

    string[] private finance = [
        "P2P Lending",
        "Commodity Market",
        "Security Market",
        "Insurance",
        "Private Vaults",
        "Crypto Exchange",
        "Private Vaults",
        "Loan Shark",
        "Mortgage Broker",
        "DeFi",
        "Bank",
        "Mortgage Broker",
        "Insurance",
        "Pawn Shop",
        "Pawn Shop",
        "DeFi",
        "Insurance",
        "Pawn Shop",
        "Mortgage Broker",
        "DeFi",
        "e-Payment",
        "Pawn Shop",
        "Mortgage Broker",
        "Insurance",
        "Mortgage Broker",
        "e-Payment"
    ];
    
    string[] private scienceAndCulture = [
        "Public School",
        "R&amp;D Center",
        "Rocket Launch Site",
        "NFT Art Gallery",
        "Cemetery",
        "University",
        "Library",
        "Museum",
        "Memorial",
        "Meta-Human Labs",
        "SciFi Club",
        "Cosplay Club"
    ];
    
    string[] private commerce = [
        "Coffee Shop",
        "Cafe",
        "Asian Restaurant",
        "Liquor Store",
        "Fine Dining",
        "Book Shop",
        "Fish N Chips Takeaway",
        "Burger Takeaway",
        "Exotic Dining",
        "Fleamarket",
        "Black Market",
        "Jewelry Store",
        "Clothes Shop",
        "Toy Store",
        "24 Hours Store",
        "Cocktail Bar",
        "Pizza Takeaway",
        "Flower Shop",
        "Supermarket",
        "Pharmacy",
        "Shopping Mall"
    ];
    
    string[] private recreation = [
        "Casino",
        "Amusement Park",
        "Horse Course",
        "Concert Hall",
        "Ski Club",
        "Surf Club",
        "Zoo",
        "Cinema",
        "Cruise Ship",
        "Strip Club",
        "Family Resort",
        "Aquarium",
        "Stadium",
        "Night Club",
        "LGBT Club",
        "Spa Motel",
        "Hotel",
        "Swimming Pool",
        "Golf Club",
        "Shooting Club",
        "Circus",
        "Dojo",
        "Gym"
    ];
    
    string[] private utility = [
        "Recycle Plant",
        "Gas Station",
        "Power Plant",
        "Hospital",
        "Cargo Port",
        "Water Supply",
        "Animal Shelter",
        "Airport",
        "Bus Station",
        "Train Station",
        "Hyperloop"
    ];
    
    string[] private mineAndFarm = [
        "Crypto Mine",
        "Gem Mine",
        "Dairy Farm",
        "Sheep Farm",
        "Gold Mine",
        "Chichen Farm",
        "Coal Mine",
        "Rare Earth Mine",
        "Cotton Farm",
        "Sawmill",
        "Quarry",
        "Vineyard",
        "Yield Farm",
        "Flower Garden",
        "Oil&amp;Gas Platform",
        "Cannabis Farm",
        "Orchard Farm",
        "Vegetable Garden",
        "Fishery"
    ];
    
    string[] private production = [
        "Machine Factory",
        "Meat Factory",
        "Clothes Factory",
        "Jewellery Factory",
        "Semiconductor Plant",
        "Winery",
        "Construction",
        "Distillery",
        "Toy Factory",
        "Pharmaceutical Supply",
        "Food Processing",
        "Brewery",
        "Chocolate Factory"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getFinance(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "FINANCE", finance);
    }
    
    function getSciCul(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "SCI-CUL", scienceAndCulture);
    }
    
    function getCommerce(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "COMMERCE", commerce);
    }
    
    function getRecreation(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "RECREATION", recreation);
    }

    function getUtility(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "UTILITY", utility);
    }
    
    function getMineAndFarm(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "MINE-FARM", mineAndFarm);
    }
    
    function getProduction(uint256 tokenId) internal view returns (string memory) {
        return pluck(tokenId, "PRODUCTION", production);
    }
    
    function getLot(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked('Lot #', StrUtil.toString(tokenId)));
    }
    
    function getCoords(uint256 tokenId) internal pure returns (string memory) {
        uint256 mod = tokenId % 100;
        uint256 divi = tokenId / 100;

        uint256 x = mod == 0 ? 100 : mod;
        uint256 y = mod == 0 ? divi : divi + 1;

        return string(abi.encodePacked('Coordinates: ','(',StrUtil.toString(x),',',StrUtil.toString(y),')'));
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, StrUtil.toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[19] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 360 360"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="goldenrod" /><text x="93" y="30" class="base">~ LAND TITLE - Lootland.xyz ~</text><text x="20" y="50" class="base">';

        parts[1] = getLot(tokenId);

        parts[2] = '</text><text x="20" y="70" class="base">';

        parts[3] = getCoords(tokenId);

        parts[4] = '</text><text x="20" y="90" class="base">Size: 10,000m x 10,000m</text><text x="115" y="120" class="base">~ Resource Licences ~</text><text x="20" y="140" class="base">';

        parts[5] = getFinance(tokenId);

        parts[6] = '</text><text x="20" y="160" class="base">';

        parts[7] = getSciCul(tokenId);

        parts[8] = '</text><text x="20" y="180" class="base">';

        parts[9] = getCommerce(tokenId);

        parts[10] = '</text><text x="20" y="200" class="base">';

        parts[11] = getRecreation(tokenId);

        parts[12] = '</text><text x="20" y="220" class="base">';

        parts[13] = getUtility(tokenId);

        parts[14] = '</text><text x="20" y="240" class="base">';

        parts[15] = getMineAndFarm(tokenId);

        parts[16] = '</text><text x="20" y="260" class="base">';

        parts[17] = getProduction(tokenId);

        parts[18] = '</text></svg>';


        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Lot #', StrUtil.toString(tokenId), '", "description": "Lootland is a collection of 10,000 NFTs - each proves your ownership of the virtual land and membership in Lootland.xyz", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function pubMint() public nonReentrant {
        require(_pubMintPaused != true, "Error: Public mint is paused");
        require(_pubTokenId < 10000, "Error: Token ID invalid");
        _firstPubTokenId = _pubTokenId;

        uint256 times = _claimTimes[msg.sender];

        require (times < 3, "Error: Invalid claim times");

        _safeMint(_msgSender(), _pubTokenId);

        _pubTokenId++;

        _claimTimes[msg.sender] = ++times;
    }

    function pausePubMint() public onlyOwner {
        _pubMintPaused = true;
    }

    function unpausePubMint() public onlyOwner {
        _pubMintPaused = false;
    }

    function isPubMintPaused() public view returns (bool) {
        return _pubMintPaused ;
    }

    function setMaxExclMintAllowed(uint256 max) public onlyOwner {
        require(_firstPubTokenId == 0, "Error: Can't change _maxExclAllowed, public mint has started");
        _maxExclAllowed = max;
        _pubTokenId = max + 1;
    }

    function maxExclMintAllowed() public view returns (uint256) {
        return _maxExclAllowed;
    }

    function exclMint(
        address recipient,
        address tokenAddress,
        bytes calldata signature
    ) external {
        bytes32 message = ExtSign.prefixed(keccak256(abi.encodePacked(
        recipient,
        tokenAddress
        )));

        require(ExtSign.recoverSigner(message, signature) == owner() , "Error: Invalid airdrop signature.");

        require(_exclTokenId < _maxExclAllowed + 1, "Error: Token ID invalid");

        uint256 times = _claimTimes[msg.sender];

        require(times < 5, "Error: Invalid claim times");

        _safeMint(_msgSender(), _exclTokenId);

        _exclTokenId++;

        _claimTimes[msg.sender] = ++times;
    }
    
    constructor() ERC721("Lootland.xyz", "LOOTLAND") Ownable() {}
}

library StrUtil {

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
}

library ExtSign {

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSig(sig);
    
        return ecrecover(message, v, r, s); // built-in function
    }

    function splitSig(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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