// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./DCAREToken.sol";
import "../common/interfaces/ITerminable.sol";

struct Stake {
    uint256 stakingTime; // Staking time
    uint256 stakedUntilTime; // Time after which a staker could get SOLVE tokens back
    uint256 amount;
}

contract DCAREMining is Ownable, ITerminable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant SOLVE_TOKEN_CONTRACT_ADDRESS =
        address(0x446C9033E7516D820cc9a2ce2d0B7328b579406F); //TODO: real address 0x446C9033E7516D820cc9a2ce2d0B7328b579406F
    uint256 public constant SOLVE_TOKEN_DECIMALS = 8;

    address public constant DCARE_TOKEN_CONTRACT_ADDRESS =
        address(0x29C7653F1bdb29C5f2cD44DAAA1d3FAd18475B5D); //TODO: set real DCARE token contract address
    uint256 public constant DCARE_TOKEN_DECIMALS = 6;

    address public constant COMMITTEE_CONTRACT_ADDRESS =
        address(0x972A5AFcAaBa9352E6DCCDc8Da872c987f1d13aF); //TODO: set DCARE committee contract address after deployment

    uint256 public constant MINING_RATE = 100; // 100 SOLVE tokens = 1 DCARE token

    uint256 public constant STAKING_PERIOD = 365 days;
    uint256 public constant START_TIME = 1644922800; // Feb 15, 2022, 3 am PST
    uint256 public constant TERMINATION_TIME = 1672559940; // Dec 31, 2022, 23:59 PST
    uint256 public deploymentTime;

    mapping(address => Stake[]) public stakes;

    bool public terminated;

    IERC20 internal SOLVEToken;
    DCAREToken internal token;

    event Staked(address indexed _address, uint256 indexed _amount);
    event Unstaked(address indexed _address, uint256 indexed _amount);
    event Terminate();

    constructor() {
        SOLVEToken = IERC20(SOLVE_TOKEN_CONTRACT_ADDRESS);
        token = DCAREToken(DCARE_TOKEN_CONTRACT_ADDRESS);

        deploymentTime = block.timestamp;
    }

    modifier onlyCommittee() {
        require(
            COMMITTEE_CONTRACT_ADDRESS == _msgSender(),
            "Caller is not the DCARE Committee contract"
        );
        _;
    }

    function stake(uint256 _amount) public {
        require(!terminated, "Contract is terminated by voting");
        require(START_TIME <= block.timestamp, "Staking is not started");
        require(
            block.timestamp < TERMINATION_TIME,
            "Contract is terminated due to expiration"
        );
        require(_amount % MINING_RATE == 0, "Invalid stake amount"); //TODO: should we revert transaction for not multiple by rate amounts?

        if (
            SOLVEToken.transferFrom(
                msg.sender,
                address(this),
                _amount.mul(10**SOLVE_TOKEN_DECIMALS)
            )
        ) {
            // stake tokens
            token.mint(
                msg.sender,
                _amount.mul(10**DCARE_TOKEN_DECIMALS).div(MINING_RATE)
            );

            stakes[msg.sender].push(
                Stake({
                    stakingTime: block.timestamp,
                    stakedUntilTime: block.timestamp.add(STAKING_PERIOD),
                    amount: _amount
                })
            );

            emit Staked(msg.sender, _amount);
        }
    }

    function unstake() public {
        //TODO: do we need have a posibility to unstake some amount of SOLVE tokens or all available?
        Stake[] storage memberStakes = stakes[msg.sender];

        uint256 tokensAmount = 0;
        for (uint8 i = 0; i < memberStakes.length; i++) {
            if (
                block.timestamp > memberStakes[i].stakedUntilTime &&
                memberStakes[i].amount > 0
            ) {
                tokensAmount = tokensAmount.add(memberStakes[i].amount);

                memberStakes[i].amount = 0;
            }
        }

        if (tokensAmount > 0) {
            SOLVEToken.safeTransfer(
                msg.sender,
                tokensAmount.mul(10**SOLVE_TOKEN_DECIMALS)
            );

            emit Unstaked(msg.sender, tokensAmount);
        }
    }

    function terminate() public override onlyCommittee {
        terminated = true;

        emit Terminate();
    }

    function retrieveTokens(uint256 _amount) public onlyOwner {
        SOLVEToken.safeTransfer(
            msg.sender,
            _amount * (10**SOLVE_TOKEN_DECIMALS)
        );
    }

    receive() external payable {
        msg.sender.transfer(msg.value);
    }

    function retrieveEther() public onlyOwner {
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
}