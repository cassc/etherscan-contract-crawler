pragma solidity >=0.5.0;

interface IUnicConverterGovernorAlphaFactory {
    function createGovernorAlpha(
        address uToken,
        address guardian,
        address converterTimeLock,
        address config
    ) external returns (address);
}