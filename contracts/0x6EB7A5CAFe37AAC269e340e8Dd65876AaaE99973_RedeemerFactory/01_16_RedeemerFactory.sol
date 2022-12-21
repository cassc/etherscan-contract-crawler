// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Redeemer.sol";
import "./interfaces/IRedeemerFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RedeemerFactory is IRedeemerFactory, Ownable {
    int public constant Version = 3;

    address public protocolManagerAddr;

    function setPMAddress(address _pmAddress) external onlyOwner {
        require(_pmAddress != address(0x0), "ZERO Addr is not allowed");
        protocolManagerAddr = _pmAddress;
    }

    function createRedeemerContract(
        address fluentToken,
        address burnerContract,
        address fedMember,
        address redeemersBookkeper,
        address redeemersTreasury
    ) external returns (address) {
        require(msg.sender == protocolManagerAddr, "Caller is not the PM");
        Redeemer newRedeemer = new Redeemer(
            fluentToken,
            burnerContract,
            fedMember,
            redeemersBookkeper,
            redeemersTreasury
        );

        return address(newRedeemer);
    }
}