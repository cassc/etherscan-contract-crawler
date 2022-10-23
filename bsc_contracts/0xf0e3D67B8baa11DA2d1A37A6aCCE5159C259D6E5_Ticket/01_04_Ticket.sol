// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) virtual external returns (bool);

    function transfer(address to, uint256 amount) public virtual returns (bool);
}

contract Ticket is Ownable, ReentrancyGuard {
    event reportWinner(address winner, uint256 time, uint256 bonus);

    struct WinnerStruct {
        address winner;
        uint256 bonus;
        uint256 time;
        uint8 status;
    }

    uint256 public ticketPrice;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint256) userBuyTotalMoney;
    mapping(address => uint256) refTotalMoney;
    address[] smallTicketUserList;
    WinnerStruct[] smallWinnerWithdraw;
    uint256 public smallWinnerBonus;
    uint[] public bigWinnerWithdrawRate;
    uint256 public totalBonus;
    mapping(uint256 => WinnerStruct[]) private bigWinnerWithdraw;
    mapping(uint256 => uint8) private bigRoundHiveOpen;
    address[10] private bigWinnerList;
    uint256 private bigRound = 0;
    uint256 private _numberSmallRound = 1;
    address public usdtAddress;
    address public inviteWallet;
    address public nextWallet;
    address public feeWallet;
    uint256[] addTime;
    uint256 public bigTotalJoinCount;
    bool public gameStatus;


    constructor(uint256[] memory _bigWinnerWithdrawRate, uint256 _smallWinnerBonus, uint256 _ticketPrice,
        address _usdtAddress, address _inviteWallet, address _nextWallet,address _feeWallet, uint256[] memory _addTime){
        bigWinnerWithdrawRate = _bigWinnerWithdrawRate;
        smallWinnerBonus = _smallWinnerBonus;
        ticketPrice = _ticketPrice;
        usdtAddress = _usdtAddress;
        inviteWallet = _inviteWallet;
        nextWallet = _nextWallet;
        feeWallet = _feeWallet;
        addTime = _addTime;
    }

    function buyTicket(address ref) public callerIsUser nonReentrant {
        require(block.timestamp >= startTime, "game not start");
        require(gameStatus, "game not start");
        require(endTime >= block.timestamp, "game end");
        if (ref == msg.sender || ref == address(0) || ref == address(0x000000000000000000000000000000000000dEaD)) {
            ref = inviteWallet;
        }
        refTotalMoney[ref] = refTotalMoney[ref] + ticketPrice / 10;
        IERC20(usdtAddress).transferFrom(msg.sender, ref, ticketPrice / 10);
        IERC20(usdtAddress).transferFrom(msg.sender, address(this), ticketPrice - ticketPrice / 10);
        userBuyTotalMoney[msg.sender] = userBuyTotalMoney[msg.sender] + ticketPrice;
        bigTotalJoinCount++;
        uint256 currentStep = bigTotalJoinCount / 1000;
        if (currentStep >= addTime.length) {
            currentStep = addTime.length - 1;
        }
        endTime = endTime + addTime[currentStep];
        if (endTime - block.timestamp > 3600) {
            endTime = block.timestamp + 3600;
        }
        smallTicketUserList.push(msg.sender);
        if (smallTicketUserList.length >= 50) {
            WinnerStruct memory smallWinner = WinnerStruct(smallTicketUserList[getRandom(50)], smallWinnerBonus, block.timestamp, 2);
            smallWinnerWithdraw.push(smallWinner);
            _numberSmallRound++;
            delete smallTicketUserList;
            totalBonus -= smallWinnerBonus;
            IERC20(usdtAddress).transfer(smallWinner.winner, smallWinnerBonus);
            emit reportWinner(smallWinner.winner, smallWinner.time, smallWinner.bonus);
        }
        removeAndAddLast(msg.sender);
        totalBonus += ticketPrice - ticketPrice / 10;
        if (bigTotalJoinCount / 1000 >= addTime.length - 1) {
            if (getRandom(1000) == 1) {
                gameStatus = false;
            }
        }
    }

    function openBig() internal {
        require(block.timestamp >= endTime || !gameStatus, "game not end");
        require(bigRoundHiveOpen[bigRound] != 1, "have open");
        gameStatus = false;
        uint256 totalSendWinnerBonus = 0;
        for (uint i = 0; i < bigWinnerList.length; i++) {
            WinnerStruct memory bigWinner = WinnerStruct(bigWinnerList[i], totalBonus * bigWinnerWithdrawRate[i] / 100000000, block.timestamp, 2);
            bigWinnerWithdraw[bigRound].push(bigWinner);
            IERC20(usdtAddress).transfer(bigWinnerList[i], bigWinner.bonus);
            totalSendWinnerBonus = totalSendWinnerBonus + bigWinner.bonus;
            emit reportWinner(bigWinner.winner, bigWinner.time, bigWinner.bonus);
        }
        uint256 fee = totalBonus * 15 / 100;
        IERC20(usdtAddress).transfer(feeWallet, fee);
        IERC20(usdtAddress).transfer(nextWallet, totalBonus - totalSendWinnerBonus - fee);
        bigRoundHiveOpen[bigRound] = 1;
        totalBonus = 0;
    }

    function endGame() external onlyOwner {
        openBig();
    }

    function initStartGame(uint256 _startTime, uint256 _endTime) external onlyOwner {
        gameStatus = true;
        startTime = _startTime;
        endTime = _endTime;
    }

    function startGame(uint256 _startTime, uint256 _endTime, uint256[] memory _addTime, uint256 initBouns) external onlyOwner {
        bigRound++;
        startTime = _startTime;
        endTime = _endTime;
        addTime = _addTime;
        delete smallTicketUserList;
        delete bigWinnerList;
        gameStatus = true;
        bigTotalJoinCount = 0;
        IERC20(usdtAddress).transferFrom(nextWallet, address(this), initBouns);
        totalBonus = totalBonus + initBouns;
    }

    function querySomeInfo() external view returns (uint256[] memory){
        uint256[] memory resultList = new uint256[](5);
        resultList[0] = startTime;
        resultList[1] = endTime;
        resultList[2] = totalBonus;
        resultList[3] = userBuyTotalMoney[msg.sender];
        resultList[4] = refTotalMoney[msg.sender];
        return resultList;
    }

    function querySmallWinnerList() external view returns (WinnerStruct[] memory){
        return smallWinnerWithdraw;
    }

    function queryBigWinnerWithdraw(uint round) external view returns (WinnerStruct[] memory){
        return bigWinnerWithdraw[round];
    }

    function queryBigWinnerList() external onlyOwner view returns (address[10] memory){
        return bigWinnerList;
    }

    function queryUserBuyTotalMoney() external view returns (uint256){
        return userBuyTotalMoney[msg.sender];
    }

    function queryRefTotalMoney() external view returns (uint256){
        return refTotalMoney[msg.sender];
    }

    function setBigWinnerWithdrawRate(uint256[] memory newPrice) external onlyOwner {
        bigWinnerWithdrawRate = newPrice;
    }

    function setTicketPrice(uint256 newPrice) external onlyOwner {
        ticketPrice = newPrice;
    }

    function setSmallWinnerBonus(uint256 newPrice) external onlyOwner {
        smallWinnerBonus = newPrice;
    }
    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }
    function removeAndAddLast(address user) internal {
        for (uint i = 0; i < bigWinnerList.length - 1; i++) {
            bigWinnerList[i] = bigWinnerList[i + 1];
        }
        bigWinnerList[bigWinnerList.length - 1] = user;
    }
    function getRandom(uint256 num) internal view returns (uint256) {
    unchecked {
        uint256 pos = unsafeRandom() % num;
        return pos;
    }
    }

    function unsafeRandom() internal view returns (uint256) {
    unchecked {
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                block.difficulty,
                block.timestamp,
                block.coinbase,
                _numberSmallRound,
                bigTotalJoinCount,
                tx.origin
            )));
    }
    }
}