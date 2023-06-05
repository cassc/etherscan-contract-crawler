// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

import "./IGBM.sol";
import "./IGBMInitiator.sol";
import "../tokens/IERC20.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC721TokenReceiver.sol";
import "../tokens/IERC1155.sol";
import "../tokens/IERC1155TokenReceiver.sol";
import "../tokens/Ownable.sol";

/// @title GBM auction contract
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud and Javier Fraile
contract GBM is IGBM, IERC1155TokenReceiver, IERC721TokenReceiver {

    //Struct used to store the representation of an NFT being auctionned
    struct token_representation {
        address contractAddress; // The contract address
        uint256 tokenID; // The ID of the token on the contract
        bytes4 tokenKind; // The ERC name of the token implementation bytes4(keccak256("ERC721")) or bytes4(keccak256("ERC1155"))
        uint256 tokenAmount; // Amount of token units under auction
    }

    struct Auction {
        uint256 dueIncentives;         // _auctionID => dueIncentives
        uint256 debt;                  // _auctionID => unsettled debt
        address highestBidder;         // _auctionID => bidder
        uint256 highestBid;            // _auctionID => bid
        bool biddingAllowed;           // tokencontract => Allow to start/pause ongoing auctions

        uint256 startTime;             // _auctionID => timestamp
        uint256 endTime;               // _auctionID => timestamp
        uint256 hammerTimeDuration;    // _auctionID => duration in seconds
        uint256 bidDecimals;           // _auctionID => bidDecimals
        uint256 stepMin;               // _auctionID => stepMin
        uint256 incMin;                // _auctionID => minimal earned incentives
        uint256 incMax;                // _auctionID => maximal earned incentives
        uint256 bidMultiplier;         // _auctionID => bid incentive growth multiplier
    }

    struct Collection {
        uint256 startTime;
        uint256 endTime;
        uint256 hammerTimeDuration;
        uint256 bidDecimals;
        uint256 stepMin;
        uint256 incMin; // minimal earned incentives
        uint256 incMax; // maximal earned incentives
        uint256 bidMultiplier; // bid incentive growth multiplier
        bool biddingAllowed; // Allow to start/pause ongoing auctions
    }

    //The address of the auctionner to whom all profits will be sent
    address public override owner;

    //Contract address storing the ERC20 currency used in auctions

    mapping(uint256 => token_representation) internal tokenMapping; //_auctionID => token_primaryKey
    mapping(address => mapping(bytes4 => mapping(uint256 => mapping(uint256 => uint256)))) auctionMapping; // contractAddress => tokenKind => tokenID => TokenIndex => _auctionID
    mapping(address => mapping(bytes4 => mapping(uint256 => mapping(uint256 => uint256)))) previousAuctionData; // contractAddress => tokenKind => tokenID => TokenIndex => _auctionID
 
    mapping(address => Collection) collections;
    mapping(uint256 => bool) claimed; // _auctionID => claimed Boolean preventing multiple claim of a token

    mapping(uint256 => Auction) auctions;

    mapping(address => mapping(uint256 => uint256)) eRC1155_tokensIndex; //Contract => TokenID => Auction index being auctionned
    mapping(address => mapping(uint256 => uint256)) eRC721_tokensIndex; //Contract => TokenID =>  Auction index being auctionned
    mapping(address => mapping(uint256 => uint256)) eRC1155_tokensUnderAuction; //Contract => TokenID => Amount being auctionned
    
    address beneficiary;

    uint256 auctionTokenIDOneOffRangeStart;
    uint256 auctionTokenIDOneOffRangeEnd;
    

    modifier onlyTokenOwner(address _contract) {
        require(msg.sender == Ownable(_contract).owner(), "Only allowed to the owner of the token contract");
        _;
    }

     modifier onlyThisContractOwner() {
        require(msg.sender == owner, "Only allowed to the owner of this contract");
        _;
    }

    constructor()
    {
        owner = msg.sender;
    }

    function setBeneficiary(address _beneficiary) external {
        require(msg.sender == owner, "Not the owner of the contract");
        beneficiary = _beneficiary;
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionID The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    function bid(uint256 _auctionID, uint256 _bidAmount, uint256 _highestBid) external payable override {
        require(tokenMapping[0].contractAddress != address(0x0) && (_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "bid: auctionID does not exist"); //Modified for the one off registration
        require(collections[tokenMapping[0].contractAddress].biddingAllowed, "bid: bidding is currently not allowed");  //Modified for the one off registration
        require(!claimed[_auctionID], "claim: this auction has alredy been claimed");
        
        require(_bidAmount > 1, "bid: _bidAmount cannot be 0");
        require(_highestBid == auctions[_auctionID].highestBid, "bid: current highest bid do not match the submitted transaction _highestBid");

        //An auction start time of 0 also indicate the auction has not been created at all
        require(getAuctionStartTime(_auctionID) <= block.timestamp && getAuctionStartTime(_auctionID) != 0, "bid: Auction has not started yet"); 
        require(getAuctionEndTime(_auctionID) >= block.timestamp, "bid: Auction has already ended");

        require(_bidAmount > _highestBid, "bid: _bidAmount must be higher than _highestBid");
	    require((_highestBid * (getAuctionBidDecimals(_auctionID) + getAuctionStepMin(_auctionID))) <= (_bidAmount * getAuctionBidDecimals(_auctionID)),
            "bid: _bidAmount must meet the minimum bid"
        );
        
        //Transfer the money of the bidder to the GBM smart contract
        require(msg.value == _bidAmount, "The bid amount doesn't match the amount of currency sent");

        //Extend the duration time of the auction if we are close to the end
        if(getAuctionEndTime(_auctionID) < block.timestamp + getHammerTimeDuration(_auctionID)) {
            auctions[_auctionID].endTime = block.timestamp + getHammerTimeDuration(_auctionID);
            emit Auction_EndTimeUpdated(_auctionID, auctions[_auctionID].endTime);
        }

        // Saving incentives for later sending
        uint256 duePay = auctions[_auctionID].dueIncentives;
        address previousHighestBidder = auctions[_auctionID].highestBidder;
        uint256 previousHighestBid = auctions[_auctionID].highestBid;

        // Emitting the event sequence
        if(previousHighestBidder != address(0)) {
            emit Auction_BidRemoved(_auctionID, previousHighestBidder, previousHighestBid);
        }

        if(duePay != 0) {
            auctions[_auctionID].debt = auctions[_auctionID].debt + duePay;
            emit Auction_IncentivePaid(_auctionID, previousHighestBidder, duePay);
        }

        emit Auction_BidPlaced(_auctionID, msg.sender, _bidAmount);

        // Calculating incentives for the new bidder
        auctions[_auctionID].dueIncentives = calculateIncentives(_auctionID, _bidAmount);

        //Setting the new bid/bidder as the highest bid/bidder
        auctions[_auctionID].highestBidder = msg.sender;
        auctions[_auctionID].highestBid = _bidAmount;

        if((previousHighestBid + duePay) != 0) {
            //Refunding the previous bid as well as sending the incentives
            (bool sent, bytes memory data) = previousHighestBidder.call{value: previousHighestBid + duePay}("");
            //Not check to avoid a contract revert in the receive function that locks the auction
            // require(sent, "Failed to refund ETH");
        }
    }

    /// @notice Attribute a token to the winner of the auction and distribute the proceeds to the owner of this contract.
    /// throw if bidding is disabled or if the auction is not finished.
    /// @param _auctionID The auctionID of the auction to complete
    function claim(uint256 _auctionID) external override {
        address _ca = tokenMapping[0].contractAddress;         //Modified for one Off
        uint256 _tid = _auctionID;         //Modified for one Off
        bytes4 _tkd = tokenMapping[0].tokenKind; //Modified for one Off
        uint256 _tam = 1; //Modified for one Off

        require(_ca != address(0x0), "claim: auctionID does not exist");
        require(collections[_ca].biddingAllowed, "claim: Claiming is currently not allowed");
        require(getAuctionEndTime(_auctionID) < block.timestamp, "claim: Auction has not yet ended");

        require(!claimed[_auctionID], "claim: this auction has alredy been claimed");   
        claimed[_auctionID] = true;

        /* 
        //Do not use in current version. We assume approved tokens, not one transferred to the GBM contract.
        if (auctions[_auctionID].highestBid == 0) {
            auctions[_auctionID].highestBidder = Ownable(_ca).owner();
        }   
        */     

        //Transfer the proceeds to the beneficiary
        uint256 finalAmount = auctions[_auctionID].highestBid - auctions[_auctionID].debt;
        require(beneficiary != address(0), "Beneficiary address not set");
        (bool sent, bytes memory data) = beneficiary.call{value: finalAmount}("");
        // require(sent, "Failed to final amount");

        if (_tkd == bytes4(keccak256("ERC721"))) { //0x73ad2146
            IERC721(_ca).safeTransferFrom(owner, auctions[_auctionID].highestBidder, _tid);
            auctionMapping[_ca][_tkd][_tid][0] = 0;
        } else if (_tkd == bytes4(keccak256("ERC1155"))) { //0x973bb640
            IERC1155(_ca).safeTransferFrom(owner, auctions[_auctionID].highestBidder, _tid, _tam, "");
            // eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] - _tam;
        }

        emit Auction_Claimed(_auctionID);
    }

    /// @notice Register an auction contract default parameters for a GBM auction. To use to save gas
    /// @param _contract The token contract the auctionned token belong to
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract
    function registerAnAuctionContract(address _contract, address _initiator) public override onlyThisContractOwner() {
        collections[_contract].startTime = IGBMInitiator(_initiator).getStartTime(uint256(uint160(_contract)));
        collections[_contract].endTime = IGBMInitiator(_initiator).getEndTime(uint256(uint160(_contract)));
        collections[_contract].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(uint256(uint160(_contract)));
        collections[_contract].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(uint256(uint160(_contract)));
        collections[_contract].stepMin = IGBMInitiator(_initiator).getStepMin(uint256(uint160(_contract)));
        collections[_contract].incMin = IGBMInitiator(_initiator).getIncMin(uint256(uint160(_contract)));
        collections[_contract].incMax = IGBMInitiator(_initiator).getIncMax(uint256(uint160(_contract)));
        collections[_contract].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(uint256(uint160(_contract)));
        require(collections[_contract].startTime > 0, "registerAnAuctionContract: Start time is not correct");
    }

    /// @notice Allow/disallow bidding and claiming for a whole token contract address.
    /// @param _contract The token contract the auctionned token belong to
    /// @param _value True if bidding/claiming should be allowed.
    function setBiddingAllowed(address _contract, bool _value) external override onlyThisContractOwner() {
        collections[_contract].biddingAllowed = _value;
    }

    /// @notice Modify the auction of a token
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _auctionID ID of the auction to modify
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default, 
    /// use an initiator sending back 0 on it's getters)
    function modifyAnAuctionToken(uint256 _auctionID, address _initiator) external override onlyThisContractOwner() {
        modifyAnAuctionToken(_auctionID, 0, _initiator);
    }

    /// @notice Modify the auction of a token
    /// Throw if the token owner is not the GBM smart contract/supply of auctionned 1155 token is insufficient
    /// @param _auctionID ID of the auction to modify
    /// @param _tokenAmount The amount of tokens being auctionned
    /// @param _initiator Set to 0 if you want to use the default value registered for the token contract (if wanting to reset to default, 
    /// use an initiator sending back 0 on it's getters)
    function modifyAnAuctionToken(uint256 _auctionID, uint256 _tokenAmount, address _initiator) public override onlyThisContractOwner() {
        address _ca = tokenMapping[_auctionID].contractAddress;
        bytes4 _tki = tokenMapping[_auctionID].tokenKind;
        uint256 _tid = tokenMapping[_auctionID].tokenID;
        uint256 _tam = tokenMapping[_auctionID].tokenAmount;
        
        require(msg.sender == Ownable(_ca).owner(), "modifyAnAuctionToken: Only the owner of a contract can modify an auction");
        require(_ca != address(0), "modifyAnAuctionToken: Auction ID is not correct");
        require(auctions[_auctionID].startTime > block.timestamp, "modifyAnAuctionToken: Auction has already started");
        require(_initiator != address(0), "modifyAnAuctionToken: Initiator address is not correct");
        
        if (_tam != _tokenAmount && _tokenAmount != 0) {
            require(_tki == bytes4(keccak256("ERC1155")), "modifyAnAuctionToken: Token amount for auction token kind not correct");
            require(_tokenAmount >= 1, "modifyAnAuctionToken: Token amount not correct");
            tokenMapping[_auctionID].tokenAmount = _tokenAmount;
            
            uint256 _tokenDiff;
            if (_tam < _tokenAmount) {
                _tokenDiff = _tokenAmount - _tam;
                require((eRC1155_tokensUnderAuction[_ca][_tid] + _tokenDiff) <= IERC1155(_ca).balanceOf(address(this), _tid), 
                    "modifyAnAuctionToken: Cannot set to auction that amount of tokens");
                eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] + _tokenDiff;
            } else {
                _tokenDiff = _tam - _tokenAmount;
                require((eRC1155_tokensUnderAuction[_ca][_tid] - _tokenDiff) <= IERC1155(_ca).balanceOf(address(this), _tid),
                    "modifyAnAuctionToken: Cannot set to auction that amount of tokens");
                eRC1155_tokensUnderAuction[_ca][_tid] = eRC1155_tokensUnderAuction[_ca][_tid] - _tokenDiff;
            }
        }
        
        auctions[_auctionID].startTime = IGBMInitiator(_initiator).getStartTime(_auctionID);
        auctions[_auctionID].endTime = IGBMInitiator(_initiator).getEndTime(_auctionID);
        auctions[_auctionID].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(_auctionID);
        auctions[_auctionID].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(_auctionID);
        auctions[_auctionID].stepMin = IGBMInitiator(_initiator).getStepMin(_auctionID);
        auctions[_auctionID].incMin = IGBMInitiator(_initiator).getIncMin(_auctionID);
        auctions[_auctionID].incMax = IGBMInitiator(_initiator).getIncMax(_auctionID);
        auctions[_auctionID].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(_auctionID);

        require(auctions[_auctionID].startTime > 0, "modifyAnAuctionToken: Start time is not correct");
    }



    //This function will NOT transfer the tokens to the smart contract. Instead, it assume the seller have given approvedForAll 1155 to the GBM smart contract.
    function massRegistrerOneOff(address _initiator, address _ERC1155Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external override onlyThisContractOwner() {

        //registering all auction Data with the ID 0. Lookup will be done on auctionID 0 if the data at the acutal auctionID is null
        if(_initiator != address(0x0)) {
            auctions[0].startTime = IGBMInitiator(_initiator).getStartTime(0);
            auctions[0].endTime = IGBMInitiator(_initiator).getEndTime(0);
            auctions[0].hammerTimeDuration = IGBMInitiator(_initiator).getHammerTimeDuration(0);
            auctions[0].bidDecimals = IGBMInitiator(_initiator).getBidDecimals(0);
            auctions[0].stepMin = IGBMInitiator(_initiator).getStepMin(0);
            auctions[0].incMin = IGBMInitiator(_initiator).getIncMin(0);
            auctions[0].incMax = IGBMInitiator(_initiator).getIncMax(0);
            auctions[0].bidMultiplier = IGBMInitiator(_initiator).getBidMultiplier(0);
            tokenMapping[0].tokenKind = bytes4(keccak256("ERC1155"));
            tokenMapping[0].contractAddress = _ERC1155Contract;
            require(auctions[0].startTime > 0, "registerAuctionData: Start time is not correct");
        }

        auctionTokenIDOneOffRangeStart = _tokenIDStart;
        auctionTokenIDOneOffRangeEnd = _tokenIDEnd;

        if(beneficiary == address(0)){
            beneficiary = msg.sender;
        }

        collections[_ERC1155Contract].biddingAllowed = true;

    }


    function getAuctionHighestBidder(uint256 _auctionID) external override view returns(address) {
        return auctions[_auctionID].highestBidder;
    }

    function getAuctionHighestBid(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].highestBid;
    }

    function getAuctionDebt(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].debt;
    }

    function getAuctionDueIncentives(uint256 _auctionID) external override view returns(uint256) {
        return auctions[_auctionID].dueIncentives;
    }
    
    function getAuctionID(address _contract, bytes4 _tokenKind, uint256 _tokenID, uint256 _index) external override view returns(uint256) {
        require( tokenMapping[0].contractAddress == _contract, "Contract not under auction");
        return _tokenID;  //Modified for one Off auctions
    }

    function getTokenKind(uint256 _auctionID) external override view returns(bytes4) {
        return tokenMapping[0].tokenKind; //Modified for one Off auctions
    }

    function getTokenId(uint256 _auctionID) external override view returns(uint256) {
        return _auctionID; //Modified for one Off auctions
    }

    function getTokenAmount(uint256 _auctionID) external override view returns(uint256){
        return 1; //Modified for one Off auctions
    }

    function getContractAddress(uint256 _auctionID) external override view returns(address) {
        return tokenMapping[0].contractAddress;
    }

    function getAuctionStartTime(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].startTime != 0) {
            return auctions[_auctionID].startTime;
        } else {
            return auctions[0].startTime;
        }
    }

    function getAuctionEndTime(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].endTime != 0) {
            return auctions[_auctionID].endTime;
        } else {
            return auctions[0].endTime;
        }
    }

    function getHammerTimeDuration(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].hammerTimeDuration != 0) {
            return auctions[_auctionID].hammerTimeDuration;
        } else {
            return auctions[0].hammerTimeDuration;
        }
    }


    function getAuctionBidDecimals(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].bidDecimals != 0) {
            return auctions[_auctionID].bidDecimals;
        } else {
            return auctions[0].bidDecimals;
        }
    }

    function getAuctionStepMin(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].stepMin != 0) {
            return auctions[_auctionID].stepMin;
        } else {
            return auctions[0].stepMin;
        }
    }

    function getAuctionIncMin(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].incMin != 0) {
            return auctions[_auctionID].incMin;
        } else {
            return auctions[0].incMin;
        }
    }

    function getAuctionIncMax(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].incMax != 0) {
            return auctions[_auctionID].incMax;
        } else {
            return auctions[0].incMax;
        }
    }

    function getAuctionBidMultiplier(uint256 _auctionID) public override view returns(uint256) {
        require((_auctionID >= auctionTokenIDOneOffRangeStart) && (_auctionID <= auctionTokenIDOneOffRangeEnd), "Token not registered for sale");
        if(auctions[_auctionID].bidMultiplier != 0) {
            return auctions[_auctionID].bidMultiplier;
        } else {
            return auctions[0].bidMultiplier;
        }
    }

    function onERC721Received(address /* _operator */, address /* _from */, uint256 /* _tokenID */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address /* _operator */, address /* _from */, uint256 /* _id */, uint256 /* _value */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

   
    function onERC1155BatchReceived(address /* _operator */, address /* _from */, uint256[] calldata /* _ids */, uint256[] calldata /* _values */, bytes calldata /* _data */) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }    


    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    function calculateIncentives(uint256 _auctionID, uint256 _newBidValue) internal view returns (uint256) {

        uint256 bidDecimals = getAuctionBidDecimals(_auctionID);
        uint256 bidIncMax = getAuctionIncMax(_auctionID);

        //Init the baseline bid we need to perform against
        uint256 baseBid = auctions[_auctionID].highestBid * (bidDecimals + getAuctionStepMin(_auctionID)) / bidDecimals;

        //If no bids are present, set a basebid value of 1 to prevent divide by 0 errors
        if(baseBid == 0) {
            baseBid = 1;
        }

        //Ratio of newBid compared to expected minBid
        uint256 decimaledRatio = ((bidDecimals * getAuctionBidMultiplier(_auctionID) * (_newBidValue - baseBid) ) / baseBid) + 
            getAuctionIncMin(_auctionID) * bidDecimals;

        if(decimaledRatio > (bidDecimals * bidIncMax)) {
            decimaledRatio = bidDecimals * bidIncMax;
        }

        return  (_newBidValue * decimaledRatio)/(bidDecimals*bidDecimals);
    }


    //Functions not usable in current implementation
        	
	function massRegistrerERC721Each(address _initiator, address _ERC721Contract, uint256 _tokenIDStart, uint256 _tokenIDEnd) external pure override {
        require(false, "This implementation only support one off registration");
    }

    function massRegistrerERC1155Each(address _initiator, address _ERC1155Contract, uint256 _tokenID, uint256 _indexStart, uint256 _indexEnd) external pure override {
        require(false, "This implementation only support one off registration");
    }


    function registerAnAuctionToken(address _contract, uint256 _tokenID, bytes4 _tokenKind, uint256 _tokenAmount, address _initiator) public pure override {
        require(false, "This implementation only support one off registration");
    }

      
}