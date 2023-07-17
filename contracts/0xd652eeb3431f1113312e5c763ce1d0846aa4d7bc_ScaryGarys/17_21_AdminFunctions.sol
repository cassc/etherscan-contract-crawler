// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

contract AdminFunctions {

    // ---
    // Properties
    // ---

    string public contractURI;
    address public imnotArtPayoutAddress;

    // ---
    // Function Modifiers
    // ---

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Only Admins.");
        _;
    }

    // ---
    // Mappings
    // ---

    mapping(address => bool) isAdmin;

    // ---
    // Functions
    // ---

    // @dev Add an address to the isAdmin mapping.
    function addAdmin(address addressToAdd) external {
        require(isAdmin[msg.sender], "Only Admins.");

        isAdmin[addressToAdd] = true;
    }

    // @dev Remove an address from the isAdmin mapping.
    function removeAdmin(address addressToRemove) external {
        require(isAdmin[msg.sender], "Only Admins.");

        isAdmin[addressToRemove] = false;
    }

    // @dev Update the contract uri.
    function updateContractUri(string memory newContractUri) external {
        require(isAdmin[msg.sender], "Only Admins.");

        contractURI = newContractUri;
    }

    // @dev Update the imnotArt payout address.
    function updateImnotartPayoutAddress(address _payoutAddress) external {
        require(isAdmin[msg.sender], "Only Admins.");

        imnotArtPayoutAddress = _payoutAddress;
    }

    // @dev Take the balance of the given contract and transfer it to the caller.
    function withdraw() external {
        require(isAdmin[msg.sender], "Only Admins.");

        uint256 amount = address(this).balance;
        require(amount > 0, "Contract balance empty.");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}