// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ERC1155Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


/**
 * @title ParadiseEgg
 * ParadiseEgg - a contract for the Paradise Egg
 */

contract ParadiseEgg is ERC1155Tradable {

    using SafeMath for uint256;

    constructor(
        address _proxyRegistryAddress
    ) ERC1155Tradable(
        "Paradise Trippy Eggs", 
        "TRIPPYEGG",
        "",
        _proxyRegistryAddress
    ) {
        create(msg.sender, 1, 1, "https://api-egg.paradise.com/token/1", "");
        create(msg.sender, 2, 1, "https://api-egg.paradise.com/token/2", "");
        create(msg.sender, 3, 1, "https://api-egg.paradise.com/token/3", "");
    }

    function airdrop(address[] memory _addrs, uint256 _quantity, uint256 _id)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _mint(_addrs[i], _id, _quantity, "");
            tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}