// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FarmReference is Ownable, Pausable {

    IERC20 public token; //FTY

    uint256 public userId = 0;
    uint256 public persentage = 10;
    uint256 public fee = 1000000000000000; //0.001 BNB

    mapping(address => bool) public privilage;
    mapping(uint256 => address) public user;
    mapping(address => address) public referrer;
    mapping(address => uint256) public refincome;
    mapping(address => uint256) public withdraw;
    mapping(address => uint256) public totalReferenced;

    modifier hasPrivilage() {
        require(privilage[_msgSender()] == true, "You don't have the privilege");
        _;
    }

    function addReference(address _user, address _referrer) external hasPrivilage{

        if (_referrer != address(0x0) && _referrer != _user && referrer[_user] == address(0x0))
        { 
            user[userId] = _user;
            referrer[_user] = _referrer;
            totalReferenced[_referrer] += 1;
            userId += 1; 
        }

    }

    function addRefIncome(address _user, uint256 _amount) external hasPrivilage{
        if(referrer[_user] != address(0x0)){
            refincome[referrer[_user]] += (_amount * persentage) / 100;
        }
    }

    function withdrawRefincome() payable external{
        require(refincome[msg.sender] > 0, 'no enough income');
        require(msg.value == fee, 'no enough fee');
        require(token.transfer(address(msg.sender), refincome[msg.sender]),'transfer failled');
        withdraw[msg.sender] += refincome[msg.sender];
        refincome[msg.sender] = 0;
    }

    //Setters

    function setToken(address _token) external onlyOwner{
        token = IERC20(_token);
    }

    function setFee(uint256 _fee) external onlyOwner{
        fee = _fee;
    }

    function setPersentage(uint _persentage) external onlyOwner{
        require(_persentage > 0 && _persentage <=100, 'must be between 1 and 100');
        persentage = _persentage;
    }

    function setPrivilage(address _contract, bool _value)
        external
        onlyOwner
    {
        privilage[_contract] = _value;
    }

    // Helper

    function withdrawToken(uint256 _amount) external onlyOwner{
        require(token.transfer(owner(), _amount), "TRANSFER FAILED");
    }

    function withdrawBnb() external onlyOwner {
        if (address(this).balance >= 0) {
            payable(owner()).transfer(address(this).balance);
        }
    }
  
}