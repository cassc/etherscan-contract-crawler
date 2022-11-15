// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BottoActiveRewards is AccessControl, EIP712 {
    using SafeERC20 for IERC20;

    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");

    // Invalidated permits due to being already claimed
    uint256 private _permitNonce;

    struct RedeemPermit {
        uint256 amount; // Amount to reward
        uint256 nonce; //
        address currency; // using the zero address means Ether
        uint256 kickoff; // block epoch timestamp in seconds when the permit is valid
        uint256 deadline; // block epoch timestamp in seconds when the permit is expired
        address recipient;
        bytes data;
    }

    bytes32 public constant REDEEM_PERMIT_TYPEHASH =
        keccak256(
            "RedeemPermit(uint256 amount,uint256 nonce,address currency,uint256 kickoff,uint256 deadline,address recipient,bytes data)"
        );

    constructor() EIP712("BOTTO-ACTIVE-REWARDS", "1.0.0") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(REWARD_ROLE, _msgSender());
    }

    function claim(
        RedeemPermit calldata permit_,
        address recipient_,
        bytes memory signature_
    ) external payable {
        address signer = _verify(_hash(permit_), signature_);

        // Make sure that the signer is authorized to create rewards and permit is valid
        require(
            hasRole(REWARD_ROLE, signer),
            "BottoActiveRewards: signature invalid"
        );

        // Check if permit is already claimed
        require(
            permit_.nonce >= _permitNonce,
            "BottoActiveRewards: permit invalid"
        );

        // Check if permit is expired
        require(
            permit_.kickoff <= block.timestamp &&
                permit_.deadline >= block.timestamp,
            "BottoActiveRewards: permit expired"
        );

        // Check if recipient matches permit
        require(
            recipient_ == permit_.recipient,
            "BottoActiveRewards: recipient does not match permit"
        );

        // Invalidate used permit
        _permitNonce = permit_.nonce + 1;

        // Transfer reward amount
        if (permit_.currency == address(0)) {
            (bool success, ) = recipient_.call{value: permit_.amount}("");
            require(success, "BottoActiveRewards: transfer failed.");
        } else {
            IERC20 token = IERC20(permit_.currency);
            token.safeTransfer(recipient_, permit_.amount);
        }
    }

    receive() external payable {}

    function deposit(address token_, uint256 amount_) external {
        IERC20 token = IERC20(token_);
        token.safeTransferFrom(_msgSender(), address(this), amount_);
    }

    /**
     * @dev see https://eips.ethereum.org/EIPS/eip-712#definition-of-encodedata
     */
    function _hash(RedeemPermit memory permit_)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        REDEEM_PERMIT_TYPEHASH,
                        permit_.amount,
                        permit_.nonce,
                        permit_.currency,
                        permit_.kickoff,
                        permit_.deadline,
                        permit_.recipient,
                        keccak256(permit_.data)
                    )
                )
            );
    }

    /**
     * @dev recover signer from `signature_`
     */
    function _verify(bytes32 digest_, bytes memory signature_)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(digest_, signature_);
    }

    /**
     * @dev recover ERC20 tokens
     * @param token_ The ERC20 token contract address
     * @param amount_ The amount to recover
     * @param recipient_ The recipient of the recovered tokens
     */
    function recoverERC20(
        address token_,
        uint256 amount_,
        address payable recipient_
    ) external virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "BottoActiveRewards: must have admin role"
        );

        require(amount_ > 0, "BottoActiveRewards: invalid amount");

        IERC20 token = IERC20(token_);
        token.safeTransfer(recipient_, amount_);
    }

    /**
     * @dev recover ETH
     * @param amount_ The amount to recover
     * @param recipient_ The recipient of the recovered tokens
     */
    function recover(uint256 amount_, address payable recipient_)
        external
        virtual
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "BottoActiveRewards: must have admin role"
        );

        require(amount_ > 0, "BottoActiveRewards: invalid amount");

        (bool success, ) = recipient_.call{value: amount_}("");
        require(success, "BottoActiveRewards: transfer failed.");
    }
}