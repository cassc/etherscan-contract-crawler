// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metamorphosis is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("") {}

    mapping(uint256 => string) uriMapping;
    mapping(uint256 => uint256) maxSupplyMapping;

    function setURI(uint256 id, string memory newURI) public onlyOwner {
        uriMapping[id] = newURI;
    }

    function setMaxSupply(uint256 id, uint256 supply) public onlyOwner {
        require(
            this.totalSupply(id) < supply,
            "Supply limit lower than current supply"
        );
        maxSupplyMapping[id] = supply;
    }

    function getMaxSupply(uint256 id) public view returns (uint256) {
        return maxSupplyMapping[id];
    }

    function airdrop(
        uint256 id,
        address[] calldata _list,
        uint256 count
    ) external onlyOwner {
        if (maxSupplyMapping[id] != 0) {
            require(
                this.totalSupply(id) + _list.length <= maxSupplyMapping[id],
                "AirDrop will break the supply limit"
            );
        }
        for (uint256 i = 0; i < _list.length; i++) {
            _mint(_list[i], id, count, "");
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        if (maxSupplyMapping[id] != 0) {
            require(
                this.totalSupply(id) + amount <= maxSupplyMapping[id],
                "Mint will break the supply limit"
            );
        }
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            if (maxSupplyMapping[ids[i]] != 0) {
                require(
                    this.totalSupply(ids[i]) + amounts[i] <=
                        maxSupplyMapping[ids[i]],
                    "Batch mint will break the supply limit"
                );
            }
        }
        _mintBatch(to, ids, amounts, data);
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

    function uri(uint256 _tokenid)
        public
        view
        override
        returns (string memory)
    {
        return (uriMapping[_tokenid]);
    }
}