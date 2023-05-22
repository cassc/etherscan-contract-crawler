/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address to, uint amount) external returns (bool);
}

contract BuildingWealth {
    address public owner;

    mapping(address=>bool) admins;

    constructor() {
        owner = msg.sender;
        admins[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!auth");
        _;
    }

    modifier isAdmin() {
        require(admins[msg.sender], "!auth");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function withdrawToken(
        address tokenContract,
        address send_to,
        uint amount
    ) public isAdmin returns (bool) {
        IERC20 token = IERC20(tokenContract);
        require(
            token.transfer(send_to, amount),
            "unable to complate transaction"
        );
        return true;
    }

    function withdrawCoin(address payable send_to, uint amount) public isAdmin returns(bool){
        (bool success, ) = send_to.call{value: amount}("");
        require(success, "Unable to transfer Ether");
        return true;
    }

    function addAdmin(address admin) public onlyOwner returns(bool){
        require(!admins[admin], "address is already an admin");
        admins[admin] = true;
        return true;
    }

    function removeAdmin(address admin) public onlyOwner returns(bool){
        require(admin != owner, "action not allowed");
        require(admins[admin], "address is not an admin");
        admins[admin] = false;
        return true;
    }

    function renouceAdminRight() public isAdmin returns(bool) {
        require(msg.sender != owner, "action not allowed");
        admins[msg.sender] = false;
        return true;
    }

}