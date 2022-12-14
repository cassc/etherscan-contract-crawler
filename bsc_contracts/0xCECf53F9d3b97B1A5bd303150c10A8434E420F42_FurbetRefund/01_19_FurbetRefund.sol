// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Interfaces.
import "./interfaces/IFurfiPresale.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @custom:security-contact [email protected]
contract FurbetRefund is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    using Strings for uint256;

    address private _signer;
    IERC20 private _usdc;
    IFurfiPresale private _presale;

    mapping (address => bool) public refunded;

    /**
     * Setup.
     */
    function setup() external
    {
        _signer = 0xfD79312E82Ef5D6511C2c85389C82F1DE72E53Af;
        _usdc = IERC20(addressBook.get("payment"));
        _presale = IFurfiPresale(addressBook.get("furfiPresale"));
        refunded[0xc448E99A6AFd259627dA38b2DC5184009A39a7f8] = true;
    }

    /**
     * Verify.
     * @param signature_ Message signature.
     * @param sender_ Message sender.
     * @param expiration_ Message expiration.
     */
    function _verify(
        bytes memory signature_,
        address sender_,
        uint256 $salt,
        uint256 expiration_
    ) internal view returns (bool) {
        // Re-create the original signature hash value.
        bytes32 _hash_ = sha256(abi.encode(sender_, $salt, expiration_));
        // Verify that the signature was created by the signer.
        if(ECDSA.recover(_hash_, signature_) != _signer) return false;
        // Signature checks out.
        return true;
    }

    /**
     * Refund.
     * @param signature_ Message signature.
     * @param amount_ Amount to refund.
     * @param expiration_ Message expiration.
     */
    function refund(bytes memory signature_, uint256 amount_, uint256 expiration_) external
    {
        require(expiration_ > block.timestamp, "Expired");
        require(!refunded[msg.sender], "Already refunded");
        require(amount_ > 0, "Invalid amount");
        require(_verify(signature_, msg.sender, amount_, expiration_), "Invalid signature");
        require(_usdc.balanceOf(address(this)) >= amount_, "Insufficient funds");
        refunded[msg.sender] = true;
        _usdc.transfer(msg.sender, amount_);
    }

    /**
     * Refund to Furfi.
     * @param signature_ Message signature.
     * @param amount_ Amount to refund.
     * @param expiration_ Message expiration.
     */
    function refundToFurfi(bytes memory signature_, uint256 amount_, uint256 expiration_) external
    {
        require(expiration_ > block.timestamp, "Expired");
        require(!refunded[msg.sender], "Already refunded");
        require(amount_ > 0, "Invalid amount");
        require(_verify(signature_, msg.sender, amount_, expiration_), "Invalid signature");
        require(_usdc.balanceOf(address(this)) >= amount_, "Insufficient funds");
        refunded[msg.sender] = true;
        _usdc.approve(address(_presale), amount_);
        _presale.buyWithUsdcFor(msg.sender, amount_);
    }
}