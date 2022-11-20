// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Parts is ERC1155, Ownable, ERC1155Supply {
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    mapping(uint256 => uint16) TOKEN_ID_TO_PART_TYPE;
    uint256 PART_TYPE_0 = 0;
    uint256 PART_TYPE_1 = 1;
    uint256 PART_TYPE_2 = 2;
    uint256 PART_TYPE_3 = 3;
    uint256 PUBLIC_PARTS_SUPPLY = 12572;
    uint256 PRIVATE_PARTS_SUPPLY = 400;
    uint256 PRIVATE_PARTS_MINTED = 0;
    uint256 PUBLIC_PARTS_MINTED = 0;
    uint256 MAX_PART_SUPPLY = 3244;
    uint256[] PART_TYPE_0_IDS = [0];
    uint256[] PART_TYPE_1_IDS = [1];
    uint256[] PART_TYPE_2_IDS = [2];
    uint256[] PART_TYPE_3_IDS = [3];
    uint256[] AIRDROP_AMOUNT = [4];

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(totalSupply(id) < MAX_PART_SUPPLY, "Max supply reached");
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                totalSupply(ids[i]) < MAX_PART_SUPPLY,
                string(
                    abi.encodePacked(
                        "Max supply reached for id: ",
                        Strings.toString(ids[i])
                    )
                )
            );
        }
        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(
        address[] memory _part0Addresses,
        address[] memory _part1Addresses,
        address[] memory _part2Addresses,
        address[] memory _part3Addresses
    ) public onlyOwner {
        for (uint256 i = 0; i < _part0Addresses.length; i++) {
            safeBatchTransferFrom(
                msg.sender,
                _part0Addresses[i],
                PART_TYPE_0_IDS,
                AIRDROP_AMOUNT,
                ""
            );
        }
        for (uint256 i = 0; i < _part1Addresses.length; i++) {
            safeBatchTransferFrom(
                msg.sender,
                _part1Addresses[i],
                PART_TYPE_1_IDS,
                AIRDROP_AMOUNT,
                ""
            );
        }
        for (uint256 i = 0; i < _part2Addresses.length; i++) {
            safeBatchTransferFrom(
                msg.sender,
                _part2Addresses[i],
                PART_TYPE_2_IDS,
                AIRDROP_AMOUNT,
                ""
            );
        }
        for (uint256 i = 0; i < _part3Addresses.length; i++) {
            safeBatchTransferFrom(
                msg.sender,
                _part3Addresses[i],
                PART_TYPE_3_IDS,
                AIRDROP_AMOUNT,
                ""
            );
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}