pragma solidity ^0.5.16;

import "../Owned.sol";
import "../MixinResolver.sol";
import "./Unimplemented.sol";
import "../SafeDecimalMath.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/IFuturesMarketManager.sol";
import "../interfaces/IFeePool.sol";
import "../interfaces/IFlexibleStorage.sol";
import "../interfaces/IERC20.sol";

interface IMockSynth {
    function balanceOf(address owner) external view returns (uint);

    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}

contract MockSynth is Owned, MixinResolver, Unimplemented, IMockSynth {
    using SafeMath for uint;

    address public token;

    bytes32 private constant CONTRACT_NAME = "SynthsUSD";

    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    constructor(address _owner, address _resolver, address _token) public Owned(_owner) MixinResolver(_resolver) {
        token = _token;
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_NAME;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses[3] = CONTRACT_FEEPOOL;
        addresses[4] = CONTRACT_FLEXIBLESTORAGE;
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    function _feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function _flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    function balanceOf(address account) public view returns (uint256 _balance) {
        return _flexibleStorage().getUIntValue(CONTRACT_NAME, bytes32(uint(account)));
    }

    function fund() public view returns (uint256 _fund) {
        return _flexibleStorage().getUIntValue(CONTRACT_NAME, "fund");
    }

    function debt() external view returns (uint256 _debt)
    {
        bool _invalid;
        (_debt, _invalid) = _futuresMarketManager().totalDebt();
        require(!_invalid, "invalid rates");
        return _debt;
    }

    function donate(uint amount) external
    {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _setFund(fund().add(amount));
        emit Donate(msg.sender, amount);
    }

    function collect(uint amount) external onlyFeeAddress
    {
        uint256 _fund = fund();
        require(amount <= _fund, "insufficient fund");
        _setFund(_fund.sub(amount));
        IERC20(token).transfer(msg.sender, amount);
        emit Collect(msg.sender, amount);
    }

    function deposit(address account, uint amount) external
    {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _setBalanceOf(account, balanceOf(account).add(amount));
        emit Deposit(msg.sender, account, amount);
    }

    function withdraw(address account, uint amount) external onlyAccount(account)
    {
        uint256 _balance = balanceOf(account);
        require(amount <= _balance, "insufficient balance");
        _setBalanceOf(account, _balance.sub(amount));
        IERC20(token).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, account, amount);
    }

    function burn(address account, uint amount) external onlyInternalContracts {
        uint256 _balance = balanceOf(account);
        require(amount <= _balance, "insufficient balance");
        _setBalanceOf(account, _balance.sub(amount));
        _setFund(fund().add(amount));
        emit Burn(account, amount);
    }

    function issue(address account, uint amount) external onlyInternalContracts {
        uint256 _fund = fund();
        require(amount <= _fund, "insufficient fund");
        _setFund(_fund.sub(amount));
        _setBalanceOf(account, balanceOf(account).add(amount));
        emit Issue(account, amount);
    }

    function migrate() external onlyOwner {
        address newContract = requireAndGetAddress(CONTRACT_NAME);
        require(newContract != address(this), "migration not available");
        IERC20(token).transfer(newContract, IERC20(token).balanceOf(address(this)));
    }

    function _setBalanceOf(address account, uint256 _balance) internal {
        _flexibleStorage().setUIntValue(CONTRACT_NAME, bytes32(uint(account)), _balance);
    }

    function _setFund(uint256 _fund) internal {
        _flexibleStorage().setUIntValue(CONTRACT_NAME, "fund", _fund);
    }

    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(_exchanger()) ||
            account == address(_futuresMarketManager());
    }

    modifier onlyInternalContracts {
        require(_isInternalContract(msg.sender), "Only Internal Contracts");
        _;
    }

    modifier onlyFeeAddress {
        require(msg.sender == _feePool().FEE_ADDRESS(), "Only Fee Address");
        _;
    }

    modifier onlyAccount(address account) {
        require(msg.sender == account, "Only Account");
        _;
    }

    event Donate(address indexed sender, uint amount);
    event Collect(address indexed sender, uint amount);
    event Deposit(address indexed sender, address indexed account, uint amount);
    event Withdraw(address indexed sender, address indexed account, uint amount);
    event Burn(address indexed account, uint amount);
    event Issue(address indexed account, uint amount);
}