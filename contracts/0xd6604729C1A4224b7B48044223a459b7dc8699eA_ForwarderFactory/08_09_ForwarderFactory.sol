// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import "./Errors.sol";
import "./Ownable.sol";
import "./Forwarder.sol";

contract ForwarderFactory is Ownable {
    address public immutable referenceForwarder;
    address public sink;

    constructor(address _sink) {
        _updateSink(_sink);
        referenceForwarder = address(new Forwarder());
    }

    function _verifySink(address _sink) internal pure {
        if (_sink == address(0)) {
            revert SinkZeroAddress();
        }
    }

    function _updateSink(address _sink) internal {
        _verifySink(_sink);
        sink = _sink;
    }

    function updateSink(address _sink) external onlyOwner {
        _updateSink(_sink);
    }

    function getAddress(bytes32 salt) public view returns (address) {
        return Clones.predictDeterministicAddress(referenceForwarder, salt, address(this));
    }

    function _getBalance(address forwarder, address erc20TokenContract) internal view returns (uint256) {
        if (erc20TokenContract == address(0)) {
            return forwarder.balance;
        } else {
            return IERC20(erc20TokenContract).balanceOf(forwarder);
        }
    }

    function getBalances(
        address[] memory forwarderAddresses,
        address[] memory erc20TokenContracts
    ) public view returns (uint256[] memory) {
        uint256 len = forwarderAddresses.length;
        uint256[] memory balances = new uint256[](len);

        for (uint256 index = 0; index < len; ) {
            balances[index] = _getBalance(forwarderAddresses[index], erc20TokenContracts[index]);

            unchecked {
                index++;
            }
        }

        return balances;
    }

    function _deployForwarder(bytes32 salt) internal returns (Forwarder forwarder) {
        forwarder = Forwarder(payable(Clones.cloneDeterministic(referenceForwarder, salt)));
        forwarder.init(address(this));
    }

    function _batchDeployFlush(
        address _sink,
        bytes32[] calldata salts,
        address[] calldata erc20TokenContracts
    ) internal {
        uint256 len = salts.length;

        for (uint256 index = 0; index < len; ) {
            _deployForwarder(salts[index]).flush(_sink, erc20TokenContracts[index]);

            unchecked {
                index++;
            }
        }
    }

    function _batchFlush(
        address _sink,
        address[] calldata forwarders,
        address[] calldata erc20TokenContracts
    ) internal {
        uint256 len = forwarders.length;

        for (uint256 index = 0; index < len; ) {
            Forwarder(payable(forwarders[index])).flush(_sink, erc20TokenContracts[index]);

            unchecked {
                index++;
            }
        }
    }

    function batchDeployFlush(bytes32[] calldata salts, address[] calldata erc20TokenContracts) external {
        _batchDeployFlush(sink, salts, erc20TokenContracts);
    }

    function batchFlush(address[] calldata forwarders, address[] calldata erc20TokenContracts) external {
        _batchFlush(sink, forwarders, erc20TokenContracts);
    }

    function customSinkBatchDeployFlush(
        address _sink,
        bytes32[] calldata salts,
        address[] calldata erc20TokenContracts
    ) external onlyOwner {
        _verifySink(_sink);
        _batchDeployFlush(_sink, salts, erc20TokenContracts);
    }

    function customSinkBatchFlush(
        address _sink,
        address[] calldata forwarders,
        address[] calldata erc20TokenContracts
    ) external onlyOwner {
        _verifySink(_sink);
        _batchFlush(_sink, forwarders, erc20TokenContracts);
    }
}