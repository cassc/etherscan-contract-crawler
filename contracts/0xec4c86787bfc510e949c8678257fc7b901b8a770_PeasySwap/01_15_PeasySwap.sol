//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PeasySwap is EIP712, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct TradeInfo {
        address trader;
        TokenType[] tokenType;
        address[] tokenAddress;
        uint256[] tokenId;
        uint256[] tokenAmount;
    }

    struct Agreement {
        uint256 nonce;
        TradeInfo signerSide;
        TradeInfo executorSide;
        uint256 expiryTimestamp;
    }

    bytes32 constant TRADE_INFO_TYPE_HASH =
        keccak256(
            "TradeInfo(address trader,uint8[] tokenType,address[] tokenAddress,uint256[] tokenId,uint256[] tokenAmount)"
        );

    bytes32 constant AGREEMENT_TYPE_HASH =
        keccak256(
            "Agreement(uint256 nonce,TradeInfo signerSide,TradeInfo executorSide,uint256 expiryTimestamp)TradeInfo(address trader,uint8[] tokenType,address[] tokenAddress,uint256[] tokenId,uint256[] tokenAmount)"
        );

    bytes32 DOMAIN_SEPARATOR;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // signer => executor => nonce
    mapping(address => mapping(address => uint256)) nonce;

    event Swap(
        address signer,
        bytes signerTokenType,
        bytes signerTokenAddress,
        bytes signerTokenId,
        bytes signerTokenAmount,
        address executor,
        bytes executorTokenType,
        bytes executorTokenAddress,
        bytes executorTokenId,
        bytes executorTokenAmount
    );

    event IncrementNonce(address signer, address executor, uint256 nonce);

    constructor(address _admin) EIP712("PeasySwap", "1") {
        transferOwnership(_admin);
    }

    function swap(
        Agreement calldata _agreement,
        bytes calldata _signature
    ) external payable nonReentrant {
        require(msg.sender == _agreement.executorSide.trader, "sender not executor");
        require(block.timestamp <= _agreement.expiryTimestamp, "agreement expired");
        require(verifySignature(_agreement, _signature), "invalid signature");
        require(
            nonce[_agreement.signerSide.trader][_agreement.executorSide.trader] == _agreement.nonce,
            "incorrect nonce"
        );

        moveAsset(_agreement.executorSide.trader, _agreement.signerSide);
        moveAsset(_agreement.signerSide.trader, _agreement.executorSide);

        emit Swap(
            _agreement.signerSide.trader,
            abi.encodePacked(_agreement.signerSide.tokenType),
            abi.encodePacked(_agreement.signerSide.tokenAddress),
            abi.encodePacked(_agreement.signerSide.tokenId),
            abi.encodePacked(_agreement.signerSide.tokenAmount),
            _agreement.executorSide.trader,
            abi.encodePacked(_agreement.executorSide.tokenType),
            abi.encodePacked(_agreement.executorSide.tokenAddress),
            abi.encodePacked(_agreement.executorSide.tokenId),
            abi.encodePacked(_agreement.executorSide.tokenAmount)
        );
    }

    function verifySignature(
        Agreement calldata _agreement,
        bytes calldata _signature
    ) public view returns (bool) {
        require(_agreement.signerSide.trader != address(0), "zero address");
        bytes32 digest = _hashTypedDataV4(hash(_agreement));
        return _agreement.signerSide.trader == digest.recover(_signature);
    }

    function getNonce(address _signer, address _executor) external view returns (uint256) {
        return nonce[_signer][_executor];
    }

    function incrementNonce(address _signer, address _executor) external {
        require(msg.sender == _signer, "sender not signer");
        nonce[_signer][_executor] += 1;

        emit IncrementNonce(_signer, _executor, nonce[_signer][_executor]);
    }

    function moveAsset(address _to, TradeInfo calldata _tradeInfo) internal {
        require(
            _tradeInfo.tokenAddress.length == _tradeInfo.tokenId.length &&
                _tradeInfo.tokenAddress.length == _tradeInfo.tokenType.length &&
                _tradeInfo.tokenAddress.length == _tradeInfo.tokenAmount.length,
            "info length not match"
        );
        for (uint256 i = 0; i < _tradeInfo.tokenType.length; i++) {
            address tokenAddress = _tradeInfo.tokenAddress[i];
            if (_tradeInfo.tokenType[i] == TokenType.ERC20) {
                // native token handling
                require(
                    tokenAddress != ETH_ADDRESS && tokenAddress != address(0),
                    "unsupported address"
                );

                uint256 _beforeBalance = IERC20(tokenAddress).balanceOf(_to);
                IERC20(tokenAddress).safeTransferFrom(
                    _tradeInfo.trader,
                    _to,
                    _tradeInfo.tokenAmount[i]
                );
                require(
                    IERC20(tokenAddress).balanceOf(_to) - _beforeBalance ==
                        _tradeInfo.tokenAmount[i],
                    "receive amount is not correct"
                );
            } else if (_tradeInfo.tokenType[i] == TokenType.ERC721) {
                IERC721(tokenAddress).safeTransferFrom(
                    _tradeInfo.trader,
                    _to,
                    _tradeInfo.tokenId[i]
                );
                require(
                    IERC721(tokenAddress).ownerOf(_tradeInfo.tokenId[i]) == _to,
                    "receive address is not correct"
                );
            } else if (_tradeInfo.tokenType[i] == TokenType.ERC1155) {
                uint256 _beforeBalance = IERC1155(tokenAddress).balanceOf(
                    _to,
                    _tradeInfo.tokenId[i]
                );
                IERC1155(tokenAddress).safeTransferFrom(
                    _tradeInfo.trader,
                    _to,
                    _tradeInfo.tokenId[i],
                    _tradeInfo.tokenAmount[i],
                    ""
                );
                require(
                    IERC1155(tokenAddress).balanceOf(_to, _tradeInfo.tokenId[i]) - _beforeBalance ==
                        _tradeInfo.tokenAmount[i],
                    "receive amount is not correct"
                );
            } else {
                revert("type does not exist");
            }
        }
    }

    function hash(TradeInfo calldata _tradInfo) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TRADE_INFO_TYPE_HASH,
                    _tradInfo.trader,
                    keccak256(abi.encodePacked(_tradInfo.tokenType)),
                    keccak256(abi.encodePacked(_tradInfo.tokenAddress)),
                    keccak256(abi.encodePacked(_tradInfo.tokenId)),
                    keccak256(abi.encodePacked(_tradInfo.tokenAmount))
                )
            );
    }

    function hash(Agreement calldata _agreement) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AGREEMENT_TYPE_HASH,
                    _agreement.nonce,
                    hash(_agreement.signerSide),
                    hash(_agreement.executorSide),
                    _agreement.expiryTimestamp
                )
            );
    }

    function withdraw(address _token) external onlyOwner {
        uint256 amount;
        if (_token == address(0)) {
            amount = address(this).balance;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "transfer eth fail");
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            require(amount > 0, "zero balance");
            IERC20(_token).safeTransfer(msg.sender, amount);
        }
    }

    function destroy(address _receiver) external onlyOwner {
        selfdestruct(payable(_receiver));
    }
}