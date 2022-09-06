// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzepplin/token/ERC1155/ERC1155.sol";
import "openzepplin/utils/Strings.sol";

contract SampleERC1155 is ERC1155 {
    uint256 public constant Rock = 1;
    uint256 public constant Paper = 2;
    uint256 public constant Scissors = 3;

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/{id}.json") {
        _mint(msg.sender, Rock, 1, "");
        _mint(msg.sender, Paper, 1, "");
        _mint(msg.sender, Scissors, 1, "");
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/",
                Strings.toString(_tokenid),".json"
            )
        );
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        _burnBatch(from, ids, amounts);
    }
}