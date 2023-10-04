// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20BackwardsCompatible.sol";
import "./interfaces/IHouseV2.sol";

contract esSMCIncentivePool is Ownable, ReentrancyGuard {
    error NoIncentivesUnclaimed();
    error NoIncentivesRemaining();

    address public immutable esSMC;
    IERC20BackwardsCompatible public immutable essmc;
    IHouse public immutable house;

    mapping (address => uint256) incentivesClaimed;

    constructor (address _esSMC, address _house) {
        esSMC = _esSMC;
        essmc = IERC20BackwardsCompatible(_esSMC);
        house = IHouse(_house);
    }

    function claimIncentives() external nonReentrant returns (uint256) {
        uint256 _incentivesUnclaimed = getIncentivesTotal(msg.sender) - incentivesClaimed[msg.sender];
        if (_incentivesUnclaimed == 0) {
            revert NoIncentivesUnclaimed();
        }
        if (_incentivesUnclaimed > essmc.balanceOf(address(this))) {
            if (essmc.balanceOf(address(this)) == 0) {
                revert NoIncentivesRemaining();
            }
            _incentivesUnclaimed = essmc.balanceOf(address(this));
        }
        incentivesClaimed[msg.sender] += _incentivesUnclaimed;
        essmc.transfer(msg.sender, _incentivesUnclaimed);
        return _incentivesUnclaimed;
    }

    function getIncentivesClaimed(address _account) external view returns (uint256) {
        return incentivesClaimed[_account];
    }

    function getIncentivesTotal(address _account) public view returns (uint256) {
        (, uint256 _wagered,,,) = house.getPlayerStats(_account);
        return _wagered * (10**11);
    }
}