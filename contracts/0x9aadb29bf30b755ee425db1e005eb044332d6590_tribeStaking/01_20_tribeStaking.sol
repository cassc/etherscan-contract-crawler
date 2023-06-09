// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {ERC721HolderUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';
import {IERC721Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {OwnableUpgradeable, Initializable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {AddressUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

import {VRFV2WrapperConsumerBaseUpgradeable, LinkTokenInterface} from './VRFV2WrapperConsumerBaseUpgradeable.sol';

contract tribeStaking is
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    VRFV2WrapperConsumerBaseUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant TRIBE_TOTAL_SUPPLY = 9409;

    IERC721Upgradeable erc721; // instance of the Tribe contract

    struct Pool {
        uint256 lockDuration;
        uint256 raffleAt;
        uint256 totalLocked;
        EnumerableSetUpgradeable.UintSet nftIds;
        bool raffling;
        bool raffled;
        bool active;
    }

    // Info of each user.
    struct User {
        EnumerableSetUpgradeable.UintSet nftIds;
    }

    mapping(uint256 => Pool) private pools;
    mapping(uint256 => mapping(address => User)) private users;

    uint256 public currentPoolId;

    mapping(uint256 => uint256) public lockedAt;
    mapping(uint256 => address) public owners;

    // ChainLink VRF
    struct RequestStatus {
        uint256 pid;
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    /* requestId --> requestStatus */
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint256 => uint256[]) public s_request_ids;

    // past requests Id.
    uint256 public lastRequestId;
    address public linkAddress;
    address public wrapperAddress;

    event PoolUpdated(
        uint256 indexed id,
        uint256 lockDuration,
        uint256 raffleAt,
        bool active
    );
    event PoolStopped(uint256 indexed id);
    event JoinedMany(address indexed user, uint256 indexed pid, uint256[] ids);
    event JoinedOne(address indexed user, uint256 indexed pid, uint256 id);
    event LeftMany(address indexed user, uint256 indexed pid, uint256[] ids);
    event LeftOne(address indexed user, uint256 indexed pid, uint256 id);

    event RndRequestSent(uint256 requestId, uint32 numWords);
    event RndRequestFulfilled(
        uint256 requestId,
        uint256 pid,
        uint256[] randomWords,
        uint256 payment
    );

    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize(address _tribe) public initializer {
        erc721 = IERC721Upgradeable(_tribe);
        linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC721Holder_init();

        __VRFV2WrapperConsumerBase_init(linkAddress, wrapperAddress);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /* Returns the Tribe contract address currently being used */
    function tribeAddress() external view returns (address) {
        return address(erc721);
    }

    /* Allows the owner of the contract to set a new Tribe contract address */
    function setERC721(address newAddress) external onlyOwner {
        require(newAddress != address(0x0), 'zero address');
        erc721 = IERC721Upgradeable(newAddress);
    }

    /*Allows the owner of the contract to add pool */
    function addPool(
        uint256 lockDuration,
        uint256 raffleAt,
        bool active
    ) external onlyOwner {
        Pool storage pool = pools[++currentPoolId];
        pool.lockDuration = lockDuration;
        pool.raffleAt = raffleAt;
        pool.active = active;

        emit PoolUpdated(currentPoolId, lockDuration, raffleAt, active);
    }

    /* Allows the owner to stop pool */
    function stopPool(uint256 id) external onlyOwner onlyExistPool(id) {
        pools[id].active = false;

        emit PoolStopped(id);
    }

    function updatePool(
        uint256 id,
        uint256 lockDuration,
        uint256 raffleAt,
        bool active
    ) external onlyOwner onlyExistPool(id) {
        pools[id].lockDuration = lockDuration;
        pools[id].raffleAt = raffleAt;
        pools[id].active = active;
        emit PoolUpdated(id, lockDuration, raffleAt, active);
    }

    function requestRnds(
        uint256 pid,
        uint32 count,
        uint32 gasLimit
    ) external onlyOwner onlyExistPool(pid) {
        Pool storage pool = pools[pid];
        require(!pool.raffled, 'raffled!');
        require(pool.raffleAt < block.timestamp, 'wait!!');

        if (!pool.raffling) {
            pool.raffling = true;
            pool.active = false;
        }

        // Request Random number
        // max gas Limit: 2500000
        uint256 requestId = requestRandomness(gasLimit, 3, count);
        s_requests[requestId] = RequestStatus({
            pid: pid,
            paid: VRF_V2_WRAPPER.calculateRequestPrice(gasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        s_request_ids[pid].push(requestId);
        lastRequestId = requestId;

        emit RndRequestSent(requestId, count);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        RequestStatus storage status = s_requests[_requestId];
        require(status.paid > 0, 'request not found');

        status.fulfilled = true;
        status.randomWords = _randomWords;
        emit RndRequestFulfilled(
            _requestId,
            status.pid,
            _randomWords,
            status.paid
        );
    }

    function decideWinners(
        uint256 pid,
        uint256 count
    ) external view returns (uint256[] memory, address[] memory) {
        Pool storage pool = pools[pid];
        require(pool.totalLocked > count, 'too many winners');

        uint256[] memory snapshot = pool.nftIds.values();
        uint256[] memory winners = new uint256[](count);
        address[] memory accounts = new address[](count);

        uint256 winnerIndex;
        for (uint256 i; i < s_request_ids[pid].length; ) {
            RequestStatus memory status = s_requests[s_request_ids[pid][i]];
            if (!status.fulfilled) {
                unchecked {
                    ++i;
                }
                continue;
            }

            for (uint256 j; j < status.randomWords.length; ) {
                uint256[] memory rndIndexes = splitRandomNumber(
                    status.randomWords[j],
                    pool.totalLocked,
                    16
                );

                for (uint256 k; k < 16; ) {
                    uint256 remaining = pool.totalLocked - winnerIndex;
                    uint256 index = rndIndexes[k] % remaining;
                    winners[winnerIndex] = snapshot[index];
                    accounts[winnerIndex] = owners[snapshot[index]];
                    snapshot[index] = snapshot[remaining - 1];

                    if (winnerIndex == count - 1) {
                        return (winners, accounts);
                    }

                    unchecked {
                        winnerIndex++;
                        ++k;
                    }
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        revert('insufficient random numbers');
    }

    function splitRandomNumber(
        uint256 randomNumber,
        uint256 maxNumber,
        uint256 count
    ) public pure returns (uint256[] memory) {
        uint256[] memory results = new uint256[](count);
        uint256 rangeSize = 2 ** 128 / count;
        for (uint256 i = 0; i < count; i++) {
            uint256 value = (randomNumber >> ((i * 128) / count)) &
                (rangeSize - 1);
            results[i] = value % maxNumber;
        }
        return results;
    }

    function joinOne(uint256 pid, uint256 id) external onlyExistPool(pid) {
        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        require(pool.active, '!active');
        require(erc721.ownerOf(id) == msg.sender, '!owner');
        erc721.safeTransferFrom(msg.sender, address(this), id);

        user.nftIds.add(id);
        pool.nftIds.add(id);

        pool.totalLocked = pool.totalLocked + 1;

        lockedAt[id] = block.timestamp;
        owners[id] = msg.sender;

        emit JoinedOne(msg.sender, pid, id);
    }

    function joinMany(
        uint256 pid,
        uint256[] memory ids
    ) external onlyExistPool(pid) {
        uint256 len = ids.length;
        require(len > 0, '!length');

        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        require(pool.active, '!active');

        for (uint256 i; i < len; ) {
            uint256 id = ids[i];
            require(erc721.ownerOf(id) == msg.sender, '!owner');
            // Transfer Tribe to msg.sender from seller.
            erc721.safeTransferFrom(msg.sender, address(this), id);
            //
            user.nftIds.add(id);
            pool.nftIds.add(id);

            lockedAt[id] = block.timestamp;
            owners[id] = msg.sender;

            unchecked {
                ++i;
            }
        }

        pool.totalLocked = pool.totalLocked + len;

        emit JoinedMany(msg.sender, pid, ids);
    }

    function leaveOne(uint256 pid, uint256 id) external onlyExistPool(pid) {
        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        require(user.nftIds.contains(id), '!owner');
        require(lockedAt[id] + pool.lockDuration < block.timestamp, 'locked!');

        erc721.safeTransferFrom(address(this), msg.sender, id);

        user.nftIds.remove(id);
        pool.nftIds.remove(id);

        pool.totalLocked = pool.totalLocked - 1;

        lockedAt[id] = 0;
        owners[id] = address(0);

        emit LeftOne(msg.sender, pid, id);
    }

    function leaveMany(
        uint256 pid,
        uint256[] memory ids
    ) public onlyExistPool(pid) {
        uint256 len = ids.length;
        require(len > 0, '!length');

        Pool storage pool = pools[pid];
        User storage user = users[pid][msg.sender];

        uint256 lockDuration = pool.lockDuration;
        for (uint256 i; i < len; ) {
            uint256 id = ids[i];
            require(user.nftIds.contains(id), '!owner');
            require(lockedAt[id] + lockDuration < block.timestamp, 'locked!');

            erc721.safeTransferFrom(address(this), msg.sender, id);

            user.nftIds.remove(id);
            pool.nftIds.remove(id);

            lockedAt[id] = 0;
            owners[id] = address(0);

            unchecked {
                ++i;
            }
        }

        pool.totalLocked = pool.totalLocked - len;

        emit LeftMany(msg.sender, pid, ids);
    }

    function exit(uint256 pid) external onlyExistPool(pid) {
        uint256[] memory ids = userStakedNFTs(pid, msg.sender);

        leaveMany(pid, ids);
    }

    function userInfo(
        uint256 pid,
        address account
    ) public view returns (uint256, uint256[] memory) {
        uint256[] memory ids = userStakedNFTs(pid, account);
        return (ids.length, ids);
    }

    function poolInfo(
        uint256 pid
    )
        public
        view
        returns (uint256, uint256, uint256, bool, bool, uint256[] memory)
    {
        Pool storage pool = pools[pid];
        uint256[] memory ids = poolStakedNFTs(pid);

        return (
            pool.lockDuration,
            pool.raffleAt,
            pool.totalLocked,
            pool.raffled,
            pool.active,
            ids
        );
    }

    function userStakedNFTs(
        uint256 pid,
        address _account
    ) public view returns (uint256[] memory ids) {
        ids = users[pid][_account].nftIds.values();
    }

    function ownerOf(uint256 id) public view returns (address) {
        if (owners[id] != address(0)) return owners[id];
        return erc721.ownerOf(id);
    }

    function poolStakedNFTs(
        uint256 pid
    ) public view returns (uint256[] memory ids) {
        ids = pools[pid].nftIds.values();
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            'Unable to transfer'
        );
    }

    receive() external payable {}

    modifier onlyTokenOwner(uint256 tokenId) {
        require(erc721.ownerOf(tokenId) == msg.sender, 'only for token owner');
        _;
    }

    modifier onlyExistPool(uint256 poolId) {
        require(poolId <= currentPoolId, 'only exist pool');
        _;
    }
}