// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeMath.sol";

contract CrossChain {
    using SafeMath for uint256;
    address payable public targetAddress;
    address public master_coin;
    address public son_coin;
    address private owner;
    address public blackhole = payable(address(1));
    uint256 public fee;
    bool public is_cross_open = true;
    uint256 master_rate = 185.7142857143*10**12; 
    uint256 son_rate = 1.3*10**3; 
    
    event crossed(uint256 zm_amount,address from_address);

    modifier opening() {
        require(is_cross_open, "cross not open");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier cross_fee(){
        require(msg.value >= fee,"Insufficient balance");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }


    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function changeOpen() external onlyOwner {
        if (is_cross_open){
            is_cross_open = false;
        }else{
            is_cross_open = true;
        }
    }

    function changetargetAddress(address _targetAddress) external onlyOwner {
        require(_targetAddress != address(0), "New targetAddress is the zero address");
        targetAddress = payable(_targetAddress);
    }

    function changeFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    constructor() {
        owner = msg.sender;
        targetAddress = payable(msg.sender);
        master_coin = address(0x44ac762dB7E7170A48e895fDC81Bc2e81c188888);
        son_coin = address(0xe2686114674a1ae98737c79830d3b6f3D850d000);
        fee = 0.03 * 10 ** 18; //预设手续费
    }


    function query_master_cross_need(uint256 zm_amount) public pure returns(uint256 master_amount){
        master_amount = master_amount = zm_amount/100;
    }


    function query_cross_need(uint256 zm_amount) public view returns(uint256 master_amount,uint256 son_amount){

        if (zm_amount % 130000000000000000000 == 0){

            master_amount = zm_amount / 130000000000000000000 * 700000000000000000;
        }
        else{

            master_amount = (zm_amount * 10**12) / master_rate;
        }
        son_amount = (zm_amount * 10**3) / son_rate;
    }


    function master_cross(uint256 zm_amount) payable external cross_fee{
        uint256 master_amount;
        master_amount = query_master_cross_need(zm_amount);


        targetAddress.transfer(msg.value);


        IERC20 tokenA = IERC20(master_coin);
        require(tokenA.transferFrom(msg.sender, blackhole, master_amount), "Master_coin transfer failed");
        emit crossed(zm_amount,msg.sender);
    }

    function cross(uint256 zm_amount) payable external cross_fee{
        uint256 master_amount;
        uint256 son_amount;

        (master_amount,son_amount) = query_cross_need(zm_amount);
        targetAddress.transfer(msg.value);

        IERC20 tokenA = IERC20(master_coin);
        require(tokenA.transferFrom(msg.sender, blackhole, master_amount), "Master_coin transfer failed");

        IERC20 tokenB = IERC20(son_coin);
        require(tokenB.transferFrom(msg.sender, blackhole, son_amount), "Son_coin transfer failed");
        emit crossed(zm_amount,msg.sender);
}
}
