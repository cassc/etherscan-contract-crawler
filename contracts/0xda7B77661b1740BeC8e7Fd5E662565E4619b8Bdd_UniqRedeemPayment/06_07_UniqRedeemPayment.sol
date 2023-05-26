// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../utils/signatures/SignatureVerify.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqOperator/IUniqOperator.sol";

contract UniqRedeemPayment is Ownable, SignatureVerify {
    // ----- EVENTS ----- //

    event RedeemedRequested(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        uint256 _networkId,
        string _redeemerName,
        uint256 _purpose
    );

    // ----- VARIABLES ----- //
    mapping(bytes => bool) internal _isSignatureUsed;
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
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp,
        address _requesterAddress,
        string memory _redeemerName,
        uint256 _purpose
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _contractAddress,
                    _redeemNetworkId,
                    _sellerAddress,
                    _percentageForSeller,
                    _tokenId,
                    _price,
                    _paymentTokenAddress,
                    _timestamp,
                    _requesterAddress,
                    _redeemerName,
                    _purpose
                )
            );
    }

    function verifySignatureRequester(
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashRequester(
            _contractAddress,
            _redeemNetworkId,
            _sellerAddress,
            _percentageForSeller,
            _tokenId,
            _price,
            _paymnetTokenAddress,
            _timestamp,
            msg.sender,
            _redeemerName,
            _purpose
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //
    function requestRedeem(
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress,
        string memory _redeemerName,
        uint256 _purpose,
        bytes memory _signature
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignatureRequester(
                _contractAddress,
                _redeemNetworkId,
                _sellerAddress,
                _percentageForSeller,
                _tokenId,
                _price,
                _paymnetTokenAddress,
                _timestamp,
                _redeemerName,
                _purpose,
                _signature
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        uint256 sellerFee = (_price * _percentageForSeller) / 100;
        if (_price != 0) {
            address treasury = operator.uniqAddresses(TREASURY_INDEX);
            if (_paymnetTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
                payable(_sellerAddress).transfer(sellerFee);
                payable(treasury).transfer(_price - sellerFee);
            } else {
                IERC20Fixed(_paymnetTokenAddress).transferFrom(
                    msg.sender,
                    _sellerAddress,
                    sellerFee
                );
                IERC20Fixed(_paymnetTokenAddress).transferFrom(
                    msg.sender,
                    treasury,
                    _price - sellerFee
                );
            }
        }
        emit RedeemedRequested(
            _contractAddress,
            _tokenId,
            _requesterAddress,
            _networkId,
            _redeemerName,
            _purpose
        );
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