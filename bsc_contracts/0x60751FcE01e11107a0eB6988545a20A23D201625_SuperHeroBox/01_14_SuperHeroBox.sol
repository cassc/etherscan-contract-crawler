// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SuperHeroBox is ERC1155, Ownable, Pausable, ERC1155Burnable {

    using SafeMath for uint256;

    address public sellerAddress;

    address public cardAddress;

    mapping(uint256 => uint256) public priceMap;

    mapping(uint256 => uint256) public ironPriceMap;

    // mainnet usdt 0x55d398326f99059fF775485246999027B3197955
    // testnet usdt 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684
    address public fixedToken=0x55d398326f99059fF775485246999027B3197955;


    address public ironFixedToken=0xcED09A45B67cEef03196e8903c8707bb3989C3e3;

    constructor(address seller) ERC1155("https://www.marvelmetaverse.org/box/{id}.json") {
        sellerAddress = seller;
        // 100 usdt
        priceMap[1] = 100000000000000000000;
        // 500 usdt
        priceMap[2] = 500000000000000000000;
        // 2000 usdt
        priceMap[3] = 2000000000000000000000;
        // 5000 usdt
        priceMap[4] = 5000000000000000000000;

        // 30 iron
        ironPriceMap[1] = 30000000000000000000;
        // 500 iron
        ironPriceMap[2] = 500000000000000000000;
        // 2000 iron
        ironPriceMap[3] = 2000000000000000000000;
        // 5000 iron
        ironPriceMap[4] = 5000000000000000000000;
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

    function setFixedToken(address token) public onlyOwner {
        fixedToken = token;
    }

    function setIronFixedToken(address token) public onlyOwner {
        ironFixedToken = token;
    }

    function setCard(address card) public onlyOwner {
        cardAddress = card;
    }

    function setPrice(uint256 id, uint256 newPrice) public onlyOwner {
        priceMap[id] = newPrice;
    }

    function setIronPrice(uint256 id, uint256 newPrice) public onlyOwner {
        ironPriceMap[id] = newPrice;
    }

    function setSellerAddress(address seller) public onlyOwner {
        sellerAddress = seller;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        whenNotPaused
    {
        uint256 price = priceMap[id];
        require(price != 0, "can not get price");
        uint256 cost = price.mul(amount);
        require(IERC20(fixedToken).transferFrom(msg.sender, sellerAddress, cost), "Payment Error");
        _mint(account, id, amount, data);
    }

    function mintWithIron(address account, uint256 id, uint256 amount, bytes memory data)
        public
        whenNotPaused
    {
        uint256 price = ironPriceMap[id];
        require(price != 0, "can not get price");
        uint256 cost = price.mul(amount);
        require(IERC20(ironFixedToken).transferFrom(msg.sender, sellerAddress, cost), "Payment Error");
        _mint(account, id, amount, data);
    }

    function mintByOwner(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burnBox(address account, uint256 id) public {
        require(msg.sender == owner() || msg.sender == cardAddress, "unknown operator");
        _burn(account, id, 1);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}