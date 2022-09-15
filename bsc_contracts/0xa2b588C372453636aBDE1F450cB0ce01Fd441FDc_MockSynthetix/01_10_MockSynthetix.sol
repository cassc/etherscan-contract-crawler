pragma solidity ^0.5.16;

import "../MixinResolver.sol";
import "./Unimplemented.sol";
import "../interfaces/IExchanger.sol";

interface IMockSynthetix {
    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;
}

contract MockSynthetix is MixinResolver, Unimplemented, IMockSynthetix {

    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";

    constructor(address _resolver) public MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_EXCHANGER;
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    modifier onlyExchanger() {
        _onlyExchanger();
        _;
    }

    function _onlyExchanger() private view {
        require(msg.sender == address(_exchanger()), "Only Exchanger can invoke this");
    }

    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external onlyExchanger {
        emit ExchangeReclaim(account, currencyKey, amount);
    }

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external onlyExchanger {
        emit ExchangeRebate(account, currencyKey, amount);
    }

    event ExchangeReclaim(address indexed account, bytes32 currencyKey, uint amount);
    event ExchangeRebate(address indexed account, bytes32 currencyKey, uint amount);
}