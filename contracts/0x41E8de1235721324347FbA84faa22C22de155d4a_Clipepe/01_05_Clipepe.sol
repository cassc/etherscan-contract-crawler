// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Clipepe is ERC20 {
    struct User {
        uint8 numberOfMints;
        uint256 lastMinted;
    }

    struct Round {
        uint8 index;
        uint128 price;
        address winner;
        uint256 deadline;
        string uri;
    }

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint8 public constant DECIMALS = 18;
    uint32 public constant MINT_INTERVAL = 1 days;
    uint128 public constant BILLION = 10**9;
    uint128 public constant MILLION = 10**6;
    uint128 public constant THOUSAND = 10**3;
    uint128 public constant MAX_SUPPLY = 210 * BILLION * DECIMALS;
    uint128 public constant TEAM_TOTAL_ALLOC = 30 * BILLION * DECIMALS;
    uint128 public constant COMMUNITY_BASE_ALLOC = 3 * MILLION * DECIMALS;
    uint128 public constant BASE_PRICE = 300 * THOUSAND * DECIMALS;
    uint128 public constant PRICE_MULTIPLIER = 150;
    uint128 public constant PRICE_MULTIPLIER_DECIMALS = 100;

    address public owner;

    // solhint-disable-next-line
    uint128[3] public JACKPOTS;
    // solhint-disable-next-line
    uint32[3] public DURATIONS;

    Round public currentRound;

    mapping(address => User) public users;

    error EUnauthorized();
    error EMintCooldown();

    event RoundWon(uint256 index, address winner);

    modifier ownerNotAllowed() {
        if (_msgSender() == owner) revert EUnauthorized();
        _;
    }

    constructor() ERC20("Clipepe", "CP") {
        JACKPOTS = [
            10 * BILLION * DECIMALS,
            15 * BILLION * DECIMALS,
            35 * BILLION * DECIMALS
        ];
        DURATIONS = [1 days, 2 days, 3 days];
        currentRound.winner = BURN_ADDRESS; // prevent potential deadlock
        currentRound.deadline = block.timestamp + DURATIONS[0];
        currentRound.price = BASE_PRICE;
        _mint(_msgSender(), TEAM_TOTAL_ALLOC);
        owner = _msgSender();
    }

    function pepe(string calldata uri) external ownerNotAllowed {
        if (block.timestamp > currentRound.deadline) {
            emit RoundWon(currentRound.index, currentRound.winner);
            _mint(currentRound.winner, JACKPOTS[currentRound.index]);
            currentRound.index++;
            currentRound.deadline += DURATIONS[currentRound.index];
            currentRound.price =
                (currentRound.price * PRICE_MULTIPLIER) /
                PRICE_MULTIPLIER_DECIMALS;
        }
        _transfer(_msgSender(), BURN_ADDRESS, currentRound.price); // avoid using _burn() so totalSupply does not decrease
        uint128 newPrice = (currentRound.price * PRICE_MULTIPLIER) /
            PRICE_MULTIPLIER_DECIMALS;
        currentRound.price = newPrice;
        currentRound.uri = uri;
        currentRound.winner = _msgSender();
    }

    function setURI(string calldata uri) external {
        if (_msgSender() != currentRound.winner) revert EUnauthorized();
        currentRound.uri = uri;
    }

    function mint() external ownerNotAllowed {
        User storage user = users[_msgSender()];
        if (block.timestamp - user.lastMinted < MINT_INTERVAL)
            revert EMintCooldown();
        uint256 divisor = ++user.numberOfMints;
        uint256 mintAmount = COMMUNITY_BASE_ALLOC / divisor;
        if (totalSupply() + mintAmount > MAX_SUPPLY) {
            mintAmount = MAX_SUPPLY - totalSupply();
        }
        _mint(_msgSender(), mintAmount);
        user.lastMinted = block.timestamp;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}