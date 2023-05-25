// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FlappyMoonBird is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18;

    uint256 public constant PRE_SEED_A_PERCENT = 8;
    uint256 public constant PRE_SEED_A_RELEASE = 8;
    uint256 public constant PRE_SEED_A_CLIFF = 6 * 30 days;
    uint256 public constant PRE_SEED_A_PERIOD = 30 days;
    uint256 public constant PRE_SEED_A_TGE = 25;
    address public constant PRE_SEED_A_ADDRESS = 0x1E3110f9Ea5db599b9d5BE89EEc14cCe33f809a8;

    uint256 public constant PRE_SEED_B_PERCENT = 8;
    uint256 public constant PRE_SEED_B_RELEASE = 7;
    uint256 public constant PRE_SEED_B_CLIFF = 6 * 30 days;
    uint256 public constant PRE_SEED_B_PERIOD = 30 days;
    uint256 public constant PRE_SEED_B_TGE = 75;
    address public constant PRE_SEED_B_ADDRESS = 0x77A717112D5fa1d6905C603c39F48531af92394A;

    uint256 public constant COMMUNITY_PERCENT = 41;
    uint256 public constant COMMUNITY_TGE = 349;
    address public constant COMMUNITY_ADDRESS = 0x1a49F1E3EE2Eb56C7F4daE29E9e70933456dD56E;

    uint256 public constant DEVELOPMENT_PERCENT = 15;
    uint256 public constant DEVELOPMENT_RELEASE = 4;
    uint256 public constant DEVELOPMENT_CLIFF = 30 days; 
    uint256 public constant DEVELOPMENT_PERIOD = 30 days; 
    address public constant DEVELOPMENT_ADDRESS = 0x785D163855E958803E2cCd6fdFCa8Ba9c7654aa0;

    uint256 public constant ECOSYSTEM_PERCENT = 16;
    uint256 public constant ECOSYSTEM_RELEASE = 2;
    uint256 public constant ECOSYSTEM_CLIFF = 3 * 30 days; 
    uint256 public constant ECOSYSTEM_PERIOD = 5;
    uint256 public constant ECOSYSTEM_TGE = 30;
    uint256 public constant ECOSYSTEM_INCENTIVES = 5;
    address public constant ECOSYSTEM_ADDRESS = 0xe04630A879c20B05F7AaE19b8819743f9856A0f7;

    uint256 public constant MARKETING_PERCENT = 12;
    uint256 public constant MARKETING_RELEASE = 8;
    uint256 public constant MARKETING_PERIOD = 30 days;
    uint256 public constant MARKETING_TGE = 36;
    address public constant MARKETING_ADDRESS = 0xE9B11640Ef60d5c811546a49DCd3445cb1c80194;

    
    mapping(address => uint256) public tokenReleased;
    mapping(address => uint256) public lastReleasedTS;
    mapping(address => uint256) public claimedAmount;

    uint256 public tokenInitTS;
    bytes32 public communityRoot;
    bool public ecosystemIncentivesReleased;

    event TokenReleased(address indexed beneficiary, uint256 amount);
    event CommunityClaim(address indexed player, uint256 amount);

    constructor() ERC20("Flappy Moon Bird", "FMB") {
        tokenInitTS = block.timestamp;
        _mint(address(this), TOTAL_SUPPLY);
        // TGE
        _transfer(address(this), PRE_SEED_A_ADDRESS, TOTAL_SUPPLY * PRE_SEED_A_TGE /10000);
        _transfer(address(this), PRE_SEED_B_ADDRESS, TOTAL_SUPPLY * PRE_SEED_B_TGE /10000);
        _transfer(address(this), COMMUNITY_ADDRESS, TOTAL_SUPPLY * COMMUNITY_TGE /10000);
        _transfer(address(this), ECOSYSTEM_ADDRESS, TOTAL_SUPPLY * ECOSYSTEM_TGE /10000);
        _transfer(address(this), MARKETING_ADDRESS, TOTAL_SUPPLY * MARKETING_TGE / 10000);
        tokenReleased[PRE_SEED_A_ADDRESS] = TOTAL_SUPPLY * PRE_SEED_A_TGE /10000;
        tokenReleased[PRE_SEED_B_ADDRESS] = TOTAL_SUPPLY * PRE_SEED_B_TGE /10000;
        tokenReleased[COMMUNITY_ADDRESS] = TOTAL_SUPPLY * COMMUNITY_TGE /10000;
        tokenReleased[ECOSYSTEM_ADDRESS] = TOTAL_SUPPLY * ECOSYSTEM_TGE /10000;
        tokenReleased[MARKETING_ADDRESS] = TOTAL_SUPPLY * MARKETING_TGE /10000;
    }

    function setCommunityRoot(bytes32 merkleroot) external onlyOwner {
        communityRoot = merkleroot;
    }

    function _release(
        address beneficiary,
        uint256 releasedAmount,
        uint256 lastReleased,
        uint256 duration,
        uint256 percentage,
        uint256 max
    ) internal {
        uint256 releasable = vestedAmount(releasedAmount, block.timestamp, lastReleased, duration, percentage, max) -
            tokenReleased[beneficiary];
        tokenReleased[beneficiary] += releasable;
        lastReleasedTS[beneficiary] = block.timestamp;
        emit TokenReleased(beneficiary, releasable);
        _transfer(address(this), beneficiary, releasable);
    }

    function vestedAmount(
        uint256 releasedAmount,
        uint256 timestamp,
        uint256 lastReleased,
        uint256 duration,
        uint256 percentage,
        uint256 max
    ) public pure returns (uint256) {
        uint256 totalAllocation = max * percentage / 100;
        if (timestamp < lastReleased || releasedAmount >= max) {
            return 0;
        } else if (timestamp > lastReleased + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - lastReleased)) / duration;
        }
    }

    function claimPreA() external nonReentrant {
        require(msg.sender == PRE_SEED_A_ADDRESS, "Not PreA");
        require(block.timestamp >= PRE_SEED_A_CLIFF + tokenInitTS, "PreA cliff now");
        _release(
            msg.sender,
            tokenReleased[msg.sender],
            lastReleasedTS[msg.sender] == 0? PRE_SEED_A_CLIFF + tokenInitTS : lastReleasedTS[msg.sender],
            PRE_SEED_A_PERIOD,
            PRE_SEED_A_RELEASE,
            (TOTAL_SUPPLY * PRE_SEED_B_PERCENT) / 100
        );
    }

    function claimPreB() external nonReentrant {
        require(msg.sender == PRE_SEED_B_ADDRESS, "Not PreB");
        require(block.timestamp >= PRE_SEED_B_CLIFF + tokenInitTS, "PreB cliff now");
        _release(
            msg.sender,
            tokenReleased[msg.sender],
            lastReleasedTS[msg.sender] == 0? PRE_SEED_B_CLIFF + tokenInitTS : lastReleasedTS[msg.sender],
            PRE_SEED_B_PERIOD,
            PRE_SEED_B_RELEASE,
            (TOTAL_SUPPLY * PRE_SEED_B_PERCENT) / 100
        );
    }

    function claimCom(uint256 amount, bytes32[] calldata proof) external nonReentrant {
        require(TOTAL_SUPPLY * COMMUNITY_PERCENT / 100 > tokenReleased[COMMUNITY_ADDRESS] + amount, "No more token");
        require(amount > claimedAmount[msg.sender], "Already Claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool isValidLeaf = MerkleProof.verify(proof, communityRoot, leaf);
        require(isValidLeaf == true, "Not in merkle");
        claimedAmount[msg.sender] = amount;
        tokenReleased[COMMUNITY_ADDRESS] += amount;
        emit CommunityClaim(msg.sender, amount - claimedAmount[msg.sender]);
        transfer(msg.sender, amount - claimedAmount[msg.sender]);
    }

    function claimDev() external nonReentrant {
        require(msg.sender == DEVELOPMENT_ADDRESS, "Not Dev");
        require(block.timestamp >= DEVELOPMENT_CLIFF + tokenInitTS, "Dev cliff now");
        _release(
            msg.sender,
            tokenReleased[msg.sender],
            lastReleasedTS[msg.sender] == 0? DEVELOPMENT_CLIFF + tokenInitTS : lastReleasedTS[msg.sender],
            DEVELOPMENT_PERIOD,
            DEVELOPMENT_RELEASE,
            (TOTAL_SUPPLY * DEVELOPMENT_PERCENT) / 100
        );
    }

    function claimEco() external nonReentrant {
        require(msg.sender == ECOSYSTEM_ADDRESS, "Not Eco");
        require(block.timestamp >= ECOSYSTEM_CLIFF + tokenInitTS, "Eco cliff now");
        _release(
            msg.sender,
            tokenReleased[msg.sender],
            lastReleasedTS[msg.sender] == 0? ECOSYSTEM_CLIFF + tokenInitTS : lastReleasedTS[msg.sender],
            ECOSYSTEM_PERIOD,
            ECOSYSTEM_RELEASE,
            (TOTAL_SUPPLY * ECOSYSTEM_PERCENT) / 100
        );
    }

    function claimEcoIncentives() external nonReentrant {
        require(msg.sender == ECOSYSTEM_ADDRESS, "Not Eco");
        require(block.timestamp >= tokenInitTS + 30 days, "Not 1 month");
        require(ecosystemIncentivesReleased == false, "Ecosystem Incentives Claimed");
        ecosystemIncentivesReleased = true;
        _transfer(address(this), ECOSYSTEM_ADDRESS, TOTAL_SUPPLY * ECOSYSTEM_INCENTIVES / 100);
        tokenReleased[ECOSYSTEM_ADDRESS] += TOTAL_SUPPLY * ECOSYSTEM_INCENTIVES /100;
    }

    function claimMarket() external nonReentrant {
        require(msg.sender == ECOSYSTEM_ADDRESS, "Not Market");
        _release(
            msg.sender,
            tokenReleased[msg.sender],
            lastReleasedTS[msg.sender] == 0? MARKETING_PERIOD + tokenInitTS : lastReleasedTS[msg.sender],
            MARKETING_PERIOD,
            MARKETING_RELEASE,
            (TOTAL_SUPPLY * MARKETING_PERCENT) / 100
        );
    }

}