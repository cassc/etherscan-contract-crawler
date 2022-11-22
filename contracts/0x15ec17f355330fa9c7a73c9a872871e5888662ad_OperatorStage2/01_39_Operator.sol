// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/Stage2/BondingEvent.sol";
import "contracts/Pausable.sol";
import "contracts/Drainable.sol";

contract OperatorStage2 is AccessControl, Pausable, Drainable {
    bytes32 public constant OPERATOR_STAGE_2 = keccak256("OPERATOR_STAGE_2");

    // BondingEvent dependency
    BondingEvent public bondingEvent;

    struct BondRate { uint256 rate; uint256 duration; }

    // Save the rates added
    BondRate[] ratesAvailable;
    // Emit an event when a new yield is added
    event Yield(uint256 indexed rate, uint256 indexed duration);

    constructor() {
        _setupRole(OPERATOR_STAGE_2, msg.sender);
    }

    modifier onlyOperatorStage2() { require(hasRole(OPERATOR_STAGE_2, msg.sender), "err-invalid-sender"); _; }

    function setBonding(address _newAddress) external onlyOperatorStage2 {
        require(_newAddress != address(bondingEvent), "err-same-address");
        bondingEvent = BondingEvent(_newAddress);
    }

    function addUniqueRate(BondRate memory _bondRate) private {
        for (uint256 i = 0; i < ratesAvailable.length; i++) if (ratesAvailable[i].rate == _bondRate.rate) revert("err-rate-exists");
        ratesAvailable.push(_bondRate);
    }

    // Adds a new rate that allows a user to bond with
    function addRate(uint256 _rate, uint256 duration) public onlyOperatorStage2 {
        addUniqueRate(BondRate(_rate, duration));
        emit Yield(_rate, duration);
    }

    function getBondRate(uint256 _rate) private view returns (BondRate memory rate, uint256 index) {
        for (; index < ratesAvailable.length; index++) if (ratesAvailable[index].rate == _rate) return (ratesAvailable[index], index);
        revert("err-rate-not-found");
    }

    function removeRate(uint256 _rate) external onlyOperatorStage2 {
        // delete rate from available rates without caring for order
        // so sorting may be required on the frontend
        // copy last rate to deleted item's such that there is a duplicate of it
        (,uint256 rateIndex) = getBondRate(_rate);
        ratesAvailable[rateIndex] = ratesAvailable[ratesAvailable.length - 1];
        ratesAvailable.pop();

        emit Yield(_rate, 0);
    }

    // Displays all the rates available as pairs of (rate, duration)
    function showRates() external view returns (BondRate[] memory) { return ratesAvailable; }

    function newBond(uint256 _amountSeuro, uint256 _rate) external ifNotPaused {
        (BondRate memory bondRate,) = getBondRate(_rate);
        bondingEvent.bond(msg.sender, _amountSeuro, bondRate.duration, _rate);
    }
}