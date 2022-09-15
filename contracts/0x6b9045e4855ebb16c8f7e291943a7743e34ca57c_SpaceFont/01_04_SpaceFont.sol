//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/access/Ownable.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";

/// @title On-chain font for space grotesk font
/// @author @0x_beans
contract SpaceFont is Ownable {
    // font is > 24kb so we need to chunk it
    uint256 public constant FONT_PARTITION_1 = 0;
    uint256 public constant FONT_PARTITION_2 = 1;
    uint256 public constant FONT_PARTITION_3 = 2;
    uint256 public constant FONT_PARTITION_4 = 3;
    uint256 public constant FONT_PARTITION_5 = 4;

    mapping(uint256 => address) public files;

    // grab font
    function getFont() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SSTORE2.read(files[0]),
                    SSTORE2.read(files[1]),
                    SSTORE2.read(files[2]),
                    SSTORE2.read(files[3]),
                    SSTORE2.read(files[4])
                )
            );
    }

    // save font on chain. pain
    function saveFile(uint256 index, string calldata fileContent)
        public
        onlyOwner
    {
        files[index] = SSTORE2.write(bytes(fileContent));
    }
}