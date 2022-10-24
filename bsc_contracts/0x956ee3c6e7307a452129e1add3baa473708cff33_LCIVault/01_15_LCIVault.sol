// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../libs/BaseRelayRecipient.sol";
import "./libs/Price.sol";

interface IStrategy {
    function invest(uint amount) external;
    function withdrawPerc(uint sharePerc) external;
    function withdrawFromFarm(uint farmIndex, uint sharePerc) external returns (uint);
    function emergencyWithdraw() external;
    function getAllPoolInUSD() external view returns (uint);
    function getCurrentTokenCompositionPerc() external view returns (address[] memory tokens, uint[] memory percentages);
    function getAPR() external view returns (uint);
}

contract LCIVault is ERC20Upgradeable, OwnableUpgradeable, 
        ReentrancyGuardUpgradeable, PausableUpgradeable, BaseRelayRecipient {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant USDT = IERC20Upgradeable(0x55d398326f99059fF775485246999027B3197955);

    IStrategy public strategy;
    address public treasuryWallet;
    address public admin;

    uint constant DENOMINATOR = 10000;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;
    uint public fees; // In USD (18 decimals)

    mapping(address => uint) private depositedBlock;

    event Deposit(address caller, uint amtDeposit, address tokenDeposit, uint shareMinted);
    event Withdraw(address caller, uint amtWithdraw, address tokenWithdraw, uint shareBurned);
    event Rebalance(uint farmIndex, uint sharePerc, uint amount);
    event Reinvest(uint amount);
    event SetTreasuryWallet(address oldTreasuryWallet, address newTreasuryWallet);
    event SetAdminWallet(address oldAdmin, address newAdmin);
    event SetBiconomy(address oldBiconomy, address newBiconomy);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event TransferredOutFees(uint fees, address token);

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == address(admin), "Only owner or admin");
        _;
    }

    function initialize(
        address _treasuryWallet, address _admin,
        address _biconomy, address _strategy
    ) external initializer {
        __ERC20_init("Low-risk Crypto Index", "LCI");
        __Ownable_init();

        strategy = IStrategy(_strategy);

        treasuryWallet = _treasuryWallet;
        admin = _admin;
        trustedForwarder = _biconomy;

        profitFeePerc = 2000;

        USDT.safeApprove(address(strategy), type(uint).max);
    }

    function deposit(uint amount) external {
        _deposit(_msgSender(), amount);
    }
    function depositByAdmin(address account, uint amount) external onlyOwnerOrAdmin {
        _deposit(account, amount);
    }
    function _deposit(address account, uint amount) private nonReentrant whenNotPaused {
        require(amount > 0, "Amount must > 0");
        depositedBlock[account] = block.number;

        uint pool = getAllPoolInUSD();
        USDT.safeTransferFrom(account, address(this), amount);

        (uint USDTPriceInUSD, uint denominator) = PriceLib.getUSDTPriceInUSD();
        uint amtDeposit = amount * USDTPriceInUSD / denominator; // USDT's decimals is 18

        if (watermark > 0) _collectProfitAndUpdateWatermark();
        uint USDTAmt = _transferOutFees();
        if (USDTAmt > 0) {
            strategy.invest(USDTAmt);
        }
        adjustWatermark(amtDeposit, true);

        uint _totalSupply = totalSupply();
        uint share = (pool == 0 || _totalSupply == 0) ? amtDeposit : _totalSupply * amtDeposit / pool;
        // When assets invested in strategy, around 0.3% lost for swapping fee. We will consider it in share amount calculation to avoid pricePerFullShare fall down under 1.
        share = share * 997 / 1000;
        _mint(account, share);

        emit Deposit(account, amtDeposit, address(USDT), share);
    }

    function withdraw(uint share) external {
        _withdraw(_msgSender(), share);
    }
    function withdrawByAdmin(address account, uint share) external onlyOwnerOrAdmin {
        _withdraw(account, share);
    }
    function _withdraw(address account, uint share) private nonReentrant {
        require(share > 0, "Shares must > 0");
        require(share <= balanceOf(account), "Not enough share to withdraw");
        require(depositedBlock[account] != block.number, "Withdraw within same block");
        
        uint _totalSupply = totalSupply();
        uint pool = getAllPoolInUSD();
        uint withdrawAmt = pool * share / _totalSupply;
        uint sharePerc = withdrawAmt * 1e18 / (pool + fees);

        if (!paused()) {
            strategy.withdrawPerc(sharePerc);
            USDT.safeTransfer(account, USDT.balanceOf(address(this)));
            adjustWatermark(withdrawAmt, false);
        } else {
            uint USDTAmt = USDT.balanceOf(address(this)) * sharePerc / 1e18;
            USDT.safeTransfer(account, USDTAmt);
        }
        _burn(account, share);
        emit Withdraw(account, withdrawAmt, address(USDT), share);
    }

    function rebalance(uint farmIndex, uint sharePerc) external onlyOwnerOrAdmin {
        uint USDTAmt = strategy.withdrawFromFarm(farmIndex, sharePerc);
        if (0 < USDTAmt) {
            strategy.invest(USDTAmt);
            emit Rebalance(farmIndex, sharePerc, USDTAmt);
        }
    }

    function emergencyWithdraw() external onlyOwnerOrAdmin whenNotPaused {
        _pause();
        strategy.emergencyWithdraw();
        watermark = 0;
    }

    function reinvest() external onlyOwnerOrAdmin whenPaused {
        _unpause();
        uint USDTAmt = USDT.balanceOf(address(this));
        if (0 < USDTAmt) {
            (uint USDTPriceInUSD, uint denominator) = PriceLib.getUSDTPriceInUSD();
            uint amtDeposit = USDTAmt * USDTPriceInUSD / denominator; // USDT's decimals is 18

            strategy.invest(USDTAmt);
            adjustWatermark(amtDeposit, true);
            emit Reinvest(USDTAmt);
        }
    }

    function collectProfitAndUpdateWatermark() external onlyOwnerOrAdmin whenNotPaused {
        _collectProfitAndUpdateWatermark();
    }
    function _collectProfitAndUpdateWatermark() private {
        uint currentWatermark = strategy.getAllPoolInUSD();
        uint lastWatermark = watermark;
        uint fee;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / DENOMINATOR;
            fees += fee;
            watermark = currentWatermark;
        }
        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) private {
        uint lastWatermark = watermark;
        watermark = signs == true
                    ? watermark + amount
                    : (watermark > amount) ? watermark - amount : 0;
        emit AdjustWatermark(watermark, lastWatermark);
    }

    function withdrawFees() external onlyOwnerOrAdmin {
        if (!paused()) {
            uint pool = strategy.getAllPoolInUSD();
            uint _fees = fees;
            uint sharePerc = _fees < pool ? _fees * 1e18 / pool : 1e18;
            strategy.withdrawPerc(sharePerc);
        }
        _transferOutFees();
    }

    function _transferOutFees() private returns (uint USDTAmt) {
        USDTAmt = USDT.balanceOf(address(this));
        uint _fees = fees;
        if (_fees != 0) {
            (uint USDTPriceInUSD, uint denominator) = PriceLib.getUSDTPriceInUSD();
            uint FeeAmt = _fees * denominator / USDTPriceInUSD; // USDT's decimals is 18

            if (FeeAmt < USDTAmt) {
                _fees = 0;
                USDTAmt -= FeeAmt;
            } else {
                _fees -= (USDTAmt * USDTPriceInUSD / denominator);
                FeeAmt = USDTAmt;
                USDTAmt = 0;
            }
            fees = _fees;

            USDT.safeTransfer(treasuryWallet, FeeAmt);
            emit TransferredOutFees(FeeAmt, address(USDT)); // Decimal follow _token
        }
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyOwner {
        require(profitFeePerc < 3001, "Profit fee cannot > 30%");
        profitFeePerc = _profitFeePerc;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        address oldTreasuryWallet = treasuryWallet;
        treasuryWallet = _treasuryWallet;
        emit SetTreasuryWallet(oldTreasuryWallet, _treasuryWallet);
    }

    function setAdmin(address _admin) external onlyOwner {
        address oldAdmin = admin;
        admin = _admin;
        emit SetAdminWallet(oldAdmin, _admin);
    }

    function setBiconomy(address _biconomy) external onlyOwner {
        address oldBiconomy = trustedForwarder;
        trustedForwarder = _biconomy;
        emit SetBiconomy(oldBiconomy, _biconomy);
    }

    function _msgSender() internal override(ContextUpgradeable, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }
    
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint pool;
        if (paused()) {
            (uint USDTPriceInUSD, uint denominator) = PriceLib.getUSDTPriceInUSD();
            pool = USDT.balanceOf(address(this)) * USDTPriceInUSD / denominator; // USDT's decimals is 18
        } else {
            pool = strategy.getAllPoolInUSD();
        }
        return (pool > fees ? pool - fees : 0);
    }

    /// @notice Can be use for calculate both user shares & APR    
    function getPricePerFullShare() external view returns (uint) {
        uint _totalSupply = totalSupply();
        if (_totalSupply == 0) return 1e18;
        return getAllPoolInUSD() * 1e18 / _totalSupply;
    }

    function getCurrentCompositionPerc() external view returns (address[] memory tokens, uint[] memory percentages) {
        return strategy.getCurrentTokenCompositionPerc();
    }

    function getAPR() external view returns (uint) {
        return strategy.getAPR();
    }
}