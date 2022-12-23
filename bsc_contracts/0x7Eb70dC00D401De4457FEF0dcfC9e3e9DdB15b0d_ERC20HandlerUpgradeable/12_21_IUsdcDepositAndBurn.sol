// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IUsdcDepositAndBurn {
    struct DestDetails {
        uint8 chainId;
        uint32 usdcDomainId;
        address reserveHandlerAddress;
        address destCallerAddress;
    }

    function setDestDetails(DestDetails[] memory destDetails) external;

    function depositAndBurnUsdc(
        address sender,
        uint256 amount,
        uint8 destChainId
    ) external returns (uint64);
}