pragma solidity 0.8.17;

interface ISymbiosis {
    struct SymbiosisData {
        ISymbiosis symStruct;
        bytes data;
    }

    struct SymbiosisDescription {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        uint256 amount;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
    }
}