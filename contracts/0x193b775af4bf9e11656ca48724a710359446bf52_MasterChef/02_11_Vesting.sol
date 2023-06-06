pragma solidity ^0.6.0;

import "../interfaces/IMuse.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;

    IMuse public token;

    uint256 public duration = 730 days;
    uint256 public timeStarted;

    mapping(address => uint256) public paid;
    mapping(address => uint256) public totalAmount;

    address owner;

    constructor(IMuse _token) public {
        timeStarted = now;
        token = IMuse(_token);
        owner = msg.sender;
    }

    function claimTokens() external {
        require(
            totalAmount[msg.sender] >= paid[msg.sender],
            "Finished vesting"
        );
        uint256 _amount = getAllocation();
        paid[msg.sender] += _amount;
        token.mint(msg.sender, _amount);
    }

    //@TODO check my math
    function getAllocation() public view returns (uint256) {
        uint256 perDay = totalAmount[msg.sender].div(duration);
        uint256 daysPassed = (now.sub(timeStarted)).div(1 days);
        uint256 amount = (daysPassed.mul(perDay)).sub(paid[msg.sender]);
        return amount;
    }

    // as we don't have many players we could add manually how much everyone should get in 2 txs
    function addAmts(address[] calldata _players, uint256[] calldata _amounts)
        external
    {
        require(owner == msg.sender);
        for (uint256 index = 0; index < _players.length; index++) {
            totalAmount[_players[index]] = _amounts[index];
        }
    }
}