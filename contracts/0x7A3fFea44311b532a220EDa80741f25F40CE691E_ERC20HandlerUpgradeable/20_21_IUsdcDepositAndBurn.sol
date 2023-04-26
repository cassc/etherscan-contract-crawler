// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUsdcDepositAndBurn {
    struct DestDetails {
        uint8 chainId;
        uint32 usdcDomainId;
        address reserveHandlerAddress;
        address destCallerAddress;
    }

    function setDestDetails(DestDetails[] memory destDetails) external;

    function depositAndBurnUsdc(uint8 destChainId, uint256 amount) external returns (uint64);
}