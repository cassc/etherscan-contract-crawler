// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {

    event Minted(address, uint);
    event Bought(address, uint);

    uint256 private _price = 170000000000000 wei;
    uint256 private _tokenOnDrop;

    constructor() ERC20("Logarithm", "LOGG") {}

    function mint(uint amount, address to) public onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function buy() public payable {
        uint count = msg.value / _price;
        require(count <= _tokenOnDrop, "No have this count");
        require(count > 0, "We dont have money");

        _tokenOnDrop -= count;
        _mint(_msgSender(), count);

        emit Bought(_msgSender(), count);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setPrice(uint256 price_) public onlyOwner {
        _price = price_;
    }

    function getDropCount() public view returns (uint256){
        return _tokenOnDrop;
    }

    function setDropCount(uint256 count) public onlyOwner {
        _tokenOnDrop = count;
    }

    function sendMoney(uint _value) public onlyOwner {
        require(_value <= address(this).balance);
        payable(_msgSender()).transfer(_value);
    }

}