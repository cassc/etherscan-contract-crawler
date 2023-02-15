// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISouvenir.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./utils/MinterAccessControl.sol";

contract Souvenir is
    ISouvenir,
    ERC1155Supply,
    Ownable,
    MinterAccessControl
{
    string private baseURI = "";

    string public constant name = "NFTOO Collectibles";
    string public constant symbol = "OOC";


    constructor() ERC1155("") {
    }

    function uri(
        uint256 _tokenid
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenid)
                )
            );
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }


    function mint(address _to, uint256 _tokenId, uint256 _amount) external onlyMinter {
        _mint(_to, _tokenId, _amount, "");
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
    * @notice Service function to add address into MinterRole
    *
    * @dev this function can only be called by Owner
    *
    * @param addr_ an address which is adding into MinterRole
    */
    function grantMinterRole(address addr_) external onlyOwner {
        _grantMinterRole(addr_);
    }

    /**
    * @notice Service function to remove address into MinterRole
    *
    * @dev this function can only be called by Owner
    *
    * @param addr_ an address which is removing from MinterRole
    */
    function revokeMinterRole(address addr_) external onlyOwner {
        _revokeMinterRole(addr_);
    }
}