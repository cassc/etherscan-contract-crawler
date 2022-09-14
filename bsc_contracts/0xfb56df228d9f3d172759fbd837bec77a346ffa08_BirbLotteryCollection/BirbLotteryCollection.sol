/**
 *Submitted for verification at BscScan.com on 2022-09-13
*/

/*  
Birb Lottery Collection

Created, deployed, run, managed and maintained by CodeCraftrs
https://codecraftrs.com
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.17;

interface IBEP20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
}

interface ICCVRF {
    function requestRandomness(uint256 requestID, uint256 howManyNumbers) external payable;
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract BirbLotteryCollection {
    address public constant CEO = 0x7D70D9EDFa339895914A87E590921c0EECb3c2CC;
    address public constant CC = 0x7c4ad2B72bA1bDB68387E0AE3496F49561b45625;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IDEXRouter private router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IBEP20 public BIRB = IBEP20(0x88888888Fc33e4ECba8958c0c2AD361089E19885); 
    ICCVRF public randomnessSupplier = ICCVRF(0xC0de0aB6E25cc34FB26dE4617313ca559f78C0dE);
    
    uint256 private vrfCost = 0.002 ether;
    uint256 public priceOfTicketBurnLottery = 10;
    uint256 public maxTicketsPerWallet = 10;
    uint256 public maxTicketsPerDraw = 50;
    uint256 public chanceToWinSuperJackpot = 10000;
    uint256 public ticketPrice = 500;
    uint256 public minBuy = 0.02 ether;
    uint256 public maxBuy = 1 ether;
    
    bool public burnJackpotIsOpen = true;
    bool public maintenanceMode;
    
    address[] public players;
    address[] public stillGetMoney;
    uint256[] public howMuch;
    mapping (uint256 => uint256) public whichLottery;
    mapping (uint256 => uint256) public birbAtNonce;
    mapping (uint256 => address) public playerAtNonce;
    mapping (uint256 => bool) public nonceProcessed;


    uint256 private nonce;
    uint256 private decimals;
    uint256 public burnJackpot;
    uint256 public superJackpot;
    uint256 public birbToBurn;
    uint256 public totalTicketsSoldInThisLottery;
    
    event Winner(address winner, uint256 tokensWon, uint256 lotteryID);
    event WinnerToBePaid(address winner, uint256 tokensWon, uint256 _nonce, uint256 lotteryID);

    modifier onlyOwner() {if(msg.sender != CEO && msg.sender != CC) return; _;}
    modifier onlyVRF() {if(msg.sender != address(randomnessSupplier)) return; _;}

    constructor() {
        decimals = BIRB.decimals();
    }

    receive() external payable {}

    function BetBirb() external payable {
        require(!maintenanceMode, "Lottery is currently suspended");
        require(msg.value >= vrfCost, "Randomness has a price!");
        IBEP20(BIRB).transferFrom(msg.sender, address(this), ticketPrice * (10**BIRB.decimals()));
        whichLottery[nonce] = 2;
        playerAtNonce[nonce] = msg.sender;
        randomnessSupplier.requestRandomness{value: vrfCost}(nonce, 1);
        nonce++;
    }

    function BuyBurn(uint256 tickets) external payable {
        require(!maintenanceMode, "Lottery is currently suspended");
        require(burnJackpotIsOpen, "Jackpot is full, please wait");
        require(msg.value >= vrfCost*6/5, "Randomness has a price");
        require(tickets + getTicketsBought(msg.sender) <= maxTicketsPerWallet, "Trying to buy too many tickets");
        
        if(totalTicketsSoldInThisLottery + tickets > maxTicketsPerDraw) tickets = maxTicketsPerDraw - totalTicketsSoldInThisLottery;
        totalTicketsSoldInThisLottery += tickets;

        uint256 tokensToSend = tickets * priceOfTicketBurnLottery * (10**decimals);

        BIRB.transferFrom(msg.sender, address(this), tokensToSend);
        burnJackpot += tokensToSend / 2;
        superJackpot += tokensToSend / 10;
        birbToBurn += tokensToSend * 4 / 10;
        for(uint256 i= 1; i<=tickets; i++) players.push(msg.sender);

        // getBonusTicket
        whichLottery[nonce] = 11;
        playerAtNonce[nonce] = msg.sender;
        randomnessSupplier.requestRandomness{value: vrfCost}(nonce, 1);
        nonce++;

        // if the jackpot is full, draw a winner
        if(players.length >= maxTicketsPerDraw) drawBurnWinner();
    }

    function betBnbToWinBirb() external payable {
        require(!maintenanceMode, "Lottery is currently suspended");
        require(msg.value >= minBuy, "Minimum bet not reached");
        require(msg.value <= maxBuy, "Maximum bet exceeded");

        uint256 balanceNow = BIRB.balanceOf(address(this));
        buyBirbWithBnb(msg.value - 0.002 ether);
        uint256 birbBought = BIRB.balanceOf(address(this)) - balanceNow;

        whichLottery[nonce] = 3;
        playerAtNonce[nonce] = msg.sender;
        birbAtNonce[nonce] = birbBought;
        randomnessSupplier.requestRandomness{value: vrfCost}(nonce, 1);
        nonce++;
    }

    function supplyRandomness(uint256 _nonce,uint256[] memory randomNumbers) external onlyVRF {
        if(whichLottery[_nonce] == 1) {
            if(nonceProcessed[_nonce]) return;
            address winnerAdd = players[(randomNumbers[0] % players.length)];
            BIRB.transfer(winnerAdd, burnJackpot);
            BIRB.transfer(DEAD, birbToBurn);
            nonceProcessed[_nonce] = true;
            emit Winner(winnerAdd, burnJackpot, 1);
            birbToBurn = 0;
            burnJackpot = 0;
            burnJackpotIsOpen = true;
            delete players;
            totalTicketsSoldInThisLottery = 0;   
        }

        if(whichLottery[_nonce] == 11 && randomNumbers[0] % chanceToWinSuperJackpot == 0) {
            if(nonceProcessed[_nonce]) return;
            address winner = playerAtNonce[_nonce];
            IBEP20(BIRB).transfer(winner,superJackpot);
            nonceProcessed[_nonce] = true;
            emit Winner(winner, superJackpot, 11);
            superJackpot = 0;
        }

        if(whichLottery[_nonce] == 2) {
            if(nonceProcessed[_nonce]) return;
            uint256 rand = randomNumbers[0] % 10000;
            address winner = playerAtNonce[_nonce];
            uint256 prizeMoney = 10**decimals;

            if(rand == 0) prizeMoney *= ticketPrice * 200;
            else if(rand <= 10)  prizeMoney *= ticketPrice * 100;
            else if(rand <= 210)  prizeMoney *= ticketPrice * 10;
            else if(rand <= 1110)  prizeMoney *= ticketPrice * 5;
            else if(rand <= 2110)  prizeMoney *= ticketPrice * 2;

            if(prizeMoney > 0) {
                if(prizeMoney>BIRB.balanceOf(address(this)) - (burnJackpot + birbToBurn + superJackpot)) {
                    stillGetMoney.push(winner);
                    howMuch.push(prizeMoney);
                    emit WinnerToBePaid(winner, prizeMoney, _nonce, 2);
                    maintenanceMode = true;
                    nonceProcessed[_nonce] = true;
                    return;
                }
                BIRB.transfer(winner,prizeMoney);
                nonceProcessed[_nonce] = true;
                emit Winner(winner, prizeMoney, 2);
            }
            return;
        }

        if(whichLottery[_nonce] == 3) {
            if(nonceProcessed[_nonce]) return;
            uint256 rand = randomNumbers[0] % 10000;
            uint256 birbBoughtAtNonce = birbAtNonce[_nonce];
            address winner = playerAtNonce[_nonce];
            uint256 prizeMoney;

            if(rand == 0)  prizeMoney = birbBoughtAtNonce * 10;
            else if(rand <= 10)  prizeMoney = birbBoughtAtNonce * 5;
            else if(rand <= 1510)  prizeMoney = birbBoughtAtNonce * 2;
            else if(rand <= 6510)  prizeMoney = birbBoughtAtNonce;
            else prizeMoney = birbBoughtAtNonce / 2;

            if(prizeMoney > 0) {
                if(prizeMoney>BIRB.balanceOf(address(this)) - (burnJackpot + birbToBurn + superJackpot)) {
                    stillGetMoney.push(winner);
                    howMuch.push(prizeMoney);
                    emit WinnerToBePaid(winner, prizeMoney, _nonce, 3);
                    maintenanceMode = true;
                    nonceProcessed[_nonce] = true;
                    return;
                }
                BIRB.transfer(winner,prizeMoney);
                nonceProcessed[_nonce] = true;
                emit Winner(winner, prizeMoney, 3);
            }
            return;
        }
    }

    function getTicketsBought(address player) public view returns (uint256) {
        uint256 ticketsOfPlayer;
        for(uint256 i= 0; i < players.length; i++) if(players[i] == player) ticketsOfPlayer++;
        return ticketsOfPlayer;
    }
    
    function  buyBirbWithBnb(uint256 bnbToSpend) internal {
        address[] memory pathFromBNBToBIRB = new address[](2);
        pathFromBNBToBIRB[0] = router.WETH();
        pathFromBNBToBIRB[1] = address(BIRB);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbToSpend}(
            0,
            pathFromBNBToBIRB,
            address(this),
            block.timestamp
        );
    }

    function drawBurnWinner() internal {
        whichLottery[nonce] = 1;
        randomnessSupplier.requestRandomness{value: vrfCost}(nonce, 1);
        nonce++;
        burnJackpotIsOpen = false;
    }

    function rescueAnyToken(address token) external onlyOwner {
        IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }
    
    function rescueBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function activateMaintenanceMode() external onlyOwner{
        maintenanceMode = true;
    }

    function deactivateMaintenanceMode() external onlyOwner{
        if(stillGetMoney.length != 0){
            for(uint256 i= 0; i<stillGetMoney.length; i++) {
                BIRB.transfer(stillGetMoney[i], howMuch[i]);
                emit Winner(stillGetMoney[i], howMuch[i], 99);
            }
        }
        maintenanceMode = false;
    }
}