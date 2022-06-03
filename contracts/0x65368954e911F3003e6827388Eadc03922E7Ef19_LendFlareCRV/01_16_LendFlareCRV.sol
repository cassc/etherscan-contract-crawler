// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/ILendFlareCRV.sol";
import "../interfaces/IConvexBasicRewards.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/IConvexVirtualBalanceRewardPool.sol";
import "../interfaces/ICVXMining.sol";
import "../interfaces/IZap.sol";

// solhint-disable no-empty-blocks, reason-string
contract LendFlareCRV is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ILendFlareCRV {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The address of cvxCRV token.
    address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    // The address of CRV token.
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    // The address of CVX token.
    address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    // The address of 3CRV token.
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    // The address of Convex cvxCRV Staking Contract.
    address private constant CVXCRV_STAKING = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    // The address of Convex CVX Mining Contract.
    address private constant CVX_MINING = 0x3c75BFe6FbfDa3A94E7E7E8c2216AFc684dE5343;
    // The address of Convex 3CRV Rewards Contract.
    address private constant THREE_CRV_REWARDS = 0x7091dbb7fcbA54569eF1387Ac89Eb2a5C9F6d2EA;

    /// @dev The address of ZAP contract, will be used to swap tokens.
    address public zap;

    function initialize(address _zap) external initializer {
        ERC20Upgradeable.__ERC20_init("LendFlare cvxCRV", "lfCRV");
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        require(_zap != address(0), "LendFlareCRV: zero zap address");

        zap = _zap;
    }

    /********************************** View Functions **********************************/

    /// @dev Return the total amount of cvxCRV staked.
    function totalUnderlying() public view override returns (uint256) {
        // TODO: stakeFor exists in CVXCRV_STAKING, maybe we need maintain correct underlying balance here.
        return IConvexBasicRewards(CVXCRV_STAKING).balanceOf(address(this));
    }

    /// @dev Return the amount of cvxCRV staked for user
    /// @param _user - The address of the account
    function balanceOfUnderlying(address _user) external view override returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        uint256 _balance = balanceOf(_user);
        return _balance.mul(totalUnderlying()) / _totalSupply;
    }

    /// @dev Return the amount of pending CRV rewards
    function pendingCRVRewards() public view returns (uint256) {
        return IConvexBasicRewards(CVXCRV_STAKING).earned(address(this));
    }

    /// @dev Return the amount of pending CVX rewards
    function pendingCVXRewards() external view returns (uint256) {
        return ICVXMining(CVX_MINING).ConvertCrvToCvx(pendingCRVRewards());
    }

    /// @dev Return the amount of pending 3CRV rewards
    function pending3CRVRewards() external view returns (uint256) {
        return IConvexVirtualBalanceRewardPool(THREE_CRV_REWARDS).earned(address(this));
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Deposit cvxCRV token to this contract
    /// @param _recipient - The address who will receive the aCRV token.
    /// @param _amount - The amount of cvxCRV to deposit.
    /// @return share - The amount of aCRV received.
    function deposit(address _recipient, uint256 _amount) public override nonReentrant returns (uint256 share) {
        require(_amount > 0, "LendFlareCRV: zero amount deposit");
        uint256 _before = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
        IERC20Upgradeable(CVXCRV).safeTransferFrom(msg.sender, address(this), _amount);
        _amount = IERC20Upgradeable(CVXCRV).balanceOf(address(this)).sub(_before);
        return _deposit(_recipient, _amount);
    }

    /// @dev Deposit all cvxCRV token of the sender to this contract
    /// @param _recipient The address who will receive the aCRV token.
    /// @return share - The amount of aCRV received.
    function depositAll(address _recipient) external override returns (uint256 share) {
        uint256 _balance = IERC20Upgradeable(CVXCRV).balanceOf(msg.sender);
        return deposit(_recipient, _balance);
    }

    /// @dev Deposit CRV token to this contract
    /// @param _recipient - The address who will receive the aCRV token.
    /// @param _amount - The amount of CRV to deposit.
    /// @return share - The amount of aCRV received.
    function depositWithCRV(address _recipient, uint256 _amount) public override nonReentrant returns (uint256 share) {
        uint256 _before = IERC20Upgradeable(CRV).balanceOf(address(this));
        IERC20Upgradeable(CRV).safeTransferFrom(msg.sender, address(this), _amount);
        _amount = IERC20Upgradeable(CRV).balanceOf(address(this)).sub(_before);

        _amount = _zapToken(_amount, CRV, _amount, CVXCRV);
        return _deposit(_recipient, _amount);
    }

    /// @dev Deposit all CRV token of the sender to this contract
    /// @param _recipient The address who will receive the aCRV token.
    /// @return share - The amount of aCRV received.
    function depositAllWithCRV(address _recipient) external override returns (uint256 share) {
        uint256 _balance = IERC20Upgradeable(CRV).balanceOf(msg.sender);
        return depositWithCRV(_recipient, _balance);
    }

    /// @dev Withdraw cvxCRV in proportion to the amount of shares sent
    /// @param _recipient - The address who will receive the withdrawn token.
    /// @param _shares - The amount of aCRV to send.
    /// @param _minimumOut - The minimum amount of token should be received.
    /// @param _option - The withdraw option (as cvxCRV or CRV or CVX or ETH or stake to convex).
    /// @return withdrawn - The amount of token returned to the user.
    function withdraw(
        address _recipient,
        uint256 _shares,
        uint256 _minimumOut,
        WithdrawOption _option
    ) public override nonReentrant returns (uint256 withdrawn) {
        uint256 _withdrawed = _withdraw(_shares);
        if (_option == WithdrawOption.Withdraw) {
            require(_withdrawed >= _minimumOut, "LendFlareCRV: insufficient output");
            IERC20Upgradeable(CVXCRV).safeTransfer(_recipient, _withdrawed);
        } else {
            _withdrawed = _withdrawAs(_recipient, _withdrawed, _minimumOut, _option);
        }

        emit Withdraw(msg.sender, _recipient, _shares, _option);
        return _withdrawed;
    }

    /// @dev Withdraw all cvxCRV in proportion to the amount of shares sent
    /// @param _recipient - The address who will receive the withdrawn token.
    /// @param _minimumOut - The minimum amount of token should be received.
    /// @param _option - The withdraw option (as cvxCRV or CRV or CVX or ETH or stake to convex).
    /// @return withdrawn - The amount of token returned to the user.
    function withdrawAll(
        address _recipient,
        uint256 _minimumOut,
        WithdrawOption _option
    ) external override returns (uint256) {
        uint256 _shares = balanceOf(msg.sender);
        return withdraw(_recipient, _shares, _minimumOut, _option);
    }

    /// @dev Harvest the pending reward and convert to cvxCRV.
    /// @param _minimumOut - The minimum amount of cvxCRV should get.
    function harvest(uint256 _minimumOut) public override nonReentrant returns (uint256) {
        return _harvest(_minimumOut);
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Update the zap contract
    function updateZap(address _zap) external onlyOwner {
        require(_zap != address(0), "LendFlareCRV: zero zap address");
        zap = _zap;

        emit UpdateZap(_zap);
    }

    /********************************** Internal Functions **********************************/

    function _deposit(address _recipient, uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "LendFlareCRV: zero amount deposit");
        uint256 _underlying = totalUnderlying();
        uint256 _totalSupply = totalSupply();

        IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, 0);
        IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, _amount);
        IConvexBasicRewards(CVXCRV_STAKING).stake(_amount);

        uint256 _shares;
        if (_totalSupply == 0) {
            _shares = _amount;
        } else {
            _shares = _amount.mul(_totalSupply) / _underlying;
        }
        _mint(_recipient, _shares);

        emit Deposit(msg.sender, _recipient, _amount);
        return _shares;
    }

    function _withdraw(uint256 _shares) internal returns (uint256 _withdrawable) {
        require(_shares > 0, "LendFlareCRV: zero share withdraw");
        require(_shares <= balanceOf(msg.sender), "LendFlareCRV: shares not enough");
        uint256 _amount = _shares.mul(totalUnderlying()) / totalSupply();
        _burn(msg.sender, _shares);

        if (totalSupply() == 0) {
            // If user is last to withdraw, harvest before exit
            // The first parameter is actually not used.
            _harvest(0);
            IConvexBasicRewards(CVXCRV_STAKING).withdraw(totalUnderlying(), false);
            _withdrawable = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
        } else {
            // Otherwise compute share and unstake
            _withdrawable = _amount;
            IConvexBasicRewards(CVXCRV_STAKING).withdraw(_withdrawable, false);
        }
        return _withdrawable;
    }

    function _withdrawAs(
        address _recipient,
        uint256 _amount,
        uint256 _minimumOut,
        WithdrawOption _option
    ) internal returns (uint256) {
        if (_option == WithdrawOption.WithdrawAndStake) {
            // simply stake the cvxCRV for _recipient
            require(_amount >= _minimumOut, "LendFlareCRV: insufficient output");
            IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, 0);
            IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, _amount);
            require(IConvexBasicRewards(CVXCRV_STAKING).stakeFor(_recipient, _amount), "LendFlareCRV: stakeFor failed");
        } else if (_option == WithdrawOption.WithdrawAsCRV) {
            _amount = _zapToken(_amount, CVXCRV, _minimumOut, CRV);
            IERC20Upgradeable(CRV).safeTransfer(_recipient, _amount);
        } else if (_option == WithdrawOption.WithdrawAsETH) {
            _amount = _zapToken(_amount, CVXCRV, _minimumOut, address(0));

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _recipient.call{ value: _amount }("");
            require(success, "LendFlareCRV: ETH transfer failed");
        } else if (_option == WithdrawOption.WithdrawAsCVX) {
            _amount = _zapToken(_amount, CVXCRV, _minimumOut, CVX);
            IERC20Upgradeable(CVX).safeTransfer(_recipient, _amount);
        } else {
            revert("LendFlareCRV: unsupported option");
        }
        return _amount;
    }

    function _harvest(uint256 _minimumOut) internal returns (uint256) {
        IConvexBasicRewards(CVXCRV_STAKING).getReward();
        // 1. CVX => ETH
        uint256 _amount = _zapToken(IERC20Upgradeable(CVX).balanceOf(address(this)), CVX, 0, address(0));
        // 2. 3CRV => USDT => ETH
        _amount += _zapToken(IERC20Upgradeable(THREE_CRV).balanceOf(address(this)), THREE_CRV, 0, address(0));
        // 3. ETH => CRV
        _zapToken(_amount, address(0), 0, CRV);
        // 3. CRV => cvxCRV (stake or swap)
        _amount = IERC20Upgradeable(CRV).balanceOf(address(this));
        _zapToken(_amount, CRV, _amount, CVXCRV);

        _amount = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
        require(_amount >= _minimumOut, "LendFlareCRV: insufficient rewards");

        emit Harvest(msg.sender, _amount);

        uint256 _totalSupply = totalSupply();
        if (_amount > 0 && _totalSupply > 0) {
            IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, 0);
            IERC20Upgradeable(CVXCRV).safeApprove(CVXCRV_STAKING, _amount);
            IConvexBasicRewards(CVXCRV_STAKING).stake(_amount);
        }

        return _amount;
    }

    function _zapToken(
        uint256 _amount,
        address _fromToken,
        uint256 _minimumOut,
        address _toToken
    ) internal returns (uint256) {
        if (_amount == 0) return 0;

        // remove delegate call
        if (_fromToken == address(0)) {
            return IZap(zap).zap{ value: _amount }(_fromToken, _amount, _toToken, _minimumOut);
        } else {
            IERC20Upgradeable(_fromToken).safeTransfer(zap, _amount);

            return IZap(zap).zap(_fromToken, _amount, _toToken, _minimumOut);
        }
    }

    receive() external payable {}
}