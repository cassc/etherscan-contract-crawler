// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../interfaces/enums/Network.sol';
import '../interfaces/enums/TokenType.sol';
import '../interfaces/IMarketplace.sol';
import '../interfaces/enums/Environment.sol';
import '../interfaces/structs/DistributedUserInfo.sol';
import '../Recoverable.sol';
import '../Literals.sol';

contract DistributedRewardsPot is
    Literals,
    Ownable,
    AccessControl,
    Recoverable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint8;

    struct Statistics {
        uint256 volume;
        uint256 collection;
        uint256 withdrawn;
        uint256 allWeightages;
        uint256 totalParticipants; // Total Confirmed Participants
    }

    Environment private _env;

    address public nftContract;
    address public nftHashContract;

    IERC20 private immutable _ayraToken;
    IERC20 private immutable _ithdToken;

    Network private immutable _network;

    bytes32 public constant NFT_CONTRACT = keccak256('NFT_CONTRACT');
    uint256 public currentMonth;

    uint256 public ayraBurnLimit;
    uint256 public ayraBurningFee;
    uint256 public totalAYRABurned;
    uint256 public ayraBurnLimitPerAddress;
    mapping(address => uint256) public totalAYRABurnedByUser;

    mapping(uint256 => bool) private _theMonthIsValid;

    mapping(uint256 => mapping(TokenType => Statistics)) public statisticsFor;
    mapping(uint256 => mapping(address => mapping(TokenType => UserInfoDistributed)))
        public userInfoFor;

    uint256 private _twoMonths;
    uint256 private _sixMonths;

    uint256 public burnWeightage;
    uint256 public mintWeightage;

    uint256[2][] private _volumeToWeightagePairs;

    string private constant _NO_REWARDS = 'No rewards available';

    event StatisticsStored(
        address indexed user,
        TokenType tokenType,
        uint256 purchaseValue,
        uint256 rewardAmount
    );

    event RewardsClaimed(
        uint256 indexed month,
        address indexed user,
        TokenType tokentype,
        uint256 amount
    );

    event UnclaimedRewardsWithdrawn(
        uint256 indexed month,
        address indexed admin,
        TokenType tokentype,
        uint256 amount
    );

    modifier onlyMarketplaceOwner() {
        address marketplace = owner();

        require(
            _msgSender() == IMarketplace(marketplace).owner(),
            'Unauthorized!'
        );
        _;
    }

    constructor(
        Environment env,
        address _marketplace,
        IERC20 ayraToken,
        IERC20 ithdToken,
        address _nftContract,
        address _nftHashContract,
        Network network,
        uint256 _currentMonth
    ) {
        _env = env;
        _network = network;

        _transferOwnership(_marketplace);

        if (_env == Environment.Development) {
            _twoMonths = 40 minutes;
            _sixMonths = 120 minutes;
        } else {
            _twoMonths = 2 * (30 days);
            _sixMonths = 6 * (30 days);
        }

        _ayraToken = ayraToken;
        _ithdToken = ithdToken;

        _setNFTContracts(_nftContract, _nftHashContract);

        if (_network == Network.Binance) {
            ayraBurnLimit = _ayraToken.totalSupply().mul(40).div(100);
            ayraBurnLimitPerAddress = 20_000 ether;
        }

        burnWeightage = 0.6 ether;
        mintWeightage = 0.5 ether;

        if (_network == Network.Binance) {
            ayraBurningFee = 0.05 ether;

            _addVolumeToWeightagePair([uint256(0.033 ether), uint256(1 ether)]);
            _addVolumeToWeightagePair(
                [uint256(0.33 ether), uint256(1.5 ether)]
            );
            _addVolumeToWeightagePair([uint256(0.65 ether), uint256(2 ether)]);
            _addVolumeToWeightagePair(
                [uint256(0.98 ether), uint256(2.5 ether)]
            );
        } else {
            _addVolumeToWeightagePair([uint256(1 ether), uint256(1 ether)]);
            _addVolumeToWeightagePair([uint256(90 ether), uint256(1.5 ether)]);
            _addVolumeToWeightagePair([uint256(180 ether), uint256(2 ether)]);
            _addVolumeToWeightagePair([uint256(280 ether), uint256(2.5 ether)]);
        }

        if (_currentMonth != _ZERO) {
            currentMonth = _currentMonth;
        } else {
            currentMonth = block.timestamp;
        }

        _updateCurrentMonth();
    }

    receive() external payable {}

    function recoverEther(
        address _to,
        uint256 _amount
    ) external onlyMarketplaceOwner returns (bool) {
        payable(_to).transfer(_amount);

        return true;
    }

    function changeMintWeightage(
        uint256 newWeightage
    ) external onlyMarketplaceOwner {
        mintWeightage = newWeightage;
    }

    function changeBurnWeightage(
        uint256 newWeightage
    ) external onlyMarketplaceOwner {
        burnWeightage = newWeightage;
    }

    function changeAYRABurnLimits(
        uint256 newLimit,
        uint256 newLimitPerAddress
    ) external onlyMarketplaceOwner {
        ayraBurnLimit = newLimit;
        ayraBurnLimitPerAddress = newLimitPerAddress;
    }

    function addVolumeToWeightagePair(
        uint256[2] memory volumeToWeightagePair
    ) external onlyMarketplaceOwner {
        _addVolumeToWeightagePair(volumeToWeightagePair);
    }

    function clearVolumeToWeightagePairs() external onlyMarketplaceOwner {
        delete _volumeToWeightagePairs;

        _volumeToWeightagePairs = new uint256[2][](0);
    }

    function setNFTContracts(
        address _nftContract,
        address _nftHashContract
    ) external onlyMarketplaceOwner {
        _setNFTContracts(_nftContract, _nftHashContract);
    }

    function noteUserMintParticipation(
        address userAddress,
        TokenType tokenType
    ) external onlyRole(NFT_CONTRACT) {
        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();

        UserInfoDistributed storage user = userInfoFor[currentMonth][
            userAddress
        ][tokenType];

        if (!user.hasParticipatedUsingMint) {
            user.hasParticipatedUsingMint = true;
            _updateTotalParticipation(userAddress, tokenType);
        }
    }

    function changeAYRABurningFee(
        uint256 newFee
    ) external onlyMarketplaceOwner {
        ayraBurningFee = newFee;
    }

    function storePurchaseStatistics(
        address userAddress,
        TokenType tokenType,
        uint256 purchaseValue,
        uint256 rewardAmount
    ) external onlyOwner {
        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();

        UserInfoDistributed storage user = userInfoFor[currentMonth][
            userAddress
        ][tokenType];

        Statistics storage statistics = statisticsFor[currentMonth][tokenType];

        user.volume = user.volume.add(purchaseValue);
        statistics.volume = statistics.volume.add(purchaseValue);

        uint256 currentVolumeInEther = IMarketplace(owner()).tokenToEther(
            purchaseValue,
            tokenType
        );
        user.volumeInEther = user.volumeInEther.add(currentVolumeInEther);
        uint256 volumeWeightage = _getWeightageForVolume(user.volumeInEther);

        if (
            volumeWeightage > _ZERO && user.volumeWeightage != volumeWeightage
        ) {
            user.volumeWeightage = volumeWeightage;
            _updateTotalParticipation(userAddress, tokenType);
        }

        statistics.collection = statistics.collection.add(rewardAmount);

        emit StatisticsStored(
            userAddress,
            tokenType,
            purchaseValue,
            rewardAmount
        );
    }

    function addMintCollection(
        TokenType tokenType,
        uint256 takenFeeAmount
    ) external onlyRole(NFT_CONTRACT) {
        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();

        Statistics storage statistics = statisticsFor[currentMonth][tokenType];
        statistics.collection = statistics.collection.add(takenFeeAmount);
    }

    function burnHundredAYRA(TokenType tokenType) external payable {
        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();
        require(_network == Network.Binance, 'Can only burn AYRA on BSC');

        address userAddress = _msgSender();
        UserInfoDistributed storage user = userInfoFor[currentMonth][
            userAddress
        ][tokenType];

        require(!user.hasBurned, 'You have already burned AYRA for this pool');
        require(msg.value >= ayraBurningFee, _INSUFFICIENT_VALUE);

        uint256 burnAmount = 100 ether;

        require(
            totalAYRABurned.add(burnAmount) <= ayraBurnLimit,
            'AYRA Burning limit reached'
        );

        totalAYRABurned = totalAYRABurned.add(burnAmount);

        require(
            totalAYRABurnedByUser[userAddress].add(burnAmount) <=
                ayraBurnLimitPerAddress,
            'AYRA Burning limit reached for this address'
        );

        totalAYRABurnedByUser[userAddress] = totalAYRABurnedByUser[userAddress]
            .add(burnAmount);

        user.hasBurned = true;

        if (ayraBurningFee > _ZERO) {
            payable(IMarketplace(owner()).bridgeAdmin()).transfer(
                ayraBurningFee
            );
        }

        _ayraToken.safeTransferFrom(userAddress, _ZERO_ADDRESS, burnAmount);

        _updateTotalParticipation(userAddress, tokenType);
    }

    function withdrawRewards(uint256 month, TokenType tokenType) external {
        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();

        address userAddress = _msgSender();

        Statistics storage statistics = statisticsFor[month][tokenType];
        UserInfoDistributed storage user = userInfoFor[month][userAddress][
            tokenType
        ];

        require(_theMonthIsValid[month], 'Month is not valid');
        require(
            user.hasParticipated,
            'You have not participated in this duration'
        );
        require(
            user.hasWithdrawn == false,
            'You have already withdrawn the rewards'
        );
        require(
            currentMonth > month,
            'Cannot withdraw during ongoing collection'
        );
        require(
            currentMonth.add(_twoMonths).sub(month) <= _sixMonths,
            'Cannot withdraw rewards older than 6 months'
        );
        require(
            user.allWeightages > _ZERO,
            'You hold no weightage in this duration'
        );

        uint256 myWeightageInPercent = _calculatePercentage(
            user.allWeightages,
            statistics.allWeightages
        );

        uint256 myShare = statistics.collection.mul(myWeightageInPercent).div(
            _ONE_HUNDRED.mul(_PERCENTAGE_PRECISION)
        );

        require(myShare > _ZERO, _NO_REWARDS);

        user.hasWithdrawn = true;

        statistics.withdrawn = statistics.withdrawn.add(myShare);

        if (tokenType == TokenType.Native) {
            payable(userAddress).transfer(myShare);
        } else if (tokenType == TokenType.AYRA) {
            _ayraToken.safeTransfer(userAddress, myShare);
        } else if (tokenType == TokenType.ITHD) {
            _ithdToken.safeTransfer(userAddress, myShare);
        }

        emit RewardsClaimed(month, userAddress, tokenType, myShare);
    }

    function withdrawUnclaimedRewards(
        uint256 month,
        address admin,
        TokenType tokenType
    ) external onlyOwner {
        // && only the marketpalace admin, should authorize using marketplace contract

        if (_shouldUpdateCurrentMonth()) _updateCurrentMonth();

        Statistics storage statistics = statisticsFor[month][tokenType];

        require(_theMonthIsValid[month], 'Month is not valid');
        require(
            currentMonth.add(_twoMonths).sub(month) > _sixMonths,
            'Can only withdraw rewards older than 6 months'
        );

        uint256 remainingRewards = statistics.collection.sub(
            statistics.withdrawn
        );

        require(remainingRewards > _ZERO, _NO_REWARDS);

        statistics.withdrawn = statistics.collection;

        if (tokenType == TokenType.Native) {
            payable(admin).transfer(remainingRewards);
        } else if (tokenType == TokenType.AYRA) {
            _ayraToken.safeTransfer(admin, remainingRewards);
        } else if (tokenType == TokenType.ITHD) {
            _ithdToken.safeTransfer(admin, remainingRewards);
        }

        emit UnclaimedRewardsWithdrawn(
            month,
            admin,
            tokenType,
            remainingRewards
        );
    }

    function recoverFunds(
        address token,
        address to,
        uint256 amount
    ) external onlyMarketplaceOwner {
        _recoverFunds(token, to, amount);
    }

    function getUserInfoForCurrentMonth(
        address userAddress,
        TokenType tokenType
    ) external view returns (UserInfoDistributed memory) {
        if (block.timestamp.sub(currentMonth) > _twoMonths) {
            // Alternative to updating current month, we assume that
            // all the values will be default
            return
                UserInfoDistributed({
                    hasParticipated: false,
                    hasParticipatedUsingMint: false,
                    hasBurned: false,
                    volumeWeightage: _ZERO,
                    allWeightages: _ZERO,
                    volume: _ZERO,
                    volumeInEther: _ZERO,
                    hasWithdrawn: false
                });
        }

        return userInfoFor[currentMonth][userAddress][tokenType];
    }

    function getAllVolumeToWeightagePairs()
        external
        view
        returns (uint256[2][] memory)
    {
        return _volumeToWeightagePairs;
    }

    function _setNFTContracts(
        address _nftContract,
        address _nftHashContract
    ) internal {
        _revokeRole(NFT_CONTRACT, nftContract);
        _revokeRole(NFT_CONTRACT, nftHashContract);

        nftContract = _nftContract;
        nftHashContract = _nftHashContract;

        _grantRole(NFT_CONTRACT, nftContract);
        _grantRole(NFT_CONTRACT, nftHashContract);
    }

    function _addVolumeToWeightagePair(
        uint256[2] memory volumeToWeightagePair
    ) private {
        uint256 totalVolumePairs = _volumeToWeightagePairs.length;

        if (totalVolumePairs > _ZERO) {
            uint256 currentMaximumVolume = _volumeToWeightagePairs[
                totalVolumePairs.sub(_ONE)
            ][_ZERO];

            require(
                volumeToWeightagePair[_ZERO] > currentMaximumVolume,
                'Volume should be greater than current maximum'
            );

            uint256 currentMaximumWeightage = _volumeToWeightagePairs[
                totalVolumePairs.sub(_ONE)
            ][_ONE];

            require(
                volumeToWeightagePair[_ONE] > currentMaximumWeightage,
                'Weightage should be greater than current maximum'
            );
        }

        _volumeToWeightagePairs.push(volumeToWeightagePair);
    }

    function _updateTotalParticipation(
        address userAddress,
        TokenType tokenType
    ) private {
        Statistics storage statistics = statisticsFor[currentMonth][tokenType];

        UserInfoDistributed storage user = userInfoFor[currentMonth][
            userAddress
        ][tokenType];

        uint256 allWeightages;

        if (user.volumeWeightage != _ZERO) {
            allWeightages = allWeightages.add(user.volumeWeightage);
        }

        if (user.hasParticipatedUsingMint) {
            allWeightages = allWeightages.add(mintWeightage);
        }

        if (user.hasBurned) {
            allWeightages = allWeightages.add(burnWeightage);
        }

        if (allWeightages > _ZERO) {
            _updateTotalParticipants(userAddress, tokenType);
        }

        if (user.allWeightages != allWeightages) {
            statistics.allWeightages = statistics
                .allWeightages
                .sub(user.allWeightages)
                .add(allWeightages);

            user.allWeightages = allWeightages;
        }
    }

    function _updateTotalParticipants(
        address userAddress,
        TokenType tokenType
    ) private {
        UserInfoDistributed storage user = userInfoFor[currentMonth][
            userAddress
        ][tokenType];

        if (!user.hasParticipated) {
            user.hasParticipated = true;
            Statistics storage statistics = statisticsFor[currentMonth][
                tokenType
            ];
            statistics.totalParticipants = statistics.totalParticipants.add(
                _ONE
            );
        }
    }

    function _updateCurrentMonth() private {
        uint256 difference = block.timestamp.sub(currentMonth);
        uint256 times = difference.div(_twoMonths);
        currentMonth = currentMonth.add(times.mul(_twoMonths));
        _theMonthIsValid[currentMonth] = true;
    }

    function _shouldUpdateCurrentMonth() private view returns (bool) {
        return block.timestamp.sub(currentMonth) > _twoMonths;
    }

    function _getWeightageForVolume(
        uint256 volume
    ) private view returns (uint256) {
        uint256 totalVolumePairs = _volumeToWeightagePairs.length;

        if (volume < _volumeToWeightagePairs[_ZERO][_ZERO]) {
            // Volume is less than the first tier
            return _ZERO;
        }

        for (uint256 index = _ONE; index < totalVolumePairs; index++) {
            if (_volumeToWeightagePairs[index][_ZERO] > volume) {
                return _volumeToWeightagePairs[index - _ONE][_ONE];
            }
        }

        // If not returned yet, return maximum weightage
        return _volumeToWeightagePairs[totalVolumePairs - _ONE][_ONE];
    }

    function _calculatePercentage(
        uint256 _value,
        uint256 _of
    ) private pure returns (uint256) {
        if (_of == _ZERO) return _ZERO;

        uint256 percentage = _value
            .mul(_ONE_HUNDRED)
            .mul(_PERCENTAGE_PRECISION)
            .div(_of);

        return percentage;
    }
}