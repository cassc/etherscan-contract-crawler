// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MERewards is ReentrancyGuard, Ownable {

    struct Voucher {
        uint256 amount;
        address beneficiary;
        address ERC20Token;
        bytes signature;
    }

    using SafeERC20 for IERC20;
    address private signer;
    string private constant SIGNING_DOMAIN = "MERewards";
    string private constant SIGNATURE_VERSION = "1";

    IERC20 public ERC20Token;

    mapping(address => uint8) public callerNonce;

    constructor(address payable _signer) {
        signer = _signer;
    }

    function setERC20Token(address _ERC20Token) external onlyOwner {
        ERC20Token = IERC20(_ERC20Token);
    }

    function setSigner(address payable _signer) external onlyOwner {
        signer = _signer;
    }

    function claim(Voucher calldata voucher) external nonReentrant {
        address _signer = _verifyVoucher(voucher);
        require(signer == _signer, "Signature invalid or unauthorized");
        require(msg.sender == voucher.beneficiary, "Sender is not receiver");
        require(IERC20(voucher.ERC20Token) == ERC20Token, "Wrong ERC20 Token");
        callerNonce[msg.sender]++;
        ERC20Token.safeTransfer(voucher.beneficiary, voucher.amount);
    }

    function _verifyVoucher(Voucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hashVoucher(Voucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        bytes memory changeInfo = abi.encodePacked(
            voucher.beneficiary,
            voucher.amount
        );
        bytes memory domainInfo = abi.encodePacked(
            this.getChainID(),
            SIGNING_DOMAIN,
            SIGNATURE_VERSION,
            address(this),
            callerNonce[msg.sender]
        );
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(changeInfo, domainInfo))
            );
    }

    function getChainID() external view returns (uint256) {
        return block.chainid;
    }
}