// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
//pragma experimental ABIEncoderV2;

/// @title HTLC for TA token swap with CP token
/// @author Z-economy
/// @notice This contract holds TA tokens whenever TA token holders opens a request for a swap with CP tokens


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../utils/IERC1155Custom.sol";

contract T2CHTLC is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {

  /**
    @dev  initialize the TATOKEN by the ERC1155 INTERFACE.
    @dev  this will extend the functionalities of the token standard to the TATOKEN variable
  */
  IERC1155Custom TATOKEN;


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

    address cpTokenHolder;
    address taTokenHolder;
    uint256 cpTokenId;
    uint256 taTokenId;
    uint256 cpTokenAmount;
    uint256 taTokenAmount;
    uint256 taTokenWithdrawalExpiration;
    OfferState offerState;
    bytes32 requestOfferId;
    

  }

  /**
    @dev  map to track the state of each request offer id
  */
  mapping(bytes32 => OfferState) private requestOfferState;

  /**
    @dev  map to track the offer details of each request offer id
  */
  mapping(bytes32 => RequestOfferDetails) private requestOfferDetails;


  function initialize (address tatokenAddress) public initializer {

      TATOKEN = IERC1155Custom(tatokenAddress);

  }

  /**
      @dev  function to create offer request for ta token
      @notice that it reverts if ta token holders haven't approved this atomic contract to move their tokens 
      @notice the offer state is set to OPEN
      @notice the offer details is initalized
      @notice the OpenOfferRequest is emitted
  */

  function createOfferRequest( address cpTokenHolder, address taTokenHolder, uint256 cpTokenId, uint256 taTokenId, uint256 cpTokenAmount, uint256 taTokenAmount, uint256 taTokenWithdrawalExpiration , bytes32 requestOfferId, string calldata keyAuth) external {

      require(msg.sender == taTokenHolder, "Offer must be opened by TA token holder");
      require(cpTokenHolder != taTokenHolder, "CP and TA token holder should not be the same address");
      require(taTokenWithdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
      require(requestOfferState[requestOfferId] == OfferState.INVALID, "Existing request ID");                
      require(TATOKEN.isApprovedForAll(taTokenHolder, address(this)), "HTLC not approved to move tokens");
      TATOKEN.safeTransferFrom(taTokenHolder, address(this), taTokenId, taTokenAmount, "", keyAuth);
      requestOfferState[requestOfferId] = OfferState.OPEN;
      requestOfferDetails[requestOfferId] = RequestOfferDetails( cpTokenHolder, taTokenHolder, cpTokenId, taTokenId, cpTokenAmount, taTokenAmount, taTokenWithdrawalExpiration, OfferState.OPEN, requestOfferId );
      emit OpenOfferRequest(cpTokenHolder, taTokenHolder, cpTokenAmount, taTokenAmount, cpTokenId, taTokenId, taTokenWithdrawalExpiration, requestOfferId);

  }

  /**
    @dev  function to settle the TA token and close the offer request
    @notice that the validity period must be a time lesser than the expiration period
  */

  function withdrawOfferRequest( bytes32 requestOfferId, string calldata keyAuth ) external {
    
      require(requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
      RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
      require(msg.sender == _requestOfferDetails.cpTokenHolder, "Invalid TA token recipient");
      require(block.timestamp < _requestOfferDetails.taTokenWithdrawalExpiration, "Settlement expired");   
      TATOKEN.safeTransferFrom(address(this), _requestOfferDetails.cpTokenHolder, _requestOfferDetails.taTokenId, _requestOfferDetails.taTokenAmount, "", keyAuth);
      requestOfferState[requestOfferId] = OfferState.SETTLED;
      requestOfferDetails[requestOfferId].offerState = OfferState.SETTLED;
      emit WithdrawOfferRequest(msg.sender, _requestOfferDetails.taTokenId, _requestOfferDetails.taTokenAmount, requestOfferId);

  }


  /**
    @dev function to refund offer
  */
  function refundOffer ( bytes32 requestOfferId, string calldata keyAuth ) external {

      require(requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
      RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
      require(msg.sender == _requestOfferDetails.taTokenHolder, "Invalid TA token holder");
      require(block.timestamp > _requestOfferDetails.taTokenWithdrawalExpiration, "Settlement not expired");   
      TATOKEN.safeTransferFrom(address(this), _requestOfferDetails.taTokenHolder, _requestOfferDetails.taTokenId, _requestOfferDetails.taTokenAmount, "", keyAuth);
      requestOfferState[requestOfferId] = OfferState.EXPIRED;
      requestOfferDetails[requestOfferId].offerState = OfferState.EXPIRED;
      emit RefundOffer(msg.sender, _requestOfferDetails.taTokenId, _requestOfferDetails.taTokenAmount, requestOfferId);
  
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
  event OpenOfferRequest(address indexed cpTokenHolder, address indexed taTokenHolder, uint256 cpTokenAmount, uint256 taTokenAmount, uint256 cpTokenId, uint256 taTokenId, uint256 taTokenWithdrawalExpiration, bytes32 requestOfferId);

  //  event to be emitted whenever an offer is being fullfilled/settled
  event WithdrawOfferRequest(address indexed taTokenRecipient, uint256 taTokenId, uint256 taTokenAmount, bytes32 requestOfferId);

  //  event to be emitted whenever an offer is refunded
  event RefundOffer(address indexed taTokenHolder, uint256 taTokenId, uint256 taTokenAmount, bytes32 requestOfferId);
  


}