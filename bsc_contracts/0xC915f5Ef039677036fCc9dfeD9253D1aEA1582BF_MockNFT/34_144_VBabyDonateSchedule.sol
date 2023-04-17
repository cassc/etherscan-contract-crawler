// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/VBabyToken.sol";

contract VBabyDonateSchedule is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public vault;
    address public caller;
    uint256 public donationsPerDay;
    vBABYToken public vBaby;
    IERC20 public babyToken;
    bool public isPause;
    mapping(uint256 => bool) public isExecuted;

    event NewDonations(uint256 oldValue, uint256 newValue);
    event NewVault(address oldVault, address newVault);
    event NewCaller(address oldCaller, address newCaller);
    event SwitchDonate(bool isPause);
    event DonateExecuted(uint256 value);

    constructor(
        vBABYToken vBaby_,
        IERC20 babyToken_,
        address vault_,
        address caller_,
        uint256 donationsPerDay_
    ) {
        vBaby = vBaby_;
        babyToken = babyToken_;
        vault = vault_;
        caller = caller_;
        donationsPerDay = donationsPerDay_;
    }

    function setVault(address _vault) external onlyOwner {
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function switchDonate() external onlyOwner {
        isPause = !isPause;
        emit SwitchDonate(isPause);
    }

    function setCaller(address _caller) external onlyOwner {
        emit NewCaller(caller, _caller);
        caller = _caller;
    }

    function setDonationsPerDay(uint256 _donationsPerDay) external onlyOwner {
        emit NewDonations(donationsPerDay, _donationsPerDay);
        donationsPerDay = _donationsPerDay;
    }

    modifier onlyCaller() {
        require(msg.sender == caller, "only the caller can do this action");
        _;
    }

    function execDonate() external onlyCaller {
        require(!isExecuted[block.timestamp.div(1 days)], "executed today");
        require(!isPause, "task paused");
        isExecuted[block.timestamp.div(1 days)] = true;
        babyToken.safeTransferFrom(vault, address(this), donationsPerDay);
        babyToken.approve(address(vBaby), donationsPerDay);
        vBaby.donate(donationsPerDay);

        emit DonateExecuted(donationsPerDay);
    }
}