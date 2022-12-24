// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GenericErrors {
    ///// TokenAddressIsZero();
    string internal constant E00 = "E00";

    ///// TokenNotSupported();
    string internal constant E01 = "E01";

    ///// CannotBridgeToSameNetwork();
    string internal constant E02 = "E02";

    ///// ZeroPostSwapBalance();
    string internal constant E03 = "E03";

    ///// NoSwapDataProvided();
    string internal constant E04 = "E04";

    ///// NativeValueWithERC();
    string internal constant E05 = "E05";

    ///// ContractCallNotAllowed();
    string internal constant E06 = "E06";

    ///// NullAddrIsNotAValidSpender();
    string internal constant E07 = "E07";

    ///// NullAddrIsNotAnERC20Token();
    string internal constant E08 = "E08";

    ///// NoTransferToNullAddress();
    string internal constant E09 = "E09";

    ///// NativeAssetTransferFailed();
    string internal constant E10 = "E10";

    ///// InvalidBridgeConfigLength();
    string internal constant E11 = "E11";

    ///// InvalidAmount();
    string internal constant E12 = "E12";

    ///// InvalidContract();
    string internal constant E13 = "E13";

    ///// InvalidConfig();
    string internal constant E14 = "E14";

    ///// UnsupportedChainId(uint256 chainId);
    string internal constant E15 = "E15";

    ///// InvalidReceiver();
    string internal constant E16 = "E16";

    ///// InvalidDestinationChain();
    string internal constant E17 = "E17";

    ///// InvalidSendingToken();
    string internal constant E18 = "E18";

    ///// InvalidCaller();
    string internal constant E19 = "E19";

    ///// AlreadyInitialized();
    string internal constant E20 = "E20";

    ///// NotInitialized();
    string internal constant E21 = "E21";

    ///// OnlyContractOwner();
    string internal constant E22 = "E22";

    ///// CannotAuthoriseSelf();
    string internal constant E23 = "E23";

    ///// RecoveryAddressCannotBeZero();
    string internal constant E24 = "E24";

    ///// CannotDepositNativeToken();
    string internal constant E25 = "E25";

    ///// InvalidCallData();
    string internal constant E26 = "E26";

    ///// NativeAssetNotSupported();
    string internal constant E27 = "E27";

    ///// UnAuthorized();
    string internal constant E28 = "E28";

    ///// NoSwapFromZeroBalance();
    string internal constant E29 = "E29";

    ///// InvalidFallbackAddress();
    string internal constant E30 = "E30";

    ///// CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
    string internal constant E31 = "E31";

    ///// InsufficientBalance(uint256 required, uint256 balance);
    string internal constant E32 = "E32";

    ///// ZeroAmount();
    string internal constant E33 = "E33";

    ///// InvalidFee();
    string internal constant E34 = "E34";

    ///// InformationMismatch();
    string internal constant E35 = "E35";

    ///// NotAContract();
    string internal constant E36 = "E36";

    ///// NotEnoughBalance(uint256 requested, uint256 available);
    string internal constant E37 = "E37";

    ///// ReentrancyError();
    string internal constant E38 = "E38";

    ///// NotImplementError();
    string internal constant E39 = "E39";

    // Diamond specific errors
    //// error IncorrectFacetCutAction();
    string internal constant E40 = "E40";

    //// error NoSelectorsInFace();
    string internal constant E41 = "E41";

    //// error FunctionAlreadyExists();
    string internal constant E42 = "E42";

    //// error FacetAddressIsZero();
    string internal constant E43 = "E43";

    //// error FacetAddressIsNotZero();
    string internal constant E44 = "E44";

    //// error FacetContainsNoCode();
    string internal constant E45 = "E45";

    //// error FunctionDoesNotExist();
    string internal constant E46 = "E46";

    //// error FunctionIsImmutable();
    string internal constant E47 = "E47";

    //// error InitZeroButCalldataNotEmpty();
    string internal constant E48 = "E48";

    //// error CalldataEmptyButInitNotZero();
    string internal constant E49 = "E49";

    //// error InitReverted();
    string internal constant E50 = "E50";
    // ----------------

    //// // LibBytes specific errors
    string internal constant E51 = "E51";

    //// error SliceOverflow();
    string internal constant E52 = "E52";

    //// error SliceOutOfBounds();
    string internal constant E53 = "E53";

    //// error AddressOutOfBounds();
    string internal constant E54 = "E54";

    //// error UintOutOfBounds();
    string internal constant E55 = "E55";

    //// // -------------------------

    //// error InvalidRouter();
    string internal constant E56 = "E56";

    /// Stargate Errors ///
    //// error UnknownStargatePool();
    string internal constant E57 = "E57";

    //// error UnknownLayerZeroChain();
    string internal constant E58 = "E58";

    //// error InvalidStargateRouter();
    string internal constant E59 = "E59";

    //// error ContractPaused();
    string internal constant E60 = "E60";

    //// error CannotPauseSelf();
    string internal constant E61 = "E61";

    /// error InvalidFeeNumerator()
    string internal constant E62 = "E62";
}