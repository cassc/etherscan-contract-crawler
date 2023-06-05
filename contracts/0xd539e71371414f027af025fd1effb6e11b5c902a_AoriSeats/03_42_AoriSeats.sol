// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@  @   @  @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity ^0.8.19;

import "./OpenZeppelin/ERC721Enumerable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/ERC2981.sol";
import "./OpenZeppelin/ReentrancyGuardUpgradeable.sol";
import "./CallFactory.sol";
import "./PutFactory.sol";
import "./OrderbookFactory.sol";

/**
    Storage for all Seat NFT management and fee checking
 */
contract AoriSeats is ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {

     uint256 maxSeats;
     uint256 public currentSeatId;
     uint256 mintFee;
     uint256 tradingFee;
     uint256 public maxSeatScore;
     uint256 public feeMultiplier;
     CallFactory public CALLFACTORY;
     PutFactory public PUTFACTORY;
     address public minter;
     address public seatRoyaltyReceiver;
     uint256 public defaultSeatScore;
     OrderbookFactory public ORDERBOOKFACTORY;
     mapping(address => uint256) pointsTotal;
     mapping(uint256 => uint256) totalVolumeBySeat;

     constructor(
         string memory name_,
         string memory symbol_,
         uint256 maxSeats_,
         uint256 mintFee_,
         uint256 tradingFee_,
         uint256 maxSeatScore_,
         uint256 feeMultiplier_
     ) ERC721(name_, symbol_) {
         maxSeats = maxSeats_;
         mintFee = mintFee_;
         tradingFee = tradingFee_;
         maxSeatScore = maxSeatScore_;
         feeMultiplier = feeMultiplier_;

         _setDefaultRoyalty(owner(), 350);
         setSeatRoyaltyReceiver(owner());
         setDefaultSeatScore(5);
     }

    event FeeSetForSeat (uint256 seatId, address SeatOwner);
    event MaxSeatChange (uint256 NewMaxSeats);
    event MintFeeChange (uint256 NewMintFee);
    event TradingFeeChange (uint256 NewTradingFee);

    /** 
    Admin control functions
    */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
            return super.supportsInterface(interfaceId);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }
    
    function setSeatRoyaltyReceiver(address newSeatRoyaltyReceiver) public onlyOwner {
        seatRoyaltyReceiver = newSeatRoyaltyReceiver;
    }

    function setCallFactory(CallFactory newCALLFACTORY) public onlyOwner returns (CallFactory) {
        CALLFACTORY = newCALLFACTORY;
        return CALLFACTORY;
    }

    function setPutFactory(PutFactory newPUTFACTORY) public onlyOwner returns (PutFactory) {
        PUTFACTORY = newPUTFACTORY;
        return PUTFACTORY;
    }
    
    function setOrderbookFactory(OrderbookFactory newORDERBOOKFACTORY) public onlyOwner returns (OrderbookFactory) {
        ORDERBOOKFACTORY = newORDERBOOKFACTORY;
        return ORDERBOOKFACTORY;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setDefaultSeatScore(uint256 score) public onlyOwner returns(uint256) {
        defaultSeatScore = score;
        return score;
    }

    function mintSeat() external returns (uint256) {
        require(msg.sender == minter);

        uint256 currentSeatIdLocal = currentSeatId;

        if (currentSeatId % 10 == 0) {
            seatScore[currentSeatIdLocal] = 1;
            _mint(seatRoyaltyReceiver, currentSeatIdLocal);
            currentSeatIdLocal++;
        }
        seatScore[currentSeatIdLocal] = defaultSeatScore;
        _mint(minter, currentSeatIdLocal);
        currentSeatId = currentSeatIdLocal + 1; //prepare seat id for future mint calls
        return currentSeatIdLocal; //return the id of the seat we just minted
    }

    /** 
        Combines two seats and adds their scores together
        Enabling the user to retain a higher portion of the fees collected from their seat
    */
    function combineSeats(uint256 seatIdOne, uint256 seatIdTwo) public returns(uint256) {
        require(msg.sender == ownerOf(seatIdOne) && msg.sender == ownerOf(seatIdTwo));
        uint256 newSeatScore = seatScore[seatIdOne] + seatScore[seatIdTwo];
        require(newSeatScore <= maxSeatScore);
        _burn(seatIdOne);
        _burn(seatIdTwo);
        uint256 newSeatId = currentSeatId++;
        _safeMint(msg.sender, newSeatId);
        seatScore[newSeatId] = newSeatScore;
        return seatScore[newSeatId];
    }

    /**
        Mints the user a series of one score seats
     */
    function separateSeats(uint256 seatId) public {
        require(msg.sender == ownerOf(seatId));
        uint256 currentSeatScore = seatScore[seatId];
        seatScore[seatId] = 1; //Reset the original seat
        _burn(seatId); //Burn the original seat
        //Mint the new seats
        for(uint i = 0; i < currentSeatScore; i++) {
            uint mintIndex = currentSeatId++;
            _safeMint(msg.sender, mintIndex);
            seatScore[mintIndex] = 1;
        }
    }

    /** 
        Volume = total notional trading volume through the seat
        For data tracking purposes.
    */
    function addTakerVolume(uint256 volumeToAdd, uint256 seatId, address Orderbook_) public nonReentrant {
        //confirms via Orderbook contract that the msg.sender is a call or put market created by the OPTIONTROLLER
        require(ORDERBOOKFACTORY.checkIsOrder(Orderbook_, msg.sender));
        
        uint256 currentVolume = totalVolumeBySeat[seatId];
        totalVolumeBySeat[seatId] = currentVolume + volumeToAdd;
    }


    /**
        Change the total number of seats
     */
    function setMaxSeats(uint256 newMaxSeats) public onlyOwner returns (uint256) {
        maxSeats = newMaxSeats;
        emit MaxSeatChange(newMaxSeats);
        return maxSeats;
    }
     /**
        Change the number of points for taking bids/asks and minting options
     */
    function setFeeMultiplier(uint256 newFeeMultiplier) public onlyOwner returns (uint256) {
        feeMultiplier = newFeeMultiplier;
        return feeMultiplier;
    }

    /**
        Change the maximum number of seats that can be combined
        Currently if this number exceeds 12 the Orderbook will break
     */
    function setMaxSeatScore(uint256 newMaxScore) public onlyOwner returns(uint256) {
        require(newMaxScore > maxSeatScore);
        maxSeatScore = newMaxScore;
        return maxSeatScore;
    }
    /** 
        Change the mintingfee in BPS
        For example a fee of 100 would be equivalent to a 1% fee (100 / 10_000)
    */
    function setMintFee(uint256 newMintFee) public onlyOwner returns (uint256) {
        mintFee = newMintFee;
        emit MintFeeChange(newMintFee);
        return mintFee;
    }
    /** 
        Change the mintingfee in BPS
        For example a fee of 100 would be equivalent to a 1% fee (100 / 10_000)
    */
    function setTradingFee(uint256 newTradingFee) public onlyOwner returns (uint256) {
        tradingFee = newTradingFee;
        emit TradingFeeChange(newTradingFee);
        return tradingFee;
    }
    /**
        Set an individual seat URI
     */
    function setSeatIdURI(uint256 seatId, string memory _seatURI) public {
        require(msg.sender == owner());
        _setTokenURI(seatId, _seatURI);
    }

    /**
    VIEW FUNCTIONS
     */
    function getOptionMintingFee() public view returns (uint256) {
        return mintFee;
    }
    function getTradingFee() public view returns (uint256) {
        return tradingFee;
    }

    function confirmExists(uint256 seatId) public view returns (bool) {
        return _exists(seatId);
    }

    function getPoints(address user) public view returns (uint256) {
        return pointsTotal[user];
    }

    function getSeatScore(uint256 seatId) public view returns (uint256) {
        return seatScore[seatId];
    }
    
    function getFeeMultiplier() public view returns (uint256) {
        return feeMultiplier;
    }

    function getSeatVolume(uint256 seatId) public view returns (uint256) {
        return totalVolumeBySeat[seatId];
    }
}