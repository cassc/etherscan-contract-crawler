// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract QUOKKA_KIDS_COIN is Ownable{

    mapping(uint256 => uint256) public tokensSent;
    mapping(uint256 => uint256) public tokensRecv;
    mapping(address => bool) public managingContracts;
    uint256 public tokensMinted;
    uint256 public tokensBurned;
    uint256 public startRecvDate = 1663970400;
    uint256 public maxQuokkas = 12000;
    uint256 public dailyReturn = 1;
    uint256 private constant dayLen = 60 * 60 * 24;

    constructor() {

    }

    function name() public pure returns (string memory) {
        return "Quokka Coin";
    }

    function totalSupply() public view returns (uint256) {
        uint256 accumulated = dailyReturn * maxQuokkas * elapsedDays();
        return accumulated + tokensMinted - tokensBurned;
    }

    function elapsedSeconds() public view returns (uint256) {
        return (block.timestamp - startRecvDate);
    }

    function elapsedDays() public view returns (uint256) {
        return (block.timestamp - startRecvDate) / dayLen;
    }

    function balanceOf(uint256 _owner) public view returns (uint256 balance){
        require(_owner < maxQuokkas, "_owner is outside quokka range");
        uint256 accumulated = dailyReturn * elapsedDays();
        return accumulated + tokensRecv[_owner] - tokensSent[_owner]; 
    }

    modifier onlyManagingContract() {
        require(managingContracts[msg.sender] == true, "Invalid manager");
        _;
    }

    function transferFrom(uint256 _from, uint256 _to, uint256 _value) public onlyManagingContract {
        require(_from < maxQuokkas, "_from is outside quokka range");
        require(_to < maxQuokkas, "_to is outside quokka range");
        require(balanceOf(_from) >= _value, "not enough tokens");
        tokensSent[_from] += _value;
        tokensRecv[_to] += _value;
    }

    function mintTokens(uint256 _to, uint256 _value) public onlyManagingContract {
        require(_to < maxQuokkas, "_to is outside quokka range");
        tokensMinted += _value;
        tokensRecv[_to] += _value;
    }

    function burnTokens(uint256 _from, uint256 _value) public onlyManagingContract {
        require(_from < maxQuokkas, "_from is outside quokka range");
        require(balanceOf(_from) >= _value, "burning too many tokens");
        tokensBurned += _value;
        tokensSent[_from] += _value;
    }


    // Nice helper functions
    function equalize() public onlyOwner {
        if (tokensMinted >= tokensBurned) {
            tokensMinted -= tokensBurned;
            tokensBurned = 0;
        }
        else if (tokensMinted < tokensBurned) {
            tokensBurned -= tokensMinted;
            tokensMinted = 0;
        }
    }

    function equalizeAcct(uint256 _acct) public onlyOwner {
        if (tokensRecv[_acct] >= tokensSent[_acct]) {
            tokensRecv[_acct] -= tokensSent[_acct];
            tokensSent[_acct] = 0;
        }
        else if (tokensRecv[_acct] < tokensSent[_acct]) {
            tokensSent[_acct] -= tokensRecv[_acct];
            tokensRecv[_acct] = 0;
        }
    }

    //SET CONTRACT CONTROLLER
    function setManager(address _contract, bool _setting) public onlyOwner {
        managingContracts[_contract] = _setting;
    }

}