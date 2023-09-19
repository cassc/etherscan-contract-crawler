// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PeterICO is Ownable {

    IERC20 public MDSE_token;
    uint public startTime;
    uint public endTime;
    uint public tokenEthPrice = 0.000026 ether; //  1 MDSE = 0.05USD
    uint public hardCap;
    uint public ethRaised;
    address deployer;
    struct TokenSale{
        uint soldToken;
        uint tokenForSale;
    }
    TokenSale public tokenSale;

    struct Account {
        uint balance;
    }

    mapping (address => Account) public accounts;

    constructor(address _MDSE,uint _startTime,uint _endTime){

        require(_endTime > _startTime,"End Time should be greater than Start Time");
        require(_startTime > block.timestamp,"Start time should be greater than current time");

        MDSE_token = IERC20(_MDSE);
        startTime = _startTime;
        endTime = _endTime;
        deployer = msg.sender;
        tokenSale.tokenForSale = 40000000 * 10**18;
        hardCap = tokenSale.tokenForSale;
    }
    modifier depositRequirements() {
        require(msg.value >= 0.0026 ether, "Minimum 0.0026 ETH");  // minimum 5USD- 100MDSE
        _;
    }
    modifier onlyowner() {
        require(owner() == msg.sender || deployer == msg.sender, "Caller is not the owner");
        _;
    }
    //==================================================================================

    function getTokenAmountFromETH(uint256 _ethAmount) public view returns (uint256) {
        // balance * 1 ether / uint
        return SafeMath.div(SafeMath.mul(_ethAmount, 1 ether), tokenEthPrice);
    }

    function buyWithETH() public payable depositRequirements {
        uint256 buyToken = getTokenAmountFromETH(msg.value);

        require(buyToken <= MDSE_token.balanceOf(address(this)), "No tokens to sell");
        require(isICOOver()==false,"ICO already end");
        require(block.timestamp >= startTime,"Out of time window");
   
        accounts[msg.sender].balance += msg.value;
        ethRaised += msg.value;

        tokenSale.tokenForSale -= buyToken;
        tokenSale.soldToken += buyToken;

        MDSE_token.transfer(msg.sender, buyToken);
    }

    function retrieveStuckedERC20Token( address _tokenAddr, uint256 _amount, address _toWallet ) public onlyowner returns (bool) {
        IERC20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }
    function withdraw(uint256 _amount) public onlyowner {
        payable(msg.sender).transfer(_amount);
    }

    function updateTime(uint256 _startTime, uint256 _endTime) public onlyowner returns (bool) {
        require( _startTime < _endTime, "End Time should be greater than start time");
        require( startTime > block.timestamp, "Can not change time after ICO starts" );      
        require(_startTime > block.timestamp,"Start time should be greater than current time" );
        
        startTime = _startTime;
        endTime = _endTime;
        return true;
    }
    function updateMSDEAddress(address _msde) public onlyowner {
        MDSE_token = IERC20(_msde);
    }
    function updateMSDEPrice(uint256 _amount) public onlyowner {
        tokenEthPrice = _amount;
    }
    //==================================================================================

    function isICOOver() public view returns (bool) {
        if (
            block.timestamp > endTime ||
            tokenSale.tokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isHardCapReach() public view returns(bool){
        if(hardCap == tokenSale.soldToken){
            return true;
        }else{
            return false;
        }
    }

    //==================================================================================
    
}