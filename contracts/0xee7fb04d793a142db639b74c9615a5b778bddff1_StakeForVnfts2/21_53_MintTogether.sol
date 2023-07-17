pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@nomiclabs/buidler/console.sol";

import "./interfaces/IStakeForVnfts.sol";
import "./interfaces/IVNFT.sol";

contract MintTogether is Ownable {
    mapping(uint256 => address[]) public stakers;
    mapping(address => uint256) public staked;
    mapping(uint256 => mapping(address => uint256)) public ticketsByStakers;

    using SafeMath for uint256;
    IVNFT public vnft;
    IERC20 public muse;
    IStakeForVnfts public stakeContract;

    address winner;
    uint256 currentRound = 1;
    uint256 public currentVNFT = 0;
    uint256 public randomBlockSize = 3;

    uint256 vnftPrice = 400 * 10**18;

    // overflow
    uint256 public MAX_INT = 2**256 - 1;

    constructor(
        IVNFT _vnft,
        IERC20 _muse,
        IStakeForVnfts _stakeContract
    ) public {
        vnft = _vnft;
        muse = _muse;
        stakeContract = _stakeContract;
        // muse.approve(address(stakeContract), MAX_INT);
    }

    function stake(uint256 _amount) public {
        require(_amount >= 5, "Min 5 muse required");

        staked[msg.sender] = _amount;

        uint256 tickets = _amount.div(5);

        for (uint256 i = 0; i < tickets; i++) {
            stakers[currentRound].push(msg.sender);
            ticketsByStakers[currentRound][msg.sender] =
                ticketsByStakers[currentRound][msg.sender] +
                1;
        }

        muse.transferFrom(msg.sender, address(this), _amount);
        stakeContract.stake(_amount);
    }

    // if 400 points, redeem, transfer to winner, withdraw
    function redeem() external {
        require(
            stakeContract.earned(address(this)) >= vnftPrice,
            "Not enough points"
        );

        stakeContract.redeem();
        stakeContract.exit();

        currentVNFT = vnft.totalSupply() - 1;
        winner = stakers[currentRound][randomNumber(
            block.number - 4,
            stakers[currentRound].length
        )];
        currentRound = currentRound + 1;

        // vnft.transferFrom(address(this), winner, currentVNFT);
    }

    function restake() external {
        require(staked[msg.sender] >= 5, "Min 5 muse required");

        uint256 tickets = staked[msg.sender].div(5);

        for (uint256 i = 0; i < tickets; i++) {
            stakers[currentRound].push(msg.sender);
            ticketsByStakers[currentRound][msg.sender] =
                ticketsByStakers[currentRound][msg.sender] +
                1;
        }
        stakeContract.stake(staked[msg.sender]);
    }

    function withdraw() external {
        ticketsByStakers[currentRound][msg.sender] = 0;
        muse.transferFrom(address(this), msg.sender, staked[msg.sender]);
        staked[msg.sender] = 0;
    }

    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < randomBlockSize; i++) {
            if (
                uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                ) %
                    2 ==
                0
            ) n += 2**i;
        }
        return n % max;
    }
}