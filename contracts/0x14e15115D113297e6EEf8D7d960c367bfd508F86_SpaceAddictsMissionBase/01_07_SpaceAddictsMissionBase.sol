// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface NFTToken {
    function changeNftMissionStatus(uint256 tokenid, bool status) external;
    function nftMissionStatus(uint256 tokenid) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract SpaceAddictsMissionBase is ERC20, IERC721Receiver, Ownable {
    struct Missions {
        uint256 duration;
        uint256 rewardAmount;
    }

    struct Stake {
        uint256 endTime;
        uint256 rewardAmount;
        uint256 startTime;
        uint256 missionID;
        bool active;
    }

    NFTToken public SpaceAddictsNFT;
    Missions[] private MissionInfos;
    bool public BaseOpen = true;
    mapping(address => mapping(uint256 => Stake)) public userStakes;
    mapping(address => uint256[]) private userTokenIds;
    event Staked(address indexed user, uint256 indexed nftTokenId);
    event Unstaked(
        address indexed user,
        uint256 indexed nftTokenId,
        uint256 rewardAmount
    );

    constructor(address _nftTokenAddress) ERC20("SpaceAddictsMPCredit", "MPCREDIT") {
        SpaceAddictsNFT = NFTToken(_nftTokenAddress);

    }

    function startMission(uint256 _nftTokenId, uint256 _missionid) external {
        require(BaseOpen, "Mission Base is closed for new missions");
        require(_missionid < MissionInfos.length, "Invalid Mission");
        require(
            !SpaceAddictsNFT.nftMissionStatus(_nftTokenId),
            "Already on Mission Space Waste!"
        );
        require(
            SpaceAddictsNFT.ownerOf(_nftTokenId) == msg.sender,
            "You Dont own this NFT"
        );
        Missions storage selecteMission = MissionInfos[_missionid];
        SpaceAddictsNFT.changeNftMissionStatus(_nftTokenId, true);
        userStakes[msg.sender][_nftTokenId] = Stake({
            endTime: selecteMission.duration + block.timestamp,
            rewardAmount: selecteMission.rewardAmount,
            startTime: block.timestamp,
            missionID: _missionid,
            active: true
        });
        userTokenIds[msg.sender].push(_nftTokenId);
        emit Staked(msg.sender, _nftTokenId);
    }

    function returnToBase(uint256 _nftTokenId) external {
        Stake storage stake = userStakes[msg.sender][_nftTokenId];
        require(stake.active, "No active Mission for the given NFT token ID");
        require(
            block.timestamp >= stake.endTime,
            "Mission duration not yet completed"
        );
        uint256 rewardAmount = stake.rewardAmount;
        delete userStakes[msg.sender][_nftTokenId];
        SpaceAddictsNFT.changeNftMissionStatus(_nftTokenId, false);
        uint256[] storage tokens = userTokenIds[msg.sender];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _nftTokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
        _mint(msg.sender, rewardAmount);
        emit Unstaked(msg.sender, _nftTokenId, rewardAmount);
    }

    
    function abortMission(uint256 _nftTokenId) external {
        Stake storage stake = userStakes[msg.sender][_nftTokenId];
        require(stake.active, "No active Mission for the given NFT token ID");
        delete userStakes[msg.sender][_nftTokenId];
        SpaceAddictsNFT.changeNftMissionStatus(_nftTokenId, false);
        uint256[] storage tokens = userTokenIds[msg.sender];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _nftTokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    function getUserStakes(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userTokenIds[_user];
    }

    function addSingleMission(uint256 _duration, uint256 _rewardAmount)
        external
        onlyOwner
    {
        require(_duration > 0, "Duration must be greater than zero");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");

        Missions memory newMissions = Missions({
            duration: _duration,
            rewardAmount: _rewardAmount
        });

        MissionInfos.push(newMissions);
    }

    function addBatchMissions(
        uint256[] calldata _durations,
        uint256[] calldata _rewardAmounts
    ) external onlyOwner {
        require(
            _durations.length == _rewardAmounts.length,
            "Arrays length mismatch"
        );

        for (uint256 i = 0; i < _durations.length; i++) {
            require(_durations[i] > 0, "Duration must be greater than zero");
            require(
                _rewardAmounts[i] > 0,
                "Reward amount must be greater than zero"
            );

            Missions memory newMission = Missions({
                duration: _durations[i] * 86400,
                rewardAmount: _rewardAmounts[i] * 1e18
            });

            MissionInfos.push(newMission);
        }
    }

    function getMissions(uint256 _idx) public view returns (Missions memory) {
        return MissionInfos[_idx];
    }

    function setBaseStatus(bool _status) public onlyOwner {
        BaseOpen = _status;
    }

        function mintCredit(address _to, uint256 amount) public onlyOwner {
        _mint(_to, amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}