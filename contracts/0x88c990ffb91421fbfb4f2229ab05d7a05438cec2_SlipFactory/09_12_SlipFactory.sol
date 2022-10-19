// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Slip.sol";
import "../interfaces/ISlipFactory.sol";

/**
 * @dev Factory for Iou minimal proxy contracts
 */
contract SlipFactory is ISlipFactory, Context {
    address public immutable target;

    constructor(address _target) {
        target = _target;
    }

    /**
     * @inheritdoc ISlipFactory
     */
    function createSlip(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external override returns (address) {
        address clone = Clones.clone(target);
        Slip(clone).init(name, symbol, _msgSender(), _collateralToken);
        emit SlipCreated(clone);
        return clone;
    }
}