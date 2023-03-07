// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/// @title HTLC contract
/// @author Z-economy



import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../../utils/IERC1155Custom.sol";

contract HTLC_V3 is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {

  /**
    @dev  initialize the TATOKEN by the ERC1155 INTERFACE.
    @dev  this will extend the functionalities of the token standard to the TATOKEN variable
  */
  IERC1155Custom TATOKEN;
  IERC1155Custom CPTOKEN;

  


  /**
    @dev  Enumerator to handle the  state of requested offers

    INVALID:  non existing offer request
    OPEN:     currently open and active offer request
    SETTLED:  settled and closed offer request
    EXPIRED:  Expired and refunded offers
  */

  enum OfferState {

    INVALID,
    OPEN,
    SETTLED,
    EXPIRED

  }


  /**
    @dev  struct to store the information about the request offer
  */
  struct RequestOfferDetails {

    address party;
    address counterParty;
    uint256[] partyCPTokenIds;
    uint256[] partyCPTokenAmounts;
    uint256[] partyTATokenIds;
    uint256[] partyTATokenAmounts;
    uint256[] counterPartyCPTokenIds;
    uint256[] counterPartyCPTokenAmounts;
    uint256[] counterPartyTATokenIds;
    uint256[] counterPartyTATokenAmounts;
    uint256 counterPartyWithdrawalExpiration;
    OfferState offerState;
    bytes32 requestOfferId;
    bool partyRefunded;
    
  }

  /**
    @dev  map to track the state of each request offer id
  */
  mapping(bytes32 => OfferState) private requestOfferState;

  /**
    @dev  map to track the offer details of each request offer id
  */
  mapping(bytes32 => RequestOfferDetails) private requestOfferDetails;

  mapping (bytes32 => bool) private counterPartyResponded;

  address private _contractOwner;


  //  remove the reinitializer(2) for QA and PRODUCTION

  function initialize (address tatokenAddress, address cptokenAddress) public {

      TATOKEN = IERC1155Custom(tatokenAddress);
      CPTOKEN = IERC1155Custom(cptokenAddress);
      _contractOwner = msg.sender;
      
      

  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
     _disableInitializers();
  }


  /**
  
    @dev  the function to submit an offer reqeust
    @param cptokenGiveIds is an array of cptoken ids that the party will be offering and submitting
    @param cptokenGiveAmounts is an array of cptoken amount that is corresponding to the index of the id in the cptokenGiveIds array that party will be offering and submitting
    @param tatokenGiveIds is an array of tatoken ids that the party will be offering and submitting
    @param tatokenGiveAmounts is an array of tatoken amount that is corresponding to the index of the id in the tatokenGiveIds array that party will be offering and submitting
    @param withdrawalExpiration is the swap validity period
    @param counterParty is the counterparty's address

    @dev  the index of an id in the array id must be corresponding to the index of the amount that will be offered
    
  */

  function partySubmitsOfferRequest(uint256[] memory cptokenGiveIds, uint256[] memory cptokenGiveAmounts, uint256[] memory tatokenGiveIds, uint256[] memory tatokenGiveAmounts, uint256 withdrawalExpiration, address counterParty, bytes32 requestOfferId, string calldata keyAuth) external {

    require(requestOfferState[requestOfferId] == OfferState.INVALID, "Existing request ID");
    require(msg.sender != counterParty, "Invalid counter-party");
    require(counterParty != address(0), "Address cannot be address zero");
    require(withdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
    require(cptokenGiveIds.length != 0 || tatokenGiveIds.length != 0, "Either of the tokens must have a valid Id");
    require(cptokenGiveAmounts.length != 0 || tatokenGiveAmounts.length != 0, "Either of the tokens must have valid values");
  

    require(_validateCpToken(cptokenGiveIds, cptokenGiveAmounts));    //  validate the cp token
    require(_validateTaToken(tatokenGiveIds, tatokenGiveAmounts));    //  validate the ta token


    _transfer(msg.sender, address(this), cptokenGiveIds, cptokenGiveAmounts, tatokenGiveIds, tatokenGiveAmounts, keyAuth);
    
    requestOfferDetails[requestOfferId] = RequestOfferDetails( msg.sender,  counterParty, cptokenGiveIds, cptokenGiveAmounts, tatokenGiveIds, tatokenGiveAmounts,  new uint256[](0), new uint256[](0), new uint256[](0), new uint256[](0), withdrawalExpiration, OfferState.OPEN, requestOfferId, false );
    requestOfferState[requestOfferId] = OfferState.OPEN;

    emit OpenOfferRequest(msg.sender, counterParty, withdrawalExpiration, requestOfferId);

    

  }


  /**

    @dev  function to be called only by the corresponding counter party of the offer
    @dev  the function initiates the swap by releasing the tokens in the htlc to the counter party and moving the counter party's tokens to the corresponding party
    @param cptokenGiveIds is an array of cptoken ids that the counterparty will be offering and submitting
    @param cptokenGiveAmounts is an array of cptoken amount that is corresponding to the index of the id in the cptokenGiveIds array that the counterparty will be offering and submitting
    @param tatokenGiveIds is an array of tatoken ids that the counterparty will be offering and submitting
    @param tatokenGiveAmounts is an array of tatoken amount that is corresponding to the index of the id in the tatokenGiveIds array that the counterparty will be offering and submitting


  */
  function acceptAndSwap (uint256[] memory cptokenGiveIds, uint256[] memory cptokenGiveAmounts, uint256[] memory tatokenGiveIds, uint256[] memory tatokenGiveAmounts, bytes32 requestOfferId, string calldata keyAuth) external {
    
    require(counterPartyResponded[requestOfferId] == false, "Offer has been fullfiled");
    require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
    RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
    require(_requestOfferDetails.counterParty == msg.sender, "Invalid offer recipient");
    require(_requestOfferDetails.counterPartyWithdrawalExpiration > block.timestamp, "Settlement expired");
    
    require(cptokenGiveIds.length != 0 || tatokenGiveIds.length != 0, "Either of the tokens must have a valid Id");
    require(cptokenGiveAmounts.length != 0 || tatokenGiveAmounts.length != 0, "Either of the tokens must have valid values");


    
    require(_validateCpToken(cptokenGiveIds, cptokenGiveAmounts));    //  validate the cp token
    require(_validateTaToken(tatokenGiveIds, tatokenGiveAmounts));    //  validate the ta token


    /**
      @dev  counter party submits offer and have their tokens sent to the party
     */


    _transfer(msg.sender, _requestOfferDetails.party, cptokenGiveIds, cptokenGiveAmounts, tatokenGiveIds, tatokenGiveAmounts, keyAuth);

    //  update the offer details

    requestOfferDetails[requestOfferId].counterPartyCPTokenIds = cptokenGiveIds;
    requestOfferDetails[requestOfferId].counterPartyCPTokenAmounts = cptokenGiveAmounts;
    requestOfferDetails[requestOfferId].counterPartyTATokenIds = tatokenGiveIds;
    requestOfferDetails[requestOfferId].counterPartyTATokenAmounts = tatokenGiveAmounts;


    /**
      @dev  counter party gets the tokens deposited by the party
    */


    _transfer(address(this), _requestOfferDetails.counterParty, _requestOfferDetails.partyCPTokenIds, _requestOfferDetails.partyCPTokenAmounts, _requestOfferDetails.partyTATokenIds, _requestOfferDetails.partyTATokenAmounts, keyAuth);

    requestOfferDetails[requestOfferId].offerState = OfferState.SETTLED;
    requestOfferState[requestOfferId] = OfferState.SETTLED;

    counterPartyResponded[requestOfferId] = true;


    emit Swap(_requestOfferDetails.party, msg.sender, requestOfferId);

    
  
  }

  /**
    @dev  function to refund offer
    @dev  function ton be called by the corresponding creator of the offer
    @dev  the offer must have exceeded its expiry period
  */
  
  function refundOffer ( bytes32 requestOfferId, string calldata keyAuth ) external {

      require(requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
      RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
      require(msg.sender == _contractOwner, "Not authorized to execute refund");
      require(block.timestamp > _requestOfferDetails.counterPartyWithdrawalExpiration, "Settlement not expired");

      _transfer(address(this), _requestOfferDetails.party, _requestOfferDetails.partyCPTokenIds, _requestOfferDetails.partyCPTokenAmounts, _requestOfferDetails.partyTATokenIds, _requestOfferDetails.partyTATokenAmounts, keyAuth);   
      
      requestOfferState[requestOfferId] = OfferState.EXPIRED;
      requestOfferDetails[requestOfferId].offerState = OfferState.EXPIRED;
      requestOfferDetails[requestOfferId].partyRefunded = true;


      emit RefundOffer(_requestOfferDetails.party, requestOfferId);
  }

  /**
    @dev function to check and fetch details of an offer using the offer request Id

    @notice `pragma experimental ABIEncoderV2` after the contract version. It was needed by this compiler version to return struct as value
  */

  function checkOfferDetails( bytes32 requestOfferId ) external view returns ( RequestOfferDetails memory ) {

      require( requestOfferState[requestOfferId] != OfferState.INVALID, "Invalid request offer Id" );
      return requestOfferDetails[requestOfferId];

  }


  /**
    @dev  an internal tranfer function to move tokens within the htlc
    @dev  the function is responsible for the party's deposit of tokens, refund and the swaping
  */

  function _transfer (address from, address to, uint256[] memory cptokenIds, uint256[] memory cptokenAmount, uint256[] memory tatokenIds, uint256[] memory tatokenAmount, string calldata keyAuth) internal {

    //  only transfer CP token
    if (tatokenIds.length == 0 && cptokenIds.length != 0) {
      
      CPTOKEN.safeBatchTransferFrom(from, to, cptokenIds , cptokenAmount, "", keyAuth);      //safeTransferFrom(msg.sender, address(this), cptokenGiveId, cptokenGiveAmount, "", keyAuth);

    }

    //  only transfer TA token
    if (tatokenIds.length !=0 && cptokenIds.length == 0) {
       TATOKEN.safeBatchTransferFrom(from, to, tatokenIds , tatokenAmount, "", keyAuth);
    }


    //  transfer both CP token and TA token
    if (tatokenIds.length !=0 && cptokenIds.length != 0) {

      //  transfer CP and TA token
      CPTOKEN.safeBatchTransferFrom(from, to, cptokenIds , cptokenAmount, "", keyAuth);
      TATOKEN.safeBatchTransferFrom(from, to, tatokenIds , tatokenAmount, "", keyAuth);

    }

  }

  /**
    @dev function to validate cp token to be exchanged such as the balance, conflict between the array of ids and amount and zero values
    @return validated as true if the validation is successful
   */
  function _validateCpToken(uint256[] memory cptokenGiveIds, uint256[] memory cptokenGiveAmounts) internal view returns (bool validated) {

    if (cptokenGiveIds.length != 0) {

      require(cptokenGiveIds.length == cptokenGiveAmounts.length, "Token Id array and Amount arrays must be of the same size");
      
       
      
      address[] memory partyAddress = new address[](cptokenGiveIds.length);     //  declare an array of addresses


      //  initialize an array for the sender
      for (uint256 index; cptokenGiveIds.length > index; index ++) {

        partyAddress[index] = msg.sender;     //  use the resultant value to get the balance

      }

      //  get balances
      uint256[] memory balances = CPTOKEN.balanceOfBatch(partyAddress, cptokenGiveIds);


      for (uint256 index; cptokenGiveIds.length > index; index ++) {

        //  check zero values
        //  check balances
        require(cptokenGiveIds[index] != 0, "CP token Id cannot be zero");
        require(cptokenGiveAmounts[index] != 0, "CP token amount cannot be zero");
        require(balances[index] >= cptokenGiveAmounts[index], "Insufficient CP token balance");

      }

      require( CPTOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move CP tokens");

    }

    return true;

  }

  /**
    @dev function to validate ta token to be exchanged such as the balance, conflict between the array of ids and amount and zero values
    @return validated as true if the validation is successful
   */
  function _validateTaToken(uint256[] memory tatokenGiveIds, uint256[] memory tatokenGiveAmounts) internal view returns (bool validated) {

    if (tatokenGiveIds.length != 0) {

      require(tatokenGiveIds.length == tatokenGiveAmounts.length, "Token Id array and Amount arrays must be of the same size");
      
       
      
      address[] memory partyAddress = new address[](tatokenGiveIds.length);     //  declare an array of addresses


      //  initialize an array for the sender
      for (uint256 index; tatokenGiveIds.length > index; index ++) {

        partyAddress[index] = msg.sender;     //  use the resultant value to get the balance

      }

      //  get balances
      uint256[] memory balances = TATOKEN.balanceOfBatch(partyAddress, tatokenGiveIds);


      for (uint256 index; tatokenGiveIds.length > index; index ++) {

        //  check zero values
        //  check balances
        require(tatokenGiveIds[index] != 0, "TA token Id cannot be zero");
        require(tatokenGiveAmounts[index] != 0, "TA token amount cannot be zero");
        require(balances[index] >= tatokenGiveAmounts[index], "Insufficient TA token balance");

      }

      require( TATOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move TA tokens");

    }

    return true;

  }



  /**
    @dev functions implements the ECR1155Receiver. This is required for ERC1155 tokens to be sent to this contract
  */

  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4){
      return this.onERC1155Received.selector;
  }

   /**
    @dev functions implements the batch ECR1155Receiver. This is required for ERC1155 tokens to be sent to this contract
  */
  function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4){
      return this.onERC1155BatchReceived.selector;
  }


//  event to be emitted whenever an offer request is created
event OpenOfferRequest(address indexed party, address indexed counterParty, uint256 withdrawalExpiration, bytes32 requestOfferId);

//  event to be emitted whenever an offer is refunded
event RefundOffer(address indexed party, bytes32 requestOfferId);

//  emit the swap event with the details of the tokens that were offered by the counter party
event Swap(address indexed party, address indexed counterParty, bytes32 requestOfferId);
  


}