// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./XenlonMarsERC20.sol";
import "./DBXenERC20.sol";

contract XenlonMars is ERC2771Context, ReentrancyGuard {
    using SafeERC20 for XenlonMarsERC20;

    struct BurnDetails {
        address user;
        uint256 amount;
        uint256 reward;
    }

    /**
     * Xenlon Mars token contract
     */
    XenlonMarsERC20 public xlon;

    /**
     * DBXen Token contract.
     */
    DBXenERC20 public dxn;

    /**
     * Contract creation timestamp.
     */
    uint256 public immutable initialTimestamp;

    /**
     * Timestamps logged per burn.
     */
    uint256[] public burnTimestamps;

    /**
     * Total number of burns.
     */
    uint256 public totalBurns;

    /**
     * Amount of XLON tokens per DXN burned
     */
    uint256 public constant XLON_PER_DXN = 100_000_000;

    /**
     * The address DXN is sent to for burning
     */
    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    // user address => DXN burn amount
    mapping(address => uint256) public burnsByUser;

    // timestamp => burn details
    mapping(uint256 => BurnDetails) public burnsByTimestamp;

    event burned(address user, uint256 amount);

    constructor(
        address forwarder,
        address dbxenTokenAddress
    ) ERC2771Context(forwarder) {
        xlon = new XenlonMarsERC20();
        initialTimestamp = block.timestamp;
        dxn = DBXenERC20(dbxenTokenAddress);
    }

    function mint(uint256 amount) internal nonReentrant {
        xlon.mint(_msgSender(), amount);
    }

    function burn(uint256 amount) external {
        require(
            dxn.transferFrom(msg.sender, address(BURN_ADDRESS), amount),
            "burn failed"
        );
        BurnDetails memory burnDetails = BurnDetails({
            user: _msgSender(),
            amount: amount,
            reward: amount * XLON_PER_DXN
        });
        burnsByTimestamp[block.timestamp] = burnDetails;
        burnTimestamps.push(block.timestamp);
        burnsByUser[_msgSender()] += amount;
        totalBurns = totalBurns + 1;
        emit burned(_msgSender(), amount);
        mint(amount * XLON_PER_DXN);
    }
}