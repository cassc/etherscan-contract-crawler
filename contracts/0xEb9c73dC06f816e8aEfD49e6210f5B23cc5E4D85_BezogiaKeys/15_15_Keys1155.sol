// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "../../accessControl/AccessProtected.sol";

contract BezogiaKeys is ERC1155, Pausable,ERC1155Burnable,AccessProtected {
    using Strings for uint256;

    bool public transferPause; 
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC1155(baseURI_) {

        name = name_;
        symbol = symbol_;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateTranferStatus(bool value)external onlyOwner{
        transferPause = value;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyAdmin
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyAdmin
    {
        _mintBatch(to, ids, amounts, data);
    }

    function mintLoop(address[] memory to, uint256[] memory ids, uint256[] memory amounts) 
        public 
        onlyAdmin
    {
        for(uint256 i=0; i< to.length;i++){
            _mint(to[i], ids[i], amounts[i], "0x");
        }

    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        require(!transferPause, "NFT transfers paused");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        string memory baseURI = uri(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function ownerBurn(address account, uint256 id, uint256 amount)public onlyAdmin{
        _burn(account, id, amount);
    }
}