// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IZaynVaultV2.sol";
import "../interfaces/IZaynStrategyV2.sol";

contract ZaynReferrerV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info of each referrer.
    struct RefInfo {
        uint256 refAmount; // How many tokens have been referred.
        uint256 paid; // underlying token paid.
    }

    // Info of each referrer.
    struct StrategyInfo {
        uint256 earned; // How many tokens have been earned.
        uint256 totalReferred; // how many vault shares have been referred.
        uint256 zaynPaid; // how many vault shares have been referred.
    }

    // refAddress => strategy => info
    mapping(address => mapping(address => RefInfo)) public refInfo;
    mapping(address => uint256) public refAmount;
    mapping(address => uint256) public refPayments;

    mapping(address => StrategyInfo) public strategyInfo;

    // Access Control
    mapping(address => bool) public allowedVaults;
    mapping(address => bool) public allowedStrategy;

    // strategy => vault
    mapping(address => address) public vaultStrategyMapping;

    // Events
    event RecordDeposit(address indexed strategy, address indexed referrer, uint256 amount);
    event RecordWithdraw(address indexed strategy, address indexed referrer, uint256 amount);
    event FeeShare(address indexed strategy, uint256 amount);


    modifier onlyVault() {
        require(
            allowedVaults[msg.sender],
            "only vault can call this"
        );
        _;
    }

    modifier onlyStrategy() {
        require(
            allowedStrategy[msg.sender],
            "only strategy can call this"
        );
        _;
    }
    

    function recordDeposit(address referrer, uint256 amount) public onlyVault {
        IZaynVaultV2 vault = IZaynVaultV2(msg.sender);
        require(referrer != address(0), "referrer cannot be zero address");
        RefInfo storage ref = refInfo[referrer][vault.strategy()];
        
        ref.refAmount = ref.refAmount.add(amount);

        StrategyInfo storage stratInfo = strategyInfo[vault.strategy()];
        stratInfo.totalReferred = stratInfo.totalReferred.add(amount);
        emit RecordDeposit(vault.strategy(), referrer, amount);

    }

    function recordWithdraw(address referrer, uint256 amount) public onlyVault {
        IZaynVaultV2 vault = IZaynVaultV2(msg.sender);

        RefInfo storage ref = refInfo[referrer][vault.strategy()];
        ref.refAmount = ref.refAmount.sub(amount);

        StrategyInfo storage stratInfo = strategyInfo[vault.strategy()];
        stratInfo.totalReferred = stratInfo.totalReferred.sub(amount);
        emit RecordWithdraw(vault.strategy(), referrer, amount);

    }

    function recordFeeShare(uint256 amount) public onlyStrategy {
        StrategyInfo storage stratInfo = strategyInfo[msg.sender];
        stratInfo.earned = stratInfo.earned.add(amount);
        emit FeeShare(msg.sender, amount);
    }

    function claimRevShareReferrer(address _strategy) external returns (uint256 amount) {
       RefInfo storage ref = refInfo[msg.sender][_strategy];
       require(ref.refAmount > 0, "no referrer amount");
       amount = getReferrerEarning(_strategy, msg.sender).sub(ref.paid);
       ref.paid += amount;

       IZaynStrategyV2 strategy = IZaynStrategyV2(_strategy);
       IERC20(strategy.revShareToken()).safeTransfer(msg.sender, amount);
    }

    function getReferrerEarning(address _strategy, address referrer) view public returns (uint256 amount){
        RefInfo storage ref = refInfo[referrer][_strategy];
        StrategyInfo storage stratInfo = strategyInfo[_strategy];

        uint256 vaultSupply = IZaynVaultV2(vaultStrategyMapping[_strategy]).totalSupply();
        uint256 feeShareAmount = stratInfo.earned;
        amount = feeShareAmount.mul(ref.refAmount).div(vaultSupply);
    }

    function getZaynEarning(address _strategy) view public returns (uint256 referrerAmount, uint256 zaynAmount){
        StrategyInfo storage stratInfo = strategyInfo[_strategy];
        uint256 feeShareAmount = stratInfo.earned;
        IZaynVaultV2 vault = IZaynVaultV2(vaultStrategyMapping[_strategy]);
        referrerAmount = feeShareAmount.mul(stratInfo.totalReferred).div(vault.totalSupply());
        zaynAmount = feeShareAmount.sub(referrerAmount);
    }

    // ========== ADMIN =================================

    function rescueTokens(address _token) external onlyOwner {
        if (_token == address(0)) {
            (bool sent, ) = msg.sender.call{value: address(this).balance}("");
            require(sent, "failed to send");
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    function zaynCollectFees(address _strategy) external onlyOwner returns (uint256 amount){
        StrategyInfo storage stratInfo = strategyInfo[_strategy];
        IZaynStrategyV2 strategy = IZaynStrategyV2(_strategy);

        ( , uint256 zaynAmount ) = getZaynEarning(_strategy);
        amount = zaynAmount.sub(stratInfo.zaynPaid);
        stratInfo.zaynPaid += amount;
        IERC20(strategy.revShareToken()).safeTransfer(msg.sender, amount);
    }

    function toggleVault(address _vault, bool toggle) external onlyOwner {
        allowedVaults[_vault] = toggle;
    }

    function toggleStrategy(address _strategy, bool toggle) external onlyOwner {
        allowedStrategy[_strategy] = toggle;
    }

    function addVault(address _vault, address _strategy) external onlyOwner {
        allowedVaults[_vault] = true;
        allowedStrategy[_strategy] = true;
        vaultStrategyMapping[_strategy] = _vault;
    }

}