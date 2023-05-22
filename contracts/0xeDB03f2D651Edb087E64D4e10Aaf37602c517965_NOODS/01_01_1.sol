// SPDX-License-Identifier: MIT
// 
/**

Please Send Noods - The Best Currency

TG: https://t.me/+Yy9c9jI4wyJkMDlh
English: Please send noods.
Spanish: Por favor, envía fideos.
French: S'il vous plaît, envoyez des nouilles.
German: Bitte schicke Nudeln.
Italian: Per favore, invia noodles.
Portuguese: Por favor, envie macarrão.
Russian: Пожалуйста, отправьте лапшу. (Pozhaluysta, otprav'te lapshu.)
Chinese (Simplified): 请发送面条。 (Qǐng fāsòng miàntiáo.)
Japanese: ヌードルを送ってください。 (Nūdoru o okutte kudasai.)
Korean: 면을 보내주세요. (Myeon-eul bonaeyo juseyo.)

*/
pragma solidity ^0.8.0;


contract NOODS {
    string public name = "Please Send NOODS";
    string public symbol = "NOODS";
    uint256 public totalSupply = 10_000_000_000* 10**18; 
    uint8 public decimals = 18;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}