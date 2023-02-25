/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

contract MonnaieUniqueAfricaine {
    string public name = "Monnaie Unique Africaine";
    string public symbol = "MUA";
    uint256 public totalSupply = 1000000000 * 10**18; // 1 billion MUA with 18 decimal places
    uint256 public burnPercentage = 1;
    uint256 public distributionPercentage = 3;
    address public owner;
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        uint256 burnAmount = (_value * burnPercentage) / 100;
        uint256 distributionAmount = (_value * distributionPercentage) / 100;
        uint256 transferAmount = _value - burnAmount - distributionAmount;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[owner] += distributionAmount;
        totalSupply -= burnAmount;
        emit Transfer(msg.sender, _to, transferAmount);
        return true;
    }
}