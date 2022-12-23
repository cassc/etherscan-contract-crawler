/*


            .':looooc;.    .,cccc,.    'cccc:. 'ccccc:. .:ccccccccccccc:. .:ccc:.    .;cccc,        
          .lOXNWWWNWNNKx;. .kWNNWk.    lNWNWK, dWWWNWX; :XWNWNNNNNWNWWWX: :XWNWX:    .OWNNWd.       
         ;0NNNNNXKXNNNNNXd..kWNNWk.    lNNNWK, oNNNNWK; :KWNNNNNNNNNNNN0, :XWNWX:    .OWNNNd.       
        ;0WNNN0c,.';x0Oxoc..kWNNW0c;:::xNNNWK, oNNNNWK; .;;;;:dKNNNNNXd'  :XWNWX:    .OWNNNd.       
       .oNNNWK;     ...    .kWNNNNNNNNNNNNNWK, :0NWNXx'     .l0NNNNNk;.   :XWNWX:    .OWNNNd.       
       .oNNNWK;     ...    .kWNNNNNWWWWNNNNWK,  .,c:'.    .;ONNNNN0c.     :XWNWXc    'OWNNNd.       
        ;0NNNN0l,.':xKOkdc..kWNNW0occcckNNNWK, .:oddo,.  'xXNNNNNKo::::;. '0WNNN0c,,:xXNNWXc        
         ;0NNNNNXKXNNNNNXo..kWNNWk.    lNNNWK,.oNNNNWK; :KNNNNNNNNNNNNNXc  :KNNNNNNXNNNNNNd.        
          .lkXNWNNWWNNKx;. .kWNNWk.    lNWNWK, :KNWNNk' oNWNNWNNNNNWNNWNc   ,dKNWWNNWWNXk:.         
            .':looolc;.    .,c::c,.    ':::c;.  .:c:,.  ':c::c:::c::::c:.     .;coodol:'.           


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./libs/markets/RequestValidator.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

error CHIZURequestMaker_Msg_Sender_Does_Not_Match();
error CHIZURequestMaker_Request_Status_Not_Correct();
error CHIZURequestMaker_Not_Refund_Due_Yet();
error CHIZURequestMaker_Request_Overdue();
error CHIZURequestMaker_Escrow_Type_Not_Correct(uint8 escrowType);
error CHIZURequestMaker_Signature_Expired();
error CHIZURequestMaker_Same_Account();

contract CHIZURequestMaker is Initializable, RequestValidator {
    uint40 internal constant TIMELIMIT = 60 days;

    // request status
    uint8 public constant REFUNDED = 1;
    uint8 public constant ACCEPTED = 2;
    uint8 public constant FINISHED = 3;

    // escrow type
    uint8 public constant CURRENCY = 1;
    uint8 public constant ERC721 = 2;
    uint8 public constant ERC1155 = 3;

    mapping(bytes32 => RequestInfo) internal requestInfo;

    event Registered(
        bytes32 indexed requestHash,
        bytes32 indexed nodeHash,
        address indexed creatorAccount,
        address requesterAccount,
        OrderInfo orderInfo,
        RequestInfo requestInfo
    );

    event Delivered(
        bytes32 indexed requestHash,
        bytes32 indexed nodeHash,
        address indexed creatorAccount,
        address requesterAccount,
        RequestInfo requestInfo,
        uint256 tokenId
    );

    event Refunded(
        bytes32 indexed requestHash,
        address indexed creatorAccount,
        address requesterAccount,
        RequestInfo requestInfo
    );

    /**
     * @dev Initialize function for upgradeable
     * @param _core The address of the contract defining roles for collections to use.
     * @param _currencyManager The address of the used currency manager
     */
    function initialize(address _core, address _currencyManager)
        external
        initializer
    {
        _initializeCore(_core, _currencyManager);
    }

    /**
     * ====================
     * Register
     * ====================
     */

    /**
     * @dev The function that registers an request by paying the currency
     * @param orderInfo Information about terms, user address, including salt to create hash
     * @param currencyInfo Information about the currency that the requester pays
     * @param userValidate Params for verifying user signature
     * @param nodeValidate Params for verifying information from a node
     */
    function registerWithCurrency(
        OrderInfo memory orderInfo,
        CurrencyInfo memory currencyInfo,
        UserValidate memory userValidate,
        NodeValidate memory nodeValidate
    ) public payable {
        if (nodeValidate.expiredAt < block.timestamp) {
            revert CHIZURequestMaker_Signature_Expired();
        }
        if (msg.sender != orderInfo.creatorAccount) {
            revert CHIZURequestMaker_Msg_Sender_Does_Not_Match();
        }
        if (orderInfo.creatorAccount == orderInfo.requesterAccount) {
            revert CHIZURequestMaker_Same_Account();
        }
        bytes32 requestHash = _requestHash(orderInfo);
        if (requestInfo[requestHash].status != 0) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }

        (
            bool success,
            string memory message
        ) = _validateRegisterWithCurrencySignature(
                ACCEPTED,
                orderInfo,
                currencyInfo,
                userValidate,
                nodeValidate
            );
        require(success, message);

        RequestInfo memory _requestInfo = RequestInfo({
            status: ACCEPTED,
            endTime: uint40(block.timestamp) + TIMELIMIT,
            escrowType: CURRENCY,
            creatorAccount: orderInfo.creatorAccount,
            requesterAccount: orderInfo.requesterAccount,
            contractAddress: currencyInfo.currencyAddress,
            value: currencyInfo.price,
            amount: 0
        });

        requestInfo[requestHash] = _requestInfo;

        (success, message) = _escrowCurrency(
            orderInfo.requesterAccount,
            currencyInfo
        );
        require(success, message);

        emit Registered(
            requestHash,
            nodeValidate.hashValue,
            orderInfo.creatorAccount,
            orderInfo.requesterAccount,
            orderInfo,
            _requestInfo
        );
    }

    /**
     * @dev The function that registers an request by paying the NFT
     * @param orderInfo Information about terms, user address, including salt to create hash
     * @param nftInfo Information about the NFT that the requester pays
     * @param userValidate Params for verifying user signature
     * @param nodeValidate Params for verifying information from a node
     */
    function registerWithNFT(
        OrderInfo memory orderInfo,
        NFTInfo memory nftInfo,
        UserValidate memory userValidate,
        NodeValidate memory nodeValidate
    ) public payable {
        if (nodeValidate.expiredAt < block.timestamp) {
            revert CHIZURequestMaker_Signature_Expired();
        }
        if (msg.sender != orderInfo.creatorAccount) {
            revert CHIZURequestMaker_Msg_Sender_Does_Not_Match();
        }
        if (orderInfo.creatorAccount == orderInfo.requesterAccount) {
            revert CHIZURequestMaker_Same_Account();
        }
        bytes32 requestHash = _requestHash(orderInfo);
        if (requestInfo[requestHash].status != 0) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }

        (
            bool success,
            string memory message
        ) = _validateRegisterWithNFTSignature(
                ACCEPTED,
                orderInfo,
                nftInfo,
                userValidate,
                nodeValidate
            );
        require(success, message);

        RequestInfo memory _requestInfo;
        uint8 escrowType;

        if (nftInfo.amount == ERC721_RESERVED_AMOUNT) {
            escrowType = ERC721;
        } else {
            escrowType = ERC1155;
        }

        _requestInfo = RequestInfo({
            status: ACCEPTED,
            endTime: uint40(block.timestamp) + TIMELIMIT,
            escrowType: escrowType,
            creatorAccount: orderInfo.creatorAccount,
            requesterAccount: orderInfo.requesterAccount,
            contractAddress: nftInfo.collectionAddress,
            value: nftInfo.tokenId,
            amount: nftInfo.amount
        });

        requestInfo[requestHash] = _requestInfo;

        (success, message) = _escrowNFT(orderInfo.requesterAccount, nftInfo);
        require(success, message);

        emit Registered(
            requestHash,
            nodeValidate.hashValue,
            orderInfo.creatorAccount,
            orderInfo.requesterAccount,
            orderInfo,
            _requestInfo
        );
    }

    /**
     * ====================
     * Deliver
     * ====================
     */

    /**
     * @dev The function that delivery the work corresponding to a request paid for by currency
     * @param requestHash Unique identifier for each request
     * @param lazyNFTInfo Information about the lazy nft that the artist create
     * @param nodeValidate Params for verifying information from a node
     */
    function deliverWithCurrency(
        bytes32 requestHash,
        LazyNFTInfo memory lazyNFTInfo,
        NodeValidate memory nodeValidate
    ) public payable {
        if (nodeValidate.expiredAt < block.timestamp) {
            revert CHIZURequestMaker_Signature_Expired();
        }

        RequestInfo memory _requestInfo = requestInfo[requestHash];

        if (msg.sender != _requestInfo.creatorAccount) {
            revert CHIZURequestMaker_Msg_Sender_Does_Not_Match();
        }

        if (_requestInfo.status != ACCEPTED) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }

        if (block.timestamp > _requestInfo.endTime) {
            revert CHIZURequestMaker_Request_Overdue();
        }

        if (_requestInfo.escrowType != CURRENCY) {
            revert CHIZURequestMaker_Escrow_Type_Not_Correct(
                _requestInfo.escrowType
            );
        }

        (bool success, string memory message) = _validateDeliverySignature(
            FINISHED,
            _requestInfo,
            lazyNFTInfo,
            nodeValidate
        );
        require(success, message);

        uint256 tokenId = _exchanageNFTAndCurrency(
            _requestInfo,
            lazyNFTInfo,
            nodeValidate.expiredAt
        );

        requestInfo[requestHash].status = FINISHED;

        emit Delivered(
            requestHash,
            nodeValidate.hashValue,
            _requestInfo.creatorAccount,
            _requestInfo.requesterAccount,
            _requestInfo,
            tokenId
        );
    }

    /**
     * @dev The function that delivery the work corresponding to a request paid for by NFT
     * @param requestHash Unique identifier for each request
     * @param lazyNFTInfo Information about the lazy nft that the artist create
     * @param nodeValidate Params for verifying information from a node
     */
    function deliverWithNFT(
        bytes32 requestHash,
        LazyNFTInfo memory lazyNFTInfo,
        NodeValidate memory nodeValidate
    ) public payable {
        if (nodeValidate.expiredAt < block.timestamp) {
            revert CHIZURequestMaker_Signature_Expired();
        }

        RequestInfo memory _requestInfo = requestInfo[requestHash];

        if (msg.sender != _requestInfo.creatorAccount) {
            revert CHIZURequestMaker_Msg_Sender_Does_Not_Match();
        }
        if (_requestInfo.status != ACCEPTED) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }
        if (block.timestamp > _requestInfo.endTime) {
            revert CHIZURequestMaker_Request_Overdue();
        }

        if (
            _requestInfo.escrowType != ERC721 &&
            _requestInfo.escrowType != ERC1155
        ) {
            revert CHIZURequestMaker_Escrow_Type_Not_Correct(
                _requestInfo.escrowType
            );
        }

        (bool success, string memory message) = _validateDeliverySignature(
            FINISHED,
            _requestInfo,
            lazyNFTInfo,
            nodeValidate
        );
        require(success, message);

        uint256 tokenId = _exchanageNFTS(
            _requestInfo,
            lazyNFTInfo,
            nodeValidate.expiredAt
        );

        requestInfo[requestHash].status = FINISHED;

        emit Delivered(
            requestHash,
            nodeValidate.hashValue,
            _requestInfo.creatorAccount,
            _requestInfo.requesterAccount,
            _requestInfo,
            tokenId
        );
    }

    /**
     * ====================
     * Refund
     * ====================
     */

    /**
     * @dev The function that refund the currency corresponding to a request paid for by currency
     * @param requestHash Unique identifier for each request
     */
    function refundCurrency(bytes32 requestHash) public payable {
        RequestInfo memory _requestInfo = requestInfo[requestHash];

        if (_requestInfo.status != ACCEPTED) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }

        if (block.timestamp <= _requestInfo.endTime) {
            revert CHIZURequestMaker_Not_Refund_Due_Yet();
        }

        if (_requestInfo.escrowType != CURRENCY) {
            revert CHIZURequestMaker_Escrow_Type_Not_Correct(
                _requestInfo.escrowType
            );
        }

        _refundCurrency(_requestInfo);

        requestInfo[requestHash].status = REFUNDED;

        emit Refunded(
            requestHash,
            _requestInfo.creatorAccount,
            _requestInfo.requesterAccount,
            _requestInfo
        );
    }

    /**
     * @dev The function that refund the NFT corresponding to a request paid for by NFT
     * @param requestHash Unique identifier for each request
     */
    function refundNFT(bytes32 requestHash) public payable {
        RequestInfo memory _requestInfo = requestInfo[requestHash];

        if (_requestInfo.status != ACCEPTED) {
            revert CHIZURequestMaker_Request_Status_Not_Correct();
        }
        if (block.timestamp <= _requestInfo.endTime) {
            revert CHIZURequestMaker_Not_Refund_Due_Yet();
        }

        if (
            _requestInfo.escrowType != ERC721 &&
            _requestInfo.escrowType != ERC1155
        ) {
            revert CHIZURequestMaker_Escrow_Type_Not_Correct(
                _requestInfo.escrowType
            );
        }

        (bool successRefund, string memory messageRefund) = _refundNFT(
            _requestInfo
        );
        require(successRefund, messageRefund);

        requestInfo[requestHash].status = REFUNDED;

        emit Refunded(
            requestHash,
            _requestInfo.creatorAccount,
            _requestInfo.requesterAccount,
            _requestInfo
        );
    }

    /**
     * ====================
     * Get function
     * ====================
     */

    /**
     * @dev The function that get request information to input orderInfo
     * @param orderInfo Information about terms, user address, including salt to create hash
     * @return requestInfo Information about account, current process, and information of escrow
     */
    function getRequestInfoFromOrder(OrderInfo memory orderInfo)
        external
        view
        returns (RequestInfo memory)
    {
        bytes32 requestHash = _requestHash(orderInfo);
        return requestInfo[requestHash];
    }

    /**
     * @dev The function that get request info to input orderInfo
     * @param requestHash Unique identifier for each request
     * @return requestInfo Information about account, current process, and information of escrow
     */
    function getRequestInfoFromHash(bytes32 requestHash)
        external
        view
        returns (RequestInfo memory)
    {
        return requestInfo[requestHash];
    }

    /**
     * ====================
     * internal function
     * ====================
     */

    /**
     * @dev The internal function that get request hash
     * @param orderInfo Information about terms, user address, including salt to create hash
     * @return _hash Unique identifier for each request
     */
    function _requestHash(OrderInfo memory orderInfo)
        public
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(
            abi.encodePacked(
                uint256(orderInfo.creatorSalt),
                uint256(orderInfo.requesterSalt),
                uint256(uint160(orderInfo.creatorAccount)),
                uint256(uint160(orderInfo.requesterAccount))
            )
        );
    }

    uint256[1000] private __gap;
}