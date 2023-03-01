// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

uint256 constant EXTRANET_TOKEN_REWARD_PRECISION = 1e12;

contract ExtranetToken is ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public minter;
    address public rewardToken; // this is essentially immutable as it's set only in the initializer
    address public rewardCustodian;

    mapping (address => uint256) public rewardDebt;
    mapping (address => uint256) public rewardUnpaid;
    uint256 public accIncentPerShare = 0;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol, address _minter,  address _rewardToken, address _rewardCustodian)
        public
        initializer
    {
        __ERC20_init(name, symbol);
        _transferOwnership(msg.sender);
        minter = _minter;
        rewardToken = _rewardToken;
        rewardCustodian = _rewardCustodian;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY_MINTER");
        _;
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
            IERC20Upgradeable(rewardToken).safeTransferFrom(rewardCustodian, msg.sender, _amount);
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

    function setRewardCustodian(address _rewardCustodian)
        public
        onlyOwner
    {
        rewardCustodian = _rewardCustodian;
    }

    function setMinter(address _minter)
        public
        onlyOwner
    {
        minter = _minter;
    }
}