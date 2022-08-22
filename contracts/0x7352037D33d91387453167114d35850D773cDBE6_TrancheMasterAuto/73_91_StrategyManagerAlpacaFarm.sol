//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../refs/CoreRefUpgradeable.sol";
import "../interfaces/IAlpaca.sol";
import "../interfaces/IWBNB.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyManagerAlpacaFarm.sol";

contract StrategyManagerAlpacaFarm is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    CoreRefUpgradeable,
    IStrategyManagerAlpacaFarm
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public alpacaAddress;

    function init(address _core, address _alpacaAddress) public initializer {
        CoreRefUpgradeable.initialize(_core);
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        alpacaAddress = _alpacaAddress;
    }

    function deposit(
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        address wantAddr,
        uint256 wantAmt,
        bytes memory data
    ) external override nonReentrant returns (uint256) {
        require(wantAmt > 0, "StrategyManagerAlpacaFarm::Invalid amount");
        IERC20Upgradeable(wantAddr).safeTransferFrom(msg.sender, address(this), wantAmt);
        IERC20Upgradeable(wantAddr).safeApprove(vaultAddress, wantAmt);
        if (vaultPositionId != 0) {
            Vault(vaultAddress).work(vaultPositionId, worker, wantAmt, 0, 0, data);
        } else {
            vaultPositionId = Vault(vaultAddress).nextPositionID();
            Vault(vaultAddress).work(0, worker, wantAmt, 0, 0, data);
        }
        return vaultPositionId;
    }

    function withdraw(
        address wantAddress,
        address vaultAddress,
        uint256 vaultPositionId,
        address worker,
        bytes memory data
    ) external payable override onlyMultistrategy nonReentrant {
        address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        Vault(vaultAddress).work(vaultPositionId, worker, 0, 0, uint256(-1), data);
        if (wantAddress == wbnb) {
            IWBNB(wbnb).deposit{value: address(this).balance}();
        }
        uint256 earnedAlpaca = IERC20Upgradeable(alpacaAddress).balanceOf(address(this));
        uint256 wantBalance = IERC20Upgradeable(wantAddress).balanceOf(address(this));

        IERC20Upgradeable(alpacaAddress).safeTransfer(msg.sender, earnedAlpaca);
        IERC20Upgradeable(wantAddress).safeTransfer(msg.sender, wantBalance);
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyTimelock {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    receive() external payable {}
}