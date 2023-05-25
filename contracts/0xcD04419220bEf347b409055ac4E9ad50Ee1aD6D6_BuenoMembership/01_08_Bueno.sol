// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BuenoMembership is AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant VIP_ROLE = keccak256("VIP_ROLE");

    uint256 public exportPrice = 0.0001 ether;

    mapping(string => bool) public paidExports;

    address private signer = address(0);
    address private buenoWallet = address(0);

    event PurchaseComplete(address purchaser, string tokenSetId);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function export(
        string memory tokenSetId,
        uint256 quantity,
        bytes memory signature
    ) public payable {
        require(quantity > 0, "INVALID_QUANTITY");
        require(msg.value == quantity * exportPrice, "INSUFFICIENT_PAYMENT");
        require(paidExports[tokenSetId] == false, "ALREADY_PAID");
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, tokenSetId, quantity)
        );
        require(verify(hash, signature), "INVALID_SIGNATURE");

        paidExports[tokenSetId] = true;
        emit PurchaseComplete(msg.sender, tokenSetId);
    }

    function setSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    function setBuenoWallet(address _buenoWallet)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        buenoWallet = _buenoWallet;
    }

    function isPaidExport(string memory tokenSetId) public view returns (bool) {
        return paidExports[tokenSetId];
    }

    function verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == signer;
    }

    function setPrice(uint256 newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPrice > 0, "INVALID_PRICE");
        exportPrice = newPrice;
    }

    function isOnVipList(address user) public view returns (bool) {
        return hasRole(VIP_ROLE, user);
    }

    function addVip(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(VIP_ROLE, user);
    }

    function removeVip(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VIP_ROLE, user);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(buenoWallet != address(0), "INVALID_PAYOUT_WALLET");
        payable(buenoWallet).transfer((address(this).balance));
    }
}