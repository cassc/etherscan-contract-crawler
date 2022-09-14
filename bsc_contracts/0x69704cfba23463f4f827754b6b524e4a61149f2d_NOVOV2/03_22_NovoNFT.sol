// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./INOVO.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Novo NFT
/// @author LiuWanJun
/// @dev Novo NFT logic is implemented and this is the upgradeable
contract NovoNFT is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using Strings for bytes;
    using Strings for string;
    using Strings for uint256;

    struct Stake {
        string stakerName;
        uint256 principalBalance;
        uint256 bagSizeReward;
        uint256 stakingTimeReward;
        uint80 stakingTimestamp;
        address addtionalWallet;
        uint256 proxyStatus;
    }

    string baseURI;
    string public baseExtension;
    uint256 public cost;
    uint256 public maxMintAmount;
    uint256 public claimLimitTime;
    uint256 private constant DESTROYED = ~uint256(0);

    mapping(uint256 => Stake) private mapStakers;
    mapping(uint256 => uint256) private mapLockStatus;
    uint256[] stakingNFTs;
    uint80[] public lockDays;
    uint8[] public feesByLockDays;

    INOVO public novo;

    uint32 public maxLockDays;
    uint256 public minStakingAmount;

    // number of tokens have been minted so far
    uint256 public minted;
    uint256 private totalBagSize;
    uint256 private totalDiffTimestamp;
    uint80 public baseTimestamp;

    function initialize(address _novo) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721_init("Novo Certificate of Stake", "NCOS");

        novo = INOVO(_novo);

        baseExtension = ".json";
        cost = 0 ether;
        maxMintAmount = 1;
        claimLimitTime = 3600;
        lockDays = [1 days, 2 days, 3 days];
        feesByLockDays = [25, 30, 35];
        maxLockDays = 7 days;
        minStakingAmount = 10000 gwei;
        totalBagSize = 0;
        baseTimestamp = uint80(block.timestamp);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(
        uint256 _mintAmount,
        uint256 _stakingAmount,
        string memory _stakerName,
        address _addtionalWallet,
        uint256 _proxyStatus
    ) public payable whenNotPaused {
        require(balanceOf(msg.sender) == 0, "Can not multi staking");
        require(_mintAmount > 0, "Mint amount should be large than 0");
        require(
            _mintAmount <= maxMintAmount,
            "Mint amount should be less than Max mint amount"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Payable cost error");
        }

        uint256 tokenId = minted;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            tokenId++;
            staking(
                tokenId,
                _stakingAmount,
                _stakerName,
                _addtionalWallet,
                _proxyStatus
            );
            _safeMint(msg.sender, tokenId);
        }

        minted = tokenId;
    }

    function mintForStakingV1ByOwner(
        address _stakingV1,
        address _stakerAddress,
        uint256 _stakingAmount,
        uint256 _rewardAmount
    ) public payable whenNotPaused onlyOwner {
        require(balanceOf(_stakerAddress) == 0, "Can not multi staking");

        // send NOVO to address
        novo.transferFrom(
            _stakingV1,
            _stakerAddress,
            _stakingAmount + _rewardAmount
        );

        uint256 tokenId = minted;

        tokenId++;
        Stake memory newStake = Stake(
            "",
            _stakingAmount,
            _rewardAmount,
            0,
            uint80(block.timestamp),
            0x0000000000000000000000000000000000000000,
            0
        );

        mapStakers[tokenId] = newStake;
        mapLockStatus[tokenId] = stakingNFTs.length;
        stakingNFTs.push(tokenId);
        totalBagSize += _stakingAmount + _rewardAmount;
        totalDiffTimestamp += (uint80(block.timestamp) - baseTimestamp);

        _safeMint(_stakerAddress, tokenId);

        minted = tokenId;
    }

    function staking(
        uint256 _tokenId,
        uint256 _amount,
        string memory _stakerName,
        address _additionalWallet,
        uint256 _proxyStatus
    ) internal whenNotPaused {
        require(
            _amount <=
                (novo.balanceOf(msg.sender) -
                    getLockedAmountByAddress(msg.sender)),
            "Not enough Novo balance"
        );
        require(
            _amount >= minStakingAmount,
            "Staking amount should be large than min amount"
        );

        Stake memory newStake = Stake(
            _stakerName,
            _amount,
            0,
            0,
            uint80(block.timestamp),
            _additionalWallet,
            _proxyStatus
        );

        mapStakers[_tokenId] = newStake;
        mapLockStatus[_tokenId] = stakingNFTs.length;
        stakingNFTs.push(_tokenId);
        totalBagSize += _amount;
        totalDiffTimestamp += (uint80(block.timestamp) - baseTimestamp);
    }

    function unstaking(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Invalid Token Owner");
        require(mapStakers[_tokenId].principalBalance > 0, "No staked address");

        uint80 diffTime = uint80(block.timestamp) -
            mapStakers[_tokenId].stakingTimestamp;
        require(
            diffTime >= maxLockDays - lockDays[lockDays.length - 1],
            "Can not unlock before locking days"
        );

        uint256 lockedAmount = getLockedAmountByTokenId(_tokenId);
        totalBagSize -= lockedAmount;
        totalDiffTimestamp -= (mapStakers[_tokenId].stakingTimestamp -
            baseTimestamp);
        mapStakers[_tokenId].principalBalance = 0;
        mapStakers[_tokenId].bagSizeReward = 0;
        mapStakers[_tokenId].stakingTimeReward = 0;

        delete mapStakers[_tokenId];

        if (mapLockStatus[_tokenId] != DESTROYED) {
            uint256 lastTokenId = stakingNFTs[stakingNFTs.length - 1];
            stakingNFTs[mapLockStatus[_tokenId]] = lastTokenId;
            stakingNFTs.pop();

            mapLockStatus[lastTokenId] = mapLockStatus[_tokenId];
            mapLockStatus[_tokenId] = DESTROYED;

            _burn(_tokenId);
        }

        if (diffTime < maxLockDays) {
            uint256 feeAmount = 0;
            for (uint256 i = 0; i < lockDays.length; i++) {
                if ((maxLockDays - diffTime) < lockDays[i]) {
                    feeAmount = (lockedAmount * feesByLockDays[i]) / 1000;
                    if (feeAmount > 0) {
                        novo.transferClaimFee(msg.sender, address(this), feeAmount);
                    }

                    break;
                }
            }
        }
    }

    function getReward(address _address) public returns (uint256) {
        // add the require to check the NOVO address
        require(
            msg.sender == address(novo),
            "This function should be called by NOVO"
        );

        uint256[] memory tokenIds = walletOfOwner(_address);
        uint256 _bagSizeReward = 0;
        uint256 _stakingTimeReward = 0;
        uint256 totalStakingTime = 0;
        uint256 totalRewardOfAddress = 0;
        totalStakingTime =
            uint80(block.timestamp - baseTimestamp) *
            stakingNFTs.length -
            totalDiffTimestamp;

        uint256 _curRemainReward = novo.balanceOf(address(this)) / 2;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _bagSizeReward =
                (_curRemainReward * getLockedAmountByTokenId(tokenIds[i])) /
                totalBagSize;
            _stakingTimeReward =
                (_curRemainReward *
                    (uint80(block.timestamp) -
                        mapStakers[tokenIds[i]].stakingTimestamp)) /
                totalStakingTime;

            mapStakers[tokenIds[i]].bagSizeReward += _bagSizeReward;
            mapStakers[tokenIds[i]].stakingTimeReward += _stakingTimeReward;
            totalRewardOfAddress += _bagSizeReward + _stakingTimeReward;
        }

        totalBagSize += totalRewardOfAddress;
        return totalRewardOfAddress;
    }

    function getAllStakers() public view returns (address[] memory) {
        address[] memory addresses = new address[](stakingNFTs.length);
        for (uint256 i = 0; i < stakingNFTs.length; i++) {
            addresses[i] = ownerOf(stakingNFTs[i]);
        }

        return addresses;
    }

    function getStakingStatusByAddress(address _address)
        public
        view
        returns (
            Stake memory stakeInfo,
            string memory tokenUri,
            uint256 novoScore,
            address stakerAddress
        )
    {
        uint256[] memory tokenIds = walletOfOwner(_address);
        stakeInfo = mapStakers[tokenIds[0]];
        tokenUri = tokenURI(tokenIds[0]);
        novoScore = getNovoScore(_address);
        stakerAddress = _address;
    }

    function getTimeKeeper()
        public
        view
        returns (
            Stake memory stakeInfo,
            address stakerAddress,
            uint80 currentTimestamp,
            uint256 novoScore
        )
    {
        uint80 shortestTimestamp = ~uint80(0);
        uint80 stakingTimestamp = 0;
        uint256 tokenId = 0;
        uint256 timeKeeper = 0;
        for (uint256 i = 0; i < stakingNFTs.length; i++) {
            tokenId = stakingNFTs[i];
            stakingTimestamp = mapStakers[tokenId].stakingTimestamp;
            if (stakingTimestamp < shortestTimestamp) {
                shortestTimestamp = stakingTimestamp;
                timeKeeper = tokenId;
            }
        }

        stakeInfo = mapStakers[timeKeeper];
        stakerAddress = ownerOf(timeKeeper);
        currentTimestamp = uint80(block.timestamp);
        novoScore = getNovoScore(stakerAddress);
    }

    function getBagWeight(address _address) internal view returns (uint256) {
        if (balanceOf(_address) == 0 || getLockedAmountByAddress(_address) == 0)
            return 0;
        return (getLockedAmountByAddress(_address) * (10**18)) / totalBagSize;
    }

    function getTimeWeight(address _address) internal view returns (uint256) {
        if (balanceOf(_address) == 0 || getLockedAmountByAddress(_address) == 0)
            return 0;
        uint256 totalStakingTime = uint80(block.timestamp - baseTimestamp) *
            stakingNFTs.length -
            totalDiffTimestamp;
        uint256[] memory tokenIds = walletOfOwner(_address);
        uint256 tokenId = tokenIds[0];
        uint256 stakingTime = (uint80(block.timestamp) - mapStakers[tokenId].stakingTimestamp);
        return stakingTime * (10**18) / totalStakingTime;
    }

    function getNovoScore(address _address) public view returns (uint256) {
        if (balanceOf(_address) == 0 || getLockedAmountByAddress(_address) == 0)
            return 0;
        return (getBagWeight(_address) + getTimeWeight(_address)) * 100;
    }

    function getLockedAmountByAddress(address _address)
        public
        view
        returns (uint256)
    {
        uint256 totalLockedAmount = 0;
        uint256[] memory tokenIds = walletOfOwner(_address);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalLockedAmount += getLockedAmountByTokenId(tokenIds[i]);
        }

        return totalLockedAmount;
    }

    function getLockedAmountByTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return
            mapStakers[_tokenId].principalBalance +
            mapStakers[_tokenId].bagSizeReward +
            mapStakers[_tokenId].stakingTimeReward;
    }

    function getEarnRewardsByAddress(address _address)
        public
        view
        returns (uint256)
    {
        uint256 totalEarnRewards = 0;
        uint256[] memory tokenIds = walletOfOwner(_address);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalEarnRewards += getEarnRewardsByTokenId(tokenIds[i]);
        }

        return totalEarnRewards;
    }

    function getEarnRewardsByTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return
            mapStakers[_tokenId].bagSizeReward +
            mapStakers[_tokenId].stakingTimeReward;
    }

    function getTotalStakers() public view returns (uint256) {
        return stakingNFTs.length;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        uint80 stakingTime = uint80(block.timestamp) -
            mapStakers[tokenId].stakingTimestamp;
        string memory stakingTimeArt = "";
        if (stakingTime >= 7 days) {
            stakingTimeArt = "VeryLong/";
        } else if (stakingTime >= 3 days) {
            stakingTimeArt = "Long/";
        } else if (stakingTime >= 1 days) {
            stakingTimeArt = "Short/";
        } else {
            stakingTimeArt = "VeryShort/";
        }

        uint256 stakingAmount = getLockedAmountByTokenId(tokenId);
        string memory stakingAmountArt = "";
        if (stakingAmount >= 5000000 gwei) {
            stakingAmountArt = "28_stars";
        } else if (stakingAmount >= 2500000 gwei) {
            stakingAmountArt = "24_stars";
        } else if (stakingAmount >= 1000000 gwei) {
            stakingAmountArt = "20_stars";
        } else if (stakingAmount >= 500000 gwei) {
            stakingAmountArt = "16_stars";
        } else if (stakingAmount >= 250000 gwei) {
            stakingAmountArt = "12_stars";
        } else if (stakingAmount >= 50000 gwei) {
            stakingAmountArt = "8_stars";
        } else {
            stakingAmountArt = "4_stars";
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        stakingTimeArt,
                        stakingAmountArt,
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) public onlyOwner {
        minStakingAmount = _minStakingAmount;
    }

    function setClaimLimitTime(uint256 _time) public onlyOwner {
        claimLimitTime = _time;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setLockDays(uint32 _lockDays) public onlyOwner {
        maxLockDays = _lockDays;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /**
     * @dev enables owner to pause / unpause minting
     * @param _bPaused the flag to pause / unpause
     */
    function setPaused(bool _bPaused) external onlyOwner {
        if (_bPaused) _pause();
        else _unpause();
    }
}