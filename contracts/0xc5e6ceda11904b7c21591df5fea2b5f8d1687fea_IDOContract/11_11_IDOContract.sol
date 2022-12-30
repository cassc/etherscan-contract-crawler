// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract IDOContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address signer = 0xB9aBC6AB17B5DDb8FA11964018D29EbB4db4a439;
    mapping(address => bool) currency;

    event BuyEvent(
        address buyer,
        address currency,
        uint256 amountIn,
        uint256 amountOut,
        uint256 cohort,
        uint256 price,
        uint256 validBefore,
        uint256 nonce
    );

    constructor() {}

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function verifySignature(
        address _buyer,
        address _currency,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _cohort,
        uint256 _price,
        uint256 _validBefore,
        uint256 _nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 messageHash =
            keccak256(abi.encodePacked(_buyer, _currency, _amountIn, _amountOut, _cohort, _price, _validBefore, _nonce));

        bytes32 ethMsgHash = getEthSignedMessageHash(messageHash);
        address recoveredSigner = ecrecover(ethMsgHash, v, r, s);
        return recoveredSigner == signer;
    }

    function buy(
        address _buyer,
        address _currency,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _cohort,
        uint256 _price,
        uint256 _validBefore,
        uint256 _nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(block.timestamp <= _validBefore, "Transaction expired");
        require(currency[_currency], "Invalid purchase currency");
        require(
            verifySignature(_buyer, _currency, _amountIn, _amountOut, _cohort, _price, _validBefore, _nonce, v, r, s),
            "bad signature"
        );
        lockERC20(_amountIn, _currency);
        emit BuyEvent(_buyer, _currency, _amountIn, _amountOut, _cohort, _price, _validBefore, _nonce);
    }

    function addCurrency(address asset) external onlyOwner {
        currency[asset] = true;
    }

    function removeCurrency(address asset) external onlyOwner {
        currency[asset] = false;
    }

    // ---------------------------

    function lockERC20(uint256 _amount, address _asset) private {
        IERC20 ercAsset = IERC20(_asset);
        ercAsset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _to, uint256 amount, address asset) external onlyOwner nonReentrant {
        require(currency[asset], "Router: non-whitelisted asset");
        IERC20(asset).transfer(_to, amount);
    }

    function withdrawAll(address _to, address asset) external onlyOwner nonReentrant {
        require(currency[asset], "Router: non-whitelisted asset");
        IERC20(asset).transfer(_to, IERC20(asset).balanceOf(address(this)));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}