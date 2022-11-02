// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/IGas.sol";
import "./interface/ILpStake.sol";
import "./interface/IGas.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface IBank {
    function restartStatus() external view returns (bool);

    function versionList() external view returns (uint32[] memory);
}

contract GasToken is ReentrancyGuard, AccessControlEnumerable, ERC20Burnable {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public constant baseNum = 1e18;


    constructor() ERC20("USDG", "USDG") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
        super._mint(_msgSender(), 30_0000 * 1e18);
    }

    uint256 public swapBase = 1;
    address public lp = address(0);
    address public token = 0x3F48700b2C17f1CF5fB3C15FF1f882c5DC5527eB;
    address public constant usdt = 0xD83ba15A1e3e9ff17E817C57e550465414D5b887;
    address public lpStake = address(0);

    function baseInit(
        address _lp,
        address _token,
        address _lpStake
    ) external onlyRole(OPERATOR_ROLE) {
        lp = _lp;
        token = _token;
        lpStake = _lpStake;
    }

    function mint(address _token, uint256 _amount) external nonReentrant {
        if (_token == usdt) {
            require(_amount % (swapBase * baseNum) == 0, "GasSwap: incorrect amount.");
            IERC20(usdt).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(usdt).safeApprove(lpStake, _amount);
            ILpStake(lpStake).recharge(_amount);
            super._mint(msg.sender, _amount);
        } else {
            mintBank(_token, _amount);
        }
    }

    mapping(address => mapping(uint256 => SwapInfo)) public swapInfos;

    struct SwapInfo {
        uint256 rate;
        uint256 limit;
        uint256 rateMax;
        uint256 swaped;
        bool status;
    }

    function setSwapInfo(
        address _bank,
        uint256 _version,
        uint256 _rate,
        uint256 _limit,
        uint256 _rateMax,
        uint256 _swaped,
        bool _state
    ) external onlyRole(OPERATOR_ROLE) {
        SwapInfo storage swapInfo = swapInfos[_bank][_version];
        swapInfo.rate = _rate;
        swapInfo.limit = _limit;
        swapInfo.rateMax = _rateMax;
        swapInfo.swaped = _swaped;
        swapInfo.status = _state;
    }

    function mintBank(address bank, uint256 amount) private {
        uint32[] memory versionTimes = IBank(bank).versionList();
        require(versionTimes.length > 0, "GasToken: error of branch version.");

        uint256 version = versionTimes[versionTimes.length - 1];
        SwapInfo storage swapInfo = swapInfos[bank][version];
        require(swapInfo.status, "GasToken: closed.");

        require(IBank(bank).restartStatus(), "GasToken: not in restart.");

        uint256 gasAmount = calcGasAmount(amount, swapInfo.rate);
        require((gasAmount + swapInfo.swaped) <= swapInfo.limit, "GasToken: amount exceeded.");

        swapInfo.swaped += gasAmount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        IGas(token).burn(amount);
        super._mint(bank, gasAmount);
    }

    function calcGasAmount(uint256 amount, uint256 rate) private view returns (uint256) {
        uint256 usdtBalance = IERC20(usdt).balanceOf(lp);
        uint256 tokenBalance = IERC20(token).balanceOf(lp);
        uint256 price = (1e18 * usdtBalance) / tokenBalance;
        return (amount * price * rate) / 1e36;
    }
}