// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './interfaces/IWETH.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IGhostFeeManagerFactory.sol';

/*
 * This contract is used to collect sRADS stacking dividends from fee (like swap, deposit on pools or farms)
 */
contract GhostFeeManager is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public WETH;
    address public admin;
    string public name; // fee manager name

    address[] public users;
    // address => level
    mapping(address => uint256) public levels;
    // address => harvestedReward
    mapping(address => uint256) public harvestedReward;
    mapping(address => uint256) private stockReward;
    // uint256 private totalLevel;
    uint256 public totalLevel;
    uint256 public totalStockReward;
    uint256 public totalHarvestedReward;

    IGhostFeeManagerFactory factory;

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Management: Not admin');
        _;
    }

    event Harvest(uint256 reward, address user);
    event Burn();
    event changeAdmin(address oldCreator, address newCreator);

    constructor(
        address _WETH,
        string memory _name,
        address _admin
    ) {
        WETH = _WETH;
        name = _name;
        admin = _admin;
        factory = IGhostFeeManagerFactory(owner());
    }

    function depositEth() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _isAlreadyRegistered(address _user) internal view returns (bool) {
        for (uint256 index = 0; index < users.length; index++) {
            if (users[index] == _user) {
                return true;
            }
        }
        return false;
    }

    function updateUser(address _user, uint256 _level) external onlyAdmin {
        uint256 _beforeLevel = levels[_user];
        levels[_user] = _level;
        totalLevel = totalLevel.sub(_beforeLevel).add(_level);
        if (!_isAlreadyRegistered(_user)) {
            users.push(_user);
        }
    }

    function _removeStockBalance() internal view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this)).sub(totalStockReward);
    }

    function _getNetAndFeeBalance() internal view returns (uint256, uint256) {
        return factory.getNetAndFeeBalance(_removeStockBalance());
    }

    function _pendingReward(address _user) internal view returns (uint256) {
        if (totalLevel == 0) {
            return 0;
        }
        (uint256 netBalance, ) = _getNetAndFeeBalance();
        return netBalance.div(totalLevel).mul(levels[_user]).add(stockReward[_user]);
    }

    function pendingReward(address _user) external view returns (uint256) {
        return _pendingReward(_user);
    }

    function _updateStock() internal {
        (uint256 netBalance, uint256 feeBalance) = _getNetAndFeeBalance();
        _feeDistribute(feeBalance);
        uint256 rewardPerLevel = netBalance.div(totalLevel);
        for (uint256 index = 0; index < users.length; index++) {
            address _user = users[index];
            uint256 _reward = rewardPerLevel.mul(levels[_user]);
            stockReward[_user] = stockReward[_user].add(_reward);
            totalStockReward = totalStockReward.add(_reward);
        }
    }

    function _feeDistribute(uint256 _feeBalance) internal {
        IERC20(WETH).safeTransfer(owner(), _feeBalance);
        factory.feeDistribute();
    }

    function _harvestRewards(address _user) internal {
        require(totalLevel > 0, 'No user operation');
        _updateStock();
        uint256 _userReward = _pendingReward(_user);
        if (_userReward > 0) {
            payReward(_user, _userReward);
            harvestedReward[_user] = harvestedReward[_user].add(_userReward);
            totalHarvestedReward = totalHarvestedReward.add(_userReward);
            stockReward[_user] = stockReward[_user].sub(_userReward);
            totalStockReward = totalStockReward.sub(_userReward);
        }
        emit Harvest(_userReward, _user);
    }

    function allUserHarvestRewards() external onlyAdmin {
        for (uint256 index = 0; index < users.length; index++) {
            if (_pendingReward(users[index]) > 0) {
                _harvestRewards(users[index]);
            }
        }
    }

    function harvestRewards() external {
        return _harvestRewards(msg.sender);
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }

    function burn() external onlyAdmin {
        for (uint256 index = 0; index < users.length; index++) {
            address _user = users[index];
            levels[_user] = 0;
            stockReward[_user] = 0;
        }
        totalStockReward = 0;
        totalLevel = 0;
        _newAdmin(factory.getOwner());
        IERC20(WETH).safeTransfer(owner(), _removeStockBalance());
        factory.feeDistribute();
        emit Burn();
    }

    function _newAdmin(address _newAdminAddress) internal {
        address _oldAdmin = admin;
        admin = _newAdminAddress;
        emit changeAdmin(_oldAdmin, _newAdminAddress);
    }

    function newAdmin(address _newAdminAddress) external onlyAdmin {
        return _newAdmin(_newAdminAddress);
    }

    function payReward(address _target, uint256 _reward) internal {
        if (payable(_target).send(0)) {
            IWETH(WETH).withdraw(_reward);
            TransferHelper.safeTransferETH(_target, _reward);
        } else {
            IERC20(WETH).safeTransfer(_target, _reward);
        }
    }
}