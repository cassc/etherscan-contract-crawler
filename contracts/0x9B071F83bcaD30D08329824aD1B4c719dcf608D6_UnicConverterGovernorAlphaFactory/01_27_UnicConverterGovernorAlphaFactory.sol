pragma solidity 0.6.12;

import {ConverterGovernorAlpha} from "./ConverterGovernorAlpha.sol";
import './interfaces/IUnicConverterGovernorAlphaFactory.sol';

contract UnicConverterGovernorAlphaFactory is IUnicConverterGovernorAlphaFactory {

    /**
     * Creates the ConverterGovernorAlpha contract for the proxy transaction functionality for a given uToken
     */
    function createGovernorAlpha(
        address uToken,
        address guardian,
        address converterTimeLock,
        address config
    ) external override returns (address) {
        return address(new ConverterGovernorAlpha(converterTimeLock, uToken, guardian, config));
    }
}