/**
 *Submitted for verification at Etherscan.io on 2023-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface lotteryInterface {
    function disperseTokenPercent(address token, address receiver, uint256 amount) external;
    function disperseTokenAmount(address token, address receiver, uint256 amount) external;
    function rescueETH(address receiver, uint256 amountPercentage) external;
    function lotteryTransaction(address user, uint256 amount) external;
    function setInitialData(uint256 _wild, address _token) external;
    function setMaxWinningsETH(uint256 amount) external;
    function setMaxWinningsToken(uint256 amount) external;
    function setETHCarryOverPercent(uint256 amount) external;
    function setTokenCarryOverPercent(uint256 amount) external;
    function resetTicketNumber(uint256 number) external;
    function setStartTime(uint256 time) external;
    function setTokenAddress(address _token) external;
    function toggleRunningDistributing(bool running, bool distributing) external;
    function setLotteryEnabled(bool enabled) external;
    function setLotteryInterval(uint256 amount) external;
    function setLotteryDoubleTime(uint256 amount) external;
    function setLotteryDuration(uint256 amount) external;
    function setWildcard(uint256 number) external;
    function toggleTokensETH(bool tokens, bool eth) external;
    function setLotteryIneligible(address user, bool ineligible) external;
    function setParameters(address _token) external;
    function closeLotteryEvent() external;
    function distributeLotteryEvent() external;
    function currentDoubleTime() external view returns (bool);
    function setAboveMinRequired(bool enabled) external;
    function viewAboveMinRequired() external view returns (bool);
    function viewLotteryIneligible(address user) external view returns (bool);
    function viewLastCompletedEvent() external view returns (uint256);
    function viewWinnings(address wallet) external view returns (uint256 tokens, uint256 eth);
    function viewStartEndDoubleTime() external view returns (uint256 doubleTimeStart, uint256 doubleTimeEnd);
    function viewLotteryEventData(uint256 _eventNumber) external view returns (address winningWallet, uint256 winningTicket, uint256 starttime, uint256 endtime, uint256 totaltickets, uint256 winnings);
    function viewLastLotteryEventData() external view returns (address winningWallet, uint256 winningTicket, uint256 starttime, uint256 endtime, uint256 totaltickets, uint256 winnings);
    function viewWalletLotteryData(address wallet) external view returns (uint256 totalTickets, uint256 totalETHWon, uint256 totalTokensWon);
    function viewWalletData(address user) external view returns (uint256 currentEventtickets, uint256 previousEventtickets, uint256 totalWallettickets, uint256 totalEventsWon, uint256 totaltokenspurchased, uint256 totalwinningsETH, uint256 totalwinningsToken, uint256 lastPurchasetime);
    function viewMinTokensHoldings() external view returns (uint256);
    function viewCarryOverTokenPercentage() external view returns (uint256);
    function viewCarryOverETHPercentage() external view returns (uint256);
    function viewMaxWinningsToken() external view returns (uint256);
    function viewMaxWinningsETH() external view returns (uint256);
    function viewWalletTicketsPurchased(address _wallet, uint256 _event) external view returns (uint256);
    function viewLotteryPurchase(uint256 _event, uint256 _ticket) external view returns (address);
    function viewCurrentLotteryAmount() external view returns (uint256);
    function viewMinPurchaseAmount() external view returns (uint256);
    function viewTotalTicketsAll() external view returns (uint256);
    function viewTotalWalletTickets(address wallet) external view returns (uint256);
    function viewTotalWalletWinningsETH(address wallet) external view returns (uint256);
    function viewTotalWalletWinningsTokens(address wallet) external view returns (uint256);
    function viewEventWinningTicket(uint256 _event) external view returns (uint256);
    function viewEventWinnings(uint256 _event) external view returns (uint256);
    function viewEventTotalTickets(uint256 _event) external view returns (uint256);
    function viewEventEndTime(uint256 _event) external view returns (uint256);
    function viewCurrentEventEndTime() external view returns (uint256);
    function viewEventStartTime(uint256 _event) external view returns (uint256);
    function viewEventWinner(uint256 _event) external view returns (address);
    function viewLastBuyer() external view returns (address);
    function viewLotteryInterval() external view returns (uint256);
    function viewDoubleTime() external view returns (uint256);
    function viewLotteryDuration() external view returns (uint256);
    function viewDistributingLottery() external view returns (bool);
    function viewLotteryEnabled() external view returns (bool);
    function viewLotteryRunning() external view returns (bool);
    function viewTotalWinningsToken() external view returns (uint256);
    function viewTotalWinningsETH() external view returns (uint256);
    function viewWinner() external view returns (address);
    function viewStartTime() external view returns (uint256);
    function viewTicketNumber() external view returns (uint256);
    function viewEventNumber() external view returns (uint256);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

contract lotteryInterfaceContract is Auth {
    using SafeMath for uint256;
    lotteryInterface public lotteryContract;
    constructor() Auth(msg.sender) {
        lotteryContract = lotteryInterface(0x34Bd681F2F0267d4dcb346fbD2156e8542392952);
    }
    
    receive() external payable {}

    function setInitialData(uint256 _wild, address _token) external authorized {
        lotteryContract.setInitialData(_wild, _token);
    }

    function setMaxWinningsETH(uint256 amount) external authorized {
        lotteryContract.setMaxWinningsETH(amount);
    }

    function setMaxWinningsToken(uint256 amount) external authorized {
        lotteryContract.setMaxWinningsToken(amount);
    }

    function setETHCarryOverPercent(uint256 amount) external authorized {
        lotteryContract.setETHCarryOverPercent(amount);
    }

    function setTokenCarryOverPercent(uint256 amount) external authorized {
        lotteryContract.setTokenCarryOverPercent(amount);
    }
    
    function resetTicketNumber(uint256 number) external authorized {
        lotteryContract.resetTicketNumber(number);
    }

    function setStartTime(uint256 time) external authorized {
        lotteryContract.setStartTime(time);
    }
    
    function setTokenAddress(address _token) external authorized {
        lotteryContract.setTokenAddress(_token);
    }
    
    function toggleRunningDistributing(bool running, bool distributing) external authorized {
        lotteryContract.toggleRunningDistributing(running, distributing);
    }

    function setAboveMinRequired(bool enabled) external authorized {
        lotteryContract.setAboveMinRequired(enabled);
    }
    
    function setLotteryEnabled(bool enabled) external authorized {
        lotteryContract.setLotteryEnabled(enabled);
    }
    
    function setLotteryInterval(uint256 amount) external authorized {
        lotteryContract.setLotteryInterval(amount);
    }

    function setLotteryDoubleTime(uint256 amount) external authorized {
        lotteryContract.setLotteryDoubleTime(amount);
    }

    function setLotteryDuration(uint256 amount) external authorized {
        lotteryContract.setLotteryDuration(amount);
    }

    function setWildcard(uint256 number) external authorized {
        lotteryContract.setWildcard(number);
    }

    function toggleTokensETH(bool tokens, bool eth) external authorized {
        lotteryContract.toggleTokensETH(tokens, eth);
    }

    function lotteryTransactionFull(address user, uint256 amount) external authorized {  
        lotteryContract.lotteryTransaction(user, amount);
    }

    function lotteryTransaction(address user) external authorized {  
        lotteryContract.lotteryTransaction(user, 100000000000000);
    }

    function closeLotteryEvent() external authorized {
        lotteryContract.closeLotteryEvent();
    }

    function distributeLotteryEvent() external authorized {
        lotteryContract.distributeLotteryEvent();
    }

    function viewWalletData(address user) external view returns (uint256 currentEventtickets, uint256 previousEventtickets, uint256 totalWallettickets, 
        uint256 totalEventsWon, uint256 totaltokenspurchased, uint256 totalwinningsETH, uint256 totalwinningsToken, uint256 lastPurchasetime) {
            return lotteryContract.viewWalletData(user);
    }

    function viewLotteryIneligible(address user) external view returns (bool) {
        return lotteryContract.viewLotteryIneligible(user);
    }

    function viewStartEndDoubleTime() external view returns (uint256 doubleTimeStart, uint256 doubleTimeEnd) {
        return lotteryContract.viewStartEndDoubleTime();
    }

    function viewLastCompletedEvent() external view returns (uint256) {
        return lotteryContract.viewLastCompletedEvent();
    }

    function currentDoubleTime() public view returns (bool) {
        return lotteryContract.currentDoubleTime();
    }

    function viewWinnings(address wallet) external view returns (uint256 tokens, uint256 eth) {
        return lotteryContract.viewWinnings(wallet);
    }

    function viewLastLotteryEventData() external view returns (address winningWallet, uint256 winningTicket, uint256 starttime, uint256 endtime, uint256 totaltickets, uint256 winnings) {
        return lotteryContract.viewLastLotteryEventData();
    }

    function viewLotteryEventData(uint256 _eventNumber) external view returns (address winningWallet, uint256 winningTicket, uint256 starttime, uint256 endtime, uint256 totaltickets, uint256 winnings) {
        return lotteryContract.viewLotteryEventData(_eventNumber);
    }

    function viewWalletLotteryData(address wallet) external view returns (uint256 totalTickets, uint256 totalETHWon, uint256 totalTokensWon) {
        return lotteryContract.viewWalletLotteryData(wallet);
    }

    function setLotteryIneligible(address user, bool ineligible) external authorized {
        lotteryContract.setLotteryIneligible(user, ineligible);
    }
    
    function setParameters(address _token) external authorized {
        lotteryContract.setParameters(_token);
    }
    
    function disperseInterfaceTokenPercent(address _token, address receiver, uint256 amount) external authorized {
        uint256 tokenAmt = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(receiver, (tokenAmt * amount / 100));
    }

    function disperseInterfaceTokenAmount(address _token, address receiver, uint256 amount) external authorized {
        IERC20(_token).transfer(receiver, amount);
    }

    function rescueInterfaceETH(address receiver, uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(receiver).transfer(amountETH * amountPercentage / 100);
    }

    function disperseLotteryTokenPercent(address _token, address receiver, uint256 amount) external authorized {
        lotteryContract.disperseTokenPercent(_token, receiver, amount);
    }

    function disperseLotteryTokenAmount(address _token, address receiver, uint256 amount) external authorized {
        lotteryContract.disperseTokenAmount(_token, receiver, amount);
    }

    function rescueLotteryETH(address receiver, uint256 amountPercentage) external authorized {
        lotteryContract.rescueETH(receiver, amountPercentage);
    }

    function viewCurrentLotteryAmount() external view returns (uint256) {
        return lotteryContract.viewCurrentLotteryAmount();
    }

    function viewTotalTicketsAll() external view returns (uint256) {
        return lotteryContract.viewTotalTicketsAll();
    }

    function viewAboveMinRequired() external view returns (bool) {
        return lotteryContract.viewAboveMinRequired();
    }

    function viewLastBuyer() external view returns (address) {
        return lotteryContract.viewLastBuyer();
    }

    function viewCurrentEventEndTime() external view returns (uint256) {
        return lotteryContract.viewCurrentEventEndTime();
    }

    function viewMinTokensHoldings() external view returns (uint256) {
        return lotteryContract.viewMinTokensHoldings();
    }

    function viewMinPurchaseAmount() external view returns (uint256) {
        return lotteryContract.viewMinPurchaseAmount();
    }

    function viewCarryOverTokenPercentage() external view returns (uint256) {
        return lotteryContract.viewCarryOverTokenPercentage();
    }

    function viewCarryOverETHPercentage() external view returns (uint256) {
        return lotteryContract.viewCarryOverETHPercentage();
    }

    function viewMaxWinningsToken() external view returns (uint256) {
        return lotteryContract.viewMaxWinningsToken();
    }

    function viewMaxWinningsETH() external view returns (uint256) {
        return lotteryContract.viewMaxWinningsETH();
    }

    function viewWalletTicketsPurchased(address _wallet, uint256 _event) external view returns (uint256) {
        return lotteryContract.viewWalletTicketsPurchased(_wallet, _event);
    }

    function viewLotteryPurchase(uint256 _event, uint256 _ticket) external view returns (address) {
        return lotteryContract.viewLotteryPurchase(_event, _ticket);
    }

    function viewTotalWalletTickets(address wallet) external view returns (uint256) {
        return lotteryContract.viewTotalWalletTickets(wallet);
    }

    function viewTotalWalletWinningsETH(address wallet) external view returns (uint256) {
        return lotteryContract.viewTotalWalletWinningsETH(wallet);
    }

    function viewTotalWalletWinningsTokens(address wallet) external view returns (uint256) {
        return lotteryContract.viewTotalWalletWinningsTokens(wallet);
    }

    function viewEventWinningTicket(uint256 _event) external view returns (uint256) {
        return lotteryContract.viewEventWinningTicket(_event);
    }

    function viewEventWinnings(uint256 _event) external view returns (uint256) {
        return lotteryContract.viewEventWinnings(_event);
    }

    function viewEventTotalTickets(uint256 _event) external view returns (uint256) {
        return lotteryContract.viewEventTotalTickets(_event);
    }

    function viewEventEndTime(uint256 _event) external view returns (uint256) {
        return lotteryContract.viewEventEndTime(_event);
    }

    function viewEventStartTime(uint256 _event) external view returns (uint256) {
        return lotteryContract.viewEventStartTime(_event);
    }

    function viewEventWinner(uint256 _event) external view returns (address) {
        return lotteryContract.viewEventWinner(_event);
    }

    function viewLotteryInterval() external view returns (uint256) {
        return lotteryContract.viewLotteryInterval();
    }

    function viewDoubleTime() external view returns (uint256) {
        return lotteryContract.viewDoubleTime();
    }

    function viewLotteryDuration() external view returns (uint256) {
        return lotteryContract.viewLotteryDuration();
    }

    function viewDistributingLottery() external view returns (bool) {
        return lotteryContract.viewDistributingLottery();
    }

    function viewLotteryEnabled() external view returns (bool) {
        return lotteryContract.viewLotteryEnabled();
    }

    function viewLotteryRunning() external view returns (bool) {
        return lotteryContract.viewLotteryRunning();
    }

    function viewTotalWinningsToken() external view returns (uint256) {
        return lotteryContract.viewTotalWinningsToken();
    }

    function viewTotalWinningsETH() external view returns (uint256) {
        return lotteryContract.viewTotalWinningsETH();
    }

    function viewWinner() external view returns (address) {
        return lotteryContract.viewWinner();
    }

    function viewStartTime() external view returns (uint256) {
        return lotteryContract.viewStartTime();
    }

    function viewTicketNumber() external view returns (uint256) {
        return lotteryContract.viewTicketNumber();
    }

    function viewEventNumber() external view returns (uint256) {
        return lotteryContract.viewEventNumber();
    }
}