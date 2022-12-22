// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICOMM {
    function handleComm(address _fromUser, uint _amount, IERC20 tokenBuy) external;
}
interface IPancakeRouter {
    function getAmountsOut(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract LotterySOW is Ownable {
    IPancakeRouter public pancakeRouter;
    address public immutable BUSD;
    address public immutable WBNB;

    using SafeERC20 for IERC20;
    address public asset2BuyAdress;
    ICOMM public commTreasury;
    mapping(uint => bool) public nonces;
    address[] public top10Winner;
    address[] public top10Player;
    uint public indexTop10Winner;
    uint public indexTop10Player;

    struct Pool {
        uint minTokenAmount; // BUSD
        uint maxTokenAmount; // BUSD
        uint decimal;
        uint referCommission; // decimal 100
        bool isOpen;
    }
    struct Spin {
        uint pid;
        uint number;
        uint amountToken;
        bool result;
        uint resultNumber;
        uint timestamp;
    }
    struct RewardInfo {
        uint pid;
        uint amount;
        uint resultNumber;
    }
    struct User {
        uint totalSpin;
        uint totalWin;
        bool top10Winner;
        bool top10Player;
        uint[] rewards;
        Spin[] spins;
        mapping(uint => RewardInfo) rewardInfo;
    }

    Pool[] public poolsLottery;
    mapping(address => User) public users;
    mapping(address => mapping(uint => uint)) public userSpined; // user => datetime => spined
    mapping(address => uint) public userTotalSpined; // user => spined

    constructor(IPancakeRouter _pancakeRouteAddress, address _WBNBAddress, address _BUSDAddress, ICOMM _commTreasury, address _asset2BuyAdress) {
        pancakeRouter = _pancakeRouteAddress;
        WBNB = _WBNBAddress;
        BUSD = _BUSDAddress;
        asset2BuyAdress = _asset2BuyAdress;
        commTreasury = _commTreasury;
    }
    function pools(uint pid) external view returns(uint minTokenAmount, uint maxTokenAmount, uint decimal, uint referCommission, bool isOpen) {
        Pool memory p = poolsLottery[pid];
        minTokenAmount = busd2Token(asset2BuyAdress, p.minTokenAmount);
        maxTokenAmount = busd2Token(asset2BuyAdress, p.maxTokenAmount);
        decimal = p.decimal;
        referCommission = p.referCommission;
        isOpen = p.isOpen;
    }
    function bnbPrice() public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = WBNB;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }

    function tokenPrice(address token) public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = BUSD;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }
    function busd2Token(address token, uint busd) public view returns (uint amount){
        uint[] memory amounts = tokenPrice(token);
        amount = amounts[0] * busd / 1 ether;
    }
    function setAsset2BuyAdress(address _asset2BuyAdress) external onlyOwner {
        asset2BuyAdress = _asset2BuyAdress;
    }
    function setTreasury(ICOMM _commTreasury) external onlyOwner {
        commTreasury = _commTreasury;
    }
    function getUserReward(address _user) external view returns(RewardInfo[] memory list, uint[] memory _users) {
        uint length = users[_user].rewards.length;
        list = new RewardInfo[](length);
        for(uint i = 0; i < length; i++) {
            list[i] = users[_user].rewardInfo[users[_user].rewards[i]];
        }
        _users = users[_user].rewards;
    }
    function getReward(address _user) external view returns(RewardInfo[] memory list, uint[] memory _users) {
        uint length = users[_user].rewards.length;
        list = new RewardInfo[](length);
        for(uint i = 0; i < length; i++) {
            list[i] = users[_user].rewardInfo[users[_user].rewards[i]];
        }
        _users = users[_user].rewards;
    }
    function getUserSpins(address _user, uint _limit, uint _skip) external view returns(Spin[] memory list, uint totalItem) {
        totalItem = users[_user].spins.length;
        if(totalItem > 0 && totalItem >= _skip) {
            uint limit = totalItem >= _skip ? totalItem - _skip : 0;

            if(limit > 0) {
                uint limitIndex = limit >= _limit ? limit - _limit : 0;
                uint lengthReturn = _limit <= totalItem - _skip ? _limit : totalItem - _skip;
                list = new Spin[](lengthReturn);
                uint index = limit-1;
                for(uint i = index; i >= limitIndex; i--) {
                    list[index - i] = users[_user].spins[i];
                    if(i == 0) break;
                }
            }
        }
    }
    function getTop10Winner() external view returns(address[]memory) {
        return top10Winner;
    }
    function getTop10Player() external view returns(address[] memory) {
        return top10Player;
    }
    function setTop10Winner() internal {
        if(!users[msg.sender].top10Winner) {
            if(top10Winner.length < 10) {
                top10Winner.push(msg.sender);
                users[msg.sender].top10Winner = true;
            } else {
                if(users[msg.sender].totalWin > users[top10Winner[indexTop10Winner]].totalWin) {
                    users[top10Winner[indexTop10Winner]].top10Winner = false;
                    top10Winner[indexTop10Winner] = msg.sender;
                    users[msg.sender].top10Winner = true;
                    resetIndexWinner();
                }
            }
        }
    }
    function setTop10Player() internal {
        if(!users[msg.sender].top10Player) {
            if(top10Player.length < 10) {
                top10Player.push(msg.sender);
                users[msg.sender].top10Player = true;
            } else {
                if(users[msg.sender].totalSpin > users[top10Player[indexTop10Player]].totalSpin) {
                    users[top10Player[indexTop10Player]].top10Player = false;
                    top10Winner[indexTop10Player] = msg.sender;
                    users[msg.sender].top10Player = true;
                    resetIndexPlayer();
                }
            }
        }
    }
    function resetIndexWinner() internal {
        uint smallest = users[top10Winner[indexTop10Winner]].totalWin;
        for(uint i = 0; i < 10; i++) {
            if(smallest > users[top10Winner[i]].totalWin) {
                smallest = users[top10Winner[i]].totalWin;
                indexTop10Winner = i;
            }
        }
    }
    function resetIndexPlayer() internal {
        uint smallest = users[top10Player[indexTop10Player]].totalSpin;
        for(uint i = 0; i < 10; i++) {
            if(smallest > users[top10Player[i]].totalSpin) {
                smallest = users[top10Player[i]].totalSpin;
                indexTop10Player = i;
            }
        }
    }

    function getDate() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
    function random(uint nonce, uint percentDecimal) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce, address(this))))%percentDecimal;
    }

    function spins(uint _pid, uint[] memory _nonces, uint[] memory numbers, uint[] memory _amounts) external {
        for(uint i = 0; i < numbers.length; i++) {
            spin(_pid, _nonces[i], numbers[i], _amounts[i]);
        }
    }
    function spin(uint _pid, uint nonce, uint number, uint amount) public {
        require(!nonces[nonce], "Lottery::spin: nonce used");
        Pool storage p = poolsLottery[_pid];
        require(p.isOpen, "Lottery::spin: _pid is not exist");
        require(number < p.decimal, "Lottery::spin: number invalid");
        uint minTokenAmount = busd2Token(asset2BuyAdress, p.minTokenAmount);
        uint maxTokenAmount = busd2Token(asset2BuyAdress, p.maxTokenAmount);
        require(amount >= minTokenAmount && amount < maxTokenAmount, "Lottery::spin: amount invalid");

        uint reward = amount * (p.decimal - p.decimal / 10);
        uint comm = p.referCommission * amount / 100;

        uint256 date = getDate();
        userSpined[_msgSender()][date]++;
        userTotalSpined[_msgSender()]++;

        User storage user = users[_msgSender()];

        user.totalSpin += amount;

        IERC20(asset2BuyAdress).transferFrom(_msgSender(), address(commTreasury), comm);
        IERC20(asset2BuyAdress).transferFrom(_msgSender(), address(this), amount-comm);

        commTreasury.handleComm(_msgSender(), comm, IERC20(asset2BuyAdress));
        setTop10Player();
        uint resultNumber = random(nonce, p.decimal);
        nonces[nonce] = true;
        bool result = resultNumber == number;
        user.spins.push(Spin(_pid, number, amount, result, resultNumber, block.timestamp));
        if(result) {
            IERC20(asset2BuyAdress).transfer(_msgSender(), reward);
            user.totalWin += reward;
            user.rewards.push(block.timestamp);
            user.rewardInfo[block.timestamp] = RewardInfo(_pid, reward, resultNumber);
            setTop10Winner();
        }
    }
    function togglePool(uint _pid, bool _isOpen) public onlyOwner {
        Pool storage p = poolsLottery[_pid];
        require(p.minTokenAmount > 0, "Lottery::togglePool pool is not exist");
        p.isOpen = _isOpen;
    }
    function updateLimitBuyPool(uint _pid, uint _minTokenAmount, uint _maxTokenAmount) public onlyOwner {
        Pool storage p = poolsLottery[_pid];
        require(p.isOpen, "Lottery::updatePool pool is not open");
        p.minTokenAmount = _minTokenAmount;
        p.maxTokenAmount = _maxTokenAmount;
    }
    function updatePool(uint _pid, uint _referCommission) public onlyOwner {
        Pool storage p = poolsLottery[_pid];
        require(p.isOpen, "Lottery::updatePool pool is not open");
        p.referCommission = _referCommission;
    }
    function addPool(uint _minTokenAmount, uint _maxTokenAmount, uint _decimal, uint _referCommission) public onlyOwner {
        require(_minTokenAmount > 0 && _maxTokenAmount > _minTokenAmount, "Lottery::addPool _price invalid");
//        if(_poolReward > 0) IERC20(asset2BuyAdress).safeTransferFrom(_msgSender(), address(this), _poolReward);
        poolsLottery.push(Pool(_minTokenAmount, _maxTokenAmount, _decimal, _referCommission, true));
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}