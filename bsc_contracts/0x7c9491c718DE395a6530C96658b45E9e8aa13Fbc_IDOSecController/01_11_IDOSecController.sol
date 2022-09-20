// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDOSec/IIDOSecController.sol";

import "./IDOSec.sol";

/** @title IDOController
 * @notice This contract creates IDOs and handle configuration
 */

contract IDOSecController is Ownable, IIDOSecController {
    // mapping to check operator
    mapping(address => bool) public override isOperator;

    // ido
    address[] public IDOs;

    // fee
    address public feeReceipient;
    uint256 public feePercent; // 1000: 100%;

    modifier isOperatorOrOwner() {
        require(isOperator[msg.sender] || owner() == msg.sender, "Not owner or operator");

        _;
    }

    constructor(address _feeReceipient, uint256 _feePercent) {
        _setFeeInfo(_feeReceipient, _feePercent);

        isOperator[msg.sender] = true;
    }

    function getIDOsCount() external view returns (uint256) {
        return IDOs.length;
    }

    function getFeeInfo() external view override returns (address, uint256) {
        return (feeReceipient, feePercent);
    }

    /**
     * @notice set operator
     */
    function setOperator(address user, bool bSet) external onlyOwner {
        require(user != address(0), "Invalid address");

        isOperator[user] = bSet;
    }

    function _setFeeInfo(address _feeReceipient, uint256 _feePercent) internal {
        require(_feeReceipient != address(0), "Invalid address");
        require(_feePercent < 1000, "Invalid percent");

        feePercent = _feePercent;
        feeReceipient = _feeReceipient;
    }

    /**
     * @notice setFeeInfo
     */
    function setFeeInfo(address _feeReceipient, uint256 _feePercent) external onlyOwner {
        _setFeeInfo(_feeReceipient, _feePercent);
    }

    /**
     * @notice createIDO
     */
    function createIDO(
        uint256 saleTarget,
        address fundToken,
        uint256 fundTarget,
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        uint256 minFundAmount,
        uint256 fcfsAmount,
        string memory meta
    ) external isOperatorOrOwner returns (address) {
        IDOSec ido = new IDOSec(this, saleTarget, fundToken, fundTarget);

        ido.setBaseData(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);

        ido.transferOwnership(msg.sender);

        IDOs.push(address(ido));

        emit NewIDOCreated(address(ido), msg.sender);

        return address(ido);
    }
}