// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

library DTKStoreErrorCodes {
    string constant InvalidNonce = "DTKStore:InvalidNonce";
    string constant InvalidSigner = "DTKStore:InvalidSigner";
    string constant SignatureExpired = "DTKStore:SignatureExpired";
    string constant InsufficientBalance = "DTKStore:InsufficientBalance";
    string constant SendEtherFailed = "DTKStore:SendEtherFailed";
}

contract DTKStore is Ownable {
    using ECDSA for bytes32;
    using ERC165Checker for address;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    event PurchaseItems(
        uint256 indexed billId,
        address indexed token,
        uint256 payment
    );

    // ─── Variables ───────────────────────────────────────────────────────────────

    /**
     * Access Right Management
     */
    address private _authedSigner;
    mapping(address => mapping(uint256 => bool)) public nonce; // Mapping from account to its current consumable nonce

    // ─────────────────────────────────────────────────────────────────────────────
    // ─── Constructor ─────────────────────────────────────────────────────────────

    /**
     * @param authedSigner_ The authorized signer to sign all the authed signature
     * ! Requirements:
     * ! Input authedSigner_ must not be an empty address
     * * Operations:
     * * Initialize the _authSigner variable
     */
    constructor(address authedSigner_) {
        require(authedSigner_ != address(0), DTKStoreErrorCodes.InvalidSigner);

        _authedSigner = authedSigner_;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // ─── Modifiers ───────────────────────────────────────────────────────────────

    /**
     * @dev [Access Right Management] Ensure the nonce has not been consumed yet,
     * @param account_ The target address for validation
     * @param nonce_ the target nonce to validate
     * ! Requirements:
     * ! The nonce_ must be available corresponding to account_
     * * Operations:
     * * Update the nonce_ corresponding to account_ to True after all operations have completed
     */
    modifier nonceGuard(address account_, uint256 nonce_) {
        require(!nonce[account_][nonce_], DTKStoreErrorCodes.InvalidNonce);

        _;

        nonce[account_][nonce_] = true;
    }

    /**
     * @dev [Access Right Management] Ensure the signature is signed by the intended signer
     * @param sig_ The target signature to validate
     * @param signer_ the intended signature signer for validation
     * @param msgHash_ the intended hash of the signature message for validation
     * @param sigExpireBlockNum_ the block number where the signature will be expired if exceed
     * ! Requirements:
     * ! The signer of sig_ recovered from msgHash_ must equals to signer_
     * ! The current block must not exceed sigExpireBlockNum_
     */
    modifier signatureGuard(
        bytes memory sig_,
        address signer_,
        bytes32 msgHash_,
        uint256 sigExpireBlockNum_
    ) {
        require(
            msgHash_.toEthSignedMessageHash().recover(sig_) == signer_,
            DTKStoreErrorCodes.InvalidSigner
        );
        require(
            sigExpireBlockNum_ >= block.number,
            DTKStoreErrorCodes.SignatureExpired
        );
        _;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // ─── External Functions ──────────────────────────────────────────────────────

    /**
     * @dev [Metadata]: Get the authed signer address
     */
    function authedSigner() external view returns (address) {
        return _authedSigner;
    }

    /**
     * @dev [Metadata]: Set the authed signer
     * ! Requirements:
     * ! The caller must be the owner
     */
    function setAuthedSigner(address authedSigner_) external onlyOwner {
        _authedSigner = authedSigner_;
    }

    // ─────────────────────────────────────────────────────────────────────
    // ─── Purchase Item ───────────────────────────────────────────────────

    /**
     * @dev User purchase item with an authed signature with either base ether or erc20 token
     * @param billId_ The bill id which user would like to pay for
     * @param tokenAddress_ The token address which the user need to pay in, if address(0) means paying with base ether
     * @param payment_ The payment amount the user need to pay
     * @param nonce_ The user nonce for the purchase
     * @param sigExpireBlockNum_ The block number where the signature will be expired if excced it
     * @param sig_ The authorized signature signed by _authedSigner
     * ! Requirements:
     * ! The user nonce must pass the validation of nonceGuard
     * ! The signature must pass the validation of signatureGuard
     * ! The msg.value must equal or greater than the payment value
     * * Operations:
     * * Emit a purchase item event
     */
    function purchaseItems(
        uint256 billId_,
        address tokenAddress_,
        uint256 payment_,
        uint256 nonce_,
        uint256 sigExpireBlockNum_,
        bytes memory sig_
    )
        external
        payable
        nonceGuard(_msgSender(), nonce_)
        signatureGuard(
            sig_,
            _authedSigner,
            keccak256(
                abi.encodePacked(
                    "purchaseItems(uint256,address,uint256,uint256,uint256,bytes)",
                    address(this),
                    _msgSender(),
                    billId_,
                    tokenAddress_,
                    payment_,
                    nonce_,
                    sigExpireBlockNum_
                )
            ),
            sigExpireBlockNum_
        )
    {
        if (tokenAddress_ == address(0)) {
            require(
                msg.value >= payment_,
                DTKStoreErrorCodes.InsufficientBalance
            );
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.safeTransferFrom(_msgSender(), address(this), payment_);
        }

        emit PurchaseItems(billId_, tokenAddress_, payment_);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // ─── Withdraw ──────────────────────────────────────────────────────────

    /**
     * @dev Withdraw base ether from the contract balance
     * @param recipient_ The recepient address where the ether would like to be withdrawed to
     * @param amount_ The withdrawal amount
     * ! Requirements:
     * ! The caller must be the owner
     * ! The the withdraw call must be success
     */
    function withdrawEther(
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        (bool sent, ) = recipient_.call{value: amount_}("");
        require(sent, DTKStoreErrorCodes.SendEtherFailed);
    }

    /**
     * @dev Withdraw base ether from the contract balance
     * @param recipient_ The recepient address where the ether would like to be withdrawed to
     * @param amount_ The withdrawal amount
     * ! Requirements:
     * ! The caller must be the owner
     * ! The the withdraw call must be success
     */
    function withdrawERC20(
        address recipient_,
        address tokenAddress_,
        uint256 amount_
    ) external onlyOwner {
        IERC20 token = IERC20(tokenAddress_);
        token.safeTransfer(recipient_, amount_);
    }

    // ─────────────────────────────────────────────────────────────────────────────

    receive() external payable {}

    fallback() external payable {}
}