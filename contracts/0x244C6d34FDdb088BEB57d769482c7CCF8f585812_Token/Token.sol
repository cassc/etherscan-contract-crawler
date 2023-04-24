/**
 *Submitted for verification at Etherscan.io on 2023-04-23
*/

// SPDX-License-Identifier: MIT

/*　　　　　　　　　 ,ｨ　 ＿　　 ＿　　　,
　　　　　　__,､-‐' '"´　　￣　　 ｀`"く
　　　 _／　　　　　　　　　　　　　　　 ｀ヽ、
　　r'/　　　　　　　　　　　　　　　　　　　 ヽ
　_/　　　　　　　　　　　　　　　　 ヽ ヽ　 }| }
'´　　　　　　　　　　 　 　 　 i　　}　 | .|　/ {　　　　　　　　　　　 　 ,､-──-､
　　　　　　　　　　　　　ヽヽ. | r_{　r'ヘﾚ' ｀`　　　 　 　 　 　 　 ／　　　　　　 `ー‐彡'´
　　　　　　　　　　　　 i　ﾉ 人ゝ ___,,,,.　ヽ　　　　　　 ＿　　 ／　　　_,,､=＝===='"´ゝ
　　　　　　　　 j| |　| ノ ﾄ､{　 　`ヽ.l,;L　　` ｰ-v‐'"´　　`ﾞ７′　 ／　　,､-------'"
　　　　　　　 __川レ'ヽ`i`　　　　　　　　　　, ノ　　ノノ ／ 　 　 / 　 ／'´フ`ー─-､､
　　　　　　　 l rｧ｀ヽ　　｀ヽ　　　　　　　　　（ ｀`ー‐'´　　　　 /　／　 ／　　　　　　 ヽ
　　　　　　　 ﾞi, {´ (_＼　　 ｀`'''ｰ-､　 　 　 ,.〈 三ミ､＿＿_,／ ／-‐''´　　　　　　　　　＼　　　,ｨ
　　　　　　　　ヽ､＿＿＼　 　 　 　 ヽ　　　 r'ヾ二ニニニ､-'"　　 __,,､----- ､　 ｀ヽ　　 `'''''"/
ヽ　　　 　 　 　 `i　|　`i￣ヽ､　　　　 ヽ.　 　ﾞi, ｀ヽ､　 ｀`ー─'ニ´__　 -'"´　　 ＼　　＼　`=く
　 ﾞヽ､ ＼　　　　|　|　 |　　　 ＼　　　　ヽ.　ノ｀ヽ､　`ー─‐r'´　　　 ｀ヽ､　　　　　`ー‐､＼　　＼
　　　 ヽ　ヽ　　 |　 ヽ　l　　　 　 ＼　　　 ＼ミ､　 _＼　 _,ノ　　　　　　　 ヽ　 --- ､　　　＼ヽ　　|
　　　　 }　 }　　 |＼　 ヽ＼＿＿＿_ヽ　　　　｀`"´　 ￣　　　　　　　　　　 ＼＿,　　 ＼　　 l　} /′
　　　 〈　　|i　　 ヽ l|　　　 |　`ー─-ヽ　　　　　　　　　　　　　　 ,､-- ､＿＿_∠ー-､　＼.　l,-'´
　　　　 ＼ |　　 // |　　　 |　　　 　 　 ＼　　　　　　　　　　　／　　　,､---- ､　 ヽ　ヽ　 ヽ､`ｰイ
　　　　　　 ヽ　r/／　　　/　　　　　　　　|ヾ-､ ＿＿_　　 ,／＝=＜´　　　　　 ヽ　ﾞi　　` ´￣￣
　　　　　 ,､-''"´　　 　 ／
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 8888888888888 * 10 ** 18;
    string public name = "Griffith";
    string public symbol = "GRIFFITH";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}