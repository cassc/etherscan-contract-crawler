// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IGamificationBll.sol";
import "../interfaces/INftSales.sol";
import "hardhat/console.sol";

contract NftFactoryUpgradeable is Initializable, OwnableUpgradeable {
    struct FactoryInfo {
        uint256 rewardAvailableTimestamp; //when production will be finished
        uint8 bonusPowerPoints; //boosts for the current production run
        uint8 bonusProductionPoints; //extra productions points for the current production run
        uint32 mintCount; //number of production runs (one nft per production)
        uint32 productionPointMintCount; //number of productions points received
    }

    struct PowerShard {
        uint8 powerPoints;
        uint8 bonusProductionPoints;
    }

    IGamificationBll public bll;
    INftSales public nftContract;
    address public treasuryAddress;

    bool public isFactoryEnabled; //enable/disable factories
    uint32 public productionPointNftType;
    uint256 public boostPercentPerPowerPoint; // 1000 = 10.00%
    uint256 public maxBonusPowerPoints; //total boost points pre production
    uint256 public maxNftType; //high end range for factory NFTs
    uint256 public minNftType; //low end range for factory NFTs
    uint256 public totalMintCount; //total number of items produced

    mapping(uint32 => FactoryInfo) public nftToFactoryInfo;
    mapping(uint32 => PowerShard) public powerShardNftTypeToPowerShard;

    error AddressIsZero();
    error FactoryDisabled();
    error MaxBoosts();
    error NftTypeOutOfRange(uint256);
    error NoClaimAvailable(uint32 tokenId);
    error NotAPowerShard(uint32 tokenId);
    error NotFactory();
    error NotReadyToClaim(uint32 tokenId);

    event BoostFactory(
        address indexed user,
        uint32 indexed tokenId,
        uint256 indexed powershardId,
        uint256 rewardAvailableTimestamp
    );
    event Claim(
        address indexed user,
        uint32 indexed claimableNftAmount,
        uint32 indexed claimableProductionPointAmount,
        uint32 tokenId,
        uint32 nftTypeToMint
    );
    event StartFactory(
        address indexed user,
        uint32 indexed tokenId,
        uint256 indexed powershardId,
        uint256 rewardAvailableTimestamp
    );

    modifier factoryEnabled() {
        if (!isFactoryEnabled) revert FactoryDisabled();
        _;
    }
    modifier notZeroAddress(address value) {
        if (value == address(0)) revert AddressIsZero();
        _;
    }

    function initialize(
        address _bll,
        address _nftContract,
        uint32[] calldata _powershardNftTypes,
        uint8[] calldata _powerPoints,
        uint8[] calldata _productionPoints,
        address _treasuryAddress,
        uint32 _productionPointNftType
    ) public initializer notZeroAddress(_bll) notZeroAddress(_treasuryAddress) {
        bll = IGamificationBll(_bll);
        nftContract = INftSales(_nftContract);
        treasuryAddress = _treasuryAddress;
        minNftType = 200000; //factories: 200,000 => 299,999
        maxNftType = 399999; //blueprint factories: 300,000 => 399,999
        maxBonusPowerPoints = 5;
        boostPercentPerPowerPoint = 1000; //10.00%
        OwnableUpgradeable.__Ownable_init();
        setPowerShardNftTypes(
            _powershardNftTypes,
            _powerPoints,
            _productionPoints
        );
        productionPointNftType = _productionPointNftType;
    }

    function claim(uint32[] calldata tokenIds) external factoryEnabled {
        for (uint256 x; x < tokenIds.length; ++x) {
            if (_claim(tokenIds[x]) == 0) revert NoClaimAvailable(tokenIds[x]);
        }
    }

    //returns count of claimable NFTs (includes product and production points)
    function getClaimableAmounts(
        uint32[] calldata tokenIds
    ) public view returns (uint256[] memory) {
        uint256[] memory claimableNFTs = new uint256[](tokenIds.length);
        for (uint256 x; x < tokenIds.length; ++x) {
            FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenIds[x]];
            (
                uint256 productCount,
                uint256 productionPointCount
            ) = _getClaimableAmount(factoryInfo);
            claimableNFTs[x] = productCount + productionPointCount;
        }
        return claimableNFTs;
    }

    //returns rewardAvailableTimestamps[], mintCounts[], boosts[]
    function getFactoryInfos(
        uint32[] calldata tokenIds
    )
        external
        view
        returns (uint256[] memory, uint32[] memory, uint8[] memory)
    {
        uint256[] memory rewardAvailableTimestamps = new uint256[](
            tokenIds.length
        );
        uint32[] memory mintCounts = new uint32[](tokenIds.length);
        uint8[] memory boosts = new uint8[](tokenIds.length);
        for (uint256 x; x < tokenIds.length; ++x) {
            FactoryInfo memory factoryInfo = nftToFactoryInfo[tokenIds[x]];
            rewardAvailableTimestamps[x] = factoryInfo.rewardAvailableTimestamp;
            mintCounts[x] = factoryInfo.mintCount;
            boosts[x] = factoryInfo.bonusPowerPoints;
        }
        return (rewardAvailableTimestamps, mintCounts, boosts);
    }

    function getNftTypeForTokenID(
        uint32 tokenId
    ) external view returns (uint32) {
        return nftContract.getNftTypeForTokenID(tokenId);
    }

    function setBoostPercentPerPowerPoint(uint256 value) external onlyOwner {
        boostPercentPerPowerPoint = value;
    }

    function setClaimable(uint32 tokenId) external onlyOwner {
        nftToFactoryInfo[tokenId].rewardAvailableTimestamp = block.timestamp;
    }

    function setFactoryEnabled(bool enabled) external onlyOwner {
        isFactoryEnabled = enabled;
    }

    function setMaxBoosts(uint256 value) external onlyOwner {
        maxBonusPowerPoints = value;
    }

    function setMaxNftType(uint32 value) external onlyOwner {
        maxNftType = value;
    }

    function setMinNftType(uint32 value) external onlyOwner {
        minNftType = value;
    }

    function setPowerShardNftType(
        uint32 _powershardNftType,
        uint8 _powerPoints,
        uint8 _productionPoints
    ) public onlyOwner {
        powerShardNftTypeToPowerShard[_powershardNftType] = PowerShard({
            powerPoints: _powerPoints,
            bonusProductionPoints: _productionPoints
        });
    }

    function setPowerShardNftTypes(
        uint32[] calldata _powershardNftTypes,
        uint8[] calldata _powerPoints,
        uint8[] calldata _productionPoints
    ) public onlyOwner {
        for (uint256 x; x < _powershardNftTypes.length; ++x) {
            setPowerShardNftType(
                _powershardNftTypes[x],
                _powerPoints[x],
                _productionPoints[x]
            );
        }
    }

    function setProductionPointNftType(uint32 value) external onlyOwner {
        productionPointNftType = value;
    }

    function setTreasuryAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    function startOrBoostFactories(
        uint32[] calldata tokenIds,
        uint32[] calldata powershardIds
    ) external factoryEnabled {
        for (uint256 x; x < tokenIds.length; ++x) {
            startOrBoostFactory(tokenIds[x], powershardIds[x]);
        }
    }

    function getClaimableAmount(
        uint32 tokenId
    ) public view returns (uint32, uint32) {
        FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenId];
        return _getClaimableAmount(factoryInfo);
    }

    function getNftTypeToMint(uint32 tokenId) public view returns (uint32) {
        return uint32(bll.getTokenIdNumericInfo(tokenId, 2));
    }

    function getPowerShard(
        uint32 powershardId
    ) public view returns (PowerShard memory) {
        return
            powerShardNftTypeToPowerShard[
                nftContract.getNftTypeForTokenID(powershardId)
            ];
    }

    function secondsToGenerate(uint32 tokenId) public view returns (uint256) {
        (uint256 secsToGenerate, , ) = bll.getAllNftTypeNumericInfo(
            nftContract.getNftTypeForTokenID(tokenId)
        );
        return secsToGenerate;
    }

    // start or boost a factory
    // claims if a factory is ready
    function startOrBoostFactory(
        uint32 tokenId,
        uint32 powershardId
    ) public factoryEnabled {
        uint32 tokenNftType = nftContract.getNftTypeForTokenID(tokenId);
        if (tokenNftType < minNftType || tokenNftType > maxNftType)
            revert NftTypeOutOfRange(tokenNftType);
        PowerShard memory powerShard = getPowerShard(powershardId);
        uint8 powerPoints = powerShard.powerPoints;
        if (powerPoints == 0) {
            revert NotAPowerShard(powershardId);
        }

        uint256 secsToGenerate = secondsToGenerate(tokenId);

        if (secsToGenerate == 0) revert NotFactory();

        _claim(tokenId);

        nftContract.transferFrom(_msgSender(), treasuryAddress, powershardId);

        FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenId];
        if (factoryInfo.rewardAvailableTimestamp == 0) {
            //start factory
            factoryInfo.rewardAvailableTimestamp =
                block.timestamp +
                secsToGenerate;
            --powerPoints;
            emit StartFactory(
                _msgSender(),
                tokenId,
                powershardId,
                factoryInfo.rewardAvailableTimestamp
            );
        }
        if (powerShard.bonusProductionPoints > 0) {
            factoryInfo.bonusProductionPoints += powerShard
                .bonusProductionPoints;
        }

        if (powerPoints == 0) return; //if a common powershard

        //boost factory
        factoryInfo.bonusPowerPoints = uint8(
            factoryInfo.bonusPowerPoints + powerPoints > maxBonusPowerPoints
                ? maxBonusPowerPoints
                : factoryInfo.bonusPowerPoints + powerPoints
        );

        uint256 secondsToBoost = (secsToGenerate *
            boostPercentPerPowerPoint *
            powerPoints) / 1e4;
        factoryInfo.rewardAvailableTimestamp = factoryInfo
            .rewardAvailableTimestamp -
            block.timestamp <=
            secondsToBoost
            ? block.timestamp
            : factoryInfo.rewardAvailableTimestamp - secondsToBoost;
        emit BoostFactory(
            _msgSender(),
            tokenId,
            powershardId,
            factoryInfo.rewardAvailableTimestamp
        );
    }

    function _claim(uint32 tokenId) private returns (uint256) {
        FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenId];
        (
            uint32 claimableNftAmount,
            uint32 claimableProductionPointAmount
        ) = _getClaimableAmount(factoryInfo);
        if (claimableNftAmount == 0 && claimableProductionPointAmount == 0)
            return 0;

        factoryInfo.rewardAvailableTimestamp = 0;
        factoryInfo.bonusPowerPoints = 0;
        factoryInfo.bonusProductionPoints = 0;
        factoryInfo.mintCount += claimableNftAmount;
        factoryInfo.productionPointMintCount += claimableProductionPointAmount;

        uint32 nftTypeToMint = getNftTypeToMint(tokenId);
        address owner = nftContract.ownerOf(tokenId);
        nftContract.mint(owner, nftTypeToMint);
        for (uint256 x; x < claimableProductionPointAmount; ++x) {
            nftContract.mint(owner, productionPointNftType);
        }
        emit Claim(
            owner,
            claimableNftAmount,
            claimableProductionPointAmount,
            tokenId,
            nftTypeToMint
        );

        totalMintCount += claimableNftAmount;
        return claimableNftAmount;
    }

    function _getClaimableAmount(
        FactoryInfo storage factoryInfo
    )
        private
        view
        returns (
            uint32 claimableNftAmount,
            uint32 claimableProductionPointAmount
        )
    {
        //if production has finished, but not restarted, add both the nft and bonus production points
        if (
            factoryInfo.rewardAvailableTimestamp != 0 && //factory has been started
            factoryInfo.rewardAvailableTimestamp <= block.timestamp //factory has finished production
        ) {
            ++claimableNftAmount;
            claimableProductionPointAmount +=
                factoryInfo.bonusProductionPoints +
                1;
        }
    }
}