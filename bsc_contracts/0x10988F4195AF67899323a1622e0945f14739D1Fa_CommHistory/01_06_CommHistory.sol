// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRefferal {
    function userInfos(address _user) external view returns(address user,
        address refferBy,
        uint dateTime,
        uint totalRefer,
        uint totalRefer7,
        bool top10Refer);
    function owner() external view returns(address);
}

contract CommHistory is Ownable {
    IRefferal public refer;
    mapping(address => bool) public specials;
    mapping(address => bool) public specials2;
    mapping(address => bool) public isComm;
    mapping(address => mapping(IERC20 => uint)) public totalRewards; // user => token => amount
    mapping(address => mapping(IERC20 => mapping(uint => uint))) public totalRewardsByDay; // user => token => day => amount

    modifier onlyComm() {
        isComm[_msgSender()] == true;
        _;
    }
    constructor(IRefferal _refer) {
        refer = _refer;
        specials[0xDe9C06352394835b60583B99Dcc77877FEB098c7] = true;
        specials2[0xD97A5862E42FF635a8833A73716e0b0A28BF25e4] = true;
        specials2[0x62089d8Ff08aE499E3e316dcd60950B76798ea8B] = true;
        specials2[0x2fc889bab73fCAEb9727c12F9968329853d40309] = true;
        specials2[0xba40121EE0A7479f38d0E8AB077eA53c82303894] = true;
        specials2[0x4DC30B3A06652DBcD491DCe3611dA800A65eb84d] = true;
        specials2[0xB39185656D41916d52A7aD481b69969f5f9F6830] = true;
    }
    function setSpecial(address _special, bool _enable) external onlyOwner {
        specials[_special] = _enable;
    }
    function setSpecial2(address _special, bool _enable) external onlyOwner {
        specials2[_special] = _enable;
    }
    function isSpecialTree(address _user) external view returns(bool isSpecial, uint _round) {
        address _refferBy;
        address from = _user;
        for(uint i = 0; i < 7; i++) {
            (, _refferBy,,,,) = refer.userInfos(from);
            if(specials[_refferBy]) {
                isSpecial = true;
                _round = i;
                break;
            }
            from = _refferBy;
        }
    }
    function getRoot(address _user, uint _type) external view returns(address root, address f1) {
        address _refferBy;
        address from = _user;
        for(uint i = 0; i < 7; i++) {
            (, _refferBy,,,,) = refer.userInfos(from);
            if(_type == 1 && specials[_refferBy]) {
                root = _refferBy;
                f1 = from;
                break;
            } else if(_type == 2 && specials2[_refferBy]) {
                root = _refferBy;
                f1 = from;
                break;
            }
            from = _refferBy;
        }
    }
    function isSpecial2Tree(address _user) external view returns(bool isSpecial, uint _round) {
        address _refferBy;
        address from = _user;
        for(uint i = 0; i < 7; i++) {
            (, _refferBy,,,,) = refer.userInfos(from);
            if(specials2[_refferBy]) {
                isSpecial = true;
                _round = i;
                break;
            }
            from = _refferBy;
        }
    }
    function setIsComm(address _comm, bool _enable) external onlyOwner {
        isComm[_comm] = _enable;
    }
    function addComm(address _user, uint _amount, IERC20 _token) external onlyComm {
        totalRewards[_user][_token] += _amount;
        totalRewardsByDay[_user][_token][getDays()] += _amount;
    }
    function getDays() public view returns(uint) {
        return block.timestamp / 1 days;
    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}