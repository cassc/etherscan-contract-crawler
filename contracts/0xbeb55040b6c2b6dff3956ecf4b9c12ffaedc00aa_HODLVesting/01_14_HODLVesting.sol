// SPDX-License-Identifier: UNLICENSED

//** HFD Vesting */
//** Author: Aaron Decubate 2022.9 */

pragma solidity ^0.8.16;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HODLVesting is AccessControl, ERC20 {
    using SafeERC20 for IERC20;

    struct VestedTokens {
        uint256 time;
        uint256 amount;
        bool claimed;
    }

    bytes32 public constant STAKING_CONTRACT_ROLE = keccak256("STAKING_CONTRACT_ROLE");
    IERC20 public immutable hfd; // Vested token
    uint256 public constant LOCK_PERIOD = 365 days; // 1 year lock period
    mapping(address => VestedTokens[]) public vesting;
    address public immutable bondingContract;
    uint256 public unlockDisabledUntil = 1706400000; //January 28 2024 00:00:00 GMT

    event VestingAdded(address indexed wallet, uint256 amount);
    event VestingClaimed(address indexed wallet, uint256 amount, uint256 penalty);
    event EscrowMinted(address wallet, uint256 amount);
    event EscrowBurned(address wallet, uint256 amount);
    event AdminChanged(address newAdmin);
    event StakingContractAdded(address staking);
    event StakingContractRemoved(address staking);
    event UnlockDisableTimeChanged(uint256 newTime);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "HODL: Not authorized");
        _;
    }

    modifier onlyAuthorized() {
        require(hasRole(STAKING_CONTRACT_ROLE, msg.sender), "HODL: Caller is not authorised");
        _;
    }

    constructor(
        address _hfd,
        address _bonding,
        address _stakingContract
    ) ERC20("HODL Finance DAO Escrow Token", "EHFD") {
        require(_hfd != address(0) && _bonding != address(0) && _stakingContract != address(0), "HODL: Zero address");
        hfd = IERC20(_hfd);
        bondingContract = _bonding;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAKING_CONTRACT_ROLE, _stakingContract);
    }

    function addVesting(address _wallet, uint256 _amount) external onlyAuthorized {
        VestedTokens[] storage userVesting = vesting[_wallet];
        userVesting.push(VestedTokens(block.timestamp, _amount, false));

        _mint(_wallet, _amount);

        emit VestingAdded(_wallet, _amount);
    }

    function mint(address _wallet, uint256 _amount) external onlyAuthorized {
        _mint(_wallet, _amount);
        emit EscrowMinted(_wallet, _amount);
    }

    function burn(address _wallet, uint256 _amount) external onlyAuthorized {
        _burn(_wallet, _amount);
        emit EscrowBurned(_wallet, _amount);
    }

    function claimUserVesting(uint256 _id) external {
        VestedTokens[] storage userVesting = vesting[msg.sender];

        require(_id < userVesting.length, "HODL: Vesting does not exist");
        require(block.timestamp >= unlockDisabledUntil, "HODL: Forced claim disabled");

        VestedTokens storage vest = userVesting[_id];

        require(!vest.claimed, "HODL: Vesting has already been claimed");

        uint256 amount = getClaimableAmount(msg.sender, _id);

        vest.claimed = true;
        // Burn escrow tokens in exhcange for HFD
        _burn(msg.sender, vest.amount);
        hfd.safeTransfer(msg.sender, amount);
        hfd.safeTransfer(bondingContract, vest.amount - amount);

        emit VestingClaimed(msg.sender, amount, vest.amount - amount);
    }

    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "HODL: Zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        emit AdminChanged(_newAdmin);
    }

    function addStakingContract(address _address) external onlyAdmin {
        _setupRole(STAKING_CONTRACT_ROLE, _address);
        emit StakingContractAdded(_address);
    }

    function removeStakingContract(address _address) external onlyAdmin {
        _revokeRole(STAKING_CONTRACT_ROLE, _address);
        emit StakingContractRemoved(_address);
    }

    function setUnlockDisableTime(uint256 _newTime) external onlyAdmin {
        unlockDisabledUntil = _newTime;
        emit UnlockDisableTimeChanged(_newTime);
    }

    function getUserVesting(address _wallet) external view returns (VestedTokens[] memory) {
        VestedTokens[] storage _userVesting = vesting[_wallet];
        return _userVesting;
    }

    function getClaimableAmount(address _wallet, uint256 _id) public view returns (uint256 amount) {
        VestedTokens[] memory userVesting = vesting[_wallet];
        VestedTokens memory vest = userVesting[_id];

        uint256 elaspedTime = block.timestamp - vest.time;

        amount = (elaspedTime * vest.amount) / LOCK_PERIOD;
    }

    function isStakingContract(address _address) external view returns (bool) {
        return hasRole(STAKING_CONTRACT_ROLE, _address);
    }
}