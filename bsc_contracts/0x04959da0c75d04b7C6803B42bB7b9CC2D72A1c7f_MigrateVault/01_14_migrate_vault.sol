// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ivault_v2.sol";
import "./interfaces/ivault.sol";
import "./interfaces/uniswapv2.sol";

import "hardhat/console.sol";

contract MigrateVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => uint8) public vaultList;

    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address public constant pancakeRouter =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address[] public BUSD_USDC = [BUSD, USDC];

    constructor() {
        IERC20(BUSD).safeApprove(pancakeRouter, type(uint256).max);
    }

    function addVault(address _vault, uint8 version) public onlyOwner {
        require(_vault != address(0), "IA");
        require(version > 0 && version < 3, "IV");

        vaultList[_vault] = version;

        if (version == 1) {
            IERC20(IVault(_vault).quoteToken()).safeApprove(
                _vault,
                type(uint256).max
            );
            IERC20(IVault(_vault).baseToken()).safeApprove(
                _vault,
                type(uint256).max
            );
        } else {
            VaultParams memory vp = IVaultV2(_vault).vaultParams();
            IERC20(vp.quoteToken).safeApprove(_vault, type(uint256).max);
            IERC20(vp.baseToken).safeApprove(_vault, type(uint256).max);
        }
    }

    function addVaults(address[] calldata _vaults, uint8[] calldata versions)
        external
        onlyOwner
    {
        require(_vaults.length > 0, "IA2");
        require(_vaults.length == versions.length, "IA3");
        for (uint8 i = 0; i < _vaults.length; i++) {
            addVault(_vaults[i], versions[i]);
        }
    }

    function migrate(
        address _from,
        address _to,
        uint256 amount
    ) external nonReentrant {
        // assertions
        require(_from != address(0), "IA");
        require(_to != address(0), "IA");
        require(vaultList[_from] > 0, "IV");
        require(vaultList[_to] == 2, "IV2");

        // receive amounts of shares from sender
        IVault(_from).transferFrom(msg.sender, address(this), amount);

        // withdraw capital
        address token;
        uint256 _before;
        uint256 _after;
        VaultParams memory vaultParams;
        if (vaultList[_from] == 1) {
            token = IVault(_from).position() == 0
                ? IVault(_from).quoteToken()
                : IVault(_from).baseToken();
        } else {
            vaultParams = IVaultV2(_from).vaultParams();
            token = IVaultV2(_from).position() == false
                ? vaultParams.quoteToken
                : vaultParams.baseToken;
        }
        _before = IERC20(token).balanceOf(address(this));
        IVault(_from).withdraw(amount);
        _after = IERC20(token).balanceOf(address(this));
        amount = _after - _before;
        require(amount > 0, "IS");

        vaultParams = IVaultV2(_to).vaultParams();
        // swap capital if needed
        if (token == BUSD && vaultParams.quoteToken == USDC) {
            _before = IERC20(USDC).balanceOf(address(this));
            uint256[] memory amounts = UniswapRouterV2(pancakeRouter)
                .swapExactTokensForTokens(
                    amount,
                    (amount * 97) / 100,
                    BUSD_USDC,
                    address(this),
                    block.timestamp + 60
                );
            _after = IERC20(USDC).balanceOf(address(this));
            amount = _after - _before;
            token = USDC;
        }

        require(
            token == vaultParams.quoteToken || token == vaultParams.baseToken,
            "IV3"
        );

        // deposit capital
        _before = IVaultV2(_to).balanceOf(address(this));
        if (IVault(_from).position() == 0) {
            IVaultV2(_to).depositQuote(amount);
        } else {
            IVaultV2(_to).depositBase(amount);
        }
        _after = IVaultV2(_to).balanceOf(address(this));
        amount = _after - _before;

        // send back new shares to the sender
        IVaultV2(_to).transfer(msg.sender, amount);
    }
}