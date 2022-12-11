pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OSEAPointsRepository {
    address public owner;
    IERC20 public token;
    mapping (address => uint256) public userPoints;

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    function addPoints(address[] calldata _receivers, uint256 _quantity) external {
        require(msg.sender == owner);

        for (uint i = 0; i < _receivers.length; i++) {
            userPoints[_receivers[i]] += (_quantity * 10**18);
        }
    }

    function claim() external {
        uint256 claimable = userPoints[msg.sender];
        require(claimable > 0, "NOT_CLAIMABLE");
        userPoints[msg.sender] = 0;
        token.transfer(msg.sender, claimable);
    }

    function withdrawRemaining() external {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}