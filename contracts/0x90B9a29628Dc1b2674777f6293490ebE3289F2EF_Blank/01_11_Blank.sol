// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

import './interfaces/IBlank.sol';

contract Blank is IBlank, ERC1155, Ownable {
    string public constant name = 'RENS Metahoodie';
    string public constant symbol = 'RENM';

    mapping(uint256 => uint256) public allocations;
    mapping(uint256 => uint256) public minted;

    mapping(address => bool) private _operators;

    constructor(string memory uri) ERC1155(uri) {}

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function mint(
        address recipient,
        uint256 tokenId,
        uint256 quantity
    ) external onlyOperator {
        require(
            minted[tokenId] + quantity <= allocations[tokenId],
            'Out of stock'
        );

        _mint(recipient, tokenId, quantity, '');

        minted[tokenId] += quantity;
    }

    modifier onlyOperator() {
        require(_operators[_msgSender()], 'Unauthorized');
        _;
    }

    function setOperators(address[] calldata users, bool remove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            _operators[users[i]] = !remove;
        }
    }

    function setAllocations(uint256 tokenId, uint256 allocation)
        external
        onlyOwner
    {
        allocations[tokenId] = allocation;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            'ERC1155: caller is not token owner nor approved'
        );

        _burn(account, id, value);
    }
}