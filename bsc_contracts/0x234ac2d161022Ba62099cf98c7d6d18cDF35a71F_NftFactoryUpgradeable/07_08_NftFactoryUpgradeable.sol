// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IGamificationBll.sol";
import "../interfaces/INftSales.sol";
import "hardhat/console.sol";

contract NftFactoryUpgradeable is Initializable, OwnableUpgradeable {
    struct FactoryInfo {
        uint256 rewardAvailableTimestamp;
        uint32 mintCount;
    }

    IGamificationBll public bll;
    INftSales public nftContract;
    address public treasuryAddress;

    bool public isFactoryEnabled;

    uint256 public boostPercentPerShard; // 1025 = 10.25%
    uint256 public maxBoosts;
    uint256 public maxNftType;
    uint256 public minNftType;
    uint256 public totalMintCount;

    mapping(uint32 => uint8) public nftToBoosts;
    mapping(uint32 => FactoryInfo) public nftToFactoryInfo;
    mapping(uint32 => uint8) public powershardNftTypeToPoints;

    error AddressIsZero();
    error FactoryDisabled();
    error MaxBoosts();
    error NotAPowershard(uint32 tokenId);
    error NotReadyToClaim(uint32 tokenId);
    error NftTypeOutOfRange(uint256);
    error NotFactory();

    event BoostFactory(
        address indexed user,
        uint32 indexed tokenId,
        uint256 indexed powershardId,
        uint256 rewardAvailableTimestamp
    );
    event Claim(address indexed user, uint32 indexed tokenId);
    event PerformClaim(
        address indexed user,
        uint32 indexed tokenId,
        uint32 indexed nftTypeToMint
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
        uint8[] calldata _powershardNftTypePoints,
        address _treasuryAddress
    ) public initializer notZeroAddress(_bll) notZeroAddress(_treasuryAddress) {
        bll = IGamificationBll(_bll);
        nftContract = INftSales(_nftContract);
        treasuryAddress = _treasuryAddress;
        minNftType = 200000; //factories: 200,000 => 299,999
        maxNftType = 399999; //blueprint factories: 300,000 => 399,999
        maxBoosts = 5;
        OwnableUpgradeable.__Ownable_init();
        setPowershardNftTypes(_powershardNftTypes, _powershardNftTypePoints);
    }

    function claim(uint32[] calldata tokenIds) external factoryEnabled {
        _claim(tokenIds);
    }

    function setBoostPercentPerShard(uint256 value) external onlyOwner {
        boostPercentPerShard = value;
    }

    function setFactoryEnabled(bool enabled) external onlyOwner {
        isFactoryEnabled = enabled;
    }

    function setMaxBoosts(uint256 value) external onlyOwner {
        maxBoosts = value;
    }

    function setMaxNftType(uint32 value) external onlyOwner {
        maxNftType = value;
    }

    function setMinNftType(uint32 value) external onlyOwner {
        minNftType = value;
    }

    function setPowershardNftType(
        uint32 _powershardNftType,
        uint8 _powershardNftTypePoints
    ) public onlyOwner {
        powershardNftTypeToPoints[
            _powershardNftType
        ] = _powershardNftTypePoints;
    }

    function setPowershardNftTypes(
        uint32[] calldata _powershardNftTypes,
        uint8[] calldata _powershardNftTypePoints
    ) public onlyOwner {
        for (uint256 x; x < _powershardNftTypes.length; x++) {
            setPowershardNftType(
                _powershardNftTypes[x],
                _powershardNftTypePoints[x]
            );
        }
    }

    function setTreasuryAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    function getNftTypeForTokenID(uint32 tokenId) external view returns(uint32){
        return nftContract.getNftTypeForTokenID(tokenId);
    }

    function powershardPoint(uint32 powershardId) external view returns(uint8) {
        return powershardNftTypeToPoints[
            nftContract.getNftTypeForTokenID(powershardId)
        ];
    }

    function secondsToGenerate(uint32 tokenId) external view returns(uint256) {
        (uint256 secondsToGenerate, , ) = bll.getAllNftTypeNumericInfo(
            nftContract.getNftTypeForTokenID(tokenId)
        );
        return secondsToGenerate;
    }

    // start or boost a factory
    // claims if a factory is ready
    function startOrBoostFactory(
        uint32 tokenId,
        uint32 powershardId
    ) external factoryEnabled {
        uint32 tokenNftType = nftContract.getNftTypeForTokenID(tokenId);
        if (tokenNftType < minNftType || tokenNftType > maxNftType)
            revert NftTypeOutOfRange(tokenNftType);
        uint8 powershardPoints = powershardNftTypeToPoints[
            nftContract.getNftTypeForTokenID(powershardId)
        ];
        if (powershardPoints == 0) {
            revert NotAPowershard(powershardId);
        }

        (uint256 secondsToGenerate, , ) = bll.getAllNftTypeNumericInfo(
            tokenNftType
        );
        if (secondsToGenerate == 0) revert NotFactory();
return;
        FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenId];
        if (
            factoryInfo.rewardAvailableTimestamp != 0 &&
            factoryInfo.rewardAvailableTimestamp <= block.timestamp
        ) {
            _performClaim(tokenId, factoryInfo);
        }

        nftContract.transferFrom(_msgSender(), treasuryAddress, powershardId);

        if (factoryInfo.rewardAvailableTimestamp == 0) {
            //start factory
            factoryInfo.rewardAvailableTimestamp =
                block.timestamp +
                secondsToGenerate;
            --powershardPoints;
            emit StartFactory(
                _msgSender(),
                tokenId,
                powershardId,
                factoryInfo.rewardAvailableTimestamp
            );
        }
        if (powershardPoints == 0) return;

        //boost factory
        if (nftToBoosts[tokenId] >= maxBoosts) revert MaxBoosts();
        nftToBoosts[tokenId] = uint8(nftToBoosts[tokenId] + powershardPoints > maxBoosts
            ? maxBoosts
            : nftToBoosts[tokenId] + powershardPoints);
        uint256 secondsToBoost = (secondsToGenerate *
            boostPercentPerShard *
            powershardPoints) / 1e4;
        factoryInfo.rewardAvailableTimestamp = factoryInfo
            .rewardAvailableTimestamp -
            block.timestamp <=
            secondsToBoost
            ? block.timestamp
            : factoryInfo.rewardAvailableTimestamp -= secondsToBoost;
        emit BoostFactory(
            _msgSender(),
            tokenId,
            powershardId,
            factoryInfo.rewardAvailableTimestamp
        );
    }

    function getNftTypeToMint(uint32 tokenId) public view returns (uint32) {
        return uint32(bll.getTokenIdNumericInfo(tokenId, 2));
    }

    function _claim(uint32[] calldata tokenIds) private {
        uint256 mintCount;
        for (uint32 x; x < tokenIds.length; ++x) {
            FactoryInfo storage factoryInfo = nftToFactoryInfo[tokenIds[x]];
            if (factoryInfo.rewardAvailableTimestamp > block.timestamp)
                revert NotReadyToClaim(tokenIds[x]);
            _performClaim(tokenIds[x], factoryInfo);
            ++mintCount;
        }
        totalMintCount += mintCount;
    }

    //calling function must have safeguards
    function _performClaim(
        uint32 tokenId,
        FactoryInfo storage factoryInfo
    ) private {
        factoryInfo.rewardAvailableTimestamp = 0;
        nftToBoosts[tokenId] = 0;
        uint32 nftTypeToMint = getNftTypeToMint(tokenId);
        nftContract.mint(nftContract.ownerOf(tokenId), nftTypeToMint);
        ++factoryInfo.mintCount;
        emit PerformClaim(_msgSender(), tokenId, nftTypeToMint);
    }
}