// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

uint256 constant EXTRANET_TOKEN_REWARD_PRECISION = 1e12;

contract ExtranetToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address public minter;
    address public rewardToken;
    address public rewardCustodian;

    mapping (address => uint256) public rewardDebt;
    mapping (address => uint256) public rewardUnpaid;
    uint256 public accIncentPerShare = 0;

    // minter is explicitly not set here as it is not yet available on deploy. ExtranetService must be deployed first.
    constructor(string memory name, string memory symbol, uint8 __decimals) ERC20(name, symbol) {
        _decimals = __decimals;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY_MINTER");
        _;
    }

    function decimals()
        public
        view
        override
        returns (uint8)
    {
        return _decimals;
    }

    function mintTo(address account, uint256 amount)
        public
        onlyMinter
    {
        _mint(account, amount);

        rewardDebt[account] += uint256(amount * accIncentPerShare / EXTRANET_TOKEN_REWARD_PRECISION);
    }

    function burnFrom(address account, uint256 amount)
        public
        onlyMinter
    {
        uint256 _rewardAmount = pendingRewardAmount(account);

        _burn(account, amount);

        if (_rewardAmount > 0) {
            rewardUnpaid[account] += _rewardAmount;
        }

        rewardDebt[account] = uint256(balanceOf(account) * accIncentPerShare / EXTRANET_TOKEN_REWARD_PRECISION);
    }

    function onReward(uint256 amount)
        public
        onlyMinter
    {
        if (totalSupply() == 0) {
            return;
        }

        accIncentPerShare += uint256(EXTRANET_TOKEN_REWARD_PRECISION * amount / totalSupply());
    }

    function collectReward()
        public
    {
        uint256 _amount = pendingReward(msg.sender);

        if (_amount > 0) {
            IERC20(rewardToken).safeTransferFrom(rewardCustodian, msg.sender, _amount);
        }

        rewardUnpaid[msg.sender] = 0;
        rewardDebt[msg.sender] = uint256(balanceOf(msg.sender) * accIncentPerShare / EXTRANET_TOKEN_REWARD_PRECISION);
    }

    function pendingReward(address account)
        public
        view
        returns (uint256)
    {
        return pendingRewardAmount(account) + rewardUnpaid[account];
    }

    function pendingRewardAmount(address account)
        internal
        view
        returns (uint256)
    {
        return uint256(accIncentPerShare * balanceOf(account) / EXTRANET_TOKEN_REWARD_PRECISION) - rewardDebt[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256)
        internal
        pure
        override
    {
        require(from == address(0) || to == address(0), "TRANSFERS_NOT_ALLOWED");
    }

    function setProperties(address _minter, address _rewardToken, address _rewardCustodian)
        public
        onlyOwner
    {
        minter = _minter;
        rewardToken = _rewardToken;
        rewardCustodian = _rewardCustodian;
    }
}