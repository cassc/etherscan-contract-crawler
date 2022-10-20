// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Som.sol";
import "./RandomNumber.sol";

contract CowardGambit is Initializable, OwnableUpgradeable {
    address public adminAddress;
    address public randomNumberAddress;
    address public SomAddress;
    address public ownerAddress;

    bool public isRandomNumber;
    uint256 public randomNumber;
    uint256 public constant DENOMINATOR = 100;

    bool public roundStarted = false;

    struct SOM {
        uint256 tokenId;
        uint256 state;
    }

    struct Round {
        uint256 roundId;
        uint256 deathPercent;
    }

    mapping(uint256 => Round) public rounds;
    
    SOM[] public joinItems;
    SOM[] public Coward;
    SOM[] public Mars;

    uint256 public currentRoundId = 0;
    uint256 public TimeLineID = 0;
    uint256 public ROUND_COUNT = 5;

    uint256 public MainWinner = 0;
    uint256 public CowardIndex = 0;
    // mapping(uint256 => uint256) public CowardTokenIDs;
    uint256[] public CowardTokenIDs;
    bool[1001] public CowardFlg;
    bool[1001] public MarsFlg;
    bool public CowardHasWinner = true;
    uint256 public CowardWinner = 0;
    bool public CowardFinished = false;
    bool public MarsFinished = false;


    event setRandomNumber();

    function setSOMAddress(address _address) external onlySOM {
        SomAddress = _address;        
    }
    
    function numbersDrawn(
        uint256 _randomNumber
    )
        external
    {
        randomNumber = _randomNumber;
        isRandomNumber = true;
        emit setRandomNumber();
    }

    function initialize(
        address _randomNumberAddress,
        address _adminAddress
    ) public initializer {
        __Ownable_init();
        randomNumberAddress = _randomNumberAddress;
        adminAddress = _adminAddress;
        ownerAddress = msg.sender;
        for (uint256 i = 0; i < ROUND_COUNT; i++) {
            rounds[i + 1].roundId = i + 1;
            if(i == 0) rounds[i + 1].deathPercent = 20;
            if(i == 1) rounds[i + 1].deathPercent = 25;
            if(i == 2) rounds[i + 1].deathPercent = 33;
            if(i == 3) rounds[i + 1].deathPercent = 50;
            if(i == 4) rounds[i + 1].deathPercent = 75;
        }
    }

    modifier onlySOM() {
        require(
            adminAddress == msg.sender || ownerAddress == msg.sender || SomAddress == msg.sender, "RNG: Caller is not the SOM address"
        );
        _;
    }

    function setJoinItems(uint256 _tokenId, uint256 _state) external onlySOM {
        joinItems.push(SOM({
            tokenId: _tokenId,
            state: _state
        }));
    }

    function endRound() external onlySOM {
        require(currentRoundId <= ROUND_COUNT + 1, "Game Finished!");
        //require(isRandomNumber, "Did not get random number");
        TimeLineID ++;
        updateCowardList();
        if(currentRoundId == 0) {
            isRandomNumber = false;
            MainWinner = 0;
            currentRoundId++;
            
            RandomGenerator(randomNumberAddress).requestRandomNumber();
        } else if(currentRoundId == 6) {
            uint256 index = randomNumber % joinItems.length;
            MainWinner = joinItems[index].tokenId;
            if(SOMFactory(SomAddress).getSOMarray(MainWinner) == 17) {
                SOMFactory(SomAddress).setSOMarray(MainWinner, 19);
            } else {
                SOMFactory(SomAddress).setSOMarray(MainWinner, 18);
            }
            joinItems[index] = joinItems[joinItems.length - 1];
            joinItems.pop();
            uint256 deathAmount = joinItems.length;
            for(uint256 i = 0; i < deathAmount; i ++) {
                uint256 dead_index = randomNumber % joinItems.length;
                if(SOMFactory(SomAddress).getSOMarray(joinItems[dead_index].tokenId) != 17) {
                    SOMFactory(SomAddress).setSOMarray(joinItems[dead_index].tokenId, 12);
                }
                joinItems[dead_index] = joinItems[joinItems.length - 1];
                joinItems.pop();
            }
            joinItems.push(SOM({
                tokenId: MainWinner,
                state: 1
            }));
        } else {
            uint256 deathAmount = uint256(joinItems.length * rounds[currentRoundId].deathPercent / DENOMINATOR);
            for (uint256 i = 0; i < deathAmount; i ++) {
                uint256 index = randomNumber % joinItems.length;
                if(currentRoundId == 1) SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 6);
                if(currentRoundId == 2) SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 5);
                if(currentRoundId == 3) {
                    if(i < deathAmount / 2) SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 8);
                    else SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 7);
                }
                if(currentRoundId == 4) {
                    if(i < deathAmount / 2) SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 9);
                    else SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 10);
                }
                if(currentRoundId == 5) {
                    if(i < deathAmount / 2) SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 3);
                    else SOMFactory(SomAddress).setSOMarray(joinItems[index].tokenId, 11);
                }
                joinItems[index] = joinItems[joinItems.length - 1];
                joinItems.pop();
            }

            currentRoundId ++;
        }
        roundStarted = false;
    }

    function setCoward(uint256 _tokenId) external {
        require(msg.sender == SOMFactory(SomAddress).ownerOf(_tokenId), "not yours");
        require(currentRoundId != 0, "Can't join Coward!");
        require(SOMFactory(SomAddress).getSOMarray(_tokenId) != 15, "Already Joined!");
        require(CowardFlg[_tokenId] == false, "Already joined!");
        CowardFlg[_tokenId] = true;
        CowardTokenIDs.push(_tokenId);
    }

    function updateCowardList() public {
        for(uint256 i = CowardIndex; i < CowardTokenIDs.length; i ++) {
            Coward.push(SOM({
                tokenId: CowardTokenIDs[i],
                state: 15
            }));
            SOMFactory(SomAddress).setSOMarray(CowardTokenIDs[i], 15);
            for (uint256 j = 0; j < joinItems.length; j ++) {
                if (joinItems[j].tokenId == CowardTokenIDs[i]) {
                    joinItems[j] = joinItems[joinItems.length - 1];
                    joinItems.pop();
                    break;
                }
            }
        }
        CowardIndex = CowardTokenIDs.length;
    }

    function setFinishCoward() external onlySOM {
        CowardFinished = true;
        if(Coward.length > 200) {
            CowardHasWinner = false;
        } else {
            uint256 index = randomNumber % Coward.length;
            CowardWinner = Coward[index].tokenId;
            SOMFactory(SomAddress).setSOMarray(CowardWinner, 16);
        }
    }

    function setMars(uint256 _tokenId) external {
        require(MarsFlg[_tokenId] == false, "Already joined!");
        MarsFlg[_tokenId] = true;
        uint256 state = SOMFactory(SomAddress).getSOMarray(_tokenId);
        require(msg.sender == SOMFactory(SomAddress).ownerOf(_tokenId), "not yours");
        require(state != 1 && state != 15 && currentRoundId == 6, "Can't join Mars' Gambit!");
        Mars.push(SOM({
            tokenId: _tokenId,
            state: state
        }));
    }

    function setFinishMars() external onlySOM {
        uint256 burnAmount = uint256(Mars.length * 90 / DENOMINATOR);
        MarsFinished = true;

        for (uint256 i = 0; i < burnAmount; i ++) {
            uint256 index = randomNumber % Mars.length;
                SOMFactory(SomAddress).Burn(Mars[index].tokenId);
                SOMFactory(SomAddress).setSOMarray(Mars[index].tokenId, 20);
                Mars[index] = Mars[Mars.length - 1];
                Mars.pop();
        }

        for (uint256 i = 0; i < Mars.length; i ++) {
            SOMFactory(SomAddress).setSOMarray(Mars[i].tokenId, 17);
            Mars[i].state = 17;
            joinItems.push(Mars[i]);
        }
    }

    function fetchCowardAmount() external view returns(uint256) {
        return Coward.length;
    }
    
    function fetchMarsAmount() external view returns(uint256) {
        return Mars.length;
    }

    function fetchTotalAliveAmount() external view returns(uint256) {
        return joinItems.length;
    }
}