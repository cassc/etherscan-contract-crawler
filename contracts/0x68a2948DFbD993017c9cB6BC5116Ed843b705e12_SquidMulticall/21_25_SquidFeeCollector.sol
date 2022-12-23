// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Upgradable.sol";
import {ISquidFeeCollector} from "./interfaces/ISquidFeeCollector.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidFeeCollector is ISquidFeeCollector, Upgradable {
    bytes32 private constant BALANCES_PREFIX = keccak256("SquidFeeCollector.balances");
    bytes32 private constant SPECIFIC_FEES_PREFIX = keccak256("SquidFeeCollector.specificFees");
    address public immutable squidTeam;
    // Value expected with 2 decimals
    /// eg. 825 is 8.25%
    uint256 public immutable squidDefaultFee;

    error ZeroAddressProvided();

    constructor(address _squidTeam, uint256 _squidDefaultFee) {
        if (_squidTeam == address(0)) revert ZeroAddressProvided();

        squidTeam = _squidTeam;
        squidDefaultFee = _squidDefaultFee;
    }

    /// @param integratorFee Value expected with 2 decimals
    /// eg. 825 is 8.25%
    function collectFee(
        address token,
        uint256 amountToTax,
        address integratorAddress,
        uint256 integratorFee
    ) external {
        if (integratorFee > 1000) revert ExcessiveIntegratorFee();

        uint256 specificFee = getSpecificFee(integratorAddress);
        uint256 squidFee = specificFee == 0 ? squidDefaultFee : specificFee;

        uint256 baseFeeAmount = (amountToTax * integratorFee) / 10000;
        uint256 squidFeeAmount = (baseFeeAmount * squidFee) / 10000;
        uint256 integratorFeeAmount = baseFeeAmount - squidFeeAmount;

        _safeTransferFrom(token, msg.sender, baseFeeAmount);
        _setBalance(token, squidTeam, getBalance(token, squidTeam) + squidFeeAmount);
        _setBalance(token, integratorAddress, getBalance(token, integratorAddress) + integratorFeeAmount);

        emit FeeCollected(token, integratorAddress, squidFeeAmount, integratorFeeAmount);
    }

    function withdrawFee(address token) external {
        uint256 balance = getBalance(token, msg.sender);
        _setBalance(token, msg.sender, 0);
        _safeTransfer(token, msg.sender, balance);

        emit FeeWithdrawn(token, msg.sender, balance);
    }

    function setSpecificFee(address integrator, uint256 fee) external onlyOwner {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            sstore(slot, fee)
        }
    }

    function getBalance(address token, address account) public view returns (uint256 value) {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            value := sload(slot)
        }
    }

    function getSpecificFee(address integrator) public view returns (uint256 value) {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            value := sload(slot)
        }
    }

    function contractId() external pure returns (bytes32 id) {
        id = keccak256("squid-fee-collector");
    }

    function _setBalance(
        address token,
        address account,
        uint256 amount
    ) private {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            sstore(slot, amount)
        }
    }

    function _computeBalanceSlot(address token, address account) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(BALANCES_PREFIX, token, account));
    }

    function _computeSpecificFeeSlot(address integrator) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(SPECIFIC_FEES_PREFIX, integrator));
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }
}