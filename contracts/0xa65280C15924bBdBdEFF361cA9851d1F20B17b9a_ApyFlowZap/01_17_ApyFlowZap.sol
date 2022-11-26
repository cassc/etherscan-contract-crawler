pragma solidity 0.8.15;


import "ERC20.sol";
import "IERC20Metadata.sol";
import "Ownable.sol";
import "IERC4626.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "AssetConverter.sol";
import "SingleAssetVault.sol";
import "PortfolioScore.sol";
import "ApyFlow.sol";


contract ApyFlowZap is Ownable {
	using SafeERC20 for IERC20;
	using SafeERC20 for IERC20Metadata;
    using SafeERC20 for ApyFlow;

    ApyFlow public immutable apyflow;
    AssetConverter public assetConverter;

    event Deposited(
        address indexed who,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken
    );

    event Withdrawal(
        address indexed who,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken
    );

    mapping (address => bool) allowedTokens;

    modifier tokenAllowed(address token) {
        require(allowedTokens[token], "The token is not allowed");
        _;
    }

    constructor(ApyFlow _apyflow) {
        require(address(_apyflow) != address(0), "Zero address provided");
        apyflow = _apyflow;
        assetConverter = apyflow.assetConverter();
    }

    function changeAllowedTokenStatus(address token) external onlyOwner {
        allowedTokens[token] = !allowedTokens[token];
    }

    function deposit(address token, uint value) external tokenAllowed(token) returns(uint256 shares)
	{
        IERC20(token).safeTransferFrom(msg.sender, address(this), value);
        uint256[] memory amounts = new uint256[](apyflow.vaultsLength());
        uint256 totalPortfolioScore = apyflow.totalPortfolioScore();
        if (IERC20(token).allowance(address(this), address(assetConverter)) < value) {
            IERC20(token).safeIncreaseAllowance(address(assetConverter), type(uint256).max);
        }
        for (uint i = 0; i < amounts.length; i++) {
            SingleAssetVault vault = SingleAssetVault(apyflow.getVault(i));
            address tokenToDeposit = vault.asset();
            uint256 amountToDeposit = vault.totalPortfolioScore() * value / totalPortfolioScore;
            if (amountToDeposit == 0) continue;
            if (tokenToDeposit != token) 
                amounts[i] = assetConverter.swap(token, tokenToDeposit, amountToDeposit);
            else 
                amounts[i] = amountToDeposit;
            if (IERC20(tokenToDeposit).allowance(address(this), address(apyflow)) < amounts[i]) {
                IERC20(tokenToDeposit).safeIncreaseAllowance(address(apyflow), type(uint256).max);
            }
        }
        shares = apyflow.deposit(amounts, msg.sender);
        emit Deposited(msg.sender, token, value, shares, apyflow.pricePerToken());
	}

    function redeem(address token, uint shares) external tokenAllowed(token) returns(uint256 assets) {
        apyflow.safeTransferFrom(msg.sender, address(this), shares);
        uint256[] memory amounts = apyflow.redeem(shares, address(this));
        for (uint i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;
            address withdrawnToken = SingleAssetVault(apyflow.getVault(i)).asset();
            if (withdrawnToken != token) {
                if (IERC20(withdrawnToken).allowance(address(this), address(assetConverter)) < amounts[i]) {
                    IERC20(withdrawnToken).safeIncreaseAllowance(address(assetConverter), type(uint256).max);
                }
                assets += assetConverter.swap(withdrawnToken, token, amounts[i]);
            } else {
                assets += amounts[i];
            }
        }
        IERC20(token).safeTransfer(msg.sender, assets);
        emit Withdrawal(msg.sender, token, assets, shares, apyflow.pricePerToken());
    }
}