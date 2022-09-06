// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AelinFeeEscrow {
    using SafeERC20 for IERC20;
    uint256 public vestingExpiry;
    address public treasury;
    address public futureTreasury;
    address public escrowedToken;

    bool private calledInitialize;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new escrow created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the treasury may change their address
     */
    function setTreasury(address _treasury) external onlyTreasury {
        require(_treasury != address(0));
        futureTreasury = _treasury;
    }

    function acceptTreasury() external {
        require(msg.sender == futureTreasury, "only future treasury can access");
        treasury = futureTreasury;
        emit SetTreasury(futureTreasury);
    }

    function initialize(address _treasury, address _escrowedToken) external initOnce {
        treasury = _treasury;
        vestingExpiry = block.timestamp;
        escrowedToken = _escrowedToken;
        emit InitializeEscrow(msg.sender, _treasury, vestingExpiry, escrowedToken);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury can access");
        _;
    }

    function delayEscrow() external onlyTreasury {
        require(vestingExpiry < block.timestamp + 90 days, "can only extend by 90 days");
        vestingExpiry = block.timestamp + 90 days;
        emit DelayEscrow(vestingExpiry);
    }

    /**
     * @dev transfer all the escrow tokens to the treasury
     */
    function withdrawToken() external onlyTreasury {
        require(block.timestamp > vestingExpiry, "cannot access funds yet");
        uint256 balance = IERC20(escrowedToken).balanceOf(address(this));
        IERC20(escrowedToken).safeTransfer(treasury, balance);
    }

    event SetTreasury(address indexed treasury);
    event InitializeEscrow(
        address indexed dealAddress,
        address indexed treasury,
        uint256 vestingExpiry,
        address indexed escrowedToken
    );
    event DelayEscrow(uint256 vestingExpiry);
}