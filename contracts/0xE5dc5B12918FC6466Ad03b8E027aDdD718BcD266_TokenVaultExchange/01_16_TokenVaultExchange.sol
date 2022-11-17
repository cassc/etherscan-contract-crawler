pragma solidity >=0.4.22 <0.9.0;

import {Errors} from "../libraries/helpers/Errors.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";
import {SettingStorage} from "../libraries/proxy/SettingStorage.sol";
import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "../libraries/openzeppelin/token/ERC20/IERC20.sol";
import {ISettings} from "../interfaces/ISettings.sol";
import {IVault} from "../interfaces/IVault.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";

contract TokenVaultExchange is SettingStorage, OwnableUpgradeable {
    //
    address public vaultToken;
    //
    IERC20[] public rewardTokens;
    //
    mapping(IERC20 => bool) public isRewardToken;

    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    //
    constructor(address _settings) SettingStorage(_settings) {}

    receive() external payable {}

    function initialize(address _vaultToken) public initializer {
        __Ownable_init();
        // update data
        require(_vaultToken != address(0), "no zero address");
        vaultToken = _vaultToken;
    }

    function addRewardToken(address _addr) external onlyOwner {
        IERC20 _rewardToken = IERC20(_addr);
        require(
            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),
            Errors.VAULT_REWARD_TOKEN_INVALID
        );
        require(rewardTokens.length < 25, Errors.VAULT_REWARD_TOKEN_MAX);
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;
    }

    function shareExchangeFeeRewardToken() external {
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            address weth = ISettings(settings).weth();
            if (address(_token) == weth) {
                TransferHelper.swapETH2WETH(
                    weth,
                    TransferHelper.balanceOfETH(address(this))
                );
            }
            uint256 balance = _token.balanceOf(address(this));
            if (balance > 0) {
                uint256 feeAmount = (balance *
                    ISettings(settings).feePercentage()) / 10000;
                // 70%
                TransferHelper.safeTransfer(
                    _token,
                    ISettings(settings).feeReceiver(),
                    feeAmount
                );
                // 30%
                TransferHelper.safeTransfer(
                    _token,
                    IVault(vaultToken).treasury(),
                    (balance - feeAmount)
                );
            }
        }
    }

    function getNewShareExchangeFeeRewardToken(address token)
        external
        view
        returns (uint256)
    {
        uint256 balance = IERC20(token).balanceOf(address(this));
        address weth = ISettings(settings).weth();
        if (address(token) == weth) {
            balance += TransferHelper.balanceOfETH(address(this));
        }
        if (balance == 0) {
            return 0;
        }
        uint256 feeAmount = (balance * ISettings(settings).feePercentage()) /
            10000;
        // 30 %
        return (balance - feeAmount);
    }
}