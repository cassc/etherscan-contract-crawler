// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface IERC20BurnableUpgradeable is IERC20Upgradeable {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * @title NFTLRaffle
 */
contract NFTLRaffle is Initializable, OwnableUpgradeable, PausableUpgradeable, ERC721HolderUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct WinnerInfo {
        uint256 ticketId;
        address winner;
        uint256 prizeTokenId;
    }

    struct TicketRange {
        uint256 startTicketId;
        uint256 endTicketId;
    }

    /// @dev Chainlink VRF params
    address private vrfCoordinator; // etherscan: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 private constant s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint16 private constant s_requestConfirmations = 3;
    uint32 private constant s_callbackGasLimit = 2500000;
    uint64 public s_subscriptionId;

    /// @dev Prize NFT (NiftyDegen) address
    IERC721Upgradeable public prizeNFT;

    /// @dev PrizeNFT TokenIds
    uint256[] public prizeNFTokenIds;

    /// @dev NFTL address
    IERC20BurnableUpgradeable public nftl;

    /// @dev Timestamp the raffle start
    uint256 public raffleStartAt; // deprecated

    // @dev VRF request Id => Prize NFT TokenId Index
    mapping(uint256 => uint256) public prizeNFTTokenIndex; // deprecated

    /// @dev Total winner count to select
    uint256 public totalWinnerTicketCount;

    /// @dev Current selected winner count
    uint256 public currentWinnerTicketCount;

    /// @dev Winner list
    WinnerInfo[] public winners;

    /// @dev Total ticket count
    uint256 public totalTicketCount;

    /// @dev NFTL amount required for 1 ticket
    uint256 public constant NFTL_AMOUNT_FOR_TICKET = 1000 * 10 ** 18;

    /// @dev User list
    EnumerableSetUpgradeable.AddressSet internal _userList;

    /// @dev TokenId list
    EnumerableSetUpgradeable.UintSet internal _ticketIdList; // deprecated

    /// @dev User -> NFTL amount deposited
    mapping(address => uint256) public userDeposits;

    /// @dev User -> Ticket Id list
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _ticketIdsByUser; // deprecated

    /// @dev Ticket Id -> User
    mapping(uint256 => address) public userByTicketId; // deprecated

    /// @dev Ticket list
    uint256[] public ticketIdList; // deprecated

    /// @dev User -> Ticket count
    mapping(address => uint256) public ticketCountByUser; // deprecated

    /// @dev Swith to on/off the deposit
    bool public isUserDepositAllowed;

    /// @dev Ticket assign status
    bool public isTicketAssignedToUsers;

    /// @dev User -> Ticket range
    mapping(address => TicketRange) public ticketRangeByUser;

    /// @dev Winner Ticket Id -> Bool
    mapping(uint256 => bool) public isWinnerTicketId;

    /// @dev Random word list
    uint256[] public randomWordList;

    event TicketDistributed(address indexed to, uint256 ticketCount);
    event UserDeposited(address indexed user, uint256 nftlAmount);
    event RandomWordsRequested(uint256 requestId, uint256 randomCountToRequest);
    event RandomWordsReceived(uint256 requestId, uint256[] randomWords);
    event WinnerSelected(address indexed by, address indexed winner, uint256 ticketId, uint256 prizeTokenId);

    modifier onlyDepositAllowed() {
        require(isUserDepositAllowed, "Only deposit allowed");
        _;
    }

    modifier onlyDepositDisallowed() {
        require(!isUserDepositAllowed, "Only deposit disallowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nftl,
        uint256 _pendingPeriod,
        uint256 _totalWinnerTicketCount,
        address _prizeNFT,
        address _vrfCoordinator
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721Holder_init();

        require(_nftl != address(0), "Zero address");
        require(_pendingPeriod > 86400, "1 day +");
        require(_totalWinnerTicketCount > 0, "Zero winner ticket count");
        require(_prizeNFT != address(0), "Zero address");
        require(_vrfCoordinator != address(0), "Zero address");

        nftl = IERC20BurnableUpgradeable(_nftl);
        raffleStartAt = block.timestamp + _pendingPeriod; // deprecated
        totalWinnerTicketCount = _totalWinnerTicketCount;
        prizeNFT = IERC721Upgradeable(_prizeNFT);
        vrfCoordinator = _vrfCoordinator;

        _createNewSubscription();
    }

    function depositPrizeNFT(uint256[] memory _prizeNFTTokenIds) external onlyOwner {
        uint256 totalPrizeCount = _prizeNFTTokenIds.length;
        require((totalPrizeCount + prizeNFTokenIds.length) == totalWinnerTicketCount, "Mismatched prize count");

        for (uint256 i = 0; i < totalPrizeCount; ) {
            uint256 prizeNFTTokenId = _prizeNFTTokenIds[i];
            prizeNFT.safeTransferFrom(msg.sender, address(this), prizeNFTTokenId, bytes(""));

            prizeNFTokenIds.push(prizeNFTTokenId);

            unchecked {
                ++i;
            }
        }
    }

    // Create a new subscription when the contract is initially deployed.
    function _createNewSubscription() private {
        s_subscriptionId = VRFCoordinatorV2Interface(vrfCoordinator).createSubscription();
        VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(s_subscriptionId, address(this));
    }

    function cancelSubscription() external onlyOwner {
        VRFCoordinatorV2Interface(vrfCoordinator).cancelSubscription(s_subscriptionId, owner());
        s_subscriptionId = 0;
    }

    function updateTotalWinnerTicketCount(uint256 _totalWinnerTicketCount) external onlyOwner {
        require(_totalWinnerTicketCount > 0, "Zero winner ticket count");
        totalWinnerTicketCount = _totalWinnerTicketCount;
    }

    function distributeTicketsToCitadelKeyHolders(
        address[] calldata _holders,
        uint256[] calldata _keyCount
    ) external onlyDepositAllowed onlyOwner {
        uint256 holderCount = _holders.length;
        require(holderCount == _keyCount.length, "Invalid params");

        // distribute 100 tickets to each Citadel Key holders
        for (uint256 i = 0; i < holderCount; ) {
            address holder = _holders[i];
            uint256 userTicketCountToAssign = 100 * _keyCount[i];

            // mark as if the holder deposited tokens for the userTicketCountToAssign calculation in deposit() function.
            userDeposits[holder] += userTicketCountToAssign * NFTL_AMOUNT_FOR_TICKET;

            // add the user if not exist
            _userList.add(holder);

            emit TicketDistributed(holder, userTicketCountToAssign);

            unchecked {
                ++i;
            }
        }
    }

    function deposit(uint256 _amount) external onlyDepositAllowed whenNotPaused {
        // burn NFTL tokens
        nftl.burnFrom(msg.sender, _amount);

        // increase the user deposit
        userDeposits[msg.sender] += _amount;

        // add the user if not exist
        _userList.add(msg.sender);

        emit UserDeposited(msg.sender, _amount);
    }

    function assignTicketToUsers() external onlyDepositDisallowed onlyOwner {
        require(!isTicketAssignedToUsers, "Already assigned");
        isTicketAssignedToUsers = true;

        uint256 totalUserCount = getUserCount();
        address[] memory users = getUserList();
        uint256 currentTotalTicketCount = 0;

        for (uint256 i = 0; i < totalUserCount; ) {
            address user = users[i];
            uint256 userTicketCountToAssign = userDeposits[user] / NFTL_AMOUNT_FOR_TICKET;
            ticketRangeByUser[user] = TicketRange({
                startTicketId: currentTotalTicketCount,
                endTicketId: currentTotalTicketCount + userTicketCountToAssign - 1
            });

            unchecked {
                currentTotalTicketCount += userTicketCountToAssign;
                ++i;
            }
        }

        // set the total ticket count
        totalTicketCount = currentTotalTicketCount;
    }

    function manageConsumers(address _consumer, bool _add) external onlyOwner {
        _add
            ? VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(s_subscriptionId, _consumer)
            : VRFCoordinatorV2Interface(vrfCoordinator).removeConsumer(s_subscriptionId, _consumer);
    }

    function chargeLINK(uint256 _amount) external {
        IERC20Upgradeable(LINK).safeTransferFrom(msg.sender, address(this), _amount);
        LinkTokenInterface(LINK).transferAndCall(vrfCoordinator, _amount, abi.encode(s_subscriptionId));
    }

    function withdrawLINK(address _to) external onlyOwner {
        IERC20Upgradeable(LINK).safeTransfer(_to, IERC20Upgradeable(LINK).balanceOf(address(this)));
    }

    function requestRandomWordsForWinnerSelection()
        external
        onlyDepositDisallowed
        onlyOwner
        returns (uint256 requestId)
    {
        require(currentWinnerTicketCount < totalWinnerTicketCount, "Request overflow");
        require(totalWinnerTicketCount <= totalTicketCount, "Not enough depositors");

        if (randomWordList.length != 0) {
            // select winners
            bool isWinnerSelected = _selectWinners();
            if (isWinnerSelected) return 0;
        }

        // request the random words ans select winners
        uint256 winnerCountToRequest = totalWinnerTicketCount * 2;
        requestId = _requestRandomWords(uint32(winnerCountToRequest));

        emit RandomWordsRequested(requestId, winnerCountToRequest);
    }

    function _requestRandomWords(uint32 _numWords) internal returns (uint256) {
        return
            VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
                s_keyHash,
                s_subscriptionId,
                s_requestConfirmations,
                s_callbackGasLimit,
                _numWords
            );
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
        require(msg.sender == vrfCoordinator, "Only VRF coordinator");
        _fulfillRandomWords(_requestId, _randomWords);

        emit RandomWordsReceived(_requestId, _randomWords);
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param _requestId The Id initially returned by requestRandomWords
     * @param _randomWords the VRF output expanded to the requested number of words
     */
    function _fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal {
        // since we'll use the random word in the reverse order, push the last random word first
        for (uint256 i = 0; i < _randomWords.length; ) {
            randomWordList.push(_randomWords[_randomWords.length - 1 - i]);

            unchecked {
                ++i;
            }
        }

        // select winners
        _selectWinners();
    }

    function _selectWinners() internal returns (bool) {
        // get the random word and remove it from the list
        uint256 randomWord = randomWordList[randomWordList.length - 1];
        randomWordList.pop();

        // select the winner
        uint256 winnerTicketId;
        while (true) {
            winnerTicketId = randomWord % totalTicketCount;

            if (isWinnerTicketId[winnerTicketId]) {
                // winner ticket Id already selected
                if (randomWordList.length == 0) {
                    return false;
                } else {
                    randomWord = randomWordList[randomWordList.length - 1];
                    randomWordList.pop();
                }
            } else {
                break;
            }
        }

        address[] memory users = getUserList();
        uint256 statIndexToCheck = 0;
        uint256 endIndexToCheck = getUserCount() - 1;
        uint256 userIndexToCheck;
        address userToCheck;
        address winner;
        while (true) {
            userIndexToCheck = (statIndexToCheck + endIndexToCheck) / 2;
            userToCheck = users[userIndexToCheck];

            if (
                ticketRangeByUser[userToCheck].startTicketId <= winnerTicketId &&
                winnerTicketId <= ticketRangeByUser[userToCheck].endTicketId
            ) {
                winner = userToCheck;
                break;
            } else if (winnerTicketId < ticketRangeByUser[userToCheck].startTicketId) {
                endIndexToCheck = userIndexToCheck - 1;
            } else {
                statIndexToCheck = userIndexToCheck + 1;
            }
        }

        // transfer the prize
        uint256 prizeTokenId = prizeNFTokenIds[currentWinnerTicketCount];
        prizeNFT.safeTransferFrom(address(this), winner, prizeTokenId, bytes(""));
        isWinnerTicketId[winnerTicketId] = true;

        // store the winner
        winners.push(WinnerInfo({ ticketId: winnerTicketId, winner: winner, prizeTokenId: prizeTokenId }));

        // increase the current winner ticket count
        ++currentWinnerTicketCount;

        emit WinnerSelected(msg.sender, winner, winnerTicketId, prizeTokenId);

        return true;
    }

    function getWinners() external view returns (WinnerInfo[] memory) {
        return winners;
    }

    function getUserCount() public view returns (uint256) {
        return _userList.length();
    }

    function getUserList() public view returns (address[] memory) {
        return _userList.values();
    }

    function getRandomWordsList() external view returns (uint256[] memory) {
        return randomWordList;
    }

    function allowUserDeposit() external onlyOwner {
        isUserDepositAllowed = true;
    }

    function disallowUserDeposit() external onlyOwner {
        isUserDepositAllowed = false;
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}