// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

    error InsufficientBalance(uint256 available, uint256 required);
    error ExpiredBlockNumber(uint256 inBlockNumber, uint256 currentBlockNumber);
    error NonceAlreadyExist(bytes nonce);
    error InvalidHash(bytes32 inHash, bytes32 expectedHash);
    error InvalidSignature(bytes inSignature);
    error InvalidSignatureLength(uint256 inLength, uint256 expectedLength);
    error PayEthFailed();
    error PayTokenFailed();
    error RedeemEthFailed();
    error RedeemTokenFailed();
    error WithdrawEthFailed(uint256 balance);

contract Payment is Pausable, Ownable {
    // using SafeMath for uint256;
    address internal signer;
    mapping(bytes => bool) internal nonceMap;

    bytes32 private constant REDEEM_KEY = "payment_redeem";
    bytes32 private constant PAY_KEY = "payment_pay";

    constructor() {
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    event PaySuccess(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed amount,
        address tokenAddress,
        bytes nonce
    );

    event RedeemSuccess(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed amount,
        address tokenAddress,
        bytes nonce
    );

    //******SET UP******
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    //******FUNCTIONS******
    function withdraw(uint256 amount) public payable onlyOwner {
        (bool sent,) = payable(msg.sender).call{value : amount}("");
        if (!sent) revert WithdrawEthFailed(amount);
    }

    function pay(
        uint256 _amount,
        address _tokenAddress,
        address _toAddress,
        bytes memory _nonce,
        bytes32 _hash,
        bytes memory _signature
    ) external payable whenNotPaused {
        if (nonceMap[_nonce]) revert NonceAlreadyExist({nonce : _nonce});
        bytes32 ethHash = payHash(
            msg.sender,
            _amount,
            _tokenAddress,
            _toAddress,
            _nonce,
            PAY_KEY
        );
        if (ethHash != _hash)
            revert InvalidHash({inHash : _hash, expectedHash : ethHash});
        if (!matchAddressSigner(_hash, _signature))
            revert InvalidSignature({inSignature : _signature});

        nonceMap[_nonce] = true;
        if (_tokenAddress == address(0x0)) {
            _payFromETH(_amount, _toAddress);
        } else {
            _payFromToken(_tokenAddress, _amount, _toAddress);
        }

        emit PaySuccess(msg.sender, _toAddress, _amount, _tokenAddress, _nonce);
    }

    function _payFromETH(uint256 _amount, address _toAddress) internal {
        if (msg.value < _amount)
            revert InsufficientBalance({
            available : msg.value,
            required : _amount
            });
        (bool send,) = payable(_toAddress).call{value : _amount}("");
        if (!send) revert PayEthFailed();
    }

    function _payFromToken(
        address _tokenAddress,
        uint256 _amount,
        address _toAddress
    ) internal {
        ERC20 tokenContract = ERC20(_tokenAddress);
        bool send = tokenContract.transferFrom(msg.sender, _toAddress, _amount);
        if (!send) revert PayTokenFailed();
    }

    function redeem(
        uint256 _amount,
        address _tokenAddress,
        address _fromAddress,
        uint256 _blockHeight,
        bytes memory _nonce,
        bytes32 _hash,
        bytes memory _signature
    ) public whenNotPaused {
        if ((_blockHeight < block.number))
            revert ExpiredBlockNumber({
            inBlockNumber : _blockHeight,
            currentBlockNumber : block.number
            });
        if (nonceMap[_nonce]) revert NonceAlreadyExist({nonce : _nonce});

        bytes32 ethHash = redeemHash(
            msg.sender,
            _amount,
            _tokenAddress,
            _fromAddress,
            _blockHeight,
            _nonce,
            REDEEM_KEY
        );
        if (ethHash != _hash)
            revert InvalidHash({inHash : _hash, expectedHash : ethHash});
        if (!matchAddressSigner(_hash, _signature))
            revert InvalidSignature({inSignature : _signature});

        nonceMap[_nonce] = true;
        if (_tokenAddress == address(0x0)) {
            _redeemETH(_amount);
        } else {
            _redeemToken(_tokenAddress, _fromAddress, _amount);
        }

        emit RedeemSuccess(
            _fromAddress,
            msg.sender,
            _amount,
            _tokenAddress,
            _nonce
        );
    }

    function _redeemToken(
        address tokenAddress,
        address fromAddress,
        uint256 amount
    ) internal {
        ERC20 tokenContract = ERC20(tokenAddress);
        bool sent = tokenContract.transferFrom(fromAddress, msg.sender, amount);
        if (!sent) revert RedeemEthFailed();
    }

    function _redeemETH(uint256 amount) internal {
        (bool sent,) = payable(msg.sender).call{value : amount}("");
        if (!sent) revert RedeemEthFailed();
    }

    //******TOOL******
    function payHash(
        address _senderAddress,
        uint256 _amount,
        address _tokenAddress,
        address _toAddress,
        bytes memory _nonce,
        bytes32 _key
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        _senderAddress,
                        _amount,
                        _tokenAddress,
                        _toAddress,
                        _nonce,
                        _key
                    )
                )
            )
        );
        return hash;
    }

    function redeemHash(
        address senderAddress,
        uint256 amount,
        address tokenAddress,
        address fromAddress,
        uint256 blockNumber,
        bytes memory nonce,
        bytes32 key
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        senderAddress,
                        amount,
                        tokenAddress,
                        fromAddress,
                        blockNumber,
                        nonce,
                        key
                    )
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        if (sig.length != 65)
            revert InvalidSignatureLength({
            inLength : sig.length,
            expectedLength : 65
            });
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}