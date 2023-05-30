// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

import "./Rockets.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Dawgs2 is ERC20Burnable, ERC20Permit, Ownable {
    uint8 private constant __decimals = 9;
    uint256 private constant __totalSupply = 1e12 * 1e9; // one trillion, 9 decimals
    string private constant __name = "SpaceDawgs";
    string private constant __symbol = "DAWGS";

    uint256 private constant __rocketsRatioFull = 1e7; // 10 million : 1
    uint256 private constant __rocketsRatioHalf = 2e7; // 20 million : 1
    uint256 private constant __rocketsSupply = 200000 * 1e9; // 200,000 with 9 decimals
    uint256 private constant __secondsOf72Hours = 259200; // 72 hours

    // The time when upgrading from v1 to v2 is enabled
    uint256 public startTime;

    IERC20 immutable dawgsV1; //  0x9F8eef61b1Ad834B44C089DBF33eb854746a6bf9
    Rockets rockets;

    event Deployed(address sender, address __rocketsSupply);
    event UpgradeDawgs(address sender, uint256 amountDawgs, uint256 amountRockets);
    event UpdateStartTime(uint256 newStartTime);

    constructor(address _dawgsV1, uint256 _startTime) ERC20(__name, __symbol) ERC20Permit(__name) {
        require(_dawgsV1 != address(0), "Dawgs2: Invalid dawgsV1 address");
        // Total supply to this contract
        _mint(address(this), __totalSupply);
        // New governance token.
        rockets = new Rockets();
        // 50% of governance token to deployer;
        // The following condition is always true unless there is an error in the rockets contract.
        require(
            rockets.balanceOf(address(this)) == __rocketsSupply,
            "Dawgs2: Unexpected Rockets supply"
        );
        rockets.transfer(_msgSender(), __rocketsSupply / 2);
        // dawgsV1 contact
        dawgsV1 = IERC20(_dawgsV1);
        // Start Time
        startTime = _startTime;
        emit Deployed(_msgSender(), address(rockets));
    }

    function decimals() public pure override returns (uint8) {
        return __decimals;
    }

    /**
     * @notice Swap V1 for V2 at 1:1 and receive bonus RKTS. Sender must pre-approve Dawgs2 to spend Dawgs.
     * @dev Non-inflationary. Not all Dawgs will be claimable owing to burning of V1 supply.
     * @dev Received amount will be less than requested amount (RFI). V1 burn ensures insolvency is not possible.
     * @param amount 9-decimal amount to swap
     */
    function upgradeDawgs(uint256 amount) external {
        require(block.timestamp >= startTime, "Dawgs2: Not started yet");
        uint256 passedTime = block.timestamp - startTime;
        address sender = _msgSender();
        uint256 rocketsAmount;
        if (passedTime < __secondsOf72Hours) {
            // First 72 hours after start
            rocketsAmount = amount / __rocketsRatioFull;
        } else if (passedTime < __secondsOf72Hours * 2) {
            // Second 72 hours after start
            rocketsAmount = amount / __rocketsRatioHalf;
        } else {
            rocketsAmount = 0;
        }
        dawgsV1.transferFrom(sender, address(this), amount);
        _transfer(address(this), sender, amount);
        if (rocketsAmount > 0) {
            rockets.transfer(sender, rocketsAmount);
        }
        emit UpgradeDawgs(sender, amount, rocketsAmount);
    }

    function rocketsToken() external view returns (address) {
        return address(rockets);
    }

    // Only update before start
    function updateStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "Dawgs2: Cannot change start time after started");
        require(block.timestamp < _newStartTime, "Dawgs2: Cannot set start time in the past");
        startTime = _newStartTime;

        emit UpdateStartTime(startTime);
    }

    function mintRockets(address to, uint256 amount) external onlyOwner {
        rockets.mint(to, amount);
    }

    function burnRockets(uint256 amount) external onlyOwner {
        rockets.burn(amount);
    }

    function transferRocketsOwnership(address newOwner) external onlyOwner {
        rockets.transferOwnership(newOwner);
    }
}