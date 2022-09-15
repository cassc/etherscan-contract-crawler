pragma solidity ^0.5.16;

import "../MixinResolver.sol";

import "../interfaces/IExchangeRates.sol";

interface IAggregatorProxy {
    function aggregator() external view returns (address);

    function phaseId() external view returns (uint16);
}

contract AggregatorLinker is MixinResolver {
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";

    constructor(address _resolver) public MixinResolver(_resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_EXRATES;
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function linkAggregator(bytes32 _currencyKey) external {
        address _proxy = _exchangeRates().aggregators(_currencyKey);
        address _aggregator = IAggregatorProxy(_proxy).aggregator();
        uint16 _phaseId = IAggregatorProxy(_proxy).phaseId();
        emit LinkAggregator(_currencyKey, _proxy, _aggregator, _phaseId);
    }

    event LinkAggregator(bytes32 indexed currencyKey, address indexed proxy, address indexed aggregator, uint16 phaseId);
}