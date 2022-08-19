// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Hinata1155 is ERC1155Supply {
    using Strings for uint256;

    string public name;
    string public symbol;
    address public owner;
    string public baseURI;

    modifier onlyOwner() {
        require(msg.sender == owner, "Hinata1155: NOT_OWNER");
        _;
    }

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) {
        require(owner_ != address(0), "Hinata1155: INVALID_OWNER");
        owner = owner_;
        name = name_;
        symbol = symbol_;
        baseURI = uri_;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return
            (string)(
                abi.encodePacked(
                    baseURI,
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/",
                    id.toString()
                )
            );
    }
}