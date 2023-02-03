// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LEFirstWallet is Ownable {
    using SafeMath for uint256;
    uint256 public managerBalance;

    struct management {
        address wallet;
        uint256 balance;
    }

    mapping(uint => management) public managementList;

    struct entre {
        address wallet;
        uint256 balance;
    }

    mapping(uint => entre) public entreList;

    struct PR {
        address wallet;
        uint256 balance;
    }

    mapping(uint => PR) public PRList;
    
    uint256[] managementMultiple = [8,4,3,3];
    uint256[] PRMultiple = [24,10,10,10,5,5];

    receive() external payable {
        uint256 bal = msg.value.div(100);
        uint256 amt = msg.value;

        for (uint i=1; i<=4; i++) {
            if(managementList[i].wallet != address(0)) {
                managementList[i].balance+=bal.mul(managementMultiple[i-1]);
                amt-=bal.mul(managementMultiple[i-1]);
            }            
        }

        for (uint i=1; i<=18; i++) {
            if(entreList[i].wallet != address(0)) {
                entreList[i].balance+=bal;
                amt-=bal;
            }            
        }

        for (uint i=1; i<=6; i++) {
            if(PRList[i].wallet != address(0)) {
                PRList[i].balance+=bal.mul(PRMultiple[i-1]);
                amt-=bal.mul(PRMultiple[i-1]);
            }            
        }

        managerBalance+=amt;
    }

    function setManagementList(uint256[] memory _id, address[] memory _wallet) external onlyOwner {
        require(_id.length == _wallet.length, "Arrays of different sizes");
        require(_wallet.length <= 4 , "Max 4 slots available for management");

        for(uint i=0; i<_wallet.length; i++) {
            require(_id[i] > 0 && _id[i] <=4, "Invalid Id");

            managementList[_id[i]].wallet = _wallet[i];

        }

    }

    function setEntreList(uint256[] memory _id, address[] memory _wallet) external onlyOwner {
        require(_id.length == _wallet.length, "Arrays of different sizes");
        require(_wallet.length <=18 , "Max 18 slots available for entre");

        for(uint i=0; i<_wallet.length; i++) {
            require(_id[i] > 0 && _id[i] <=18, "Invalid Id");

            entreList[_id[i]].wallet = _wallet[i];
        }

    }

    function setPRList(uint256[] memory _id, address[] memory _wallet) external onlyOwner {
        require(_id.length == _wallet.length, "Arrays of different sizes");
        require(_wallet.length <=6 , "Max 6 slots available for entre");

        for(uint i=0; i<_wallet.length; i++) {
            require(_id[i] > 0 && _id[i] <=6, "Invalid Id");

            PRList[_id[i]].wallet = _wallet[i];
        }

    }

    // types: 0 - management; 1 - entre; 2- PR
    function withdrawBalance(uint _type, uint position) external {
        require(_type <3 , "Invalid type");
        if(_type == 0) {
           address wallet = managementList[position].wallet;
           uint256 balance = managementList[position].balance;
           require(wallet == msg.sender, "Unauthorized");

           managementList[position].balance = 0;
           payable(wallet).transfer(balance);
        }

        else if (_type == 1) {
           address wallet = entreList[position].wallet;
           uint256 balance = entreList[position].balance;
           require(wallet == msg.sender, "Unauthorized");

           entreList[position].balance = 0;
           payable(wallet).transfer(balance);
        }

        else {
           address wallet = PRList[position].wallet;
           uint256 balance = PRList[position].balance;
           require(wallet == msg.sender, "Unauthorized");

           PRList[position].balance = 0;
           payable(wallet).transfer(balance);
        }

    }

    function withdraw() external onlyOwner {
        uint balance = managerBalance;
        managerBalance = 0;
        payable(msg.sender).transfer(balance);
    }

}