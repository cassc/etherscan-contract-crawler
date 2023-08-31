/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

/**

https://coinrace.racing
https://t.me/CoinRacePortal
https://x.com/CoinRace_


**/


// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

abstract contract Context{
    function _msgSender() internal view virtual returns (address){
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address){
        return _owner;
    }

    modifier onlyOwner(){
        require(_owner == _msgSender(), "Ownerable: caller is not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
}

contract CoinRacing is Context, Ownable{

    using SafeMath for uint256;

    struct Pool {
        uint256 totalBet;
        mapping(address => uint256) bets;
    }

    Pool[10] public pools;
    uint256 public winningPool;

    bool public betFinalized = false;
    bool public drawMode = false;
    bool public isGameStart = false; 
    IERC20 private coins; 
    uint256 public totalCoinsToDistribute;
    address payable private _depolymentWallet;


    constructor(address _coins) {
        _depolymentWallet = payable(_msgSender());
        coins = IERC20(_coins);
    }

    function setGameStart(bool onoff) external {
        require(_msgSender() == _depolymentWallet);
        isGameStart = onoff;
    }

    function bet(uint256 amount,uint poolNumber) public payable {
        require(coins.balanceOf(_msgSender()) >= amount && coins.allowance(_msgSender(), address(this)) >= amount,"Don't have enough COINS");
        require(isGameStart, "The game hasn't started yet.");
        require(poolNumber < 10, "Invalid pool number.");
        require(!betFinalized, "Betting is finalized.");

        pools[poolNumber].bets[msg.sender] += amount;
        pools[poolNumber].totalBet += amount;

        coins.transferFrom(_msgSender(),address(this), amount);
    }

    function finalizeBet(uint _winningPool) external {
        require(_msgSender() == _depolymentWallet);
        winningPool = _winningPool; 
        betFinalized = true;
        totalCoinsToDistribute = coins.balanceOf(address(this));
    }



    function expectedClaim(uint256 amount, uint pool) public view returns(uint256 ){
        uint256 tempCoinsToDistribute = coins.balanceOf(address(this));
        uint256 share = amount.mul(tempCoinsToDistribute).div(pools[pool].totalBet.add(amount));
        return share;

    }


    function getClaim(address player) public view returns(uint256){
        uint256 winnerBet = pools[winningPool].bets[player];
        uint256 share = (winnerBet * totalCoinsToDistribute).div(
            pools[winningPool].totalBet
        );
        return share;
    }

    function getPoolsDetail() public view returns(uint256[10] memory){
        uint256[10] memory totalBets;
        for(uint  i =0; i<10; i++){
            totalBets[i] = pools[i].totalBet;
        }
        return totalBets;
    }

    function getBetDetail(address player) public view returns(uint256[10] memory){
        uint256[10] memory totalBets;
        for(uint  i =0; i<10; i++){
            totalBets[i] = pools[i].bets[player];
        }
        return totalBets;
    }

    function claim() public {
        require(betFinalized, "Betting is not finalized yet.");
        require(
            pools[winningPool].bets[msg.sender] > 0,
            "No bet in the winning pool."
        );
        uint256 winnerBet = pools[winningPool].bets[msg.sender];

        uint256 share = winnerBet.mul(totalCoinsToDistribute).div(
            pools[winningPool].totalBet
        );
        pools[winningPool].bets[msg.sender] = 0;

        IERC20(coins).transfer(msg.sender, share);
    }

    function clearStuckBalance(address token,uint256 amountPercentage) external onlyOwner{
        if(token == address(0)){
		uint256 amountToClear = amountPercentage.mul(address(this).balance).div(100);
		payable(msg.sender).transfer(amountToClear);
        }else{
        uint256 caBalances = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amountPercentage.mul(caBalances).div(100));
        }
	}
}