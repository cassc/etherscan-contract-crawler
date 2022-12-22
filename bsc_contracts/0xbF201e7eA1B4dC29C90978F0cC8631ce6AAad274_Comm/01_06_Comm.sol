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
}

interface ICommHistory {
    function addComm(address _user, uint _amount, IERC20 _token) external;
    function isSpecialTree(address _user) external view returns(bool isSpecial, uint _round);
    function isSpecial2Tree(address _user) external view returns(bool isSpecial, uint _round);
    function getRoot(address _user, uint _type) external view returns(address root, address f1);
}

contract Comm is Ownable {
    IRefferal refer;
    ICommHistory public commHistory;

    address public treasury;
    constructor(IRefferal _refer, address _treasury, ICommHistory _commHistory) {
        refer = _refer;
        treasury = _treasury;
        commHistory = _commHistory;
    }

    function handleUserComm(address _refferBy, uint comm, IERC20 tokenBuy) internal {
        tokenBuy.transfer(_refferBy, comm);
        commHistory.addComm(_refferBy, comm, tokenBuy);
    }
    function handleComm(address _fromUser, uint totalComm, IERC20 tokenBuy) external {
        address from = _fromUser;
        uint currentComm = totalComm;
        address _refferBy;
        for(uint i = 0; i <= 7; i++) {
            uint comm = totalComm / (2 ** (i+1));
            (, _refferBy,,,,) = refer.userInfos(from);
            if((from == _refferBy)) {
                if(currentComm > 0) tokenBuy.transfer(treasury, currentComm);
                break;
            } else {
                from = _refferBy;
                handleUserComm(_refferBy, comm, tokenBuy);
                currentComm -= comm;
            }

        }
    }
    function setRefer(IRefferal _refer) external onlyOwner {
        refer = _refer;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}