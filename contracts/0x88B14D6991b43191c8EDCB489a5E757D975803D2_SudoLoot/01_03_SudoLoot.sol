// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract SudoLoot is ERC721A, ReentrancyGuard, Ownable {
    string[] private Names = [
        "Warlax",
        "Artiryu",
        "Warbat",
        "Lacuno",
        "Maromoth",
        "Polito",
        "Omarados",
        "Dragoly",
        "Porycool",
        "Vilelith",
        "Venobell",
        "Aeroly",
        "Maronyte",
        "Omageot",
        "Laros",
        "Larow",
        "Vilecute",
        "Blasway",
        "Electratops",
        "Clepuff",
        "Artislash",
        "Lachu",
        "Electrawrath",
        "Zaptales"
    ];

    string[] private Location = [
        "Celalet",
        "Cerudon",
        "Cinnasia",
        "Fuchdon",
        "Lavenbar",
        "Paldon",
        "Fuchdian",
        "Verfron",
        "Safbar",
        "Virisia"
    ];

    string[] private Ability1 = [
        "StringDrill",
        "HyperDrill",
        "Leechwind",
        "WaterLeaf",
        "DragonSludge",
        "HypnosisSlap",
        "AcidWing",
        "DragonSlam",
        "QuickSurf",
        "BarrierKick",
        "SeismicBolt",
        "HydroDance",
        "FlameDance",
        "SeismicEnergy",
        "FocusRoar",
        "BlizzardScreen",
        "StrengthAttack",
        "ToxicScreen",
        "EmberFly",
        "MegaQuake",
        "SeismicRazor",
        "HyperKick",
        "SleepRage",
        "PsychicAttack"
    ];

    string[] private Ability2 = [
        "StringDrill",
        "HyperDrill",
        "Leechwind",
        "WaterLeaf",
        "DragonSludge",
        "HypnosisSlap",
        "AcidWing",
        "DragonSlam",
        "QuickSurf",
        "BarrierKick",
        "SeismicBolt",
        "HydroDance",
        "FlameDance",
        "SeismicEnergy",
        "FocusRoar",
        "BlizzardScreen",
        "StrengthAttack",
        "ToxicScreen",
        "EmberFly",
        "MegaQuake",
        "SeismicRazor",
        "HyperKick",
        "SleepRage",
        "PsychicAttack"
    ];

    string[] private Type = [
        "Normal",
        "Fire",
        "Water",
        "Grass",
        "Electric",
        "Ice",
        "Fighting",
        "Poison",
        "Ground",
        "Flying",
        "Psychic",
        "Bug",
        "Rock",
        "Ghost",
        "Dragon",
        "Steel",
        "Dark",
        "Fairy"
    ];

    string[] private Rarity = [
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Shiny"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getNames(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NAMES", Names);
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LOCATION", Location);
    }

    function getAbility1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABILITY1", Ability1);
    }

    function getAbility2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ABILITY2", Ability2);
    }

    function getType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TYPE", Type);
    }

    function getRarity(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RARITY", Rarity);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #000000; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#bab7db" /><text x="10" y="20" class="base">';

        parts[1] = getNames(tokenId);
        (tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getLocation(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getAbility1(tokenId);
        (tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getAbility2(tokenId);
        (tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getType(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getRarity(tokenId);
        (tokenId);

        parts[12] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[7],
                parts[8],
                parts[9],
                parts[10],
                parts[11],
                parts[12]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "SudoBag #',
                        toString(tokenId),
                        '", "description": "Sudo Loot is a randomly generated name, abilities, and information inspired by 0xmon and Loot. The metadata are being stored on the Ethereum blockchain. For future implementation, stats, levels, and pictures are intentionally omitted", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
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

    constructor() ERC721A("SudoLoot", "SUDOLOOT") Ownable() {
        _safeMint(_msgSender(), 1000);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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