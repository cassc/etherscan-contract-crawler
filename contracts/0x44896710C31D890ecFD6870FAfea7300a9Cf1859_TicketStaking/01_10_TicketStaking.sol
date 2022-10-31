pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./Interfaces/ITickets.sol";
import "./Interfaces/IMaestro.sol";

/**
 * https://opus-labs.io
 * @title   Maestro - Tickets Staking
 * @notice  Stake Maestro - Tickets NFTs
 * @author  BowTiedPickle
 */
contract TicketStaking is Ownable, ReentrancyGuard, ERC721Holder {
    event Stake(uint256 indexed token, address indexed depositor);
    event Unstake(uint256 indexed token, address indexed depositor);
    event StakingEnabled(bool newStatus);
    event TierWeightUpdated(uint8 tier, uint256 weight);

    ITickets public immutable tickets;
    IMaestro public maestro;

    struct StakeInfo {
        address depositor;
        uint8 tier;
        uint256 stakeTime;
    }

    mapping(uint256 => StakeInfo) public tokenToStakeInfo;

    bool public stakingEnabled;
    uint256 public totalStaked;

    uint8 public constant TICKET_DIAMOND = 1;
    uint8 public constant TICKET_GOLD = 2;
    uint8 public constant TICKET_SILVER = 3;
    uint8 public constant TICKET_BRONZE = 4;

    mapping(uint8 => uint256) public tierToWeight;

    // ----- Construction -----

    /**
     * @param   _tickets    Address of the Maestro - Tickets contract
     */
    constructor(ITickets _tickets) {
        tickets = _tickets;
        tierToWeight[TICKET_DIAMOND] = 20_000;
        tierToWeight[TICKET_GOLD] = 15_000;
        tierToWeight[TICKET_SILVER] = 12_500;
        tierToWeight[TICKET_BRONZE] = 10_000;
    }

    // ----- Public Functions -----

    /**
     * @notice  Stake a Maestro - Ticket NFT
     * @param   _token  Token ID of the ticket to stake
     */
    function stake(uint256 _token) external nonReentrant {
        require(stakingEnabled, "!enabled");
        stakeInternal(_token);
    }

    /**
     * @notice  Stake multiple Maestro - Ticket NFTs
     * @param   _tokens   Token IDs of the tickets to stake
     */
    function stakeMultiple(uint256[] calldata _tokens) external nonReentrant {
        require(stakingEnabled, "!enabled");
        uint256 len = _tokens.length;
        for (uint256 i; i < len; ) {
            stakeInternal(_tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Unstake a Maestro - Ticket NFT
     * @param   _token  Token ID of the ticket to unstake
     */
    function unstake(uint256 _token) external nonReentrant {
        unstakeInternal(msg.sender, _token);
    }

    /**
     * @notice  Unstake multiple Maestro - Ticket NFTs
     * @param   _tokens   Token IDs of the tickets to unstake
     */
    function unstakeMultiple(uint256[] calldata _tokens) external nonReentrant {
        uint256 len = _tokens.length;
        for (uint256 i; i < len; ) {
            unstakeInternal(msg.sender, _tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    function stakeInternal(uint256 _token) internal {
        StakeInfo storage stakeInfo = tokenToStakeInfo[_token];
        require(stakeInfo.depositor == address(0), "!staked");

        ++totalStaked;
        stakeInfo.depositor = msg.sender;
        stakeInfo.stakeTime = block.timestamp;
        uint8 tier = tickets.ticketTier(_token);
        stakeInfo.tier = tier;

        maestro.notifyTicketStaked(true, msg.sender, tier);

        // Intake token
        tickets.safeTransferFrom(msg.sender, address(this), _token);

        emit Stake(_token, msg.sender);
    }

    function unstakeInternal(address _to, uint256 _token) internal {
        StakeInfo storage stakeInfo = tokenToStakeInfo[_token];
        require(stakeInfo.depositor == _to, "!owner");

        --totalStaked;
        stakeInfo.depositor = address(0);
        stakeInfo.stakeTime = 0;
        uint8 tier = stakeInfo.tier;
        stakeInfo.tier = 0;

        maestro.notifyTicketStaked(false, _to, tier);

        // Send out token
        tickets.safeTransferFrom(address(this), _to, _token);

        emit Unstake(_token, _to);
    }

    // ----- View Functions -----

    /**
     * @notice  View the time a ticket has been staking
     * @param   _token  Token ID of the ticket
     */
    function timeStaking(uint256 _token) external view returns (uint256) {
        uint256 stakeTime = tokenToStakeInfo[_token].stakeTime;
        return stakeTime > 0 ? block.timestamp - stakeTime : 0;
    }

    /**
     * @notice  View the Notes a ticket has accumulated
     * @param   _token  Token ID of the ticket
     */
    function notesBalance(uint256 _token) external view returns (uint256) {
        StakeInfo memory stakeInfo = tokenToStakeInfo[_token];
        uint256 stakeTime = stakeInfo.stakeTime;
        uint256 tierWeight = tierToWeight[stakeInfo.tier];
        if (stakeTime > 0) {
            return ((block.timestamp - stakeTime) * tierWeight) / 10_000;
        } else {
            return 0;
        }
    }

    /**
     * @notice  View if a ticket is currently staked
     * @param   _token  Token ID of the ticket
     */
    function isStaked(uint256 _token) external view returns (bool) {
        return tokenToStakeInfo[_token].stakeTime > 0;
    }

    /**
     * @notice  View all staking information for a ticket
     * @param   _token  Token ID of the ticket
     */
    function getStakeInfo(uint256 _token)
        external
        view
        returns (StakeInfo memory)
    {
        return tokenToStakeInfo[_token];
    }

    // ----- Admin Functions -----

    /**
     * @notice  Force unstake a user in case staking needs to be disabled
     * @dev     Permissioned
     * @param   _token  Token ID of the ticket to unstake
     */
    function unstakeFor(address _to, uint256 _token)
        external
        nonReentrant
        onlyOwner
    {
        unstakeInternal(_to, _token);
    }

    /**
     * @notice  Enable or disable staking
     * @param   _status     True for enabled, false for disabled
     */
    function setStakingEnabled(bool _status) external onlyOwner {
        stakingEnabled = _status;
        emit StakingEnabled(_status);
    }

    /**
     * @notice  Set the Notes generation weight of a ticket tier
     * @dev     Set to 0 to disable Notes for this ticket
     * @param   _tier   Ticket tier
     * @param   _weight New weight, where <10,000 is a penalty, 10,000 is neutral, and greater than 10,000 is a boost
     */
    function setTierWeight(uint8 _tier, uint256 _weight) external onlyOwner {
        require(_tier <= TICKET_BRONZE && _tier > 0, "!tier");
        tierToWeight[_tier] = _weight;
        emit TierWeightUpdated(_tier, _weight);
    }

    // ----- Irreversible Admin Functions -----

    /**
     * @notice  Irreversibly set the Maestro - Genesis contract address
     * @dev     May only be called once
     * @param   _maestro    Address of Maestro - Genesis contract
     */
    function setMaestro(IMaestro _maestro) external onlyOwner {
        require(address(maestro) == address(0), "!initialized");
        maestro = _maestro;
    }
}