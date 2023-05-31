// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../utils/signatures/SignatureVerify.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqOperator/IUniqOperator.sol";

contract UniqStorePayment is Ownable, SignatureVerify {
    // ----- EVENTS ----- //

    event StoreRequested(
        address indexed _requester,
        bytes32 nonce,
        uint256 paymentAmount,
        address paymentToken
    );

    // ----- VARIABLES ----- //
    mapping(bytes32 => bool) public isNonceUsed;
    uint256 internal _transactionOffset;
    uint256 internal _networkId;
    IUniqOperator public operator;
    uint256 internal constant TREASURY_INDEX = 0;

    // ----- CONSTRUCTOR ----- //
    constructor(uint256 _pnetworkId, IUniqOperator uniqOperator) {
        _transactionOffset = 3 minutes;
        _networkId = _pnetworkId;
        operator = uniqOperator;
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHashRequester(
        bytes32 _nonce,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nonce,
                    _price,
                    _paymentTokenAddress,
                    _timestamp,
                    _networkId
                )
            );
    }

    function verifySignatureRequester(
        bytes32 _nonce,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashRequester(
            _nonce,
            _price,
            _paymentTokenAddress,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //
    function requestStore(
        bytes32 _nonce,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp,
        bytes memory _signature
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!isNonceUsed[_nonce], "Nonce already used");
        require(
            verifySignatureRequester(
                _nonce,
                _price,
                _paymentTokenAddress,
                _timestamp,
                _signature
            ),
            "Signature mismatch"
        );
        isNonceUsed[_nonce] = true;
        if (_price != 0) {
            address treasury = operator.uniqAddresses(TREASURY_INDEX);
            if (_paymentTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
                payable(treasury).transfer(_price);
            } else {
                IERC20Fixed(_paymentTokenAddress).transferFrom(
                    msg.sender,
                    treasury,
                    _price
                );
            }
        }
        emit StoreRequested(msg.sender, _nonce, _price, _paymentTokenAddress);
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(msg.sender, val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner {
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function wthdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}