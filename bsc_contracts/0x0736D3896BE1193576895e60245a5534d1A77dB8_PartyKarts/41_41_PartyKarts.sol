// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";

contract PartyKarts is ERC721Drop {
    event AllRacersCompletedEvent(string raceId);
    event RaceCompletedEvent(string raceId);

    struct RaceResult {
        address name;
        string raceTime;
        uint256 finishPosition;
        uint256 lapCount;
    }

    struct RaceLobby {
        string raceId;
        uint256 rewardsPool;
        address creator;
        uint256 entryFee;
        address[] joinedPlayers;
        address[] rewardsCollected;
        bool isStarted;
        bool isFinished;
        string trackName;
        uint256 maxRacers;
        bool isVisible;
        bool isOpen;
    }

    mapping(address => uint256) pendingRewards;
    mapping(string => bool) raceIDExists;
    // Consensus Mechanism:
    // Each address submits their full race results for all players in the lobby
    mapping(address => mapping(address => RaceResult)) raceResults;

    mapping(string => RaceLobby) public raceLobbies;
    address public tokenAddress;
    IERC20 token;

    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenAddress,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
        emit OwnerUpdated(address(0), msg.sender);
    }

    function setTokenAddress(address newAddress) public onlyOwner {
        tokenAddress = newAddress;
    }

    function renounceOwnership() public onlyOwner {
        this.setOwner(address(0));
        emit OwnerUpdated(owner(), address(0));
    }

    receive() external payable {}

    function leaveRaceLobby(string memory _raceID) external {
        RaceLobby storage raceLobby = raceLobbies[_raceID];
        require(raceLobby.creator != address(0), "Race lobby not found");
        require(
            !raceLobby.isStarted,
            "Race has already started, cannot withdraw entry fee"
        );

        address[] storage joinedPlayers = raceLobby.joinedPlayers;
        uint256 entryFee = raceLobby.entryFee;
        bool found = false;
        for (uint i = 0; i < joinedPlayers.length; i++) {
            if (joinedPlayers[i] == msg.sender) {
                found = true;
                joinedPlayers[i] = joinedPlayers[joinedPlayers.length - 1];
                joinedPlayers.pop();
                break;
            }
        }
        require(found, "You are not part of this race lobby");

        // Return entry fee to player
        token.transfer(msg.sender, entryFee);
    }

    function collectRaceRewards(
        string memory _raceId,
        uint256 _amount
    ) external {
        RaceLobby storage raceLobby = raceLobbies[_raceId];
        require(raceLobby.creator != address(0), "Race lobby not found");

        bool found = false;
        address[] storage joinedPlayers = raceLobby.joinedPlayers;

        for (uint i = 0; i < joinedPlayers.length; i++) {
            if (joinedPlayers[i] == msg.sender) {
                found = true;
                joinedPlayers[i] = joinedPlayers[joinedPlayers.length - 1];
                joinedPlayers.pop();
                break;
            }
        }

        require(found, "You are not part of this race lobby");
        if (raceLobby.rewardsCollected.length == 0) {
            raceLobby.isOpen = false;
            raceLobby.isFinished = true;
            raceLobby.isStarted = true;
            emit RaceCompletedEvent(_raceId);
        }

        raceLobby.rewardsCollected.push(msg.sender);

        if (
            raceLobby.rewardsCollected.length == raceLobby.joinedPlayers.length
        ) {
            emit AllRacersCompletedEvent(_raceId);
        }

        require(
            raceLobby.rewardsPool >= _amount,
            "Not enough rewards available"
        );

        raceLobby.rewardsPool -= _amount;

        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function joinRaceLobby(string memory _raceID) external payable {
        RaceLobby storage raceLobby = raceLobbies[_raceID];
        require(raceLobby.creator != address(0), "Race lobby not found");
        require(!raceLobby.isStarted, "Race has already started, cannot join");
        require(
            raceLobby.joinedPlayers.length < raceLobby.maxRacers,
            "Race is full"
        );

        address[] storage joinedPlayers = raceLobby.joinedPlayers;
        for (uint256 i = 0; i < joinedPlayers.length; i++) {
            require(
                joinedPlayers[i] != msg.sender,
                "You have already joined this race"
            );
        }

        require(
            token.balanceOf(msg.sender) >= raceLobby.entryFee,
            "Not enough tokens to enter race"
        );

        uint256 beforeBalance = token.balanceOf(address(this));
        require(
            token.approve(msg.sender, raceLobby.entryFee),
            "You must allow the spending of KART Tokens"
        );
        require(
            token.transferFrom(msg.sender, address(this), raceLobby.entryFee),
            "Race fee payment failed"
        );

        require(
            token.balanceOf(address(this)) ==
                beforeBalance + raceLobby.entryFee,
            "Token transfer failed"
        );

        raceLobby.rewardsPool += raceLobby.entryFee;
        joinedPlayers.push(msg.sender);
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function createRaceLobby(
        uint256 _entryFee,
        string memory _raceID,
        string memory _trackName,
        uint256 _maxRacers,
        bool _isVisible,
        bool _isOpen
    ) external payable returns (RaceLobby memory) {
        require(_entryFee >= 0, "Entry fee must be a positive number");

        // Check if the race with the given ID already exists
        require(!raceIDExists[_raceID], "Race with this ID already exists!");

        RaceLobby memory newRaceLobby = RaceLobby({
            raceId: _raceID,
            creator: msg.sender,
            entryFee: _entryFee,
            joinedPlayers: new address[](0),
            rewardsCollected: new address[](0),
            isStarted: false,
            isFinished: false,
            rewardsPool: 0,
            trackName: _trackName,
            maxRacers: _maxRacers,
            isVisible: _isVisible,
            isOpen: _isOpen
        });

        raceLobbies[_raceID] = newRaceLobby;
        raceIDExists[_raceID] = true;

        return newRaceLobby;
    }

    function withdrawAll() external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw.");

        require(
            IERC20(tokenAddress).transfer(msg.sender, tokenBalance),
            "Transfer failed."
        );
    }
}