// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./utils/AdminPermissionable.sol";

abstract contract IntandemERC1155 is ERC1155Supply, ERC1155Burnable, AdminPermissionable {
    using SafeMath for uint256;
    string  name_;
    string  symbol_;
    mapping(address => uint[]) internal holdings;

    struct MintToken {
        string ipfsMetadataLink;
        uint256 mintedCount;
        uint256 maxSupply;
        uint256 mintPerTransLimit;
        mapping(address => uint256) claimedMTs;
    }

    function setURI(string memory baseURI) external onlyAdmin {
        _setURI(baseURI);
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }


    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mint(account, id, amount, data);
    }

    function balanceOf(address account, uint256 id) public view virtual override(ERC1155) returns (uint256){
        return super.balanceOf(account, id);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155) {
        super._burnBatch(account, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawAllFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawFunds(address payable _to, uint256 _amount) external onlyOwner
    {
        require(_to != address(0), "cant send money to null address");
        _to.transfer(_amount);
    }

    function getBalance() external view returns (uint256){
        return address(this).balance;
    }
}