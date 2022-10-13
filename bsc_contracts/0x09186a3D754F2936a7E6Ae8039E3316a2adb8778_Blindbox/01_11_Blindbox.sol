// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blindbox is ERC1155, Ownable {
    uint256 public constant NORMAL = 0;
    uint256 public constant RARE = 1;
    uint256 public constant EPIC = 2;
    uint256 public constant LEGENDARY = 3;
    uint256 public constant MYTHIC = 4;

    constructor()
        ERC1155("https://blindbox.kingdomraids.io/api/box/{id}.json")
    {
        _mint(msg.sender, NORMAL, 100000, "");
        _mint(msg.sender, RARE, 7500, "");
        _mint(msg.sender, EPIC, 2500, "");
        _mint(msg.sender, LEGENDARY, 40, "");
        _mint(msg.sender, MYTHIC, 4, "");
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _mint(_to, _tokenId, _amount, "");
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        _burn(_from, _tokenId, _amount);
    }

    function burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external {
        _burnBatch(_from, _ids, _amounts);
    }

    function setUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }
}