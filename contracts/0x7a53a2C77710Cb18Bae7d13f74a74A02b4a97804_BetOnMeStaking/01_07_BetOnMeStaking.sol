// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "IERC721.sol";
import "Ownable.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";


contract BetOnMeStaking is VRFConsumerBaseV2 {

    IERC721 public LadyLilethCollection;

    VRFCoordinatorV2Interface COORDINATOR;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 1000000;
    uint32 numWords = 1;
    uint64 s_subscriptionId;
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address public s_owner;
    address[] public stakers;
    address[] public winners;
    bytes32 s_keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    bool lotteryStarted = false;

    struct Token {
        uint256 timeOfLastStake;
        uint256 timeStakedBefore;
        address staker;
    }

    mapping(uint256 => Token) public tokens;
    mapping(address => uint256[]) tokenIdsStaked;

    event Winner(address winner, uint256 requestId, uint256 luckyNumber, uint256 date);

    constructor(IERC721 _LadyLilethCollection, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        LadyLilethCollection = _LadyLilethCollection;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function stake(uint256[] memory _tokenIds) external {
        require(lotteryStarted == false, "Lottery in progress. Staking paused");
        if (tokenIdsStaked[msg.sender].length == 0) {
            stakers.push(msg.sender);
        }
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                LadyLilethCollection.ownerOf(_tokenIds[i]) == msg.sender,
                "Can't stake tokens you don't own!"
            );
            LadyLilethCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            tokenIdsStaked[msg.sender].push(_tokenIds[i]);
            tokens[_tokenIds[i]].timeOfLastStake = block.timestamp;
            tokens[_tokenIds[i]].staker = msg.sender;
        }
    }

    function withdraw(uint256[] memory _tokenIds) external {
        require(lotteryStarted == false, "Lottery in progress. Withdrawals paused");
        for (uint256 i; i < _tokenIds.length; i++) {
            require(tokens[_tokenIds[i]].staker == msg.sender);
            for (uint256 j; j < tokenIdsStaked[msg.sender].length; ++j) {
                if (tokenIdsStaked[msg.sender][j] == _tokenIds[i]) {
                    tokenIdsStaked[msg.sender][j] = tokenIdsStaked[msg.sender][
                        tokenIdsStaked[msg.sender].length - 1
                    ];
                    tokenIdsStaked[msg.sender].pop();
                    if (tokenIdsStaked[msg.sender].length == 0) {   
                        for (uint256 k; k < stakers.length; ++k) {
                            if( stakers[k] == msg.sender ){
                                removeStaker(k);
                            }
                        }
                    }
                }
            }
            LadyLilethCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
            tokens[i].timeStakedBefore =
                block.timestamp -
                tokens[i].timeOfLastStake;
            tokens[i].timeOfLastStake = 0;
        }
    }

    function calculateDaysStaked(address _user) public view returns (uint256) {
        uint256 totalTimeStaked;
        for (uint256 i; i < tokenIdsStaked[_user].length; i++) { 
            if (tokens[tokenIdsStaked[_user][i]].timeOfLastStake == 0) {
                totalTimeStaked += tokens[tokenIdsStaked[_user][i]]
                    .timeStakedBefore;
            } else {
                totalTimeStaked += (tokens[tokenIdsStaked[_user][i]]
                    .timeStakedBefore +
                    (block.timestamp -
                        tokens[tokenIdsStaked[_user][i]].timeOfLastStake));
            }
        }
        return totalTimeStaked / SECONDS_IN_A_DAY;
    }

    function _zeroDaysStaked(address _user) internal {
        for (uint256 i; i < tokenIdsStaked[_user].length; i++) {
            tokens[tokenIdsStaked[_user][i]].timeStakedBefore = 0;
            tokens[tokenIdsStaked[_user][i]].timeOfLastStake = block.timestamp;

        }

    }

    function removeStaker( uint256 index ) internal {
        if (index >= stakers.length) return;

        stakers[index] = stakers[stakers.length - 1];
        stakers.pop();
    }

    function getUserNftsStaked(address _user) public view returns (uint256[] memory) {
        return tokenIdsStaked[_user];
    }

    function getStakers() external view returns (address[] memory) {
        return stakers;
    }

    function requestRandomness() public onlyOwner returns (uint256 requestId) {
        lotteryStarted = true;
        
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

        address winner;
        uint256 total;
        uint256 stakersLength = stakers.length;
        uint256[] memory chances = new uint256[](stakersLength);
        chances[0] = calculateDaysStaked(stakers[0]);
        for (uint256 i = 1; i < stakersLength; i++) {
            uint256 chance = calculateDaysStaked(stakers[i]);
            chances[i] += chances[i - 1] + chance;
        }
        total = chances[stakersLength - 1];
        // random number 
        uint256 luckyNumber = (randomWords[0] % total) + 1;
        for (uint256 i; i < stakersLength; i++) {
            if (luckyNumber < chances[i]) {
                winner = stakers[i];
                break;
            }
        }

        _zeroDaysStaked(winner);

        winners.push(winner);
        emit Winner(winner, requestId, luckyNumber, block.timestamp);

        lotteryStarted = false;

    }

    function getWinners() external view returns (address[] memory) {
        return winners;
    }

    function setVRFCoordinator(address _VRFCoordinator) public onlyOwner {
        vrfCoordinator = _VRFCoordinator;
    }

    function setKeyHash(bytes32 _s_keyHash) public onlyOwner {
        s_keyHash = _s_keyHash;
    }

    function setSubscriptionId(uint64 _s_subscriptionId) public onlyOwner {
        s_subscriptionId = _s_subscriptionId;
    }

    function destroy(address apocalypse) public onlyOwner {
        selfdestruct(payable(apocalypse));
    }

}