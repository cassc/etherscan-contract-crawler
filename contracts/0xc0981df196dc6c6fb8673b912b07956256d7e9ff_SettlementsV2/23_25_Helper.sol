// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";
import "./SettlementsV2.sol";
import "./ERC20Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Helpers is Ownable {
    function _makeLegacyParts(
        string memory size,
        string memory spirit,
        string memory age,
        string memory resource,
        string memory morale,
        string memory government,
        string memory realm
    ) public pure returns (string[18] memory) {
        string[18] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.txt { fill: black; font-family: monospace; font-size: 12px;}</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="txt">';
        parts[1] = size;
        parts[2] = '</text><text x="10" y="40" class="txt">';
        parts[3] = spirit;
        parts[4] = '</text><text x="10" y="60" class="txt">';
        parts[5] = age;
        parts[6] = '</text><text x="10" y="80" class="txt">';
        parts[7] = resource;
        parts[8] = '</text><text x="10" y="100" class="txt">';
        parts[9] = morale;
        parts[10] = '</text><text x="10" y="120" class="txt">';
        parts[11] = government;
        parts[12] = '</text><text x="10" y="140" class="txt">';
        parts[13] = realm;
        parts[14] = "</text></svg>";
        return parts;
    }

    function _makeLegacyAttributeParts(string[18] memory parts)
        public
        pure
        returns (string[18] memory)
    {
        string[18] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Size", "value": "';
        attrParts[1] = parts[1];
        attrParts[2] = '" }, { "trait_type": "Spirit", "value": "';
        attrParts[3] = parts[3];
        attrParts[4] = '" }, { "trait_type": "Age", "value": "';
        attrParts[5] = parts[5];
        attrParts[6] = '" }, { "trait_type": "Resource", "value": "';
        attrParts[7] = parts[7];
        attrParts[8] = '" }, { "trait_type": "Morale", "value": "';
        attrParts[9] = parts[9];
        attrParts[10] = '" }, { "trait_type": "Government", "value": "';
        attrParts[11] = parts[11];
        attrParts[12] = '" }, { "trait_type": "Realm", "value": "';
        attrParts[13] = parts[13];
        attrParts[14] = '" }]';
        return attrParts;
    }

    function _makeParts(
        string memory size,
        string memory spirit,
        string memory age,
        string memory resource,
        string memory morale,
        string memory government,
        string memory realm,
        uint256 unharvestedTokenAmount,
        string memory tokenSymbol
    ) public pure returns (string[18] memory) {
        string[18] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.txt { fill: black; font-family: monospace; font-size: 12px;}</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="txt">';
        parts[1] = size;
        parts[2] = '</text><text x="10" y="40" class="txt">';
        parts[3] = spirit;
        parts[4] = '</text><text x="10" y="60" class="txt">';
        parts[5] = age;
        parts[6] = '</text><text x="10" y="80" class="txt">';
        parts[7] = resource;
        parts[8] = '</text><text x="10" y="100" class="txt">';
        parts[9] = morale;
        parts[10] = '</text><text x="10" y="120" class="txt">';
        parts[11] = government;
        parts[12] = '</text><text x="10" y="140" class="txt">';
        parts[13] = realm;
        parts[14] = '</text><text x="10" y="160" class="txt">';
        parts[15] = "------------";
        parts[16] = '</text><text x="10" y="180" class="txt">';
        parts[17] = string(
            abi.encodePacked(
                "$",
                tokenSymbol,
                ": ",
                Strings.toString(unharvestedTokenAmount / 10**18),
                "</text></svg>"
            )
        );

        return parts;
    }

    function _makeAttributeParts(
        string memory size,
        string memory spirit,
        string memory age,
        string memory resource,
        string memory morale,
        string memory government,
        string memory realm,
        uint256 unharvestedTokenAmount,
        string memory tokenSymbol
    ) public pure returns (string[18] memory) {
        string[18] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Size", "value": "';
        attrParts[1] = size;
        attrParts[2] = '" }, { "trait_type": "Spirit", "value": "';
        attrParts[3] = spirit;
        attrParts[4] = '" }, { "trait_type": "Age", "value": "';
        attrParts[5] = age;
        attrParts[6] = '" }, { "trait_type": "Resource", "value": "';
        attrParts[7] = resource;
        attrParts[8] = '" }, { "trait_type": "Morale", "value": "';
        attrParts[9] = morale;
        attrParts[10] = '" }, { "trait_type": "Government", "value": "';
        attrParts[11] = government;
        attrParts[12] = '" }, { "trait_type": "Realm", "value": "';
        attrParts[13] = realm;
        attrParts[14] = '" }, { "trait_type": ';
        attrParts[15] = string(abi.encodePacked('"$', tokenSymbol, '", "value": '));

        attrParts[16] = string(
            abi.encodePacked('"', Strings.toString(unharvestedTokenAmount / 10**18), '"')
        );

        attrParts[17] = " }]";
        return attrParts;
    }

    struct TokenURIInput {
        string size;
        string spirit;
        string age;
        string resource;
        string morale;
        string government;
        string realm;
    }

    function tokenURI(
        TokenURIInput memory tokenURIInput,
        uint256 unharvestedTokenAmount,
        string memory tokenSymbol,
        bool useLegacy,
        uint256 tokenId
    ) public view returns (string memory) {
        string[18] memory parts;
        string[18] memory attributesParts;

        if (useLegacy) {
            parts = _makeLegacyParts(
                tokenURIInput.size,
                tokenURIInput.spirit,
                tokenURIInput.age,
                tokenURIInput.resource,
                tokenURIInput.morale,
                tokenURIInput.government,
                tokenURIInput.realm
            );

            attributesParts = _makeLegacyAttributeParts(
                _makeLegacyParts(
                    tokenURIInput.size,
                    tokenURIInput.spirit,
                    tokenURIInput.age,
                    tokenURIInput.resource,
                    tokenURIInput.morale,
                    tokenURIInput.government,
                    tokenURIInput.realm
                )
            );
        } else {
            parts = _makeParts(
                tokenURIInput.size,
                tokenURIInput.spirit,
                tokenURIInput.age,
                tokenURIInput.resource,
                tokenURIInput.morale,
                tokenURIInput.government,
                tokenURIInput.realm,
                unharvestedTokenAmount,
                tokenSymbol
            );

            attributesParts = _makeAttributeParts(
                tokenURIInput.size,
                tokenURIInput.spirit,
                tokenURIInput.age,
                tokenURIInput.resource,
                tokenURIInput.morale,
                tokenURIInput.government,
                tokenURIInput.realm,
                unharvestedTokenAmount,
                tokenSymbol
            );
        }

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(abi.encodePacked(output, parts[17]));

        string memory atrrOutput = string(
            abi.encodePacked(
                attributesParts[0],
                attributesParts[1],
                attributesParts[2],
                attributesParts[3],
                attributesParts[4],
                attributesParts[5],
                attributesParts[6],
                attributesParts[7],
                attributesParts[8]
            )
        );
        atrrOutput = string(
            abi.encodePacked(
                atrrOutput,
                attributesParts[9],
                attributesParts[10],
                attributesParts[11],
                attributesParts[12],
                attributesParts[13],
                attributesParts[14]
            )
        );

        atrrOutput = string(
            abi.encodePacked(
                atrrOutput,
                attributesParts[15],
                attributesParts[16],
                attributesParts[17]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Settlement #',
                        Strings.toString(tokenId),
                        '", "description": "Settlements are a turn based civilisation simulator stored entirely on chain, go forth and conquer.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"',
                        ',"attributes":',
                        atrrOutput,
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    uint8[] public civMultipliers;
    uint8[] public realmMultipliers;
    uint8[] public moralMultipliers;

    uint256 constant ONE = 10**18;

    function setMultipliers(
        uint8[] memory civMultipliers_,
        uint8[] memory realmMultipliers_,
        uint8[] memory moralMultipliers_
    ) public onlyOwner {
        civMultipliers = civMultipliers_;
        realmMultipliers = realmMultipliers_;
        moralMultipliers = moralMultipliers_;
    }

    function getUnharvestedTokens(uint256 tokenId, SettlementsV2.Attributes memory attributes)
        public
        view
        returns (ERC20Mintable, uint256)
    {
        SettlementsV2 caller = SettlementsV2(msg.sender);

        uint256 lastHarvest = caller.tokenIdToLastHarvest(tokenId);
        uint256 blockDelta = block.number - lastHarvest;

        ERC20Mintable tokenAddress = caller.resourceTokenAddresses(attributes.resource);

        if (blockDelta == 0 || lastHarvest == 0) {
            return (tokenAddress, 0);
        }

        uint256 realmMultiplier = realmMultipliers[attributes.turns];
        uint256 civMultiplier = civMultipliers[attributes.size];
        uint256 moralMultiplier = moralMultipliers[attributes.morale];
        uint256 tokensToMint = (civMultiplier *
            blockDelta *
            moralMultiplier *
            ONE *
            realmMultiplier) / 300;

        return (tokenAddress, tokensToMint);
    }
}