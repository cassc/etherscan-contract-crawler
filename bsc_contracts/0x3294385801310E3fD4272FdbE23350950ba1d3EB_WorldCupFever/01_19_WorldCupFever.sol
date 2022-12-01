// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {

    struct RequestStatus {
        bool fulfilled; 
        bool exists; 
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 3;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0xc587d9053cd1118f25F645F9E08BB98c9712A4EE)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0xc587d9053cd1118f25F645F9E08BB98c9712A4EE);
        s_subscriptionId = subscriptionId;
    }

    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getAddress() external view onlyOwner returns(address){
        return address(this);
    }

    function getWinners(uint256 _totalLotteryTickets) external view onlyOwner returns(uint256 [3] memory  ){
        uint256 [3] memory tempWinners;
        for (uint256 i=0 ; i <s_requests[lastRequestId].randomWords.length; i++){
            tempWinners[i]=s_requests[lastRequestId].randomWords[i]% _totalLotteryTickets;
        }
        return tempWinners;
    }

    fallback() external payable{}

    receive() external payable{}

}

contract Minter is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    string public baseURI;
    string public baseExtension = ".json";

    bool public pausedMint;
    bool public pausedBurn=true;

    WorldCupFever main;

    constructor( 
        string memory _name,
        string memory _initBaseURI,
        address addressInterface
        ) ERC1155(_name)  {
            baseURI=_initBaseURI;
            main= WorldCupFever(payable(addressInterface));
        }

    function mint(address _user, uint256 _countryID, uint256 _amount) public onlyOwner{
        require(pausedMint==false,"No mint allowed ");
        _mint(_user, _countryID, _amount, " ");
    }

    function burnAll() public {
        require(pausedBurn==false,"No burn allowed ");
        (uint256 tempBalance,uint256[] memory tempIdNfts,uint256[] memory tempBalanceNfts)=_preBurnHook(msg.sender);
        _burnBatch(msg.sender,tempIdNfts,tempBalanceNfts);
        if(tempBalance>0){
            _postBurnHook(msg.sender);
        }
    }

    function toggleMint() public onlyOwner{
        pausedMint=!pausedMint;
    }

    function toggleBurn() public onlyOwner{
        pausedBurn=!pausedBurn;
    }

    function uri(uint _tokenId) override public view returns (string memory){
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId),baseExtension));
    }

    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }

    function _preBurnHook(address _account) internal returns(uint256,uint256[] memory,uint256[] memory){
        (uint256 tempBalance,uint256[] memory tempIdNfts,uint256[] memory tempBalanceNfts)=main.preBurnHook(_account);
        return(tempBalance,tempIdNfts,tempBalanceNfts);
    }

    function _postBurnHook(address _account) internal{
        main.postBurnHook(_account);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    fallback() external payable {}

    receive() external payable{}
}

contract WorldCupFever is Ownable, Pausable{

    uint256 public mintPrice=0.2 ether;
    uint256 public numberCoutries =32;
    uint256[5] public thresoldsList=[50,150,300,600,1200];
    uint256[6] public amountList=[1,2,3,6,12,16];
    uint256[32] oddCountry = [1,2,1,1,3,2,3,1,1,2,1,1,1,3,1,3,2,2,3,2,1,2,3,2,2,3,1,2,3,1,2,2] ;
    uint256[32] percentCountry  =[113,132,116,110,134,130,138,119,118,128,112,111,115,133,118,137,129,124,133,127,117,131,140,121,125,135,114,122,136,120,123,126] ;
    uint256 public totalLotteryTickets; 

    struct List {
        address player;
        uint256 odds;
        uint256 balance;
    }

    List[] public finalList;

    struct Position{
        uint256 position;
        bool positioned;
    }

    mapping (address=>Position) public positionList;

    struct Country {
        uint256 finalPercent;
        uint256 initPercent;
        uint256 odd;
        uint256 mintAmount;
        uint256 supply;
    } 

    Country[32] public countries;

    Lottery lottery ; 
    uint256 requestId;
    address lotteryAddress;
    bool lotteryFinished;
    bool adminPayed;

    Minter minter ; 
    address minterAddress;

    event WinningCountrySet (uint256 countryID,uint256 percent);
    event HasMinted (address user, uint256 countryID,uint256 amount);
    event HasSuscribed (address user, uint256 odd);
    event HasWithdraw (address user, uint256 cashback);
    event LotteryWinnerPicked(address winner1,address winner2,address winner3);

    constructor( 
        string memory _name,
        string memory _initBaseURI,
        uint64 _subscriptionId
        ){
            lottery =new Lottery(_subscriptionId);
            minter =new Minter(_name,_initBaseURI,address(this));
            _initialisation(oddCountry,percentCountry);

        }
 
    function mint(uint256 _countryID) public payable{
        require(_countryID >=0 &&_countryID <32, "Not a valid country ");
        uint256 number =countries[_countryID].mintAmount;
        countries[_countryID].supply =minter.totalSupply(_countryID)+number;
        _setMintAmount(_countryID,number);
        totalLotteryTickets+=countries[_countryID].odd*number;
        if (msg.sender != owner()) {
            require(msg.value >=  mintPrice*number, "Not enought funds !");
            minter.mint(msg.sender, _countryID, number);
        }else{
            minter.mint(msg.sender, _countryID, number);
        }
        emit HasMinted(msg.sender,_countryID,number);
    }

    function preBurnHook(address _account) public returns(uint256,uint256[] memory,uint256[] memory){
        require(msg.sender==address(minter),"Not allowed");
        (uint256[] memory temp2IdNfts,uint256[] memory temp2BalanceNfts)=calculateBalance(_account);
        (uint256 tempBalance,uint256 tempOdds)=calculateOddsPercent(temp2BalanceNfts);
        if(positionList[_account].positioned==false){
            _addPlayer(_account);
        }
        finalList[positionList[_account].position].odds=tempOdds;
        finalList[positionList[_account].position].balance=tempBalance;
        emit HasSuscribed(_account,tempOdds);
        return(tempBalance,temp2IdNfts,temp2BalanceNfts);
    }

    function postBurnHook(address _account) public {
        require(msg.sender==address(minter),"Not allowed");
        require(finalList[positionList[_account].position].balance>0,"Empty balance");
            uint256 tempBalance=finalList[positionList[_account].position].balance;
            finalList[positionList[_account].position].balance=0;       
            (bool success, )= _account.call{value: tempBalance*mintPrice/1000}("");
            require (success, "Withdraw failed");
            tempBalance=0;
            emit HasWithdraw(_account,tempBalance);
    }

    function setCashback(uint256 _countryID) public onlyOwner {
        require(_countryID>=0 &&_countryID<32,"The countryID isn't valid");
        countries[_countryID].finalPercent+=countries[_countryID].initPercent;
        emit WinningCountrySet (_countryID,countries[_countryID].finalPercent);
    }

    function toggleMint() public onlyOwner{
        minter.toggleMint();
    }

    function toggleBurn() public onlyOwner{
        minter.toggleBurn();
    }
    
    function requestRandomWords() external onlyOwner {
        requestId = lottery.requestRandomWords();
        lotteryFinished=true;
    }

    function payWinners() external onlyOwner {
        require(lotteryFinished==true, "Request words before");
        require(adminPayed==true, "Pay admin before");
        uint256[3] memory winner = lottery.getWinners(totalLotteryTickets);
        address[3] memory finalWinners =_findWinners(winner);
            payable(finalWinners[0]).transfer(address(this).balance/ 10 * 9);
            payable(finalWinners[1]).transfer(address(this).balance/ 10 * 9);
            payable(finalWinners[2]).transfer(address(this).balance);          
        emit LotteryWinnerPicked(finalWinners[0],finalWinners[1],finalWinners[2]);
    }

    function payAdmin()external onlyOwner{
        require(lotteryFinished==true, "Finish lottery first");
        require(adminPayed==false, "Admin already payed");
        adminPayed=true;
        if (address(this).balance>=7344 ether){
            (bool success, )= (msg.sender).call{value: address(this).balance- 3672 ether}("");
            require (success, "Payment failed");
        }else {  
            (bool success, )= (msg.sender).call{value: address(this).balance/2}("");
            require (success, "Payment failed");           
        }
    }

    function calculateBalance(address _player) public view returns(uint256[] memory,uint256[] memory ){
        uint256[] memory idNfts = new uint256[](32);
        uint256[] memory balanceNfts = new uint256[](32);
        for(uint256 i=0; i< 32;i++){
            idNfts[i]=i;
            balanceNfts[i]=minter.balanceOf(_player,i);
        }
        return (idNfts,balanceNfts);
    }

    function calculateOddsPercent(uint256[] memory _balanceNfts) public view returns(uint256,uint256){
        uint256 percent;
        uint256 odd;
        for(uint256 i=0;i<32;i++){
            percent +=countries[i].finalPercent *_balanceNfts[i] ;
            odd +=countries[i].odd*_balanceNfts[i] ;
        }
        return (percent,odd);
    }

    function getCountries() public view returns(Country[32] memory){
        return countries;
    }

    function getMinterAddress() public view returns(address){
        return address(minter);
    }

    function getLotteryAddress() public view returns(address){
        return address(lottery);
    }

    function _initialisation(uint256[32] memory _odds,uint256[32] memory _percents) internal {
        for (uint256 i=0; i<numberCoutries;i++){
            countries[i].supply=minter.totalSupply(i);
            countries[i].odd=_odds[i];
            countries[i].initPercent=_percents[i];
            countries[i].mintAmount=1;
        }
    }

    function _setMintAmount(uint256 _countryID,uint256 _number) internal  { 
        uint256 supply =minter.totalSupply(_countryID)+_number;
        if (supply  <= thresoldsList[0]){
            countries[_countryID].mintAmount= amountList[0];
        } else if (supply <= thresoldsList[1]){
            countries[_countryID].mintAmount= amountList[1];
        } else if (supply <= thresoldsList[2]){
           countries[_countryID].mintAmount= amountList[2];
        } else if (supply <= thresoldsList[3]){
            countries[_countryID].mintAmount= amountList[3];
        } else if (supply <= thresoldsList[4]){
            countries[_countryID].mintAmount= amountList[4];                 
        } else{
            countries[_countryID].mintAmount= amountList[5];
        }
    }

    function _addPlayer(address _player) internal {
        require( _player!=address(0),"Not a valid address");
        List memory player = List(_player,0,0);
        finalList.push(player);
        uint256 position= finalList.length -1;
        positionList[_player].position=position;
        positionList[_player].positioned=true;
    }

    function _findWinners(uint256[3] memory _player) internal view returns(address[3] memory) {
        uint256 countLottery=0;
        address[3] memory winningList;
        for (uint256 i =0 ;i < finalList.length; i++ ){
            for (uint256 y=0 ; y<finalList[i].odds;y++){
                if(countLottery==_player[0]){
                    winningList[0] =finalList[i].player;
                }
                if(countLottery==_player[1]){
                    winningList[1] =finalList[i].player;
                }
                if(countLottery==_player[2]){
                    winningList[2] =finalList[i].player;
                }
                countLottery += 1;
            }
        }
        return winningList;
    }

    fallback() external payable {}

    receive() external payable{}
}