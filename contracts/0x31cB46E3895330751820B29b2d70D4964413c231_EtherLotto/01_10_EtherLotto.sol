// SPDX-License-Identifier: GPL-2.0-or-later
/* Created by & Property of EtherLotto*/

pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721SUB.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


  contract EtherLotto is ERC721SUB, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
      
    /* -- Random Number Variables Chainlink VRF -- */
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256[] public s_randomWords;
    uint256 public randomNumber;
    uint256 public s_requestId;
    address s_owner;
    /* ---- */

    /* -- Lottery Variables -- */
    mapping (uint256 => uint256[]) public pastWinningNumbers;
    mapping (uint256 => address[]) public historyOfWinningAddresses;
    uint256[] public arrayofWinningTickets;
    uint256 public numberOfWinners = 3;
    uint256 public prizePercentagePerWinner = 20;
    uint256 public prizePercentagePerWinnerBoost = 25;
    uint256 public pricePerTicket = 5000000000000000;
    address public ETLottoWallet = 0x1c7001eEf7d90583B0BE987784034EC3d3d40A41;
    /* ---- */
    
    /* -- NFT Variables -- */
    string public baseURI = "";
    string public ticketBoostURI = "";
    string public ticketExpiredURI = "";
    bool public isTicketSalesActive = false;
    uint256 public ticketPrice = 1000000000000000;
    uint256 public MAX_PER_TX = 5;
    using SafeMath for uint256;
    using Strings for uint256;
    event NFTMINTED(uint256 tokenId, address owner);
    /* ---- */


    constructor(uint64 subscriptionId) ERC721SUB("EtherLottos", "EL") VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    }


  /* -- VRF Functions -- */
    function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    }
    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
    ) internal override {
    s_randomWords = randomWords;
    randomNumber = s_randomWords[0];
    }

    function setVRFCoordinator(address _newVRFCoordinator) external onlyOwner {
      vrfCoordinator = _newVRFCoordinator;
    }

    function setKeyhash(bytes32 _newKeyHash) external onlyOwner{
      keyHash = _newKeyHash;
    }

    function setCallBackGas(uint32 _newCallBackGas) external onlyOwner{
      callbackGasLimit = _newCallBackGas;
    }

     function setRequestConfirmations(uint16 _newRequestConfirmations) external onlyOwner{
      requestConfirmations = _newRequestConfirmations;
    }

    function changeSubscriptionId(uint64 _newSubscriptionID) external onlyOwner{
      s_subscriptionId = _newSubscriptionID;
    }
    /* ---- */

    /* -- Lottery Functions -- */
    /* Created by & Property of EtherLotto*/
    function selectAndRewardWinners() external payable onlyOwner nonReentrant {
    isTicketSalesActive= false;
    uint256 entriesCounter = totalSupply();
    uint256[] memory expandedValues;
    expandedValues = new uint256[](numberOfWinners);
    for (uint256 i = 0; i < numberOfWinners ; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomNumber, i)));
        expandedValues[i] = (expandedValues[i] % entriesCounter);
    }
    arrayofWinningTickets = expandedValues;
    pastWinningNumbers[currentWeek] = expandedValues;
    uint256 finalJackpot = address(this).balance;
    uint256 prizeFunds = finalJackpot/uint256(100)*(prizePercentagePerWinner);
    uint256 prizeFundsBoost = finalJackpot/uint256(100)*(prizePercentagePerWinnerBoost);
    for(uint256 i = 0; i < arrayofWinningTickets.length; i++){
        historyOfWinningAddresses[currentWeek].push(ownerOf(arrayofWinningTickets[i]));
        if(boost[currentWeek][arrayofWinningTickets[i]] == true){
          payable(ownerOf(arrayofWinningTickets[i])).transfer(prizeFundsBoost);
        }else{
           payable(ownerOf(arrayofWinningTickets[i])).transfer(prizeFunds);
        }
    }
    payable(ETLottoWallet).transfer(prizeFunds);
    }

    function startNextWeeksLottery() external onlyOwner{
      currentWeek++;
      indexTracker = 0;
      isTicketSalesActive = true;
    }

    function setLottoWallet(address _ETLottoWallet) external onlyOwner{
        ETLottoWallet = _ETLottoWallet;
    }

    function setPrizePercentagePerWinner(uint256 _newPrizePercentagePerWinner) external onlyOwner {
      prizePercentagePerWinner = _newPrizePercentagePerWinner;
    }

    function setAmountOfWinners(uint256 _newAmountofWinners) external onlyOwner {
        numberOfWinners = _newAmountofWinners;
    }

    function lastWeeksWinningNumbers() public view virtual returns (uint256[] memory) {
      return arrayofWinningTickets;
    }

    function lookupPastWinningNumbers(uint256 week) public view virtual returns (uint256[] memory){
      return pastWinningNumbers[week];
    }

    function lookupPastWinners(uint256 week) public view virtual returns (address[] memory){
      return historyOfWinningAddresses[week];
    }

     function isMultiplierActive(uint256 ticketID) public view virtual returns (bool){
      return boost[currentWeek][ticketID];
    }

    function checkMyNumbers(address yourWallet, uint256 week) public view virtual returns (bool){
      bool Winner = false;
      for(uint256 i = 0; i < numberOfWinners; i++){
        if(yourWallet == historyOfWinningAddresses[week][i]){
          Winner = true;
          break;
        }
      }
      return Winner;
    }

    function prizePool() public view virtual returns (uint256){
      //Repersented in WEI
      uint256 currentPrizePool = (3 * (address(this).balance/100*prizePercentagePerWinner));
      return currentPrizePool;
    }
    /*-----*/

    /* -- NFT Functions -- */
    
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
      }

    function _ticketExpiredURI() internal view virtual returns (string memory) {
        return ticketExpiredURI;
      }
    
     function _ticketBoostURI() internal view virtual returns (string memory) {
        return ticketBoostURI;
      }
      
    function _price() internal view virtual returns (uint256) {
      return ticketPrice;
      }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
      }
    
    function setTicketBoostURI(string memory _newBoostURI) public onlyOwner {
      ticketBoostURI = _newBoostURI;
      }

    function setExpiredURI(string memory _newExpiredURI) public onlyOwner {
      ticketExpiredURI = _newExpiredURI;
      }

    function setTicketPrice(uint256 _newTicketPrice) public onlyOwner {
      ticketPrice = _newTicketPrice;
      }

    function setMaxPerTX(uint256 _newMaxPerTX) public onlyOwner {
      MAX_PER_TX = _newMaxPerTX;
      }

    function activateTicketSale() external onlyOwner {
      isTicketSalesActive = !isTicketSalesActive;
      }
    /* Created by & Property of EtherLotto*/
    function exists(uint256 tokenId) public view returns (bool) {
      return _exists(tokenId);
    }
    
     function withdraw(address payable _to, uint _amount) public onlyOwner nonReentrant {
        _to.transfer(_amount);
    }

    function buyTicket(uint256 quantity) external payable {
      require(isTicketSalesActive, "Sale not Active");
      require(
        quantity > 0 && quantity <= MAX_PER_TX,
        "Can Mint only 5 per TX & Can't Mint Zero"
        );
        require(msg.value >= ticketPrice.mul(quantity),
         "0.001 eth Per Ticket"
        );
        _mint(msg.sender, quantity);
        }

     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
    
        string memory currentBaseURI = _baseURI();
        string memory currentBoostURI = _ticketBoostURI();
        string memory currentExpiredURI = _ticketExpiredURI();

      if(tokenId >= indexTracker){
        return currentExpiredURI;
      }

      if(boost[currentWeek][tokenId] == true){
        return currentBoostURI;
      }

        return
          currentBaseURI;                
      }
  }

/* Created by & Property of EtherLotto*/