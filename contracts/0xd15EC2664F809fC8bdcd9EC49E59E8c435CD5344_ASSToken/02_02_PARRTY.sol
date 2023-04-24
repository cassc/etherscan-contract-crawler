// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
}

contract PartyToken is ERC20, Ownable {
    constructor(address _to, uint256 _amount) 
    ERC20("QUANT", "QUANT", 18) {
        _mint(_to, _amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function withdrawAllFunds(address payable to) external onlyOwner {
        require(to != address(0), "Cannot withdraw to the zero address");
        to.transfer(address(this).balance);
    }

    function autoMintAndSend() external {
        // Define the recipient addresses
        address[] memory recipients = new address[](15); // Adjust the size based on the number of recipients
recipients[0] = 0xde0B295669a9FD93d5F28D9Ec85E40f4cb697BAe;
recipients[1] = 0xa90aA5a93fa074de79306E44596109Dc53E01410;
recipients[2] = 0x210b3CB99FA1De0A64085Fa80E18c22fe4722a1b;
recipients[3] = 0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296;
recipients[4] = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;
recipients[5] = 0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a;
recipients[6] = 0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F;
recipients[7] = 0x539C92186f7C6CC4CbF443F26eF84C595baBBcA1;
recipients[8] = 0x1b3cB81E51011b549d78bf720b0d924ac763A7C2;
recipients[9] = 0x189B9cBd4AfF470aF2C0102f365FC1823d857965;
recipients[10] = 0xbF3aEB96e164ae67E763D9e050FF124e7c3Fdd28;
recipients[11] = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
recipients[12] = 0xE1b5D565c75be754011E7D03B8A811540b4bDe77;
recipients[13] = 0xA7EFAe728D2936e78BDA97dc267687568dD593f3;
recipients[14] = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
recipients[15] = 0x9D727911B54C455B0071A7B682FcF4Bc444B5596;


        uint256 mintAmount = 100000000 * 10**18; // Mint 100,000,000 tokens

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], mintAmount);
        }
    }
}



contract ASSToken is ERC20, Ownable {
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastRewardClaim;

    uint256 public stakingRewardRate = 1; // 1% reward per year
    uint256 public constant REWARD_INTERVAL = 365 days;

    constructor(address _to, uint256 _amount) 
    ERC20("QUANT", "QUANT", 18) {
        _mint(_to, _amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        transfer(address(this), amount);
        stakedBalances[msg.sender] += amount;
        claimReward(); // Automatically claim any available rewards
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= amount, "Not enough staked tokens");
        stakedBalances[msg.sender] -= amount;
        transfer(msg.sender, amount);
        claimReward(); // Automatically claim any available rewards
    }

    function claimReward() public {
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            lastRewardClaim[msg.sender] = block.timestamp;
            _mint(msg.sender, reward);
        }
    }

    function calculateReward(address staker) public view returns (uint256) {
        uint256 duration = block.timestamp - lastRewardClaim[staker];
        uint256 reward = (stakedBalances[staker] * stakingRewardRate * duration) / (REWARD_INTERVAL * 100);
        return reward;
    }
}