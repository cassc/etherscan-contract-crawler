/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract BTH {
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balances;

    address public governance;
    address public liquidityPool = 0xa4A8472446bEB65c3b7c447dC569f3F40882A09b;
    address public burnWallet = 0x6A2dfb35459fCBDeee9c6a6101b717A96d4Fa1D0;
    address public developmentWallet = 0x0fBb9c0f61b1a79213eF4f7212d5D65F3855Eafb;
    address public stakingContract = 0xfE2FF363586903DD297e4BE662a049D3EB255012;

    uint256 public constant totalSupply = 2000000000000000000000000000;
    uint256 public liquidityFee = 2;
    uint256 public burnFee = 1;
    uint256 public developmentFee = 1;
    uint256 public constant transactionFee = 4;

    string public name = "Bytehive";
    string public symbol = "BTH";
    uint8 public constant decimals = 18;

    bool public stopped;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokenMined(address indexed miner, uint256 value);
    event TokenMinted(address indexed to, uint256 value);
    event TokenBurned(address indexed burner, uint256 value);
    event TokenStaked(address indexed staker, uint256 value);
    event TokenUnstaked(address indexed unstaker, uint256 value);
    event GovernanceVoteCast(uint256 indexed voteId, address indexed voter, bool vote);
    event Stopped();

    constructor() {
        governance = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier whenNotStopped() {
        require(!stopped, 'contract is stopped');
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public whenNotStopped returns (bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        require(to != address(this), 'cannot transfer to contract');

        uint256 fee = calculateFee(value, transactionFee);
        uint256 transferAmount = value - fee;

        balances[msg.sender] -= value;
        balances[to] += transferAmount;

        emit Transfer(msg.sender, to, transferAmount);

        if (fee > 0 && msg.sender != governance) {
            // Transfer fee to liquidity pool
            balances[liquidityPool] += calculateFee(fee, liquidityFee);
            emit Transfer(msg.sender, liquidityPool, calculateFee(fee, liquidityFee));

            // Burn fee
            balances[burnWallet] += calculateFee(fee, burnFee);
            emit Transfer(msg.sender, burnWallet, calculateFee(fee, burnFee));

            // Development fee
            balances[developmentWallet] += calculateFee(fee, developmentFee);
            emit Transfer(msg.sender, developmentWallet, calculateFee(fee, developmentFee));
        }

        return true;
    }

    function approve(address spender, uint256 value) public whenNotStopped returns (bool) {
        require(spender != address(this), 'cannot approve contract');

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotStopped returns (bool) {
        require(value <= balances[from], 'balance too low');
        require(value <= allowance[from][msg.sender], 'allowance exceeded');
        require(to != address(this), 'cannot transfer to contract');

        balances[from] -= value;
        balances[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotStopped returns (bool) {
        require(spender != address(this), 'cannot approve contract');

        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotStopped returns (bool) {
        require(subtractedValue <= allowance[msg.sender][spender], 'allowance below zero');
        require(spender != address(this), 'cannot approve contract');

        allowance[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function mine() public {
        balances[msg.sender] += 1;
        emit TokenMined(msg.sender, 1);
        emit Transfer(address(0), msg.sender, 1);
    }

    function mint(address to, uint256 value) public {
        require(msg.sender == governance, 'only governance can mint tokens');

        balances[to] += value;
        emit TokenMinted(to, value);
        emit Transfer(address(0), to, value);
    }

    function burn(uint256 value) public {
        require(balances[msg.sender] >= value, 'balance too low');

        balances[msg.sender] -= value;
        emit TokenBurned(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    function stake(uint256 value) public {
        require(balances[msg.sender] >= value, 'balance too low');

        balances[msg.sender] -= value;
        balances[stakingContract] += value;

        emit TokenStaked(msg.sender, value);
        emit Transfer(msg.sender, stakingContract, value);
    }

    function unstake(uint256 value) public {
        require(balances[stakingContract] >= value, 'balance too low');

        balances[stakingContract] -= value;
        balances[msg.sender] += value;

        emit TokenUnstaked(msg.sender, value);
        emit Transfer(stakingContract, msg.sender, value);
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, 'only governance can set new governance address');

        governance = _governance;
    }

    function vote(uint256 voteId, bool _vote) public {
        require(msg.sender == governance, 'only governance can cast votes');

        emit GovernanceVoteCast(voteId, msg.sender, _vote);
    }

    function calculateFee(uint256 value, uint256 feePercentage) internal pure returns (uint256) {
        return (value * feePercentage) / 100;
    }

    function stop() public {
        require(msg.sender == governance, 'only governance can stop the contract');
        stopped = true;

        emit Stopped();
    }

    function resume() public {
        require(msg.sender == governance, 'only governance can resume the contract');
        stopped = false;
    }
}