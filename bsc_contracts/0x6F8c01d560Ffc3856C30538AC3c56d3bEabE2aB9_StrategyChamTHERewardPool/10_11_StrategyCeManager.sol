// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFeeConfig.sol";

contract StrategyCeManager is Ownable, Pausable {

    struct CommonAddresses {
        address vault;
        address uniRouter;
        address keeper;
        address strategist;
        address coFeeRecipient;
        address coFeeConfig;
    }

    // common addresses for the strategy
    address public vault;
    address public uniRouter;
    address public keeper;
    address public strategist;
    address public coFeeRecipient;
    IFeeConfig public coFeeConfig;

    uint256 constant DIVISOR = 1 ether;
    uint256 constant public WITHDRAWAL_FEE_CAP = 50;
    uint256 constant public WITHDRAWAL_MAX = 10000;
    uint256 public withdrawalFee = 10;

    event SetStratFeeId(uint256 feeId);
    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetVault(address vault);
    event SetUniRouter(address uniRouter);
    event SetKeeper(address keeper);
    event SetStrategist(address strategist);
    event SetCoFeeRecipient(address coFeeRecipient);
    event SetCoFeeConfig(address coFeeConfig);

    constructor(CommonAddresses memory _commonAddresses) {
        vault = _commonAddresses.vault;
        uniRouter = _commonAddresses.uniRouter;
        keeper = _commonAddresses.keeper;
        strategist = _commonAddresses.strategist;
        coFeeRecipient = _commonAddresses.coFeeRecipient;
        coFeeConfig = IFeeConfig(_commonAddresses.coFeeConfig);
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "StrategyCeManager: MANAGER_ONLY");
        _;
    }

    // fetch fees from config contract
    function getFees() public view returns (IFeeConfig.FeeCategory memory) {
        return coFeeConfig.getFees(address(this));
    }

    function getStratFeeId() external view returns (uint256) {
        return coFeeConfig.stratFeeId(address(this));
    }

    function setStratFeeId(uint256 _feeId) external onlyManager {
        coFeeConfig.setStratFeeId(_feeId);
        emit SetStratFeeId(_feeId);
    }

    // adjust withdrawal fee
    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "StrategyCeManager: MAX_WITHDRAWAL_FEE");
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    // set new vault (only for strategy upgrades)
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit SetVault(_vault);
    }

    // set new uniRouter
    function setUniRouter(address _uniRouter) external onlyOwner {
        uniRouter = _uniRouter;
        emit SetUniRouter(_uniRouter);
    }

    // set new keeper to manage strat
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
        emit SetKeeper(_keeper);
    }

    // set new strategist address to receive strat fees
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "StrategyCeManager: STRATEGIST_ONLY");
        strategist = _strategist;
        emit SetStrategist(_strategist);
    }

    // set new co fee address to receive co fees
    function setCoFeeRecipient(address _coFeeRecipient) external onlyOwner {
        coFeeRecipient = _coFeeRecipient;
        emit SetCoFeeRecipient(_coFeeRecipient);
    }

    // set new fee config address to fetch fees
    function setCoFeeConfig(address _coFeeConfig) external onlyOwner {
        coFeeConfig = IFeeConfig(_coFeeConfig);
        emit SetCoFeeConfig(_coFeeConfig);
    }

    function beforeDeposit() external virtual {}
}