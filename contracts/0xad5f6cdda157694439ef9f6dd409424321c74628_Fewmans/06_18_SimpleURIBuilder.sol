//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IURIBuilder.sol";
import "./Fewmans.sol";

contract SimpleURIBuilder is IURIBuilder {
    Fewmans private immutable fewmans;

    constructor(Fewmans fewmans_) {
        fewmans = fewmans_;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory baseURI = "http://few.fewmans.com/";
        uint8[8] memory state = fewmans.personality(tokenId);
        string memory gender = tokenId % 2 == 0 ? "f" : "m";
        for (uint8 i = 0; i < 8; i++) state[i] += 48;
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "0x",
                    toHexString(tokenId),
                    gender,
                    state,
                    ".json"
                )
            );
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

    function toHexString(uint256 a) public pure returns (string memory) {
        uint256 count = 4;
        uint256 b = a;
        bytes memory res = new bytes(count);
        for (uint256 i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(res);
    }
}