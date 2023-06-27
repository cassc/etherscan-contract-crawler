// SPDX-License-Identifier: MIT
// DumplingZai v69696969 
// "I smash keyboards and vomit smart contracts"


pragma solidity ^0.8.7;

import "./2.IERC20.sol";
import "./3.Ownable.sol";
import "./4.Pausable.sol";
import "./5.IERC721.sol";
import "./6.VRFV2WrapperConsumerBase.sol";
import "./7.ConfirmedOwner.sol";
import "./8.IERC721Receiver.sol";
import "./9.AccessControl.sol";

contract EGGPOT_LD is 
    AccessControl,
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    Pausable,
    IERC721Receiver
    {
    
    // ==== Variables declaration ====
        // ==== Game related ====
        IERC721[] public rewardNFTs; // NFT rewards array
        uint256[] public rewardNFTIds; // NFT token ID array
        uint256 public rewardETHPerWinner; // ETH rewards
        uint256 public gameRound = 1; //for clearing participant mapping
        uint256 public gameStarted = 0;
        uint256 public numberOfWinners;  
        uint256 private entriesTracker; // internal tracker
        uint256 public totalEntries;
        address[] public winnerList; //storing of winners per round
        mapping(address => Participant) public participants; // mapping of each unique participants
        mapping(uint256 => mapping(uint256 => address)) public participantByEntryIndexPerRound; //for new participantByEntryIndex each round
        mapping(address => mapping(uint256 => PrizeInfo[])) Winners; // mapping of each winner to their prizes
        mapping(uint256 => address[]) public winnersPerRound;
        mapping(uint256 => address[]) public participantAddressesPerRound;
        mapping(uint256 => mapping(address => uint256)) public participantCumulativeTicketsPerRound;

        struct PrizeInfo {
            address nft;
            uint256 prizeAmountOrId;
            bool claimed;
            uint256 round;
        }

        struct Participant { // record of each unique participants information
            uint256 lastParticipatedRound;
            uint256 numberOfEntries;
        }
        
        // ==== Chainlink VRF related ====
        uint256 public randomResult; //stores result of the chainlink randomizer 
        uint32 private callbackGasLimit = 300000; // gas limit to call on VRF
        uint16 private requestConfirmations = 3;
        uint32 private numWords = 1;
        address private linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA; //$LINK tokens address 
        address private wrapperAddress =0x5A861794B927983406fCE1D062e00b9368d97Df6; //ChainLink wrapper address
  
        // ==== Automation related ====
        bytes32 public constant AUTOMATOR_ROLE = keccak256("AUTOMATOR_ROLE"); //Automator initalisation

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    //==== Game & Rewards Settings ====    
    function setRewardsNFT(IERC721[] memory _rewardNFTs, uint256[] memory _rewardNFTIds) external onlyOwnerOrAutomator {
        require(_rewardNFTs.length == _rewardNFTIds.length, "NFTs and IDs arrays should have the same length");
        require(_rewardNFTs.length >= numberOfWinners, "The number of rewards is lesser than the number of winners");
        rewardNFTs = _rewardNFTs;
        rewardNFTIds = _rewardNFTIds;
    }

    function setRewardsETHPerWinner(uint256 _rewardETHPerWinner) external onlyOwnerOrAutomator {
        rewardETHPerWinner = _rewardETHPerWinner;
    }

    function gameSetup(uint256 _numberOfWinners) external onlyOwnerOrAutomator {
        numberOfWinners = _numberOfWinners;
        gameStarted = 1;
    }
    
    function resetGame() external onlyOwnerOrAutomator {
        // Increment the game round
        gameRound++;

        // Reset the current entries, max entries, reward NFTs, and reward NFT IDs
        numberOfWinners = 0;
        delete rewardNFTs;
        delete rewardNFTIds;
        delete winnerList;
        gameStarted = 0;
        rewardETHPerWinner = 0;
        entriesTracker = 0;
        totalEntries = 0;
    }

    function clearRewards() external onlyOwnerOrAutomator {
        delete rewardNFTs;
        delete rewardNFTIds;
        rewardETHPerWinner = 0;
    }

    function setGameRound(uint256 round) public onlyOwnerOrAutomator {
        gameRound = round;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ==== Game Operations ====

  // Updated updateParticipants function
function updateParticipants(address[] calldata _participants, uint256[] calldata _numberOfTickets) external onlyOwnerOrAutomator {
    require(_participants.length == _numberOfTickets.length, "Input arrays must be of equal length");
    
    for (uint256 i = 0; i < _participants.length; i++) {
        require(_participants[i] != address(0), "Invalid address");

        if(participants[_participants[i]].lastParticipatedRound < gameRound){
            participants[_participants[i]].numberOfEntries = _numberOfTickets[i];
            participants[_participants[i]].lastParticipatedRound = gameRound;
            participantAddressesPerRound[gameRound].push(_participants[i]);
            participantCumulativeTicketsPerRound[gameRound][_participants[i]] = totalEntries + _numberOfTickets[i];
        }
        else{
            participants[_participants[i]].numberOfEntries += _numberOfTickets[i];
            participantCumulativeTicketsPerRound[gameRound][_participants[i]] += _numberOfTickets[i];
        }
        
        totalEntries += _numberOfTickets[i];
        entriesTracker += _numberOfTickets[i];

    }
}

function pickWinners() public onlyOwnerOrAutomator whenNotPaused {
    require(numberOfWinners <= entriesTracker, "More winners than entries");

    for(uint256 i = 0; i < numberOfWinners; i++) {
        uint256 index = uint256(keccak256(abi.encodePacked(randomResult, i))) % entriesTracker + 1;
        address winnerAddress = findWinner(gameRound, index);
        address payable winner = payable(winnerAddress);
        winnerList.push(winner);

        PrizeInfo memory prize;
        if (rewardNFTs.length > 0) {
            // NFT prize
            uint256 nftIndex = randomResult % rewardNFTs.length;
            IERC721 rewardNFT = rewardNFTs[nftIndex];
            uint256 rewardNFTId = rewardNFTIds[nftIndex];
            require(rewardNFT.ownerOf(rewardNFTId) == address(this), "Contract doesn't own the NFT");
            prize = PrizeInfo(address(rewardNFTs[nftIndex]), rewardNFTIds[nftIndex], false, gameRound);
            Winners[winner][gameRound].push(prize);

            rewardNFTs[nftIndex] = rewardNFTs[rewardNFTs.length - 1];
            rewardNFTs.pop();
            rewardNFTIds[nftIndex] = rewardNFTIds[rewardNFTIds.length - 1];
            rewardNFTIds.pop();
        } else {
            // ETH prize
            require(address(this).balance >= rewardETHPerWinner, "Contract doesn't have enough ETH");
            prize = PrizeInfo(address(0), rewardETHPerWinner, false, gameRound);
            Winners[winner][gameRound].push(prize);
        }

        // Update the entries count and the participation data of the winner
        //participants[winner].numberOfEntries--;
        entriesTracker--;
    }

    gameStarted = 2;
}


function findWinner(uint256 round, uint256 index) internal view returns (address) {
    address[] storage participantsArray = participantAddressesPerRound[round];

    uint256 left = 0;
    uint256 right = participantsArray.length - 1;
    while (left < right) {
        uint256 mid = (right + left + 1) / 2;
        if (participantCumulativeTicketsPerRound[round][participantsArray[mid]] < index) {
            left = mid;
        } else {
            right = mid - 1;
        }
    }

    return participantsArray[left];
}
   
   function claimPrizes(address winner) external {
        require(Winners[winner][gameRound].length > 0, "No prizes in this round");

        for(uint256 i = 0; i < Winners[winner][gameRound].length; i++) {
            if (!Winners[winner][gameRound][i].claimed) {
                if (Winners[winner][gameRound][i].nft == address(0)) {
                    // ETH prize
                    require(address(this).balance >= Winners[winner][gameRound][i].prizeAmountOrId, "Contract doesn't have enough ETH");
                    payable(winner).transfer(Winners[winner][gameRound][i].prizeAmountOrId);
                } else {
                    // NFT prize
                    IERC721 rewardNFT = IERC721(Winners[winner][gameRound][i].nft);
                    uint256 rewardNFTId = Winners[winner][gameRound][i].prizeAmountOrId;
                    require(rewardNFT.ownerOf(rewardNFTId) == address(this), "Contract doesn't own the NFT");
                    rewardNFT.transferFrom(address(this), winner, rewardNFTId);
                }
                Winners[winner][gameRound][i].claimed = true;
            }
        }
    }

        
    // ==== Game information query ====
    function getContractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getParticipantEntries(address participantAddress) external view returns (uint256) {
        if (participants[participantAddress].lastParticipatedRound < gameRound) {
            return 0;
        } else {
            return participants[participantAddress].numberOfEntries;
        }
    }

    function winnerCheck (address winner) external view returns (bool) {
        PrizeInfo[] storage prizeInfo = Winners[winner][gameRound];
        if (prizeInfo.length > 0) {
            for(uint256 i = 0; i < prizeInfo.length; i++) {
                if (!prizeInfo[i].claimed) {
                    return true;
                }
            }
        }
        return false;
    }

    function getWinnerListLength() public view returns (uint) {
        return winnerList.length;
    }

    // ==== Random generator =====
    function requestRandomNumber() external onlyOwnerOrAutomator returns (uint256 requestId) {
        require(LINK.balanceOf(address(this)) >= 0.25 ether, "Not enough LINK to pay fee");
        return requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    function fulfillRandomWords(uint256 , uint256[] memory randomWords)
        internal
        override
    {
        randomResult = randomWords[0];
    }

    // ==== Withdraw assets ====
    function withdrawETH(address payable _to) external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address token, address to) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        erc20Token.transfer(to, balance);
    }

    function withdrawNFTs(address nft, uint256 id, address to) external onlyOwner {
        IERC721 erc721Token = IERC721(nft);
        require(erc721Token.ownerOf(id) == address(this), "The contract doesn't own this NFT");
        erc721Token.transferFrom(address(this), to, id);
    }

    // ===== Others =====
    function onERC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    modifier onlyOwnerOrAutomator() {
            require(owner() == _msgSender() || hasRole(AUTOMATOR_ROLE, _msgSender()), "Caller is not the owner or an automator");
            _;
        }
    function addAutomator(address _automator) external onlyOwner {
        grantRole(AUTOMATOR_ROLE, _automator);
    }

    function removeAutomator(address automator) external onlyOwner {
    revokeRole(AUTOMATOR_ROLE, automator);
    }

    

    receive() external payable {}

}