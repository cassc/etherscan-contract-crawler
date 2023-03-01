// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {StakePoolStorage} from "./StakePoolStorage.sol";
import {IAtpadNft} from "./interfaces/IAtpadNft.sol";

contract StakePool is
    StakePoolStorage,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @title StakePool
    // @notice This is a Natspec commented contract by AtomPad Development Team
    // @notice Version v2.2.3 date: 20 Feb 2023

    IERC20Upgradeable public stakeToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _stakeToken) external initializer {
        stakeToken = IERC20Upgradeable(_stakeToken);
        decimals = 18;
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        stakeOn = false;
        withdrawOn = false;
        maxStakeOrWithdrawNft = 10;
        minStakingAmount = 10000;
    }

    function stake(uint256 _amount)
        external
        stakeEnabled
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(
            _amount > (10 * 10**decimals),
            "StakePool: Minimum stake amount is 10 tokens."
        );

        require(
            (_amount + tokenBalances[msg.sender]) >=
                (minStakingAmount * 10**decimals),
            "StakePool: Staking amount is less than minimum staking amount."
        );

        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);

        tokenBalances[msg.sender] += _amount;

        totalAllocPoint -= allocPoints[msg.sender];

        allocPoints[msg.sender] = _reBalance(tokenBalances[msg.sender]);

        timeLocks[msg.sender] = block.timestamp;

        totalAllocPoint += allocPoints[msg.sender];

        totalStaked += _amount;

        userAdresses.push(msg.sender);

        emit Staked(msg.sender, _amount);

        return true;
    }

    function withdraw(uint256 _amount)
        public
        withdrawEnabled
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(
            tokenBalances[msg.sender] >= _amount,
            "StakePool: Insufficient staking balance!"
        );

        require(_amount > 0, "StakePool: !amount");

        uint256 _fee = calculateWithdrawFees(_amount, msg.sender);

        tokenBalances[msg.sender] -= _amount;

        totalAllocPoint -= allocPoints[msg.sender];

        allocPoints[msg.sender] = _reBalance(tokenBalances[msg.sender]);

        uint256 _transferAmount = _amount - _fee;

        totalAllocPoint += allocPoints[msg.sender];

        collectedFee += _fee;

        totalStaked -= _amount;

        stakeToken.safeTransfer(msg.sender, _transferAmount);

        emit Withdrawn(msg.sender, _amount);

        return true;
    }

    function withdrawAll()
        external
        withdrawEnabled
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        withdraw(tokenBalances[msg.sender]);
        return true;
    }

    function stakeNft(uint256[] memory _tokenIds, uint256 _tierIndex)
        external
        stakeEnabled
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        uint256 _tokenIdsLength = _tokenIds.length;

        require(_tokenIdsLength > 0, "StakePool: !tokenIDs");

        require(
            _tokenIdsLength <= maxStakeOrWithdrawNft,
            "StakePool: Nft count exceeds max limit."
        );

        require(_tierIndex < tiers.length, "StakePool: Tier does not exists !");

        Tier memory _tier = tiers[_tierIndex];

        address _collection = _tier.collection;

        uint256 _weight = _tier.weight;

        uint256 _totalWeight = _weight * _tokenIdsLength;

        for (uint256 i; i < _tokenIds.length; i++) {
            IAtpadNft(_tier.collection).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );

            nftOwners[_collection][_tokenIds[i]] = msg.sender;
        }

        nftBalances[_collection][msg.sender] += _tokenIdsLength;

        nftAllocPoints[msg.sender] += _totalWeight;

        totalAllocPoint += _totalWeight;

        totalStakedNft += _tokenIdsLength;

        userAdresses.push(msg.sender);

        emit NFTStaked(msg.sender, _tokenIds);

        return true;
    }

    function withdrawNft(uint256[] memory _tokenIds, uint256 _tierIndex)
        external
        nonReentrant
        whenNotPaused
        withdrawEnabled
        returns (bool)
    {
        uint256 _tokenIdsLength = _tokenIds.length;

        require(_tokenIdsLength > 0, "StakePool: !tokenIDs");

        require(
            _tokenIdsLength <= maxStakeOrWithdrawNft,
            "StakePool: Nft count exceeds max limit."
        );

        require(_tierIndex < tiers.length, "StakePool: Tier does not exists !");

        Tier memory _tier = tiers[_tierIndex];

        address _collection = _tier.collection;

        require(
            _tokenIdsLength <= nftBalances[_collection][msg.sender],
            "StakePool: !staked"
        );

        for (uint256 i; i < _tokenIdsLength; i++) {
            require(
                nftOwners[_collection][_tokenIds[i]] == msg.sender,
                "StakePool: !staked"
            );
        }

        uint256 _totalWeight = _tier.weight * _tokenIdsLength;

        nftAllocPoints[msg.sender] -= _totalWeight;

        nftBalances[_collection][msg.sender] -= _tokenIdsLength;

        totalAllocPoint -= _totalWeight;

        totalStakedNft -= _tokenIdsLength;

        for (uint256 i; i < _tokenIdsLength; i++) {
            nftOwners[_collection][_tokenIds[i]] = address(0);

            IAtpadNft(_tier.collection).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }

        emit NFTWithdrawn(msg.sender, _tokenIds);

        return true;
    }

    function balanceOf(address _sender) external view returns (uint256) {
        return tokenBalances[_sender];
    }

    function lockOf(address _sender) external view returns (uint256) {
        return timeLocks[_sender];
    }

    function allocPointsOf(address _sender) public view returns (uint256) {
        return
            allocPoints[_sender] +
            nftAllocPoints[_sender] +
            promoAllocPoints[_sender];
    }

    function tokenAllocPointsOf(address _sender)
        external
        view
        returns (uint256)
    {
        return allocPoints[_sender];
    }

    function nftAllocPointsOf(address _sender) external view returns (uint256) {
        return nftAllocPoints[_sender];
    }

    function promoAllocPointsOf(address _sender)
        external
        view
        returns (uint256)
    {
        return promoAllocPoints[_sender];
    }

    function allocPercentageOf(address _sender)
        external
        view
        returns (uint256)
    {
        uint256 points = allocPointsOf(_sender) * 10**6;

        uint256 millePercentage = points / totalAllocPoint;

        return millePercentage;
    }

    function ownerOf(uint256 _tokenId, address _collection)
        external
        view
        returns (address)
    {
        return nftOwners[_collection][_tokenId];
    }

    function getTiers() external view returns (Tier[] memory) {
        return tiers;
    }

    function users() external view returns (address[] memory) {
        return userAdresses;
    }

    function user(uint256 _index) external view returns (address) {
        return userAdresses[_index];
    }

    function getNfts(
        address _collection,
        address _sender,
        uint256 _limit
    ) external view returns (uint256[] memory) {
        uint256 _balance = nftBalances[_collection][_sender];
        uint256[] memory _tokenIds = new uint256[](_balance);
        uint256 j;
        for (uint256 i; i <= _limit; i++) {
            if (nftOwners[_collection][i] == _sender) {
                _tokenIds[j] = i;
                j++;
            }
        }

        return _tokenIds;
    }

    function getNftBalance(address _collection, address _sender)
        external
        view
        returns (uint256)
    {
        return nftBalances[_collection][_sender];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function calculateWithdrawFees(uint256 _amount, address _account)
        public
        view
        returns (uint256 _fee)
    {
        uint256 _timeLock = timeLocks[_account];
        _fee = calculateWithdrawFees(_amount, _timeLock);
    }

    function _reBalance(uint256 _balance)
        public
        view
        returns (uint256 _points)
    {
        _points = 0;

        uint256 _smallest = tiers[tiers.length - 1].stake;

        while (_balance >= _smallest) {
            for (uint256 i = 0; i < tiers.length; i++) {
                if (_balance >= tiers[i].stake) {
                    _points += tiers[i].weight;
                    _balance -= tiers[i].stake;
                    i = tiers.length;
                }
            }
        }
        return _points;
    }

    function calculateWithdrawFees(uint256 _amount, uint256 _timeLock)
        private
        view
        returns (uint256 _fee)
    {
        _fee = 0;

        uint256 _now = block.timestamp;

        if (_now > _timeLock + uint256(8 weeks)) {
            _fee = 0;
        }

        if (_now <= _timeLock + uint256(8 weeks)) {
            _fee = (_amount * 2) / 100;
        }

        if (_now <= _timeLock + uint256(6 weeks)) {
            _fee = (_amount * 5) / 100;
        }

        if (_now <= _timeLock + uint256(4 weeks)) {
            _fee = (_amount * 10) / 100;
        }

        if (_now <= _timeLock + uint256(2 weeks)) {
            _fee = (_amount * 20) / 100;
        }

        return _fee;
    }

    function withdrawCollectedFee() external onlyOwner {
        require(collectedFee > 0, "StakePool: No fee to withdraw");

        uint256 _amount = collectedFee;
        collectedFee = 0;

        stakeToken.transfer(msg.sender, _amount);
        emit FeeWithdrawn(msg.sender, _amount);
    }

    function resetStakeToken(address _stakeToken) external onlyOwner {
        require(_stakeToken != address(0), "StakePool: !StakeToken");
        stakeToken = IERC20Upgradeable(_stakeToken);
    }

    function addTier(
        string memory _name,
        address _collection,
        uint256 _stake,
        uint256 _weight
    ) external onlyOwner {
        tiers.push(
            Tier({
                name: _name,
                collection: _collection,
                stake: _stake,
                weight: _weight
            })
        );
    }

    function increasePromoAllocPoints(uint256 _points, address _account)
        external
        onlyOwner
    {
        require(_points > 0, "StakePool: !points");
        promoAllocPoints[_account] += _points;

        totalAllocPoint += _points;
    }

    function decreasePromoAllocPoints(uint256 _points, address _account)
        external
        onlyOwner
    {
        require(_points > 0, "StakePool: !points");
        require(
            promoAllocPoints[_account] >= _points,
            "StakePool: Not enough points!"
        );
        promoAllocPoints[_account] -= _points;

        totalAllocPoint -= _points;
    }

    function setEnableOrDisableStake(bool _flag) external onlyOwner {
        stakeOn = _flag;
    }

    function setDisableOrWithdraw(bool _flag) external onlyOwner {
        withdrawOn = _flag;
    }

    function setDecimals(uint8 _decimals) external onlyOwner {
        require(_decimals > 0, "StakePool: !decimals");
        decimals = _decimals;
    }

    function setMaxStakeOrWithdrawNft(uint256 _max) external onlyOwner {
        require(_max > 0, "StakePool: !max");
        maxStakeOrWithdrawNft = _max;
    }

    function setMinStakingAmount(uint256 _min) external onlyOwner {
        require(_min > 0, "StakePool: !min");
        minStakingAmount = _min;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event Staked(address indexed user, uint256 amount);
    event NFTStaked(address indexed user, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256 amount);
    event NFTWithdrawn(address indexed user, uint256[] tokenIds);
    event FeeWithdrawn(address indexed user, uint256 amount);

    modifier stakeEnabled() {
        require(stakeOn == true, "StakePool: Staking is paused !");
        _;
    }

    modifier withdrawEnabled() {
        require(withdrawOn == true, "StakePool: Withdrawing is paused !");
        _;
    }
}