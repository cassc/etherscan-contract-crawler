// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

abstract contract AbstractERC1155Factory is
    IERC2981,
    Ownable,
    Pausable,
    ERC1155Supply,
    ERC1155Burnable
{
    string private _name;
    string private _symbol;
    string private _baseExtension;
    address private _royaltyReceiver;
    uint256 private _royaltyShare;

    constructor(
        string memory uri_,
        string memory baseExtension_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyShare_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        _baseExtension = baseExtension_;
        _royaltyReceiver = royaltyReceiver_;
        _royaltyShare = royaltyShare_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function setbBaseExtension(string memory baseExtension_)
        external
        onlyOwner
    {
        _baseExtension = baseExtension_;
    }

    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        _royaltyReceiver = royaltyReceiver_;
    }

    function setRoyaltyShare(uint256 royaltyShare_) external onlyOwner {
        _royaltyShare = royaltyShare_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(exists(tokenId), "Non-existent token");
        return (royaltyReceiver(), (salePrice * royaltyShare()) / 10000);
    }

    function baseExtension() public view returns (string memory) {
        return _baseExtension;
    }

    function royaltyReceiver() public view returns (address) {
        return _royaltyReceiver;
    }

    function royaltyShare() public view returns (uint256) {
        return _royaltyShare;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
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
}