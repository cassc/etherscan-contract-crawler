// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RTRST {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public admin;
    uint256 public annualDistributionPercentage;
    uint256 public lastDistributionTimestamp;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rorapBalance;
    address[] public tokenHolders;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Distribution(address indexed wallet, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        name = "RTRST Token";
        symbol = "RTRST";
        totalSupply = 200;
        admin = msg.sender;
        balanceOf[admin] = totalSupply;
        annualDistributionPercentage = 5;
        lastDistributionTimestamp = block.timestamp;
        tokenHolders.push(msg.sender);
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        require(msg.sender != _to, "Invalid transfer");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        if (balanceOf[_to] == _amount) {
            tokenHolders.push(_to);
        }
        emit Transfer(msg.sender, _to, _amount);
    }

    function distributeRewards() public onlyAdmin {
        uint256 timeSinceLastDistribution = block.timestamp -
            lastDistributionTimestamp;
        require(
            timeSinceLastDistribution >= 365 days,
            "Distribution can only occur once per year"
        );

        uint256 totalDistributed = 0;

        uint256 count = tokenHolders.length;

        for (uint256 i = 0; i < count; i++) {
            // Access each token holder's address using tokenHolders[i]
            // Perform desired operations with the token holder's address
            if (rorapBalance[address(tokenHolders[i])] > 0) {
                uint256 distributionAmount = (rorapBalance[address(tokenHolders[i])] *
                    annualDistributionPercentage) / 100;
                balanceOf[address(tokenHolders[i])] += distributionAmount;
                totalDistributed += distributionAmount;
                emit Distribution(address(tokenHolders[i]), distributionAmount);
            }
        }

        lastDistributionTimestamp = block.timestamp;

        require(totalDistributed > 0, "No distribution amount available");

        // Adjust total supply to account for distribution
        totalSupply += totalDistributed;
    }

    function updateRorapBalance(address _wallet, uint256 _rorapBalance)
        public
        onlyAdmin
    {
        rorapBalance[_wallet] = _rorapBalance;
    }

    function getTokenHolders() public view returns (address[] memory) {
        return tokenHolders;
    }
}