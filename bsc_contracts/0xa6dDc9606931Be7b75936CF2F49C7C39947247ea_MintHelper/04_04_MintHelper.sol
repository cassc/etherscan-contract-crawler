// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface MintOnRareboard {
    function mint(
        address _collection,
        address _to,
        uint256 _amount
    )
        external
        payable;
    function priceFor(address _collection, address _user)
        external
        view
        returns (uint256);
    function maxSupplyOf(address _collection)
        external
        view
        returns (uint256);
    function totalSupplyOf(address _collection)
        external
        view
        returns (uint256); 
}

contract MintHelper {
    MintOnRareboard private constant MINTER = MintOnRareboard(0xd695ef1990f1DCc33AD5884128432b0e5F962481);

    function mint(address _collection, address _to, uint256 _amount, uint256 _maxPerTx) external payable {
        uint256 maxSupply = MINTER.maxSupplyOf(_collection);
        uint256 totalSupply = MINTER.totalSupplyOf(_collection);
        uint256 price_ = MINTER.priceFor(_collection, _to);

        uint256 mintable = maxSupply - totalSupply;
        _amount = _amount > mintable ? mintable : _amount;

        while (_amount > 0) {
            uint256 amount = _amount > _maxPerTx ? _maxPerTx : _amount;
            MINTER.mint{value: price_ * amount}(_collection, _to, amount);
            _amount -= amount;
        }

        payable(msg.sender).transfer(address(this).balance);
    }

    function price(address _collection, address _to) external view returns (uint256) {
        return MINTER.priceFor(_collection, _to);
    }
}