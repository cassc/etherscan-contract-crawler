// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract SwordOfBravery is Ownable, ERC1155Pausable, ERC1155Burnable {
    using Strings for uint256;
    using ECDSA for bytes32;

    mapping(address => bool) private __wakumbas;
    mapping(address => uint16) private __claimedAmt;

    constructor(string memory url) ERC1155(url) {}

    function isValidSignature(
        address addr,
        uint16 amt,
        uint16 maxAmt,
        bytes memory signature
    ) public view returns (bool) {
        return owner() == keccak256(abi.encodePacked(addr, amt, maxAmt)).toEthSignedMessageHash().recover(signature);
    }

    function airdrop(
        address to,
        uint16 amount,
        uint16 maxAmt,
        bytes calldata signature
    ) public {
        require(_msgSender() == to, 'Invalid caller');
        require(isValidSignature(to, amount, maxAmt, signature), 'Invalid signature');
        __claimedAmt[_msgSender()] += amount;
        _mint(to, 0, amount, abi.encodePacked(maxAmt));
        require(__claimedAmt[_msgSender()] <= maxAmt, 'max amount exceeded');
    }

    function mint(
        address to,
        uint256 id,
        uint16 amount,
        bytes memory data
    ) public onlyWakumbas {
        _mint(to, id, amount, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addWakumba(address addr) public onlyOwner {
        __wakumbas[addr] = true;
    }

    function removeWakumba(address addr) public onlyOwner {
        __wakumbas[addr] = false;
    }

    modifier onlyWakumbas() {
        require(__wakumbas[_msgSender()], 'Only Wakumba is allowed');
        _;
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        if (__wakumbas[operator]) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = super.uri(0);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function claimed(address user) public view returns (uint16) {
        return __claimedAmt[user];
    }
}