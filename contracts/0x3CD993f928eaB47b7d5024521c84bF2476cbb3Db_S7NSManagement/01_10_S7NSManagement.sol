// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
    @title S7NSManagement contract
    @dev This contract is being used as Governance of S7NS
       + Register address (Treasury) to receive Commission Fee 
       + Set up additional special roles - DEFAULT_ADMIN_ROLE, MANAGER_ROLE and MINTER_ROLE
*/
contract S7NSManagement is AccessControlEnumerable {
    address public treasury;

    mapping(address => bool) public paymentTokens;
    bool public halted;

    //  Declare Roles - MANAGER_ROLE and MINTER_ROLE
    //  There are three roles:
    //     - Top Gun = DEFAULT_ADMIN_ROLE:
    //         + Manages governance settings
    //         + Has an authority to grant/revoke other roles
    //         + Has an authority to set him/herself other roles
    //     - MANAGER_ROLE
    //         + Has an authority to do special tasks, i.e. settings
    //     - MINTER_ROLE
    //         + Has an authority to mint NFT items
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _admin, address _treasury) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        treasury = _treasury;
    }

    /**
       @notice Change new address of Treasury
       @dev  Caller must have DEFAULT_ADMIN_ROLE
       @param _treasury    Address of new Treasury
    */
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_treasury != address(0), "AddressZero");

        treasury = _treasury;
    }

    /**
       @notice Set `halted = true`
       @dev  Caller must have MANAGER_ROLE
    */
    function halt() external onlyRole(MANAGER_ROLE) {
        halted = true;
    }

    /**
       @notice Set `halted = false`
       @dev  Caller must have MANAGER_ROLE
    */
    function unhalt() external onlyRole(MANAGER_ROLE) {
        halted = false;
    }

    /**
       @notice Register Payment Token
       @dev  Caller must have MANAGER_ROLE
       @param _token         Address of Payment Token (0x00 - Native Coin)
    */
    function addPayment(address _token) external onlyRole(MANAGER_ROLE) {
        require(!paymentTokens[_token], "PaymentExist");

        paymentTokens[_token] = true;
    }

    /**
       @notice Unregister Payment Token
       @dev  Caller must have MANAGER_ROLE
       @param _token         Address of Payment Token (0x00 - Native Coin)
    */
    function removePayment(address _token) external onlyRole(MANAGER_ROLE) {
        require(paymentTokens[_token], "PaymentNotFound");

        delete paymentTokens[_token];
    }
}