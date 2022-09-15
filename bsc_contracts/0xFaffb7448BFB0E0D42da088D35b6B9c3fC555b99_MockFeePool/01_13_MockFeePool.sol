pragma solidity ^0.5.16;

import "../Owned.sol";
import "../MixinResolver.sol";
import "./Unimplemented.sol";
import "../SafeDecimalMath.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IFuturesMarketManager.sol";
import "../interfaces/ISynth.sol";

interface IMockFeePool {
    function FEE_ADDRESS() external view returns (address);

    function recordFeePaid(uint amount) external;
}

contract MockFeePool is Owned, MixinResolver, Unimplemented, IMockFeePool {
    using SafeMath for uint;

    address public FEE_ADDRESS;
    uint public fees;

    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";
    bytes32 private constant CONTRACT_SYNTHSUSD = "SynthsUSD";

    constructor(address _owner, address _resolver, address _FEE_ADDRESS) public Owned(_owner) MixinResolver(_resolver) {
        FEE_ADDRESS = _FEE_ADDRESS;
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_EXCHANGER;
        addresses[1] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses[2] = CONTRACT_SYNTHSUSD;
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    function _sUSD() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function setFEE_ADDRESS(address _FEE_ADDRESS) external onlyOwner {
        FEE_ADDRESS = _FEE_ADDRESS;
    }

    function recordFeePaid(uint amount) external onlyInternalContracts {
        fees = fees.add(amount);
    }

    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(_exchanger()) ||
            account == address(_futuresMarketManager()) ||
            account == address(_sUSD());
    }

    modifier onlyInternalContracts {
        require(_isInternalContract(msg.sender), "Only Internal Contracts");
        _;
    }
}