// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./FeralfileSaleData.sol";
import "./ECDSASigner.sol";

contract FeralfileVault is Ownable, FeralfileSaleData, ECDSASigner {
    mapping(bytes32 => bool) private _paidSale;

    constructor(address signer_) ECDSASigner(signer_) {}

    /// @notice pay for buyArtwork to a FFV4 contract destination.
    /// @param r_ - part of signature for validating parameters integrity
    /// @param s_ - part of signature for validating parameters integrity
    /// @param v_ - part of signature for validating parameters integrity
    /// @param saleData_ - the sale data
    function payForSale(
        bytes32 r_,
        bytes32 s_,
        uint8 v_,
        SaleData calldata saleData_
    ) external {
        require(
            saleData_.payByVaultContract,
            "FeralfileVault: not pay by vault"
        );
        require(
            address(this).balance >= saleData_.price,
            "FeralfileVault: insufficient balance"
        );

        validateSaleData(saleData_);

        bytes32 message = keccak256(
            abi.encode(block.chainid, msg.sender, saleData_)
        );
        require(!_paidSale[message], "FeralfileVault: paid sale");
        require(
            isValidSignature(message, r_, s_, v_),
            "FeralfileVault: invalid signature"
        );
        _paidSale[message] = true;
        payable(msg.sender).transfer(saleData_.price);
    }

    function withdrawFund(uint256 weiAmount) external onlyOwner {
        require(
            address(this).balance >= weiAmount,
            "FeralfileVault: insufficient balance"
        );
        payable(msg.sender).transfer(weiAmount);
    }

    receive() external payable {}
}