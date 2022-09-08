// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './interfaces/IWETH.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IGhostSharePotFactory.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

contract GhostSharePot is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public collection;
    address public WETH;
    address public admin;
    string public name;

    // _tokenId => level
    mapping(uint256 => uint256) public levels;
    mapping(uint256 => uint256) public stockReward;
    mapping(uint256 => uint256) public harvestedReward;

    uint256 public totalLevel;
    uint256 public totalStockReward;
    uint256 public totalHarvestedReward;

    IGhostSharePotFactory factory;
    IERC721Enumerable collectionInstance;

    event Harvest(uint256 reward, address user);
    event Burn();
    event changeAdmin(address oldCreator, address newCreator);

    receive() external payable {
        assert(msg.sender == WETH);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Management: Not admin');
        _;
    }

    constructor(
        string memory _name,
        address _collection,
        address _WETH,
        address _admin
    ) {
        name = _name;
        collection = _collection;
        collectionInstance = IERC721Enumerable(collection);
        require(collectionInstance.supportsInterface(0x80ac58cd), 'Error: Collection is invalid');
        WETH = _WETH;
        admin = _admin;
        factory = IGhostSharePotFactory(owner());
    }

    function depositEth() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    function _collectionTotalSupply() internal view returns (uint256) {
        return collectionInstance.totalSupply();
    }

    function collectionTotalSupply() external view returns (uint256) {
        return _collectionTotalSupply();
    }

    function updateTokenLevel(uint256 _tokenId, uint256 _level) external onlyAdmin {
        _updateStock();
        totalLevel = totalLevel.sub(levels[_tokenId]).add(_level);
        levels[_tokenId] = _level;
    }

    function _getTokenPendingReward(uint256 _tokenId) internal view returns (uint256) {
        (uint256 netBalance, ) = _getNetAndFeeBalance();
        if (totalLevel == 0) {
            return 0;
        }
        return netBalance.div(totalLevel).mul(levels[_tokenId]).add(stockReward[_tokenId]);
    }

    function _removeStockBalance() internal view returns (uint256) {
        return IERC20(WETH).balanceOf(address(this)).sub(totalStockReward);
    }

    function _getNetAndFeeBalance() internal view returns (uint256, uint256) {
        return factory.getNetAndFeeBalance(_removeStockBalance());
    }

    function _pendingReward(address _user) internal view returns (uint256) {
        uint256 userTokens = collectionInstance.balanceOf(_user);
        uint256 _reward = 0;
        for (uint256 index = 0; index < userTokens; index++) {
            uint256 _tokenId = collectionInstance.tokenOfOwnerByIndex(_user, index);
            _reward = _reward.add(_getTokenPendingReward(_tokenId));
        }
        return _reward;
    }

    function pendingReward(address _user) external view returns (uint256) {
        return _pendingReward(_user);
    }

    function userLevel(address _user) external view returns (uint256) {
        uint256 userTokens = collectionInstance.balanceOf(_user);
        uint256 _level = 0;
        for (uint256 index = 0; index < userTokens; index++) {
            uint256 _tokenId = collectionInstance.tokenOfOwnerByIndex(_user, index);
            _level = _level.add(levels[_tokenId]);
        }
        return _level;
    }

    function _updateStock() internal {
        (uint256 netBalance, uint256 feeBalance) = _getNetAndFeeBalance();
        if (netBalance > 0) {
            _feeDistribute(feeBalance);
            uint256 rewardPerLevel = netBalance.div(totalLevel);
            uint256 totalSupply = _collectionTotalSupply();
            for (uint256 index = 0; index < totalSupply; index++) {
                uint256 _tokenId = collectionInstance.tokenByIndex(index);
                uint256 _reward = rewardPerLevel.mul(levels[_tokenId]);
                stockReward[_tokenId] = stockReward[_tokenId].add(_reward);
                totalStockReward = totalStockReward.add(_reward);
            }
        }
    }

    function _feeDistribute(uint256 _feeBalance) internal {
        IERC20(WETH).safeTransfer(owner(), _feeBalance);
        factory.feeDistribute();
    }

    function _harvestFromToken(uint256 _tokenId) internal returns (uint256) {
        uint256 _tokenPendingReward = _getTokenPendingReward(_tokenId);
        if (_tokenPendingReward > 0) {
            address _user = collectionInstance.ownerOf(_tokenId);
            payReward(_user, _tokenPendingReward);
            harvestedReward[_tokenId] = harvestedReward[_tokenId].add(_tokenPendingReward);
            totalHarvestedReward = totalHarvestedReward.add(_tokenPendingReward);
            stockReward[_tokenId] = stockReward[_tokenId].sub(_tokenPendingReward);
            totalStockReward = totalStockReward.sub(_tokenPendingReward);
        }
        return _tokenPendingReward;
    }

    function _harvestRewards(address _user) internal {
        require(totalLevel > 0, 'No level operation');
        _updateStock();
        uint256 userTokens = collectionInstance.balanceOf(_user);
        uint256 _reward = 0;
        for (uint256 index = 0; index < userTokens; index++) {
            uint256 _tokenId = collectionInstance.tokenOfOwnerByIndex(_user, index);
            uint256 _tokenReward = _harvestFromToken(_tokenId);
            _reward = _reward.add(_tokenReward);
        }
        emit Harvest(_reward, _user);
    }

    function harvestRewards(address _user) external {
        require(_user == msg.sender || msg.sender == admin, 'Error: You can not harvest operation');
        _harvestRewards(_user);
    }

    function burn() external onlyAdmin {
        uint256 totalSupply = _collectionTotalSupply();
        for (uint256 index = 0; index < totalSupply; index++) {
            uint256 _tokenId = collectionInstance.tokenByIndex(index);
            stockReward[_tokenId] = 0;
            levels[_tokenId] = 0;
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