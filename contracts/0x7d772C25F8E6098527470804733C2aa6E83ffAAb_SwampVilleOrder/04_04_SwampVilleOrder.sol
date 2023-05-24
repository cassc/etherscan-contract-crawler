// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "hardhat/console.sol";

contract SwampVilleOrder is Ownable {
    using SafeMath for uint;

    event Order(address buyer, uint quantity);

    uint public price = 0.033 ether;
    bool public isOrderActivated;

    mapping(address => uint) public userClaimableQuantity;

    constructor() {
        isOrderActivated = true;
    }

    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    function setOrderActive(bool active_) public onlyOwner {
        isOrderActivated = active_;
    }

    function order(uint qty_) public payable {
        require(
            isOrderActivated,
            "SwampVilleOrder: Ordering is not activated."
        );
        require(
            msg.value >= price * qty_,
            "SwampVilleOrder: insufficient ETH amount"
        );
        if (msg.value > price * qty_) {
            (bool sent, ) = _msgSender().call{
                value: msg.value.sub(price * qty_)
            }("");
            require(
                sent,
                "SwampVilleOrder: Failed to send back remaining Ether"
            );
        }
        userClaimableQuantity[_msgSender()] += qty_;
        emit Order(_msgSender(), qty_);
    }

    function withdrawETH() public onlyOwner {
        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "SwampVilleOrder: Failed to withdraw Ether");
    }
}