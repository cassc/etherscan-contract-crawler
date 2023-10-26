// OPEN SOURCE LICENSE.  RADICAL ACCELERATION.  BREAK THINGS RESPONSIBLY.
// FLAPPY ROYALE:  A TRUSTLESS IMPLEMENTATION FOR EVM BASED BATTLE ROYALE GAMES.
//                                     ................................                                
//                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                               
//                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*                               
//                          @@@@@@@@@@@.....................(@@@@@     #@@@@@                          
//                          @@@@@@@@@@@.....................(@@@@@     #@@@@@                          
//                    #@@@@@...........................@@@@@(                @@@@@,                    
//                    #@@@@@...........................@@@@@(                @@@@@,                    
//         /@@@@@@@@@@@@@@@@@@@@@*.....................@@@@@(          #@@@@@     &@@@@@               
//         /@@@@@@@@@@@@@@@@@@@@@*.....................@@@@@(          #@@@@@     &@@@@@               
//    @@@@@#.....................&@@@@@................@@@@@(          #@@@@@     &@@@@@               
//    @@@@@#.....................&@@@@@................@@@@@(          #@@@@@     &@@@@@               
//    @@@@@#.....................%&&&&&,,,,,...........&&&&&(.....     (&&&&&     &@@@@@               
//    @@@@@#...........................@@@@@................(@@@@@                &@@@@@               
//    @@@@@#...........................@@@@@................(@@@@@                &@@@@@               
//    @@@@@#...........................@@@@@......................@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//    @@@@@#...........................@@@@@......................@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//         /@@@@@................&@@@@@.....................(@@@@@***************************@@@@@@    
//         /@@@@@................&@@@@@.....................(@@@@@***************************@@@@@@    
//               @@@@@@@@@@@@@@@@*.....................@@@@@%*****@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//               @@@@@@@@@@@@@@@@*.....................@@@@@%*****@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//                          @@@@@*..........................(@@@@@**********************@@@@@          
//                          @@@@@*..........................(@@@@@**********************@@@@@          
//                          &&&&&/**********................/&&&&&/////////////////////(@@@@@          
//                               &@@@@@@@@@@......................@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//                               &@@@@@@@@@@......................@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//                                          @@@@@@@@@@@@@@@@@@@@@@                                     
//                                          @@@@@@@@@@@@@@@@@@@@@@    
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FlappyRoyale is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public price = 0.02 ether;
    uint256 public highstakePrice = 0.06 ether;
    bool public highStakesActive = false;
    uint256 public entrants = 100;
    uint256 public totalContributions = 0;
    uint256 public totalPrizes = 0;
    uint256 public unclaimedPrizes = 0;
    uint256 public withdrawnFunds = 0;
    uint256 public prizeEquation = 60; 
    uint256 public gameCounter = 0;
    uint256 public currentPlayerCount = 0; 
    address[] public currentPlayersList;  
    address public treasuryWallet = msg.sender;
    uint256 public lastGiveawayMint;

    uint256 public firstPrize = 40;
    uint256 public secondPrize = 20;
    uint256 public thirdPrize = 10;

    mapping(address => uint256) public tickets;
    mapping(address => uint256) public highStakeTickets;
    mapping(address => uint256) public deductedTickets;
    mapping(address => uint256) public pendingWithdrawals; 
    mapping(address => bool) public currentPlayers;  
    mapping(address => uint256) public winsFirst;
    mapping(address => uint256) public winsSecond;
    mapping(address => uint256) public winsThird;

    event LobbyFull(address[] players); 
    event LobbyFullHighStakes(address[] players); 
    event TicketDeducted(address indexed user, uint256 currentPlayerCount);
    event HighStakeTicketDeducted(address indexed user, uint256 currentPlayerCount);
    event TicketsPurchased(address indexed user, uint256 amount);
    event HighStakeTicketsPurchased(address indexed user, uint256 amount);
    event TicketsGranted(address indexed user1, address indexed user2);
    event TicketsGifted(address indexed sender, address indexed receiver, uint256 amount);
    event WinnersPayoutUpdated(address winner1, address winner2, address winner3, uint256 winner1Amount, uint256 winner2Amount, uint256 winner3Amount);
    event EntrantsUpdated(uint256 newEntrants);
    event FundsWithdrawn(uint256 amount);
    event PrizeEquationUpdated(uint256 newPrizeEquation);
    event AmountClaimed(address indexed user, uint256 amount);

    bool public isShutDown = false;
    bool public contractOpened = false;

    modifier onlyWhenHighStakesInactive() {
        require(!highStakesActive, "High Stakes are active");
        _;
    }

    modifier onlyWhenHighStakesActive() {
        require(highStakesActive, "High Stakes are not active");
        _;
    }

    modifier onlyEOA() {
        require(!isContract(msg.sender), "Caller must be an EOA");
        _;
    }

    modifier onlyTreasuryWallet() {
        require(msg.sender == treasuryWallet, "Not authorized");
        _;
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function toggleHighStakes() external onlyTreasuryWallet {
        require(currentPlayerCount == entrants, "Current players list is not equal to entrants");
        highStakesActive = !highStakesActive;
    }

    function purchaseTickets(uint256 amount) external payable whenNotPaused  {        
        require(!isShutDown, "Ticket purchasing has been shut down");
        require(msg.value == amount.mul(price), "Incorrect ETH sent");

        totalContributions = totalContributions.add(msg.value);
        creditTickets(msg.sender, amount);

        emit TicketsPurchased(msg.sender, amount);
    }

    function creditTickets(address user, uint256 amount) internal {
        tickets[user] = tickets[user].add(amount);
    }

    function purchaseHighStakeTickets(uint256 amount) external payable whenNotPaused  {        
        require(!isShutDown, "Ticket purchasing has been shut down");
        require(msg.value == amount.mul(highstakePrice), "Incorrect ETH sent"); 
        
        totalContributions = totalContributions.add(msg.value);
        creditHighStakeTickets(msg.sender, amount);
        
        emit HighStakeTicketsPurchased(msg.sender, amount);
    }

    function creditHighStakeTickets(address user, uint256 amount) internal {
        highStakeTickets[user] = highStakeTickets[user].add(amount);
    }

    function deductTickets() external onlyEOA onlyWhenHighStakesInactive {        
        require(!isShutDown, "Game is shut down");
        require(contractOpened, "Contract not open yet");
        require(currentPlayerCount < entrants, "Lobby is full. Wait for payout.");
        require(tickets[msg.sender] > 0, "Insufficient tickets");
        require(gameCounter < 1, "Game is in progress please wait");
        require(!currentPlayers[msg.sender], "You've already joined the current lobby");

        if(!currentPlayers[msg.sender]) {
            tickets[msg.sender] = tickets[msg.sender].sub(1);
            deductedTickets[msg.sender] = deductedTickets[msg.sender].add(1);
            
            currentPlayerCount++;
            emit TicketDeducted(msg.sender, currentPlayerCount);
      
            currentPlayersList.push(msg.sender);
            currentPlayers[msg.sender] = true;

            if(currentPlayerCount == entrants) {
                emit LobbyFull(currentPlayersList);
                gameCounter = gameCounter.add(1); 
            }
        }
    }

    function deductHighStakeTickets() external onlyEOA onlyWhenHighStakesActive {        
        require(!isShutDown, "Game is shut down");
        require(contractOpened, "Contract not open yet");
        require(currentPlayerCount < entrants, "Lobby is full. Wait for payout.");
        require(highStakeTickets[msg.sender] > 0, "Insufficient high-stake tickets");
        require(!currentPlayers[msg.sender], "You've already joined the current lobby");

        if(!currentPlayers[msg.sender]) {
            highStakeTickets[msg.sender] = highStakeTickets[msg.sender].sub(1);
            deductedTickets[msg.sender] = deductedTickets[msg.sender].add(1);
        
            currentPlayerCount++;
            emit HighStakeTicketDeducted(msg.sender, currentPlayerCount);
         
            currentPlayersList.push(msg.sender);
            currentPlayers[msg.sender] = true;  
        
            if(currentPlayerCount == entrants) {
                emit LobbyFullHighStakes(currentPlayersList);
                gameCounter = gameCounter.add(1); 
            }
        }
    }

    function giftTickets(address receiver, uint256 amount) external {
        require(receiver != address(0), "Invalid receiver address");
        require(amount > 0, "Amount must be greater than 0");
        address sender = msg.sender;
        require(tickets[sender] >= amount, "Insufficient tickets to gift");

        tickets[sender] = tickets[sender].sub(amount); 
        tickets[receiver] = tickets[receiver].add(amount); 

        emit TicketsGifted(sender, receiver, amount);
    }

    function mintGiftTickets() external onlyTreasuryWallet {
        uint256 amountToMint = 10;
        require(block.timestamp - lastGiveawayMint >= 1 days, 
            "Can only mint 10 tickets per day");

        lastGiveawayMint = block.timestamp;
        tickets[owner()] = tickets[owner()].add(amountToMint);
    }

    function setWinnersPayoutStandard(address winner1, address winner2, address winner3) external onlyTreasuryWallet   {
        _setWinnersPayout(winner1, winner2, winner3, price);
    }

    function setWinnersPayoutHighStakes(address winner1, address winner2, address winner3) external onlyTreasuryWallet   {
        _setWinnersPayout(winner1, winner2, winner3, highstakePrice);
    }

   function _setWinnersPayout(address winner1, address winner2, address winner3, uint256 activePrice) internal {
        require(gameCounter > 0, "No completed games available for payout");
        require(prizeEquation >= 60 && prizeEquation <= 100, "Invalid prize equation percentage");

        uint256 totalPrize = activePrice.mul(entrants); 
        
        uint256 winner1Amount = totalPrize.mul(firstPrize).div(100); 
        uint256 winner2Amount = totalPrize.mul(secondPrize).div(100); 
        uint256 winner3Amount = totalPrize.mul(thirdPrize).div(100);

        pendingWithdrawals[winner1] = pendingWithdrawals[winner1].add(winner1Amount);
        pendingWithdrawals[winner2] = pendingWithdrawals[winner2].add(winner2Amount);
        pendingWithdrawals[winner3] = pendingWithdrawals[winner3].add(winner3Amount);
        totalPrizes = totalPrizes.add(winner1Amount).add(winner2Amount).add(winner3Amount);
        unclaimedPrizes = unclaimedPrizes.add(winner1Amount).add(winner2Amount).add(winner3Amount);

        emit WinnersPayoutUpdated(winner1, winner2, winner3, winner1Amount, winner2Amount, winner3Amount);

        winsFirst[winner1] = winsFirst[winner1].add(1);
        winsSecond[winner2] = winsSecond[winner2].add(1);
        winsThird[winner3] = winsThird[winner3].add(1);

        gameCounter = 0;
        currentPlayerCount = 0;
        delete currentPlayersList;
    }

    function setPrizePercentages(uint256 _firstPrize, uint256 _secondPrize, uint256 _thirdPrize) external onlyTreasuryWallet {
        require(_firstPrize >= 40, "First prize cannot be less than 40%");
        require(_secondPrize >= 20, "Second prize cannot be less than 20%");
        require(_thirdPrize >= 10, "Third prize cannot be less than 10%");
        require(_firstPrize.add(_secondPrize).add(_thirdPrize) <= 100, "Total prize percentages cannot exceed 100%");
        
        firstPrize = _firstPrize;
        secondPrize = _secondPrize;
        thirdPrize = _thirdPrize;
    }


    function claim() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to claim.");

        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        unclaimedPrizes = unclaimedPrizes.sub(amount);

        emit AmountClaimed(msg.sender, amount);
    }

    function updatePrizeEquation(uint256 newPrizeEquation) external onlyTreasuryWallet {
        require(newPrizeEquation >= 60 && newPrizeEquation <= 100, "Invalid prize equation percentage");

        prizeEquation = newPrizeEquation;

        emit PrizeEquationUpdated(newPrizeEquation);
    }

    function grantTickets(address user1, address user2) external onlyTreasuryWallet {
        require(user1 != address(0) && user2 != address(0), "Invalid address");
        tickets[user1] = tickets[user1].add(1);
        tickets[user2] = tickets[user2].add(1);
        emit TicketsGranted(user1, user2);
    }


    function updateEntrants(uint256 newEntrants) external onlyTreasuryWallet {
        if(contractOpened) {
            require(gameCounter > 0, "No completed games available for payout");
        }
        entrants = newEntrants;
        emit EntrantsUpdated(newEntrants);
    }
    
    function getCurrentPlayersList() external view returns (address[] memory) {
        return currentPlayersList;
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        uint256 maxAmount = totalContributions.mul(40).div(100);
        require(withdrawnFunds.add(amount) <= maxAmount, "Exceeding withdrawal limit");

        withdrawnFunds = withdrawnFunds.add(amount);
        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(amount);
    }

    function delegateTreasuryWallet(address newTreasuryWallet) external onlyOwner {
        require(newTreasuryWallet != address(0), "Invalid address");
        treasuryWallet = newTreasuryWallet;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Renouncing ownership is not allowed");
    }

    function pauseTicketBuying() external onlyTreasuryWallet {
        require(!isShutDown, "Contract is already shut down");
        isShutDown = true;
    }

    function resumeTicketBuying() external onlyTreasuryWallet {
        require(isShutDown, "Contract is not shut down");
        isShutDown = false;
    }

    function startContract() external onlyOwner {
        contractOpened = true;
    }
}