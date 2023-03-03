// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IStake.sol";
import "./interfaces/IBonus.sol";

// import "hardhat/console.sol";
// import "forge-std/console.sol";

contract OKXFootballCup is
    Initializable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155URIStorageUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    error OnlyMintToCaller();

    /**
     * @dev Emitted when the cancelEvent is triggered.
     */
    event Canceled(bool cancel);

    /**
     * @dev Emitted when claim is enabled.
     */
    event ClaimEnabled(bool enable);

    /**
     * @dev Emitted when withdraw is enabled.
     */
    event WithdrawEnabled(bool enable);

    event ETHStakeEnabled(bool enable);

    struct PauseTimeStruct {
        uint256 startTime;
        uint256 endTime;
    }

    string public constant name = "OKXFootballCup";
    string public constant symbol = "OKXFC";

    uint256 public mintStartTime;
    uint256 public mintEndTime;

    bool public claimEnabled;
    bool public withdrawEnabled;

    address public stakeContract;
    address public bonusContract;
    uint256 public stakePrice;

    uint256 public totalStaking;
    mapping(address => uint256) public stakeAmountMap; //Staker address to stake balance
    uint256 public totalMintForDrop;

    mapping(uint256 => PauseTimeStruct[]) public mintPauseTimeMap;
    mapping(uint256 => PauseTimeStruct) public claimPauseTimeMap;
    mapping(uint256 => bool) public _pauseClaimMap; //unable claim before game start

    uint256 private logIndex;
    mapping(uint256 => uint256) private _totalHolder;
    mapping(uint256 => mapping(address => uint256)) private _holderMap;
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _holderSets;

    uint256 private _totalHolderForAll;
    mapping(address => uint256) private _holderMapForAll;

    address private _appSignerAccount;
    address private _webSignerAccount;
    address private _serverAccount;
    address private _admin;

    mapping(bytes32 => bool) private _apiHashMap;

    bool private _eventCanceled;

    EnumerableSetUpgradeable.AddressSet private _blocklist;
    mapping(address => uint256) private _blockRateMap;

    /**** these now in Bonus ****/
    // uint256 public totalBonus;
    // uint256 public totalMintBonus;
    // uint256 public totalGroupBonus;
    // uint256 public claimedMintBonus;
    // mapping(address => uint256) private _groupBonusMap; //Bonus address to amount
    // mapping(uint256 => uint256) private _totalMintBonusMap; //tokenId to token bonus
    // mapping(address => uint256) private _eliminationBonusMap; //Bonus address to amount

    // ----- update v2 -----
    uint256 public ethStakePrice;
    uint256 public ethTotalStaking;
    mapping(address => uint256) public ethStakeAmountMap;
    bool public ethStakeEnabled;

    // ----- update v3 -----
    mapping(address => bool) public transferPausedMap;

    // -----

    // @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(address _stakeContract, address _bonusContract)
        public
        initializer
    {
        __ERC1155_init("");
        __Ownable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();

        stakeContract = _stakeContract;
        bonusContract = _bonusContract;
        stakePrice = IStake(stakeContract).stakePrice();
    }

    function initializeV2() public reinitializer(2) {
        ethStakePrice = IStake(stakeContract).ethStakePrice();
    }

    modifier stageOne() {
        require(
            mintStartTime > 0 && block.timestamp > mintStartTime,
            "FootballCup: mint not start"
        );
        require(block.timestamp < mintEndTime, "FootballCup: mint stage ended");
        _;
    }

    modifier stageTwo() {
        require(claimEnabled, "FootballCup: claim is not activated");
        _;
    }

    modifier stageThree() {
        require(withdrawEnabled, "FootballCup: withdraw is not activated");
        _;
    }

    modifier idRange(uint256 id) {
        require(id >= 1 && id <= 32, "FootballCup: token id out of range 1-32");
        _;
    }

    modifier idsRange(uint256[] memory ids) {
        uint256 length = ids.length;

        for (uint256 i = 0; i < length; ) {
            uint256 id = ids[i];
            if (id > 32 || id <= 0) {
                revert("FootballCup: token id out of range 1-32");
            }
            unchecked {
                ++i;
            }
        }
        _;
    }

    modifier onlyAdminOrOwner() {
        require(
            msg.sender == _admin || msg.sender == owner(),
            "FootballCup: only admin or owner"
        );
        _;
    }

    modifier onlyAdminOrServer() {
        require(
            msg.sender == _admin || msg.sender == _serverAccount,
            "FootballCup: only admin or server"
        );
        _;
    }

    // ---- methods ----

    function totalHolder(uint256 id) public view returns (uint256) {
        return _totalHolder[id];
    }

    function totalHolder() public view returns (uint256) {
        return _totalHolderForAll;
    }

    function totalSupply() public view returns (uint256) {
        uint256 _totalSupply;
        for (uint256 id = 1; id <= 32; ) {
            _totalSupply += totalSupply(id);
            unchecked {
                ++id;
            }
        }
        return _totalSupply;
    }

    /**
     * @dev balance of all team NFT
     */
    function balanceOfAll(address account) public view returns (uint256) {
        return _holderMapForAll[account];
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    function getBlockList() public view returns (address[] memory) {
        return _blocklist.values();
    }

    function mintedAmountOf(address account) public view returns (uint256) {
        return
            stakeAmountMap[account] /
            stakePrice +
            ethStakeAmountMap[account] /
            ethStakePrice;
    }

    function _checkIdMintPausedTime(uint256 id) internal view {
        PauseTimeStruct[] memory pauseTimeArray = mintPauseTimeMap[id];
        uint256 length = pauseTimeArray.length;

        for (uint256 i = 0; i < length; ) {
            require(
                block.timestamp < pauseTimeArray[i].startTime ||
                    block.timestamp > pauseTimeArray[i].endTime,
                "FootballCup: competition is on going"
            );

            unchecked {
                ++i;
            }
        }
    }

    function _checkIdsMintPausedTime(uint256[] memory ids) internal view {
        uint256 length = ids.length;

        for (uint256 i = 0; i < length; ) {
            _checkIdMintPausedTime(ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable stageOne idRange(id) {
        if (to != msg.sender) revert OnlyMintToCaller();
        _verify(amount, hash, v, r, s);
        _checkIdMintPausedTime(id);
        ethStakeEnabled ? _ethMintStake(amount) : _mintStake(amount);
        _mint(to, id, amount, "0x");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable stageOne idsRange(ids) {
        if (to != msg.sender) revert OnlyMintToCaller();
        uint256 totalMintAmount = _totalMintAmount(amounts);
        _verify(totalMintAmount, hash, v, r, s);
        _checkIdsMintPausedTime(ids);
        _mintStake(totalMintAmount);
        _mintBatch(to, ids, amounts, "0x");
    }

    function mintBatchWithETH(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable stageOne idsRange(ids) {
        uint256 totalMintAmount = _totalMintAmount(amounts);
        _verify(totalMintAmount, hash, v, r, s);
        _checkIdsMintPausedTime(ids);
        _ethMintStake(totalMintAmount);
        _mintBatch(msg.sender, ids, amounts, "0x");
    }

    function _verify(
        uint256 amount,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(
            _apiHashMap[hash] == false,
            "FootballCup: hash code have been used"
        );
        _apiHashMap[hash] = true;
        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        uint256 mintedAmount = mintedAmountOf(msg.sender);
        require(
            signer == _appSignerAccount || signer == _webSignerAccount,
            "FootballCup: invalid call signature"
        );
        require(
            mintedAmount + amount <= 3,
            "FootballCup: free mint reach the cap 3"
        );
        if (signer == _webSignerAccount) {
            require(
                mintedAmount + amount == 1,
                "FootballCup: free mint reach the web cap 1"
            );
        }
    }

    function _mintStake(uint256 totalMintAmount) internal {
        // mint amount (stake amount) already checked in _verify
        uint256 totalMintFee = 0;
        totalMintFee = totalMintAmount * stakePrice;

        IStake(stakeContract).deposit(msg.sender, totalMintFee);

        totalStaking += totalMintFee;

        stakeAmountMap[msg.sender] = stakeAmountMap[msg.sender] + totalMintFee;
    }

    function _ethMintStake(uint256 totalMintAmount) internal {
        // mint amount (stake amount) already checked in _verify
        uint256 totalMintFee = 0;
        totalMintFee = totalMintAmount * ethStakePrice;

        require(
            msg.value >= totalMintFee,
            "FootballCup: mint fee(ETH) not enough"
        );

        IStake(stakeContract).depositETH{value: totalMintFee}(msg.sender);

        ethTotalStaking += totalMintFee;

        ethStakeAmountMap[msg.sender] =
            ethStakeAmountMap[msg.sender] +
            totalMintFee;
    }

    function _totalMintAmount(uint256[] memory amounts)
        internal
        pure
        returns (uint256 totalMintAmount)
    {
        uint256 length = amounts.length;
        for (uint256 i = 0; i < length; ) {
            totalMintAmount += amounts[i];
            unchecked {
                ++i;
            }
        }
    }

    function claimBonus(uint256 id, uint256 amount) external stageTwo {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = id;
        amounts[0] = amount;

        claimBatchBonus(ids, amounts);
    }

    function _checkIdClaimPausedTime(uint256 id) internal view {
        require(
            block.timestamp < claimPauseTimeMap[id].startTime ||
                block.timestamp > claimPauseTimeMap[id].endTime,
            "FootballCup: competetion is on going"
        );
    }

    function claimBatchBonus(uint256[] memory ids, uint256[] memory amounts)
        public
        stageTwo
        idsRange(ids)
    {
        require(
            ids.length == amounts.length,
            "FootballCup: claim param length not match"
        );
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ) {
            uint256 id = ids[i];

            _checkIdClaimPausedTime(id);
            require(
                _pauseClaimMap[id] == false,
                "FootballCup: claim still paused"
            );
            unchecked {
                ++i;
            }
        }

        IBonus(bonusContract).claim(msg.sender, ids, amounts);
        _burnBatch(msg.sender, ids, amounts);
    }

    function withdraw(uint256 bonusAmount, bytes32[] memory proof)
        external
        stageThree
    {
        uint256 blockRate = _blockRateMap[msg.sender];
        //withdraw stake
        IStake(stakeContract).unstake(msg.sender, blockRate);

        if (transferPausedMap[msg.sender]) return; // allow unstake but no bonus

        //withdraw  bonus
        if (_eventCanceled == false && bonusAmount > 0) {
            IBonus(bonusContract).withdraw(msg.sender, bonusAmount, proof);
        }
    }

    // ---- only owner ----

    function setAppSignerAccount(address appSignerAccount) public onlyOwner {
        _appSignerAccount = appSignerAccount;
    }

    function setWebSignerAccount(address webSignerAccount) public onlyOwner {
        _webSignerAccount = webSignerAccount;
    }

    function setAdmin(address admin) public onlyOwner {
        _admin = admin;
    }

    function setBlockList(address _blockAddress, uint256 _blockRate)
        public
        onlyOwner
    {
        require(
            _blockRate <= 10_000,
            "FootballCup: withdrawRate can not greater than 10_000"
        );
        _blocklist.add(_blockAddress);
        _blockRateMap[_blockAddress] = _blockRate;
    }

    function setURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function setMintStartTime(uint256 _mintStartTime) public onlyOwner {
        mintStartTime = _mintStartTime;
    }

    function setMintEndTime(uint256 _mintEndTime) public onlyOwner {
        mintEndTime = _mintEndTime;
    }

    function cancelEvent(bool cancel) public onlyOwner {
        _eventCanceled = cancel;

        emit Canceled(cancel);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // ---- only admin or server ----
    function groupStageEnds(uint256[] memory winners, uint256[] memory losers)
        external
        onlyAdminOrServer
    {
        IBonus(bonusContract).groupStageEnds(winners, losers);
    }

    function elimination(uint256 winner, uint256 loser)
        external
        onlyAdminOrServer
    {
        IBonus(bonusContract).elimination(winner, loser);
    }

    // ---- only admin or owner ----

    function setMintBonus(uint256 id, uint256 bonus) external onlyAdminOrOwner {
        IBonus(bonusContract).setMintBonus(id, bonus);
    }

    function pauseTransfer(address[] calldata accounts, bool action)
        external
        onlyAdminOrOwner
    {
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; ) {
            transferPausedMap[accounts[i]] = action;
            unchecked {
                ++i;
            }
        }
    }

    function setPauseClaimTimes(uint256 id, PauseTimeStruct memory pauseTime)
        external
        onlyAdminOrOwner
    {
        uint256 startTime = pauseTime.startTime;
        uint256 endTime = pauseTime.endTime;
        require(startTime < endTime, "FootballCup: startTime > endTime");
        claimPauseTimeMap[id].startTime = pauseTime.startTime;
        claimPauseTimeMap[id].endTime = pauseTime.endTime;
    }

    function pauseClaim(uint256 id) external onlyAdminOrOwner {
        _pauseClaimMap[id] = true;
    }

    function unpauseClaim(uint256 id) external onlyAdminOrOwner {
        _pauseClaimMap[id] = false;
    }

    function setClaimEnable(bool active) public onlyAdminOrOwner {
        claimEnabled = active;
        emit ClaimEnabled(active);
    }

    function setWithdrawEnable(bool active) public onlyAdminOrOwner {
        withdrawEnabled = active;
        emit WithdrawEnabled(active);
    }

    function setEthStakeEnable(bool active) public onlyAdminOrOwner {
        ethStakeEnabled = active;
        emit ETHStakeEnabled(active);
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function snapshot(
        uint256 id,
        uint256 pageSize,
        uint256 pageIndex // 0,1,2...
    )
        public
        view
        returns (
            address[] memory accounts,
            uint256[] memory amounts,
            uint256 snapshotSize // snapshotSize
        )
    {
        EnumerableSetUpgradeable.AddressSet storage holderSet = _holderSets[id];
        uint256 length = holderSet.length();
        uint256 skip = pageSize * pageIndex;
        require(skip < length, "FootballCup: snapshot size out of bound");
        uint256 unread = length - skip;
        if (unread > pageSize) {
            unread = pageSize;
        }
        accounts = new address[](unread);
        amounts = new uint256[](unread);
        for (uint256 i = 0; i < unread; ++i) {
            accounts[i] = holderSet.at(i + skip);
            amounts[i] = _holderMap[id][holderSet.at(i + skip)];
        }
        snapshotSize = _holderSets[id].length();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(
            !transferPausedMap[from],
            "FootballCup: transfer from blocklist"
        );

        uint256 length = ids.length;

        for (uint256 i = 0; i < length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (from != address(0) && amount > 0) {
                _holderMapForAll[from] -= amount;
                _holderMap[id][from] -= amount;

                if (_holderMapForAll[from] == 0) {
                    _totalHolderForAll -= 1;
                }

                if (_holderMap[id][from] == 0) {
                    _totalHolder[id] -= 1;
                    _holderSets[id].remove(from);
                }
            }

            if (to != address(0) && amount > 0) {
                uint256 holderMapForAllBefore = _holderMapForAll[to];
                uint256 holderMapBefore = _holderMap[id][to];

                _holderMapForAll[to] += amount;
                _holderMap[id][to] += amount;

                if (holderMapForAllBefore == 0) {
                    _totalHolderForAll += 1;
                }

                if (holderMapBefore == 0) {
                    _totalHolder[id] += 1;
                    _holderSets[id].add(to);
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}