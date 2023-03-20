// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import {RenderConstant} from "src/lib/RenderConstant.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {strings} from "src/lib/strings.sol";

library Renderer {
    using strings for *;

    function renderByTokenId(
        mapping(uint256 => IRebornDefination.LifeDetail) storage details,
        uint256 tokenId
    ) public view returns (string memory) {
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    "Degen Tombstone",
                    '","description":"',
                    "",
                    '","image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            renderSvg(
                                details[tokenId].seed,
                                details[tokenId].score,
                                details[tokenId].round,
                                details[tokenId].age,
                                details[tokenId].creatorName,
                                details[tokenId].cost
                            )
                        )
                    ),
                    '","attributes": ',
                    renderTrait(
                        details[tokenId].seed,
                        details[tokenId].score,
                        details[tokenId].round,
                        details[tokenId].age,
                        details[tokenId].creator,
                        details[tokenId].creatorName,
                        details[tokenId].reward,
                        details[tokenId].cost
                    ),
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", metadata);
    }

    function renderSvg(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        string memory creatorName,
        uint256 cost
    ) public pure returns (string memory) {
        string memory Part1 = _renderSvgPart1(seed, lifeScore, round, age);
        string memory Part2 = _renderSvgPart2(creatorName, cost);
        return string(abi.encodePacked(Part1, Part2));
    }

    function renderTrait(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age,
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _renderTraitPart1(seed, lifeScore, round, age),
                    _renderTraitPart2(creator, creatorName, reward, cost)
                )
            );
    }

    function _renderTraitPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Seed", "value": "',
                    Strings.toHexString(uint256(seed), 32),
                    '"},{"trait_type": "Life Score", "value": ',
                    Strings.toString(lifeScore),
                    '},{"trait_type": "Round", "value": ',
                    Strings.toString(round),
                    '},{"trait_type": "Age", "value": ',
                    Strings.toString(age)
                )
            );
    }

    function _renderTraitPart2(
        address creator,
        string memory creatorName,
        uint256 reward,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '},{"trait_type": "Creator", "value": "',
                    Strings.toHexString(uint160(creator), 20),
                    '"},{"trait_type": "CreatorName", "value": "',
                    creatorName,
                    '"},{"trait_type": "Reward", "value": ',
                    Strings.toString(reward),
                    '},{"trait_type": "Cost", "value": ',
                    Strings.toString(cost),
                    "}]"
                )
            );
    }

    function _renderSvgPart1(
        bytes32 seed,
        uint256 lifeScore,
        uint256 round,
        uint256 age
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P1(),
                    _transformBytes32Seed(seed),
                    RenderConstant.P2(),
                    _transformUint256(lifeScore),
                    RenderConstant.P3(),
                    Strings.toString(round),
                    RenderConstant.P4(),
                    Strings.toString(age)
                )
            );
    }

    function _renderSvgPart2(
        string memory creator,
        uint256 cost
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RenderConstant.P5(),
                    _compressUtf8(creator),
                    RenderConstant.P6(),
                    _tranformWeiToDecimal2(cost),
                    RenderConstant.P7()
                )
            );
    }

    function _tranformWeiToDecimal2(
        uint256 value
    ) public pure returns (string memory str) {
        if (value > 100 ether) {
            return Strings.toString(value / 1 ether);
        } else {
            uint256 secondFractional = value % (1 ether / 10);
            uint256 firstFractional = (value - secondFractional) % (1 ether);
            uint256 integer;
            if (firstFractional != 0 || secondFractional != 0) {
                integer = value - firstFractional - secondFractional;
            } else {
                integer = value;
            }

            return
                string.concat(
                    Strings.toString(integer / 1 ether),
                    ".",
                    Strings.toString(firstFractional / 10 ** 17),
                    Strings.toString(secondFractional / 10 ** 16)
                );
        }
    }

    function _transformUint256(
        uint256 value
    ) public pure returns (string memory str) {
        if (value < 10 ** 7) {
            return _recursiveAddComma(value);
        } else if (value < 10 ** 11) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 6), "M")
                );
        } else if (value < 10 ** 15) {
            return
                string(
                    abi.encodePacked(_recursiveAddComma(value / 10 ** 9), "B")
                );
        } else {
            revert ValueOutOfRange();
        }
    }

    function _recursiveAddComma(
        uint256 value
    ) internal pure returns (string memory str) {
        if (value / 1000 == 0) {
            str = string(abi.encodePacked(Strings.toString(value), str));
        } else {
            str = string(
                abi.encodePacked(
                    _recursiveAddComma(value / 1000),
                    ",",
                    _numberStringToLengthThree(Strings.toString(value % 1000)),
                    str
                )
            );
        }
    }

    function _transformBytes32Seed(
        bytes32 b
    ) public pure returns (string memory) {
        string memory str = Strings.toHexString(uint256(b), 32);
        return
            string(
                abi.encodePacked(
                    _substring(str, 0, 14),
                    unicode"…",
                    _substring(str, 45, 66)
                )
            );
    }

    function _numberStringToLengthThree(
        string memory number
    ) internal pure returns (string memory) {
        if (bytes(number).length == 1) {
            return string(abi.encodePacked("00", number));
        } else if (bytes(number).length == 2) {
            return string(abi.encodePacked("0", number));
        } else {
            return number;
        }
    }

    error ValueOutOfRange();

    function _shortenAddr(address addr) private pure returns (string memory) {
        uint256 value = uint160(addr);
        bytes memory allBytes = bytes(Strings.toHexString(value, 20));

        string memory newString = string(allBytes);

        return
            string(
                abi.encodePacked(
                    _substring(newString, 0, 6),
                    unicode"…",
                    _substring(newString, 38, 42)
                )
            );
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _compressUtf8(
        string memory str
    ) public pure returns (string memory res) {
        strings.slice memory sl = str.toSlice();
        strings.slice memory resl = res.toSlice();

        uint256 length = sl.len();
        if (length > 12) {
            for (uint256 i = 0; i < 5; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            for (uint256 i = 5; i < length - 7; i++) {
                sl.nextRune().toString();
            }

            resl = resl.concat(unicode"…".toSlice()).toSlice();
            for (uint256 i = length - 7; i < length; i++) {
                resl = resl.concat(sl.nextRune()).toSlice();
            }
            return resl.toString();
        }
        return str;
    }
}