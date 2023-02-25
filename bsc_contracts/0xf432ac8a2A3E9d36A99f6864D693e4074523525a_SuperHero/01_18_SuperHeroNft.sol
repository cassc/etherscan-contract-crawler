// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SuperHeroBox.sol";

contract SuperHero is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {

    address public box;

    address public boxOwner;

    constructor(address boxContract, address boxowner) ERC1155("https://www.marvelmetaverse.org/card/{id}.json") {
        box = boxContract;
        boxOwner = boxowner;
    }

    function setBoxOwner(address boxowner) public onlyOwner {
        boxOwner = boxowner;
    }

    function setBox(address box_ontract) public onlyOwner {
        box = box_ontract;
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

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function openBox(address account, uint256 boxId, bytes calldata message, bytes calldata signature) public {
        require(SuperHeroBox(box).balanceOf(account, boxId) > 0, "no box");

        address source = verifyMessage(message, signature);
        require(source == boxOwner, "Error signed message");

        (uint256 cardId, uint256 amount) = abi.decode(message, (uint256, uint256));
        _mint(account, cardId, amount, "");
        SuperHeroBox(box).burnBox(account, boxId);
    }

    function verifyMessage(bytes memory message, bytes memory signature) internal pure returns (address) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(message);
        return ECDSA.recover(hash, signature);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function balanceOfRange(address account, uint256 beginId, uint256 endId)
        public
        view
        returns (uint256[] memory)
    {
        require(beginId <= endId, "ERC1155: error range");
        uint256 len = endId - beginId + 1;
        uint256[] memory batchBalances = new uint256[](len);

        for (uint256 i = beginId; i <= endId; ++i) {
            batchBalances[i] = balanceOf(account, i);
        }

        return batchBalances;
    }
}