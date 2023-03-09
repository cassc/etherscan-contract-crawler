pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IDEXRouter {
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external pure returns(uint256[] memory);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

contract DuelGame is Ownable {
  address public BUSD = block.chainid==56 ? 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 : 0xaB1a4d4f1D656d2450692D237fdD6C7f9146e814;
  address public WBNB = block.chainid==56 ? 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c : 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  uint256 public duelCounter;
  uint256 public invitePeriod = block.chainid==56 ? 6 hours : 3 minutes;
  uint256 public duelLength = block.chainid==56 ? 24 hours : 5 minutes;
  struct Duel {
    address wallet1;
    address wallet2;
    uint256 depositAmount;
    uint256 price1;
    uint256 price2;
    uint256 resultPrice;
    uint8 categoryIndex;
    uint256 createdTime;
    uint8 status;
  }

  mapping(uint256 => Duel) public duels;
  uint256[] public amountArr = [0.003 ether, 0.02 ether, 0.04 ether, 0.08 ether, 0.15 ether, 0.35 ether, 0.8 ether, 1.5 ether, 3 ether, 6 ether];
  address public royaltyWallet1;
  address public royaltyWallet2;
  address public royaltyWallet3;
  uint256 public fee1;
  uint256 public fee2;
  uint256 public fee3;
  IDEXRouter router;
  address public botAddress;
  bool public paused;
  mapping(address => mapping(uint8=> bool)) public walletToCategory;

  bool public disableTokenHold;
  uint256 public holdAmount;
  address public duelToken;
  mapping(address => bool) public whitelistedWallets;

  event DUELS_CREATED(uint256 indexed duelID, address indexed player1);
  event DUELS_CANCELED(uint256 indexed duelID, address indexed player1);
  event DUELS_JOINED(uint256 indexed duelID, address indexed player1, address indexed player2);
  event DUELS_FINISHED(uint256 indexed duelID, address indexed player1, address indexed player2);
  modifier onlyBot() {
    require(msg.sender == botAddress || msg.sender == owner(), "not bot");
    _;
  }
  modifier notPaused() {
    require(paused==false, "paused");
    _;
  }
  modifier onlyTokenHolder {
    require(IERC20(duelToken).balanceOf(msg.sender)>=holdAmount || disableTokenHold || whitelistedWallets[msg.sender], "not whitelisted");
    _;
  }
  constructor () {
    router = IDEXRouter(block.chainid==56 ? 0x10ED43C718714eb63d5aA57B78B54704E256024E : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    royaltyWallet1 = msg.sender;
    royaltyWallet2 = msg.sender;
    royaltyWallet3 = msg.sender;
    fee1 = 7;
    fee2 = 8;
    fee3 = 6;
    botAddress = msg.sender;
  }
 
  function isContract(address addr) private returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
  
  function createDuelForBNB(uint8 _categoryIndex, uint256 _price1) external payable notPaused {
    require(_categoryIndex<=9, "out of range");
    require(msg.value == amountArr[_categoryIndex], "not matching amount");
    require(!walletToCategory[msg.sender][_categoryIndex], "already create for this division");
    duels[duelCounter] = Duel(msg.sender, address(0), amountArr[_categoryIndex], _price1, 0, 0, _categoryIndex, block.timestamp, 1); 
    emit DUELS_CREATED(duelCounter, msg.sender);
    duelCounter++;
    walletToCategory[msg.sender][_categoryIndex] = true;
  }

  function cancelDuel(uint256 duelId) external {
    require(duels[duelId].wallet1==msg.sender, "not matching wallet");
    require(duels[duelId].status == 1, "not matching status");
    payable(duels[duelId].wallet1).transfer(duels[duelId].depositAmount);
    walletToCategory[duels[duelId].wallet1][duels[duelId].categoryIndex] = false;
    emit DUELS_CANCELED(duelId, duels[duelId].wallet1);
    duels[duelId] = duels[duelCounter];
    duelCounter--;
  }
  
  function joinDuelForBNB(uint256 duelId, uint256 _price2) external payable notPaused {
    require(block.timestamp<=duels[duelId].createdTime+invitePeriod, "expired duel");
    require(msg.sender!=duels[duelId].wallet1, "same wallet");
    require(msg.value==amountArr[duels[duelId].categoryIndex], "not matching amount");
    require(duels[duelId].status==1, "not matching status");
    duels[duelId].wallet2 = msg.sender;
    duels[duelId].depositAmount*=2;
    duels[duelId].price2 = _price2;
    duels[duelId].status = 2;
    emit DUELS_JOINED(duelId, duels[duelId].wallet1, duels[duelId].wallet2);
  }
  function finishDuel(uint256 duelId) external {
    require(duels[duelId].status == 2 && duels[duelId].resultPrice==0, "condition not meet");
    require(block.timestamp>=duels[duelId].createdTime+duelLength, "not reached time");
    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = BUSD;
    duels[duelId].resultPrice = router.getAmountsOut(1 ether, path)[1];
    uint256 diff1 = duels[duelId].resultPrice >= duels[duelId].price1 ? duels[duelId].resultPrice - duels[duelId].price1 : duels[duelId].price1 - duels[duelId].resultPrice;
    uint256 diff2 = duels[duelId].resultPrice >= duels[duelId].price2 ? duels[duelId].resultPrice - duels[duelId].price2 : duels[duelId].price2 - duels[duelId].resultPrice;
    uint256 amount1 = duels[duelId].depositAmount*fee1/100;
    uint256 amount2 = duels[duelId].depositAmount*fee2/100;
    uint256 amount3 = duels[duelId].depositAmount*fee3/100;
    uint256 restAmount = duels[duelId].depositAmount - amount1 - amount2 - amount3;
    if(diff1>diff2) { // wallet2 wins
      payable(royaltyWallet1).transfer(amount1);
      payable(royaltyWallet2).transfer(amount2);
      payable(royaltyWallet3).transfer(amount3);
      payable(duels[duelId].wallet2).transfer(restAmount);
    } else if(diff1<diff2) { // wallet1 wins 
      payable(royaltyWallet1).transfer(amount1);
      payable(royaltyWallet2).transfer(amount2);
      payable(royaltyWallet3).transfer(amount3);
      payable(duels[duelId].wallet1).transfer(restAmount);
    } else { // When duel is a draw,
      payable(duels[duelId].wallet1).transfer(duels[duelId].depositAmount/2);
      payable(duels[duelId].wallet2).transfer(duels[duelId].depositAmount/2);
    }
    duels[duelId].status = 3; // finshed duel
    walletToCategory[duels[duelId].wallet1][duels[duelId].categoryIndex] = false;
    walletToCategory[duels[duelId].wallet2][duels[duelId].categoryIndex] = false;
    emit DUELS_FINISHED(duelId, duels[duelId].wallet1, duels[duelId].wallet2);
  }

  function getDepositAmount(address _token, uint256 _categoryIndex) public view returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = BUSD;
    path[1] = _token;
    return router.getAmountsOut(amountArr[_categoryIndex] * 10**18, path)[1];
  }
  function setBot(address _addr) external onlyOwner {
    botAddress = _addr;
  }
  function setPause(bool _paused) external onlyOwner {
    paused = _paused;
  }
  
  function withdrawBNB() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
  function updateInvitationPeriod(uint256 _invitationPeriod, uint256 _duelLength) external onlyOwner {
    invitePeriod = _invitationPeriod;
    duelLength = _duelLength;
  }
  
  function manageDuelTokenHold(bool _disable, uint256 _holdAmount) external onlyOwner {
    disableTokenHold = _disable;
    holdAmount = _holdAmount;
  }

  function manageWhitelistedWallets(address[] memory _wallets, bool _whitelist) external onlyOwner {
    for(uint256 i = 0; i< _wallets.length; i++) {
      whitelistedWallets[_wallets[i]] = _whitelist;
    }
  }

  function setDuelToken(address _token) external onlyOwner {
    duelToken = _token;
  }

  function setAmount(uint256 amount, uint256 index) external onlyOwner {
    require(index<10, "out of range");
    amountArr[index] = amount; 
  }

  function getAmounts() external view returns(uint256[] memory) {
    return amountArr;
  }

  function getAllDuels() external view returns(Duel[] memory) {
    Duel[] memory ret = new Duel[](duelCounter);
    for(uint256 i=0; i<duelCounter; i++) {
      ret[i] = duels[i];
    }
    return ret;
  }
  
  receive() external payable{}
}