// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

/** @title A contract for betting.
 *  @author KY chae
 * @notice This contract is used for betting on games (especially 2022worldcup).
 * @dev
*/ 

contract BetScore {
    struct Score {
        uint16 team1Score;
        uint16 team2Score;
        bool isSet; // score가 0으로 초기화되기 때문에, score가 설정되었는지 확인하기 위한 변수 
    }

    bool public canParticipate = true;
    bool public isAnswered = false;
    uint16 public numOfPlayers = 0;
    uint256 public numOfWinners = 0;
    uint256 public claimAmount = 0;
    // balance maybe larger than betAmount (if there are donations)
    uint256 public betAmount = 0;
    bool public noBodyWin = false;

    mapping(uint16 => mapping(uint16 => address[])) public scoreToAddresses;
    mapping(address => Score) public addressToScore;
    Score public answer;

    address[] public players;

    // winner list who received reward
    address[] receivedAddresses;

    event Bet(address player, uint16 team1Score, uint16 team2Score);
    event ChangeBet(address player, uint16 team1Score, uint16 team2Score);


    address public immutable i_owner;
    
    constructor(){
        i_owner = msg.sender;
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? b : a;
    }

    function bet(uint16 team1Score, uint16 team2Score) payable  onlyParticipatable onlyBeforeAnswered public {

        // if there is no bet, create a new one
        if( addressToScore[msg.sender].isSet == true) {
            revert("You already bet");
        }

        // 10 dollar
        if(msg.value != 0.035 ether) {
            revert("You should bet 0.035 ether");
        }

        betAmount += msg.value;


        addressToScore[msg.sender].team1Score = team1Score;
        addressToScore[msg.sender].team2Score = team2Score;
        addressToScore[msg.sender].isSet = true;

        scoreToAddresses[team1Score][team2Score].push(msg.sender);
        numOfPlayers = numOfPlayers + 1;
        players.push(msg.sender);

        emit Bet(msg.sender, team1Score, team2Score);
    }


    function changeBet(uint16 team1Score, uint16 team2Score) onlyParticipatable onlyBeforeAnswered public {
        if( addressToScore[msg.sender].isSet == false) {
            revert("You didn't bet, use bet function");
        }
        // remove precvious score should be done
        removeScoreFromScoreToAddresses(msg.sender); 

        addressToScore[msg.sender].team1Score = team1Score;
        addressToScore[msg.sender].team2Score = team2Score;

        scoreToAddresses[team1Score][team2Score].push(msg.sender);

        emit ChangeBet(msg.sender, team1Score, team2Score);
    }

    function removeScoreFromScoreToAddresses(address player) private {
        uint16 prevTeam1Score = addressToScore[msg.sender].team1Score;
        uint16 prevTeam2Score = addressToScore[msg.sender].team1Score;
        address[] storage addressArr = scoreToAddresses[prevTeam1Score][prevTeam2Score];
         for (uint i=0; i<addressArr.length; i++) {
            if(addressArr[i] == player) {
                delete addressArr[i];
            }
        }
    }

    
    modifier onlyOwner {
        console.log('msg.sender != iowner', msg.sender != i_owner);
        if (msg.sender != i_owner) revert('NotOwner');
        _;
    }

    modifier onlyAfterAnswered {
        if(!isAnswered) {
            revert('The answer is not submitted');
        }
        _;
    }

       
    modifier onlyBeforeAnswered {
        if(isAnswered) {
            revert("The game is over.");
        }
        _;
    }

    modifier onlyParticipatable {
        if(!canParticipate) {
            revert("The game is not participative");
        }
        _;
    }


    function withdraw() onlyOwner public {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function claim() onlyAfterAnswered public {
        bool canClaim = false;
        address[] memory winners; 
        if(noBodyWin) {
            for(uint i=0; i<receivedAddresses.length; i++) {
                if(receivedAddresses[i] == msg.sender) {
                    revert('Already claimed');
                }
            }
            receivedAddresses.push(msg.sender);
            canClaim = true;
        } else {
            winners = scoreToAddresses[answer.team1Score][answer.team2Score];
            for(uint i=0; i<receivedAddresses.length; i++) {
                if(receivedAddresses[i] == msg.sender) {
                    revert('Already claimed');
                }
            }

            for(uint i=0; i<winners.length; i++) {
                if(winners[i] == msg.sender) {
                    Score memory score = addressToScore[msg.sender];
                    // for double check
                    if(score.team1Score == answer.team1Score && score.team2Score == answer.team2Score) {
                        receivedAddresses.push(msg.sender);
                        canClaim = true;
                        break;
                    }
                }
            }
        }

       
        if(!canClaim) revert("You are not a winner");

        uint256 balance = getBalance();
        (bool callSuccess, ) = payable(msg.sender).call{value: min(claimAmount, balance)}("");
        require(callSuccess, "Call failed");
    }


    function setAnswer(uint16 team1Score, uint16 team2Score) onlyOwner public {
        isAnswered = true;
        answer.team1Score = team1Score;
        answer.team2Score = team2Score;

        address[] storage winners = scoreToAddresses[team1Score][team2Score];
        numOfWinners = winners.length;
        if(numOfWinners > 0) {
            claimAmount = getBalance() / numOfWinners;
        }

        if(numOfWinners == 0) {
            claimAmount = getBalance() / numOfPlayers;
            noBodyWin = true;
        }

        setCanParticipate(false);
    }

    function setCanParticipate(bool newcanParticipate) onlyOwner public {
            canParticipate = newcanParticipate;
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    function getAnswer() public view returns (Score memory){
        return answer;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

}

   // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()