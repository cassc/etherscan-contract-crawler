pragma solidity 0.8.17;
//pragma experimental ABIEncoderV2;

/// @title HTLC for TA token to TA token atomic swap between parties and counter-parties
/// @author Z-economy
/// @notice This contract holds TA tokens whenever TA token holders opens a request for a swap with TA tokens

//import "../utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../utils/IERC1155Custom.sol";


contract T2THTLC is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {

    /**
    @dev  initialize the TATOKEN by the ERC1155 INTERFACE.
    @dev  this will extend the functionalities of the token standard to the TATOKEN variable
    */
    //IERC1155 TATOKEN;
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

    struct RequestOfferDetails {

        address party;
        address counterParty;
        uint256 partyTokenGiveId;
        uint256 counterPartyTokenGiveId;
        uint256 partyTokenGiveAmount;
        uint256 counterPartyTokenGiveAmount;
        uint256 partyTokenWithdrawalExpiration;
        uint256 counterPartyTokenWithdrawalExpiration;
        OfferState offerState;
        bytes32 requestOfferId;
        bool partySettled;
        bool counterPartySettled;
        bool partyRefunded;
        bool counterPartyRefunded;

    }


    /**
        @dev  map to track the state of each request offer id
    */
    mapping(bytes32 => OfferState) private requestOfferState;

    /**
        @dev  map to track the offer details of each request offer id
    */
    mapping(bytes32 => RequestOfferDetails) private requestOfferDetails;


    function initialize(address taTokenAddress) public initializer {

      TATOKEN = IERC1155Custom(taTokenAddress);

    }

    /**
        @dev    function for a party to submit an offer request,  TA token for TA token

        amount should not be zero
        Id must be invalid ( not an existing id )
        party's address must not be the same as the counter party
        counter party expiration time must be greater than the current opening time
    */

    function partySubmitsOfferRequest( uint256 taTokenGiveAmount, uint256 taTokenGiveId, uint256 counterPartyTATokenWithdrawalExpiration, address counterParty, bytes32 requestOfferId, string calldata keyAuth  ) external {

        require(requestOfferState[requestOfferId] == OfferState.INVALID, "Existing request ID");
        require(msg.sender != counterParty, "Invalid counter-party");
        require(taTokenGiveAmount > 0, "Amount can't be zero");
        require(counterPartyTATokenWithdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
        require(TATOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move tokens");
        TATOKEN.safeTransferFrom(msg.sender, address(this), taTokenGiveId, taTokenGiveAmount, "", keyAuth);
        requestOfferState[requestOfferId] = OfferState.OPEN;
        requestOfferDetails[requestOfferId] = RequestOfferDetails(msg.sender, counterParty, taTokenGiveId, 0, taTokenGiveAmount, 0, 0, counterPartyTATokenWithdrawalExpiration, OfferState.OPEN, requestOfferId, false, false, false, false);
        emit OpenOfferRequest(msg.sender, taTokenGiveId, taTokenGiveAmount, counterPartyTATokenWithdrawalExpiration, requestOfferId);

    }

    /**
        @dev    function for counter party to accept and submit request offer
        @notice offer state must be opened, because counter-party can only accept an existing request offer and submit their corresponding offer details
        @dev    counter party can only accept and submit his offer before his withdrawal expiration date
    */

    function counterPartySubmitsOfferRequest( uint256 taTokenGiveAmount, uint256 taTokenGiveId, uint256 partyTATokenWithdrawalExpiration, bytes32 requestOfferId, string calldata keyAuth ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];              //  fetch the request details
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid counter-party");                  //  the msg.sender must be the counter party for this request id
        require(_requestOfferDetails.counterPartyTokenWithdrawalExpiration > block.timestamp, "Settlement expired");
        require(partyTATokenWithdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
        require(taTokenGiveAmount > 0, "Amount can't be zero");
        require(TATOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move tokens");
        TATOKEN.safeTransferFrom(msg.sender, address(this), taTokenGiveId, taTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].counterPartyTokenGiveId = taTokenGiveId;
        requestOfferDetails[requestOfferId].counterPartyTokenGiveAmount = taTokenGiveAmount;
        requestOfferDetails[requestOfferId].partyTokenWithdrawalExpiration = partyTATokenWithdrawalExpiration;
        emit OpenOfferRequest( msg.sender, taTokenGiveId, taTokenGiveAmount, partyTATokenWithdrawalExpiration, requestOfferId );

    }


    /**
        @dev    function for a party to withdraw the counter-party's submitted offer
        @notice withdrawal time must not exceed the expiration time. The party must be the correct recipient of the offer
                The offer state must be OPEN as at the withdrawal period.

                If both parties are settled, update the offer state to settled
     */
    function partyWithdrawsCounterPartyOffer( bytes32 requestOfferId, string calldata keyAuth ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened" );
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
        require(_requestOfferDetails.partySettled == false, "Party has been settled");
        require(_requestOfferDetails.party == msg.sender, "Invalid TA token recipient");
        require(block.timestamp < _requestOfferDetails.partyTokenWithdrawalExpiration, "Settlement expired");
        TATOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.counterPartyTokenGiveId, _requestOfferDetails.counterPartyTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].partySettled = true;

        /**
            @notice the state is updated if both parties have been settled        
        */
        
        if ( requestOfferDetails[requestOfferId].partySettled == true && requestOfferDetails[requestOfferId].counterPartySettled == true ) {

            requestOfferState[requestOfferId] = OfferState.SETTLED;
            requestOfferDetails[requestOfferId].offerState = OfferState.SETTLED;

        }

        emit WithdrawOfferRequest(msg.sender, _requestOfferDetails.counterPartyTokenGiveId,  _requestOfferDetails.counterPartyTokenGiveAmount, requestOfferId);

    }

    /**
        @dev    function for a counter-party to withdraw the party's submitted offer
        @notice withdrawal time must not exceed the expiration time. The party must be the correct recipient of the offer
                The offer state must be OPEN as at the withdrawal period.

                If both parties are settled, update the offer state to settled
     */

    function counterPartyWithdrawsPartyOffer( bytes32 requestOfferId, string calldata keyAuth ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened" );
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
        require(_requestOfferDetails.counterPartySettled == false, "Party has been settled");
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid TA token recipient");
        require(block.timestamp < _requestOfferDetails.partyTokenWithdrawalExpiration, "Settlement expired");
        TATOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.partyTokenGiveId, _requestOfferDetails.partyTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].counterPartySettled = true;

        /**
            @notice the state is updated if both parties have been settled        
        */
        
        if ( requestOfferDetails[requestOfferId].partySettled == true && requestOfferDetails[requestOfferId].counterPartySettled == true ) {

            requestOfferState[requestOfferId] = OfferState.SETTLED;
            requestOfferDetails[requestOfferId].offerState = OfferState.SETTLED;

        }

        emit WithdrawOfferRequest(msg.sender, _requestOfferDetails.partyTokenGiveId,  _requestOfferDetails.partyTokenGiveAmount, requestOfferId);

    }

    /**
        @dev    function for a party to request refund
        @notice the current time of request must be more that the set expiration time
                the settlement status for that offer must be false
                the refund status for that offer must be false
    */

    function refundParty( bytes32 requestOfferId, string calldata keyAuth  ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened" );
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
        require(_requestOfferDetails.counterPartySettled == false, "Party has been settled");
        require(_requestOfferDetails.partyRefunded == false, "Party has been refunded");
        require(_requestOfferDetails.party == msg.sender, "Invalid TA token recipient");
        require(block.timestamp  > _requestOfferDetails.counterPartyTokenWithdrawalExpiration, "Settlement not expired");
        TATOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.partyTokenGiveId, _requestOfferDetails.partyTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].partyRefunded = true;
        emit RefundOffer(msg.sender, _requestOfferDetails.partyTokenGiveId, _requestOfferDetails.partyTokenGiveAmount, requestOfferId);

    }

    /**
        @dev    function for a counter-party to request refund
        @notice the current time of request must be more that the set expiration time
                the settlement status for that offer must be false
                the refund status for that offer must be false
    */

    function refundCounterParty( bytes32 requestOfferId, string calldata keyAuth  ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened" );
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];
        require(_requestOfferDetails.partySettled == false, "Party has been settled");
        require(_requestOfferDetails.counterPartyRefunded == false, "Party has been refunded");
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid TA token recipient");
        require(block.timestamp  > _requestOfferDetails.counterPartyTokenWithdrawalExpiration, "Settlement not expired");
        TATOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.counterPartyTokenGiveId, _requestOfferDetails.counterPartyTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].counterPartyRefunded = true;
        emit RefundOffer(msg.sender, _requestOfferDetails.counterPartyTokenGiveId, _requestOfferDetails.counterPartyTokenGiveAmount, requestOfferId);
    
    }

    /**
        @dev    function to check the offer details using the request id
        @notice the request offer id must be valid
    */

    function checkOfferDetails( bytes32 requestOfferId ) external view returns (RequestOfferDetails memory) {
        
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

    /**
        Task to implement in the pre-exisiting HTLC

        1.  Amounts must be greater than 0
    */

    //  event to be emitted whenever an offer request is created
    event OpenOfferRequest( address indexed party, uint256 tokenGiveId, uint256 tokenGiveAmount, uint256 counterPartyWithdrawalExpiration, bytes32 requestOfferId );

    //  event to be emitted whenever an offer is being fullfilled/settled
    event WithdrawOfferRequest(address indexed party, uint256 taTokenId, uint256 taTokenAmount, bytes32 requestOfferId);
    
    //  event to be emitted whenever an offer is refunded
    event RefundOffer(address indexed party, uint256 taTokenId, uint256 taTokenAmount, bytes32 requestOfferId);

}