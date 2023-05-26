// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISalesPolicyFactory {
    function getProtocolId(address _protocolAddress) external view returns (uint16);

    function checkIfProtocolInWhitelistArray() external view returns (bool);

    function getProtocolData(uint16 _protocolIdx) external view returns (address protocolAddress, bool isBlackList);

    // function newSalesPolicy(
    //     uint16 _protocolIdx,
    //     address _exchangeAgent,
    //     address _premiumPool,
    //     address _capitalAgent,
    //     string memory _protocolURI
    // ) external returns (address);
}