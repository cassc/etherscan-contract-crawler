// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import "./Forwarder.sol";

contract ForwarderFactory is Ownable {
    address public immutable referenceForwarder;
    address public sink;

    constructor(address _sink) {
        referenceForwarder = address(new Forwarder());
        sink = _sink;
    }

    function getAddress(bytes32 salt) public view returns (address) {
        return Clones.predictDeterministicAddress(referenceForwarder, salt, address(this));
    }

    function getBalance(address forwarder, address erc20TokenContract) internal view returns (uint256) {
        if (erc20TokenContract == address(0)) {
            return forwarder.balance;
        } else {
            IERC20 erc20 = IERC20(erc20TokenContract);
            return erc20.balanceOf(forwarder);
        }
    }

    function getBalances(
        address[] memory forwarderAddresses,
        address[] memory erc20TokenContracts
    ) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](forwarderAddresses.length);

        for (uint256 index = 0; index < forwarderAddresses.length; index++) {
            balances[index] = getBalance(forwarderAddresses[index], erc20TokenContracts[index]);
        }

        return balances;
    }

    function getBalanceFromSalts(
        bytes32[] calldata salts,
        address[] calldata erc20TokenContracts
    ) public view returns (uint256[] memory) {
        address[] memory forwarderAddresses = new address[](salts.length);

        for (uint256 index = 0; index < salts.length; index++) {
            forwarderAddresses[index] = getAddress(salts[index]);
        }

        return getBalances(forwarderAddresses, erc20TokenContracts);
    }

    function updateSink(address _sink) external onlyOwner {
        require(_sink != address(0), "Sink cannot be empty");
        sink = _sink;
    }

    function deployForwarder(bytes32 salt) internal returns (Forwarder forwarder) {
        forwarder = Forwarder(payable(Clones.cloneDeterministic(referenceForwarder, salt)));
        forwarder.init(sink);
    }

    function deployAndFlushNative(bytes32 salt) external {
        deployForwarder(salt).flushNative();
    }

    function deployAndFlushERC20(bytes32 salt, address erc20TokenContract) external {
        deployForwarder(salt).flushERC20(erc20TokenContract);
    }

    function batchDeployAndFlush(bytes32[] calldata salts, address[] calldata erc20TokenContracts) external {
        for (uint256 index = 0; index < salts.length; index++) {
            deployForwarder(salts[index]).flush(erc20TokenContracts[index]);
        }
    }

    function batchFlush(address[] calldata forwarders, address[] calldata erc20TokenContracts) external {
        for (uint256 index = 0; index < forwarders.length; index++) {
            Forwarder(payable(forwarders[index])).flush(erc20TokenContracts[index]);
        }
    }
}