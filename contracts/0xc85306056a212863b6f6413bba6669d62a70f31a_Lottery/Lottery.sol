/**
 *Submitted for verification at Etherscan.io on 2020-09-13
*/

pragma solidity 0.5.17;


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes20 data) external;
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function mult(uint256 x, uint256 y) internal pure returns (uint256) {
      if (x == 0) {
          return 0;
      }

      uint256 z = x * y;
      require(z / x == y, "Mult overflow");
      return z;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
      require(y != 0, "Div by zero");
      uint256 r = x / y;
      if (x % y != 0) {
          r = r + 1;
      }

      return r;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Admin{
  mapping(address=>bool) public admin;
}





contract IContribute{
  function donateTokens(uint256 todonate) public;
}
contract Lottery is ApproveAndCallFallBack{
  using SafeMath for uint;
  mapping(uint => mapping (uint => uint)) public token_map;
  mapping(uint => mapping (uint => address)) public entry_map;
  mapping(uint => mapping (uint => uint)) public entry_position_map;

  //read only
  mapping(uint => mapping (address => uint)) public token_count_by_address;
  mapping(uint => uint) public totalRoundTokens;

  uint public current_round;
  uint public entry_cursor;
  uint public cursor;
  ERC20 public tributeToken;
  ERC20 public liquidityToken;
  IContribute public contributeContract;
  uint public tokensToSend;
  Admin public administration; //other contracts allowed to access functions
  bytes32 public entropyHash;//secret for preventing miner manipulation of random
  uint256 public finalizationBlock;//the block from which random winner will be derived
  uint256 public winningIndex;
  bool public finalizingLock=false;
  uint public lastDrawing=0;
  uint public startingLiquidityTokens=0;
  uint public maxRewardable=15;//15%
  uint public minTimeBetweenDrawings=24 hours;//10 minutes;//6 days;

  modifier isAdmin(){
    require(administration.admin(msg.sender),"is not admin");
    _;
  }
  modifier isStakingTime(){
    require(!finalizingLock,"is not staking time");
    _;
  }
  constructor(address token,address a,address fundsDestination) public{
    tributeToken=ERC20(token);

    administration=Admin(a);
    contributeContract=IContribute(fundsDestination);
  }
  /*
    call this AFTER sending liquidity tokens
  */
  function init(address liqToken) public isAdmin{
    require(lastDrawing==0,"must be before any dispersal");
    liquidityToken=ERC20(liqToken);
    startingLiquidityTokens=liquidityToken.balanceOf(address(this));
  }
  function setWinningIndex1(bytes32 eh) public isAdmin{
    require(startingLiquidityTokens>0);
    require(now>=lastDrawing.add(minTimeBetweenDrawings),"is not finalization time");
    require(finalizationBlock==0||block.number>finalizationBlock+256,"finalization block is already set");
    entropyHash=eh;
    finalizationBlock=block.number+1;
    finalizingLock=true;
    lastDrawing=now;
  }
  //must call this before 256 blocks pass from setWinnngIndex1
  function setWinningIndex2(uint a,uint b) public isAdmin{
    require(finalizationBlock!=0,"fblock is zero");
    require(block.number>=finalizationBlock,"block number not large enough yet");
    require(block.number<finalizationBlock+256,"block number progressed too far");
    require(keccak256(abi.encodePacked(a,b))==entropyHash,"hash does not match");
    winningIndex=random(cursor,finalizationBlock,a);
  }
  function withdrawFunds(uint left,uint right,address winner,uint reward) public isAdmin{
    require(getWinningIndex().sub(left)!=getWinningIndex().add(right),"w1");//checked indexes should be different positions
    require(getWinningIndex()!=0,"w2");
    uint leftval=token_map[current_round][getWinningIndex().sub(left)];
    uint rightval=token_map[current_round][getWinningIndex().add(right)];
    require(leftval!=0,"w3");//both checked indexes should be nonzero
    require(leftval==rightval,"w4");//both checked values should be the same
    require(winner == entry_map[current_round][leftval],"w5");//check that the proposed winner actually submitted the given entry

    //uint cbal=liquidityToken.balanceOf(address(this));
    require(startingLiquidityTokens.mul(maxRewardable).div(100)>=reward,"cannot reward too large a portion");
    liquidityToken.transfer(winner,reward);

    current_round+=1;
    entry_cursor=0;
    cursor=0;
    winningIndex=0;
    finalizingLock=false;
    finalizationBlock=0;
  }
  function getWinningIndex() public view returns(uint256){
    return winningIndex;
  }
  function getWinningOffsets() public view returns(uint,uint){
    if(getWinningIndex()==0 || entry_cursor<1){
      return(0,0);
    }
    if(entry_cursor==1){
      return (getWinningIndex()-1,cursor-getWinningIndex());//then return the first entry (the only one)
    }
    for(uint i=2;i<=entry_cursor;i++){
      if(entry_position_map[current_round][i]>getWinningIndex()){
        return (getWinningIndex()-entry_position_map[current_round][i-1],entry_position_map[current_round][i]-1-getWinningIndex());
      }
    }
    return (getWinningIndex()-entry_position_map[current_round][entry_cursor],cursor-getWinningIndex());
  }
  function getWinningAddress() public view returns(address){
    (uint l,uint r) = getWinningOffsets();
    return entry_map[current_round][token_map[current_round][getWinningIndex()-l]];
  }
  function getHashCombo(uint a,uint b) public pure returns(bytes32){
    return keccak256(abi.encodePacked(a,b));
  }
  function maxRandom(uint blockn, uint256 entropy)
    internal view
    returns (uint256 randomNumber)
  {
      return uint256(keccak256(
          abi.encodePacked(
            blockhash(blockn),
            entropy)
      ));
  }
  function random(uint256 upper, uint256 blockn, uint256 entropy)
    internal view
    returns (uint256 randomNumber)
  {
      return maxRandom(blockn, entropy) % upper + 1;
  }
  function checkAndTransfer(
      uint256 _amount,
      address _from
  )
      private
  {
      require(
          tributeToken.transferFrom(
              _from,
              address(this),
              _amount
          ) == true, "transfer must succeed"
      );
  }
  //event DebugTest(uint allowed,uint amount,address from,address tokenAddr,address sender,address lotteryAddr);

  function receiveApproval(address from, uint256 tokens, address tokenAddr, bytes20 data) external{
    require(msg.sender==address(tributeToken));
    //emit DebugTest(ERC20(msg.sender).allowance(from,address(this)),tokens,from,tokenAddr,msg.sender,address(this));

    checkAndTransfer(tokens,from);
    tributeToken.approve(address(contributeContract),tokens/2);
    contributeContract.donateTokens(tokens/2);
    tributeToken.burn(tokens/2);
    enter(from,tokens);

  }

  function enter(address entrant,uint toLock) private isStakingTime{
    require(!finalizingLock,"contest is now finalizing please wait");
    require(toLock>3,"must lock a minimal quantity of tokens");
    entry_cursor=entry_cursor.add(1);
    token_map[current_round][cursor.add(1)]=entry_cursor;
    token_map[current_round][cursor.add(toLock)]=entry_cursor;
    entry_position_map[current_round][entry_cursor]=cursor.add(1);
    cursor=cursor.add(toLock);
    entry_map[current_round][entry_cursor]=entrant;//msg.sender;
    token_count_by_address[current_round][entrant]=token_count_by_address[current_round][entrant].add(toLock);
    totalRoundTokens[current_round]=totalRoundTokens[current_round].add(toLock);
  }
}