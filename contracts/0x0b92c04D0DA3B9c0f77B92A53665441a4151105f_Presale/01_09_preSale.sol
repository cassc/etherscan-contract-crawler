// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./vestingClaims.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Presale is Ownable {
    using SafeMath for uint256;
    // event WalletCreated(address vestingAddress,address userAddress,uint256 amount);
    bool public isPresaleOpen = true;
    address public admin;

    AggregatorV3Interface internal priceFeed;

    address public tokenAddress;
    uint256 public tokenDecimals;

    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 2;
    uint256 public tokenSold = 0;
    
    uint256 public totalEthAmount = 0;
    uint256 public totalUSDAmount = 0;
    uint256 public buyTokenPercentage = 500;
    uint256[] public rLockinPeriod = [0,180,360,720,720];

    uint256[] public priceBrackets = [5000,50000,150000,250000];
    uint256[] public pricePerToken = [8,7,6,5];
    
    uint256 public sliceDays;

    uint256 public hardcap = 10000*1e18;  // Total Eth Value
    address private dev;

    vestingContract vestingAddress;

    mapping(address => uint256) public usersInvestments;

    address public recipient;

    modifier onlyOwnerAndAdmin()   {
        require(
            owner() == _msgSender() || _msgSender() == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    constructor(
        address _token,
        address _recipient
    ) {
        tokenAddress = _token;
        tokenDecimals = IToken(_token).decimals();
        recipient = _recipient;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        sliceDays = 30;
        admin = _msgSender();
    }

    function getEthPriceInUsd() public view returns(int256) {
        return (priceFeed.latestAnswer()/1e8);
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(vestingAddress.listedAt());
    }

    function setAdmin(address account) external  onlyOwnerAndAdmin{
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }

    function setVestingAddress(address _vestingAddress) external onlyOwnerAndAdmin {
        vestingAddress = vestingContract(_vestingAddress);
    }

    function setRecipient(address _recipient) external onlyOwnerAndAdmin {
        recipient = _recipient;
    }

    function setBuyTokenPercentage(uint _percentage) public  onlyOwnerAndAdmin{
        buyTokenPercentage = _percentage;  
    }

    function setPriceBrackets(uint256[] memory _priceBrackets)
        external
        onlyOwnerAndAdmin
    {
        priceBrackets = _priceBrackets;
    }

    function setPricePerToken(uint256[] memory _pricePerToken)
        external
        onlyOwnerAndAdmin
    {
        pricePerToken = _pricePerToken;
    }

    function setRLockinPeriods(uint256[] memory _rLockinPeriod) external onlyOwnerAndAdmin {
        rLockinPeriod = _rLockinPeriod;
    }

    function setHardcap(uint256 _hardcap) external onlyOwnerAndAdmin {
        hardcap = _hardcap;
    }

    function startPresale() external onlyOwnerAndAdmin {
        require(!isPresaleOpen, "Presale is open");

        isPresaleOpen = true;
    }

    function closePresale() external onlyOwnerAndAdmin {
        require(isPresaleOpen, "Presale is not open yet.");

        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwnerAndAdmin {
        require(token != address(0), "Token address zero not allowed.");
        tokenAddress = token;
        tokenDecimals = IToken(token).decimals();
    }

    function setTokenDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        tokenDecimals = decimals;
    }

    function setRateDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        rateDecimals = decimals;
    }

    receive() external payable {

    }

    function buyToken(uint256 _amountInUSD) public payable  {
        require(isPresaleOpen, "Presale is not open.");
        require(getLaunchedAt() == 0,"Already Listed!");
        
        uint256 priceInUSD = uint256(getEthPriceInUsd());

        uint256 priceUSDInEth = (((1*1e18)/priceInUSD)*_amountInUSD);

        require(priceUSDInEth <= msg.value,"Insufficient amount.");

        (,uint256 tokenAmount) = getTokens(_amountInUSD);  // token amount with decimals
        
        (uint256 range,uint256 _slicePeriod) = getDuration(_amountInUSD);


        if (range == 0) {
            require(
                IToken(tokenAddress).transfer(msg.sender, tokenAmount),
                "Insufficient balance of presale contract!"
            );
        } else {
            createVestingWallets(
            tokenAmount,
            _msgSender(),
            range,
            _slicePeriod
            );
        }
        tokenSold += tokenAmount;

        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(
            msg.value
        );

        totalEthAmount = totalEthAmount + msg.value;
        totalUSDAmount = totalUSDAmount + _amountInUSD;


        payable(recipient).transfer(msg.value);

        if (totalEthAmount > hardcap) {
            isPresaleOpen = false;
        }
       
    }


    function createVestingWallets(
        uint256 tokenAmount,
        address _userAddress,
        uint256 _totalDays,
        uint256 _slicePeriod
    ) private {

        uint _tokenAmount = (tokenAmount * buyTokenPercentage)/(10**(2+rateDecimals));
        tokenAmount =  tokenAmount - _tokenAmount;

        vestingContract(vestingAddress).createVesting(
            _userAddress,
            _totalDays,
            _slicePeriod,
            tokenAmount
        );

        require(IToken(tokenAddress).transfer(_userAddress, _tokenAmount),
            "Insufficient balance of presale contract!"
        );
        
        require(IToken(tokenAddress).transfer(address(vestingAddress), tokenAmount),
            "Insufficient balance of presale contract!"
        );

    }

    function vestingCreate(uint256 tokenAmount,address _userAddress,uint256 _totalDays,uint256 _slicePeriod) public {

        vestingContract(vestingAddress).createVesting(_userAddress,_totalDays,_slicePeriod,tokenAmount);
        
        IToken(tokenAddress).transferFrom(msg.sender,address(vestingAddress), tokenAmount);

    }

    function getTokens(uint256 _amountInUSD) public view returns(uint256 _pricePerToken, uint256 tokenAmount) {

        uint256 per=0;
        require(_amountInUSD >= pricePerToken[0],"Amount should not be less then minimum amount");

        if(_amountInUSD >= priceBrackets[0] && _amountInUSD <= priceBrackets[1] ){
            per = pricePerToken[0];
        }
        else if(_amountInUSD > priceBrackets[1] && _amountInUSD <= priceBrackets[2] ){
            per = pricePerToken[1];
        }
        else if(_amountInUSD > priceBrackets[2] && _amountInUSD <= priceBrackets[3] ) {
            per = pricePerToken[2];
        }
        else if(_amountInUSD > priceBrackets[3] ){
            per = pricePerToken[3];
        }
        
        return (per, _amountInUSD*10**(tokenDecimals+rateDecimals)/per);

    } 

    function burnUnsoldTokens() external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot burn tokens untitl the presale is closed."
        );

        IToken(tokenAddress).burn(
            IToken(tokenAddress).balanceOf(address(this))
        );
    }

    function getUnsoldTokens(address to) external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot get tokens until the presale is closed."
        );

        IToken(tokenAddress).transfer(to,IToken(tokenAddress).balanceOf(address(this)));
    
    }

    function getDuration(uint256 amount)
        public
        view
        returns (uint256 range,uint256 _slicePeriod)
    {
      uint256 retrunDuration=0;
      _slicePeriod=0;
    
        if(amount < priceBrackets[0]){
            retrunDuration = 0;
            _slicePeriod=0;
        }
        else if(amount <= priceBrackets[1]){
            retrunDuration = rLockinPeriod[1] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount <= priceBrackets[2]){
            retrunDuration = rLockinPeriod[2] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount <= priceBrackets[3]){
            retrunDuration = rLockinPeriod[3] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount > priceBrackets[3]){
            retrunDuration = rLockinPeriod[4] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        
        return  (retrunDuration,_slicePeriod);
    }

    function getVestingAddress() external view returns (address){
        return address(vestingAddress);
    }
    
    function setTimeUnit(uint _unit,uint _sliceDays) public onlyOwnerAndAdmin{
        vestingContract(vestingAddress).setTimeUnit(_unit);
        sliceDays = _sliceDays;
    }

    function getTimeUnit() public view returns(uint _timeUnit){
        return vestingContract(vestingAddress).timeUnit();
    }

    function launch() public onlyOwnerAndAdmin {
         vestingContract(vestingAddress).launch();
    }

    function setAdminForpreSale(address _address) public onlyOwnerAndAdmin{
        vestingContract(vestingAddress).setAdmin(_address);
    }

    function getVestingId(address _address) public view returns(uint[] memory){
        return vestingContract(vestingAddress).getVestingIds(_address);
    }

    function getClaimAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {
        return vestingContract(vestingAddress).getClaimableAmount(_walletAddress,_vestingId);
    }

    function getUserVestingData(address _address,uint256 _vestingId) public view returns(address _owner,
        uint _totalEligible,
		uint _totalClaimed,
		uint _remainingBalTokens,
		uint _lastClaimedAt,
        uint _startTime,
        uint _totalVestingDays,
        uint _slicePeriod ){
        (,_owner,_totalEligible,_totalClaimed,_remainingBalTokens,_lastClaimedAt,_startTime,_totalVestingDays,_slicePeriod) = vestingContract(vestingAddress).userClaimData(_address,_vestingId);
        
    }

}