// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EIP712} from "@openzeppelin-4.7.3/contracts/utils/cryptography/draft-EIP712.sol";
import {Address} from "@openzeppelin-4.7.3/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin-4.7.3/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin-4.7.3/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin-4.7.3/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin-4.7.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-4.7.3/contracts/security/ReentrancyGuard.sol";
import {IWBNB} from "./interfaces/IWBNB.sol";
import {SafeWBNB} from "./utils/SafeWBNB.sol";

contract PancakeSwapMMPool is EIP712, ReentrancyGuard, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using SafeWBNB for IWBNB;

    address constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable WBNB_ADDRESS;

    struct MMInfo {
        address treasury;
        mapping(address => uint256) userNonce;
        string name;
        bool active;
    }

    struct Quote {
        uint256 nonce;
        address user;
        address baseToken;
        address quoteToken;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 expiryTimestamp;
    }

    mapping(address => MMInfo) mmInfos;

    event Swap(
        uint256 nonce,
        address indexed user,
        address indexed mm,
        address mmTreasury,
        address baseToken,
        address quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    event IncrementNonce(address mm, address user);

    event CreateMMInfo(address mm, address treasury, string name, bool active);

    event UpdateMMInfo(address mm, address treasury, bool active);

    event RemoveMMInfo(address mm);

    modifier existMMInfo(address _mm) {
        require(mmInfos[_mm].treasury != address(0), "mm not exist");
        _;
    }

    constructor(address wbnb) EIP712("PCS MM Pool", "1") {
        require(wbnb != address(0), "zero address");
        WBNB_ADDRESS = wbnb;
    }

    receive() external payable {}

    function swap(
        address _mmSigner,
        Quote calldata _quote,
        bytes calldata signature
    ) external payable nonReentrant {
        require(verifyQuoteSignature(_mmSigner, _quote, signature), "wrong signature");
        require(block.timestamp <= _quote.expiryTimestamp, "quote expired");
        require(msg.sender == _quote.user, "sender not receiver");

        MMInfo storage mmInfo = mmInfos[_mmSigner];
        require(mmInfo.active, "mm not active");
        require(mmInfo.userNonce[_quote.user] == _quote.nonce, "wrong nonce");

        mmInfo.userNonce[_quote.user] += 1;

        if (_quote.baseToken == address(0) || _quote.baseToken == BNB_ADDRESS) {
            require(msg.value >= _quote.baseTokenAmount, "not enough amount");
            IWBNB(WBNB_ADDRESS).safeDeposit(_quote.baseTokenAmount);
            IWBNB(WBNB_ADDRESS).safeTransfer(mmInfo.treasury, _quote.baseTokenAmount);
            uint256 leftover = msg.value - _quote.baseTokenAmount;
            if (leftover > 0) payable(msg.sender).sendValue(leftover);
        } else {
            uint256 _balanceBefore = IERC20(_quote.baseToken).balanceOf(mmInfo.treasury);
            IERC20(_quote.baseToken).safeTransferFrom(_quote.user, mmInfo.treasury, _quote.baseTokenAmount);
            require(
                IERC20(_quote.baseToken).balanceOf(mmInfo.treasury) - _balanceBefore == _quote.baseTokenAmount,
                "send amount not match"
            );
        }

        if (_quote.quoteToken == address(0) || _quote.quoteToken == BNB_ADDRESS) {
            IWBNB(WBNB_ADDRESS).safeTransferFrom(mmInfo.treasury, address(this), _quote.quoteTokenAmount);
            IWBNB(WBNB_ADDRESS).safeWithdraw(_quote.quoteTokenAmount);
            require(address(this).balance >= _quote.quoteTokenAmount, "not enough amount");
            payable(_quote.user).sendValue(_quote.quoteTokenAmount);
        } else {
            uint256 _balanceBefore = IERC20(_quote.quoteToken).balanceOf(_quote.user);
            IERC20(_quote.quoteToken).safeTransferFrom(mmInfo.treasury, _quote.user, _quote.quoteTokenAmount);
            require(
                IERC20(_quote.quoteToken).balanceOf(_quote.user) - _balanceBefore == _quote.quoteTokenAmount,
                "receive amount not match"
            );
        }

        emit Swap(
            _quote.nonce,
            _quote.user,
            _mmSigner,
            mmInfo.treasury,
            _quote.baseToken,
            _quote.quoteToken,
            _quote.baseTokenAmount,
            _quote.quoteTokenAmount
        );
    }

    function verifyQuoteSignature(
        address _account,
        Quote calldata _quote,
        bytes calldata _signature
    ) public view returns (bool) {
        require(_account != address(0), "zero address");
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Quote(uint256 nonce,address user,address baseToken,address quoteToken,uint256 baseTokenAmount,uint256 quoteTokenAmount,uint256 expiryTimestamp)"
                    ),
                    _quote.nonce,
                    _quote.user,
                    _quote.baseToken,
                    _quote.quoteToken,
                    _quote.baseTokenAmount,
                    _quote.quoteTokenAmount,
                    _quote.expiryTimestamp
                )
            )
        );
        return _account == digest.recover(_signature);
    }

    function incrementNonce(address _user) external existMMInfo(msg.sender) returns (uint256) {
        mmInfos[msg.sender].userNonce[_user] += 1;

        emit IncrementNonce(msg.sender, _user);

        return mmInfos[msg.sender].userNonce[_user];
    }

    function createMMInfo(
        address _mm,
        address _treasury,
        string calldata _name,
        bool _active
    ) external onlyOwner {
        require(_mm != address(0) && _treasury != address(0), "zero address");
        require(mmInfos[_mm].treasury == address(0), "mm exist");

        mmInfos[_mm].treasury = _treasury;
        mmInfos[_mm].name = _name;
        mmInfos[_mm].active = _active;

        emit CreateMMInfo(_mm, _treasury, _name, _active);
    }

    function updateMMInfo(address _treasury, bool _active) external existMMInfo(msg.sender) {
        if (mmInfos[msg.sender].treasury != _treasury && _treasury != address(0))
            mmInfos[msg.sender].treasury = _treasury;
        if (mmInfos[msg.sender].active != _active) mmInfos[msg.sender].active = _active;

        emit UpdateMMInfo(msg.sender, mmInfos[msg.sender].treasury, mmInfos[msg.sender].active);
    }

    function removeMMInfo(address _mm) external onlyOwner existMMInfo(_mm) {
        delete mmInfos[_mm];

        emit RemoveMMInfo(_mm);
    }

    function getUserNonce(address _mm, address _user) external view existMMInfo(_mm) returns (uint256) {
        return mmInfos[_mm].userNonce[_user];
    }

    function getMMInfo(address _mm)
        external
        view
        returns (
            string memory,
            address,
            bool
        )
    {
        return (mmInfos[_mm].name, mmInfos[_mm].treasury, mmInfos[_mm].active);
    }

    function redeemToken(address _token) external onlyOwner {
        if (_token == address(0) || _token == BNB_ADDRESS) {
            uint256 totalAmount = address(this).balance;
            require(totalAmount > 0, "zero balance");
            (bool success, ) = msg.sender.call{value: totalAmount}("");
            require(success, "transfer eth to sender fail");
        } else {
            uint256 totalAmount = IERC20(_token).balanceOf(address(this));
            require(totalAmount > 0, "zero balance");
            IERC20(_token).safeTransfer(msg.sender, totalAmount);
        }
    }
}