// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IERC20Burnable{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external  ; 
}
contract TicketSales is Ownable {
    using SafeMath for uint256;

    struct TicketsDetail{
        uint256 TotalTicketsSoldInRound;
        address[] participants;
        mapping (address=>uint256) tickets;
    }
    address public marketingWallet;
    IERC20Burnable public token; // Address of the token to purchase
    IUniswapV2Router02 public router;
    uint256 public ticketPurchaseLimit = 6;
    uint256 public ticketPrice; // Price of a ticket in wei
    uint256 public contractBalance; // Total ETH stored in the contract
    uint256 public currentround;
    address[3] public winners;
    mapping(uint256 => TicketsDetail) public ticketsPurchasedInRound;
    bool public isTicketSaleActive;

    event TicketsPurchased(address indexed buyer, uint256 numberOfTickets);
    event TicketPriceChanged(uint256 newPrice);
    event WinnersAnnounced(address[3] indexed winners, uint256 amount);
    event PrizeClaimed(address[3] indexed winner,uint256 amount);
    constructor(
        uint256 _initialTicketPrice,
        address _marketingWallet,
        address _uniswapV2Router
        
    ) {
        ticketPrice = _initialTicketPrice;
        marketingWallet = _marketingWallet;
        router =IUniswapV2Router02(_uniswapV2Router);
        token = IERC20Burnable(address(0));
        isTicketSaleActive = true;      
        currentround = 0;
    }

    modifier onlyTicketSaleActive() {
        require(isTicketSaleActive, "Ticket sale is not active");
        _;
    }
    function setToken(address _token)external onlyOwner{
        token = IERC20Burnable(_token);
    }
    function changeMaxTicketLimit(uint256 _ticketsAmount) external onlyOwner{
        require(_ticketsAmount > 0,"Cannot update the ticketsamount to zero");
        ticketPurchaseLimit = _ticketsAmount;
    }
    function purchaseTicket() external payable onlyTicketSaleActive {
        uint256 purchasedTickets = ticketsPurchasedInRound[currentround].tickets[msg.sender];
        require(purchasedTickets < 1,"One user Cannot purchase more then one ticket");
        require(ticketsPurchasedInRound[currentround].TotalTicketsSoldInRound < ticketPurchaseLimit,"The tickets purchase limit has reached for this round!");
        require(msg.value == ticketPrice.mul(1), "Incorrect ETH amount sent");
        
        contractBalance = contractBalance.add(msg.value);
        ticketsPurchasedInRound[currentround].tickets[msg.sender] = ticketsPurchasedInRound[currentround].tickets[msg.sender].add(1);
        ticketsPurchasedInRound[currentround].TotalTicketsSoldInRound += 1 ;
        ticketsPurchasedInRound[currentround].participants.push(msg.sender);
        emit TicketsPurchased(msg.sender, 1);
    }

    function changeTicketPrice(uint256 newPrice) external onlyOwner {
        ticketPrice = newPrice;
        emit TicketPriceChanged(newPrice);
    }
    function calculateBuyBackAndMarketting()internal {
        if(address(token)!=address(0)){
          uint256 purchaseAmount = contractBalance.mul(5).div(100);
          uint256 marketingAmount = contractBalance.mul(5).div(100);
          // Perform Uniswap purchase logic using the uniswapV2Router
          buyAndBurn(purchaseAmount);
          payable(marketingWallet).transfer(marketingAmount);
        }
        else {
            uint256 marketingAmount = contractBalance.mul(10).div(100);
            payable(marketingWallet).transfer(marketingAmount);
        }
    }
    function claimPrize()external {
        require(checkIfWinner(msg.sender),"Only Winner can claim the prize");
        
        uint256 totalWinningAmount = contractBalance.mul(90).div(100);
        uint256 FirstPlaceAmount = totalWinningAmount.mul(50).div(100);
        uint256 SecondPlaceAmount = totalWinningAmount.mul(30).div(100);
        uint256 ThirdPlaceAmount = totalWinningAmount.mul(20).div(100);
        
        if(msg.sender == winners[0]){
            payable(winners[0]).transfer(FirstPlaceAmount);
            calculateBuyBackAndMarketting();
            winners[0] = address(0);
        }else if(msg.sender == winners[1]){
            payable(winners[1]).transfer(SecondPlaceAmount);
            winners[1] = address(0);
        }else if(msg.sender == winners[2]){
            payable(winners[2]).transfer(ThirdPlaceAmount);
            winners[2] = address(0);
        }
        // Check if all winners have claimed their prizes
         if (winners[0] == address(0) && winners[1] == address(0) && winners[2] == address(0)) {
        // Reset contract balance after all winners have claimed their prizes
        contractBalance = 0;
         //Move to the next round
        currentround +=1 ;
    }
        emit PrizeClaimed(winners,totalWinningAmount);

    }
    function resetLottery()external onlyOwner{
        delete winners;
        contractBalance=0;
        //Move to the next round
        currentround +=1 ;
    } 
    function announceWinner(address firstPlace,address secondPlace,address thirdPlace) external onlyOwner {
        require(ticketsPurchasedInRound[currentround].tickets[firstPlace] > 0, "First Place must have purchased tickets");
        require(ticketsPurchasedInRound[currentround].tickets[secondPlace] > 0, "First Place must have purchased tickets");
        require(ticketsPurchasedInRound[currentround].tickets[thirdPlace] > 0, "First Place must have purchased tickets");
        
        uint256 winningAmount = contractBalance.mul(90).div(100);
        winners[0] = (firstPlace);
        winners[1]= (secondPlace);
        winners[2]= (thirdPlace);
        emit WinnersAnnounced(winners, winningAmount);
       
    }

    function toggleTicketSale(bool isActive) external onlyOwner {
        isTicketSaleActive = isActive;
    }

    function buyAndBurn(uint256 amount)public{
        //Logic To Buy the tokens and burn them
        require(address(this).balance >= amount,"Not enough eth inside the contract to purchase the tokens!");
    
        address[] memory path = new address[](2) ;
        path[0] = router.WETH();
        path[1] = address(token); //the token address 
        
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:amount}(
            100,
            path,
            address(this),
            block.timestamp + 100
        );
        //Now burn the tokens
        uint256 tokensToBurn = token.balanceOf(address(this));
        token.burn(tokensToBurn);
    }
    function withdraw() payable external  onlyOwner{
        uint256 balance = address(this).balance ;
        require(balance > 0,"No ether to withdraw");
        payable (owner()).transfer(balance);
    }
    function getParticipants()external view returns(address[] memory){
        address[] storage participants = ticketsPurchasedInRound[currentround].participants;
        return(participants);
    }
    function checkIfWinner(address _address)internal view returns(bool){
        for (uint i=0; i<winners.length; i++) 
        {
            if(winners[i] == _address){
                return true;
            }

        }
        return false;
    }
    receive() external  payable {
        //For making the smart contract receive the ethers
    }

}