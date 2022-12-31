pragma solidity 0.8.17;
//pragma experimental ABIEncoderV2;

/// @title HTLC for CP token to CP token atomic swap between parties and counter-parties
/// @author Z-economy
/// @notice This contract holds CP tokens whenever CP token holders opens a request for a swap with TA tokens

//import "../utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "../utils/IERC1155Custom.sol";


contract C2CHTLC is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {

    /**
    @dev  initialize the CPTOKEN by the ERC1155 INTERFACE.
    @dev  this will extend the functionalities of the token standard to the CPTOKEN variable
    */
    //IERC1155 CPTOKEN;
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


    function initialize (address cpTokenAddress) public initializer {

      CPTOKEN = IERC1155Custom(cpTokenAddress);

    }

    /**
        @dev    function for a party to submit an offer request,  CP token for CP token

        amount should not be zero
        Id must be invalid ( not an existing id )
        party's address must not be the same as the counter party
        counter party expiration time must be greater than the current opening time
    */

    function partySubmitsOfferRequest( uint256 cpTokenGiveAmount, uint256 cpTokenGiveId, uint256 counterPartyCPTokenWithdrawalExpiration, address counterParty, bytes32 requestOfferId, string calldata keyAuth  ) external {

        require(requestOfferState[requestOfferId] == OfferState.INVALID, "Existing request ID");
        require(msg.sender != counterParty, "Invalid counter-party");
        require(cpTokenGiveAmount > 0, "Amount can't be zero");
        require(counterPartyCPTokenWithdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
        require(CPTOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move tokens");
        CPTOKEN.safeTransferFrom(msg.sender, address(this), cpTokenGiveId, cpTokenGiveAmount, "", keyAuth);
        requestOfferState[requestOfferId] = OfferState.OPEN;
        requestOfferDetails[requestOfferId] = RequestOfferDetails(msg.sender, counterParty, cpTokenGiveId, 0, cpTokenGiveAmount, 0, 0, counterPartyCPTokenWithdrawalExpiration, OfferState.OPEN, requestOfferId, false, false, false, false);
        emit OpenOfferRequest(msg.sender, cpTokenGiveId, cpTokenGiveAmount, counterPartyCPTokenWithdrawalExpiration, requestOfferId);

    }

    /**
        @dev    function for counter party to accept and submit request offer
        @notice offer state must be opened, because counter-party can only accept an existing request offer and submit their corresponding offer details
        @dev    counter party can only accept and submit his offer before his withdrawal expiration date
    */

    function counterPartySubmitsOfferRequest( uint256 cpTokenGiveAmount, uint256 cpTokenGiveId, uint256 partyCPTokenWithdrawalExpiration, bytes32 requestOfferId, string calldata keyAuth ) external {

        require( requestOfferState[requestOfferId] == OfferState.OPEN, "Request not opened");
        RequestOfferDetails memory _requestOfferDetails = requestOfferDetails[requestOfferId];              //  fetch the request details
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid counter-party");                  //  the msg.sender must be the counter party for this request id
        require(_requestOfferDetails.counterPartyTokenWithdrawalExpiration > block.timestamp, "Settlement expired");
        require(partyCPTokenWithdrawalExpiration > block.timestamp, "Expiration period must be more than current time");
        require(cpTokenGiveAmount > 0, "Amount can't be zero");
        require(CPTOKEN.isApprovedForAll(msg.sender, address(this)), "HTLC not approved to move tokens");
        CPTOKEN.safeTransferFrom(msg.sender, address(this), cpTokenGiveId, cpTokenGiveAmount, "", keyAuth);
        requestOfferDetails[requestOfferId].counterPartyTokenGiveId = cpTokenGiveId;
        requestOfferDetails[requestOfferId].counterPartyTokenGiveAmount = cpTokenGiveAmount;
        requestOfferDetails[requestOfferId].partyTokenWithdrawalExpiration = partyCPTokenWithdrawalExpiration;
        emit OpenOfferRequest( msg.sender, cpTokenGiveId, cpTokenGiveAmount, partyCPTokenWithdrawalExpiration, requestOfferId );

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
        require(_requestOfferDetails.party == msg.sender, "Invalid CP token recipient");
        require(block.timestamp < _requestOfferDetails.partyTokenWithdrawalExpiration, "Settlement expired");
        CPTOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.counterPartyTokenGiveId, _requestOfferDetails.counterPartyTokenGiveAmount, "", keyAuth);
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
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid CP token recipient");
        require(block.timestamp < _requestOfferDetails.partyTokenWithdrawalExpiration, "Settlement expired");
        CPTOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.partyTokenGiveId, _requestOfferDetails.partyTokenGiveAmount, "", keyAuth);
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
        require(_requestOfferDetails.party == msg.sender, "Invalid CP token recipient");
        require(block.timestamp  > _requestOfferDetails.counterPartyTokenWithdrawalExpiration, "Settlement not expired");
        CPTOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.partyTokenGiveId, _requestOfferDetails.partyTokenGiveAmount, "", keyAuth);
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
        require(_requestOfferDetails.counterParty == msg.sender, "Invalid CP token recipient");
        require(block.timestamp  > _requestOfferDetails.counterPartyTokenWithdrawalExpiration, "Settlement not expired");
        CPTOKEN.safeTransferFrom(address(this), msg.sender, _requestOfferDetails.counterPartyTokenGiveId, _requestOfferDetails.counterPartyTokenGiveAmount, "", keyAuth);
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
    event WithdrawOfferRequest(address indexed party, uint256 cpTokenId, uint256 cpTokenAmount, bytes32 requestOfferId);
    
    //  event to be emitted whenever an offer is refunded
    event RefundOffer(address indexed party, uint256 cpTokenId, uint256 cpTokenAmount, bytes32 requestOfferId);

}