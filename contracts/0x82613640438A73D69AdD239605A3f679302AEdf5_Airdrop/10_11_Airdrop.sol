// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../Validatable.sol";

contract Airdrop is Validatable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    /**
     *  @notice _idCounter uint256 (counter). This is the counter for store
     *          current airdrop ID value in storage.
     */
    CountersUpgradeable.Counter private _idCounter;

    struct AirdropInfo {
        address collection;
        uint256 id;
        uint256 maximum;
        uint256 claimedQty;
        uint256 startTime;
        uint256 endTime;
        bool status;
    }

    /**
     *  @notice mapping user address => id => amount is claimable of user
     */
    mapping(address => mapping(uint256 => uint256)) public claimable;

    /**
     *  @notice mapping user address => id => amount of each user claim
     */
    mapping(address => mapping(uint256 => uint256)) public claimAmountOf;

    /**
     *  @notice mapping id => info airdrop
     */
    mapping(uint256 => AirdropInfo) public airdrops;

    event CreateAirdrop(uint256 indexed id, AirdropInfo airdropInfo);
    event UpdateAirdrop(uint256 indexed id, uint256 startTime, uint256 endTime);
    event Claimed(uint256 indexed id, address indexed user, uint256 indexed amount);
    event SetWhitelist(uint256 indexed id, address[] users, uint256[] amounts);
    event CancelledAirdrop(uint256 indexed id);

    /**
     * @notice Init contract
     * @dev    Replace for contructor
     * @param _admin Address of admin contract
     */
    function initialize(IAdmin _admin) public initializer {
        __Validatable_init(_admin);
        __ReentrancyGuard_init();
    }

    /**
     * Throw an exception if airdrop id is not valid
     */
    modifier validAirdropId(uint256 id) {
        require(id > 0 && id <= _idCounter.current(), "Invalid id");
        _;
    }

    /**
     * @notice create airdrop
     * @dev    Only admin can call this function
     * @param collection Address of collection contract
     * @param maximum Max nft can claim
     * @param startTime Time to start
     * @param endTime Time to end
     * @param receivers List of receivers
     * @param amounts List of amount
     *
     * emit {CreateAirdrop} events
     */
    function createAirdrop(
        address collection,
        uint256 maximum,
        uint256 startTime,
        uint256 endTime,
        address[] memory receivers,
        uint256[] memory amounts
    ) external onlyAdmin validGenesis(collection) notZero(maximum) {
        require(startTime > 0 && startTime < endTime, "Invalid time");

        _idCounter.increment();
        airdrops[_idCounter.current()] = AirdropInfo({
            id: _idCounter.current(),
            collection: collection,
            maximum: maximum,
            claimedQty: 0,
            startTime: startTime,
            endTime: endTime,
            status: true
        });

        _setWhitelist(_idCounter.current(), receivers, amounts);

        emit CreateAirdrop(_idCounter.current(), airdrops[_idCounter.current()]);
    }

    /**
     * @notice Update airdrop
     * @dev    Only admin can call this function
     * @param id id of airdrop
     * @param maximum Max nft can claim
     * @param startTime Time to start
     * @param endTime Time to end
     *
     * emit {UpdateAirdrop} events
     */
    function updateAirdrop(
        uint256 id,
        uint256 maximum,
        uint256 startTime,
        uint256 endTime
    ) external onlyAdmin validAirdropId(id) notZero(maximum) {
        require(startTime > 0 && startTime < endTime, "Invalid time");

        AirdropInfo storage airdropInfo = airdrops[id];
        require(airdropInfo.status, "Airdrop was cancel");

        airdropInfo.maximum = maximum;
        airdropInfo.startTime = startTime;
        airdropInfo.endTime = endTime;

        emit UpdateAirdrop(id, startTime, endTime);
    }

    /**
     * @notice Set whitelist that will be able to buy NFT
     * @dev    Only admin can call this function
     * @param id id of airdrop
     * @param receivers List of receivers
     * @param amounts List of amount
     *
     * emit {SetWhitelist} events
     */
    function setWhitelist(uint256 id, address[] memory receivers, uint256[] memory amounts) external onlyAdmin {
        _setWhitelist(id, receivers, amounts);

        emit SetWhitelist(id, receivers, amounts);
    }

    /**
     * @notice Used to airdrop
     * @dev    User in whitelist can call
     * @param id id of airdrop
     *
     * emit {Claimed} events
     */
    function claim(uint256 id, uint256 times) external nonReentrant validAirdropId(id) notZero(times) {
        require(claimable[_msgSender()][id] >= times, "Insufficient claim amount");
        AirdropInfo storage airdropInfo = airdrops[id];
        require(airdropInfo.status, "Airdrop was cancel");
        require(
            airdropInfo.startTime <= block.timestamp && block.timestamp <= airdropInfo.endTime,
            "Can not airdrop at this time"
        );

        airdropInfo.claimedQty += times;
        require(airdropInfo.claimedQty <= airdropInfo.maximum, "Exceed the allowed qty");

        claimAmountOf[_msgSender()][id] += times;
        claimable[_msgSender()][id] -= times;
        // Mint Airdrop NFTs
        //slither-disable-next-line unused-return
        IGenesis(airdropInfo.collection).mintBatch(_msgSender(), times);

        // Emit events
        emit Claimed(id, _msgSender(), times);
    }

    /**
     * @notice Admin cancel airdrop
     * @dev    Only admin can call this function
     * @param id id of airdrop
     *
     * emit {CancelledAirdrop} events
     */
    function cancelAirdrop(uint256 id) external onlyAdmin validAirdropId(id) {
        require(airdrops[id].status, "Airdrop was cancel");
        airdrops[id].status = false;

        // Emit events
        emit CancelledAirdrop(id);
    }

    /**
     * @notice setWhitelist
     */
    function _setWhitelist(
        uint256 id,
        address[] memory receivers,
        uint256[] memory amounts
    ) private validAirdropId(id) {
        require(airdrops[id].status, "Airdrop was cancel");
        require(receivers.length > 0 && receivers.length == amounts.length, "Invalid length");
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i] != address(0), "Invalid address");
            claimable[receivers[i]][id] = amounts[i];
        }
    }

    /**
     *
     *  @notice Get airdrop counter
     *
     *  @dev    All caller can call this function.
     */
    function getAirdropCounter() external view returns (uint256) {
        return _idCounter.current();
    }
}