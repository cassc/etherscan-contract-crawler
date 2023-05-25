// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IpenguPins.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
                         %@@@@*  @@@  *#####
                   &@@@@@@@@ ,@@@@@@@@@  #########
              ,@@@@@@@@  #                  %. @@@@@@@
           &@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@ [email protected]@@@@@@@
         @@@@@@@@@@@. @@@@@@@@@@@@ @@@@@@@@@@@@@  @@@@@@@@@@
       ####       @  @@@@@@@@@@@@@ @@@@@@@@@@@@@@.       .&@@@
     ########. @@@@@@@@@@ @@@@@%#///#%@@@@@@ @@@@@@@@@@@  @@@@@.
    ########  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@. @@@@@@
   ######### @@@@@@@@@@@ &@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@  @@@@@@
  %@@(       ,@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@,      &@
  @@@# @@@@@@@@@@@@ ,#####*                 . ,@@@@  %@@@@@@@@@@@@@@/
  @@@  @@@@@@@@@@@@ ##############  @@@@@@@@@@@@ ,@@@@.   @@@&  @@@@@@..#
  @@@ &@@@@@@@@@@@@ ##############  @@@@@@@@@@ @@@@@@@@@@@&   @@@@@@@@ #####
  @@@ @@@@@@@@@@@@@ ##############  @@@@@@@@ *@@@@@@@@@@  @@@. @@@@@@ ########
  @@        %@@@@@@ ##############  @@@@@@@ @@@@@@@@@@@ @@@@@@@ @@@&@ ####### /
  &&@@@@@  @@@@@@@@@@&*                    @@@@@@@@@@# @@@@@@@  &&&&&&& ##  @@@
  &&&&&@@  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@* @@@    [email protected]% @@@@@@ &&&&&&&&&&& @@@@@@
  @&&&&&&  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@@ @@@    &&&&&&&&&&&&& @@@@@
      &&&  &@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@ @@@@@@    . #&&&&&&&& @@@@/
   (((  &&       /@@@@@* @@@@@@@@@@@@@@@,[email protected]@@@@@@@@ @@@@@& &&&&& &&&&&&     @@@
   (((* &&&&&&&&&/ @@@@@@@@@@@@@@@ @@@@@ .   [email protected]@@@@ @@@@@  &&&&& &&&&&&&& @@@@@
   (((( &&&&&&&&&/ &&&@@@@@@@@@@@@ @@@@@  ######### %@@@@  &&&&& &&&&&&&& @@@@@
     (( &&&&&&&&&/ &&&&&&&@@@@@@@@ @@@@@% ######### @@@@@%          &&&&& @@@.
           .&&&&&/ &&&&&&&&&&&&&&@ @@@@@@ ######### @@@@@@
                                           ######## @@@@@@
*/

/**
 * @title Intermediary contract for dropping pengupins
 * @author Pudgy Penguins Penguineering Team (davidbailey.eth, Lorenzo)
 */
contract Intermediary is Ownable {
    // ========================================
    //     EVENT & ERROR DEFINITIONS
    // ========================================

    error AddressAlreadySet();
    error InvalidAddress();
    error NotAnAdmin();
    error MaximumAllowanceExceeded();

    // ========================================
    //     VARIABLE DEFINITIONS
    // ========================================

    bool private pengupinsAddressSet = false;
    IpenguPins public pengupins;

    mapping(address => mapping(uint256 => uint256)) public adminAllowance;

    // ========================================
    //    CONSTRUCTOR AND CORE FUNCTIONS
    // ========================================

    constructor() {}

    /**
     * @notice Drops airdrop tokens to a list of holders
     * @param _id token ID to be received
     * @param _holders list of addresses to receive tokens
     * @dev only nominated admins or contract owner can call this function
     */
    function airdropPenguPin(
        uint256 _id,
        address[] calldata _holders
    ) external {
        if (msg.sender != owner()) {
            if (adminAllowance[msg.sender][_id] < _holders.length)
                revert MaximumAllowanceExceeded();

            adminAllowance[msg.sender][_id] -= _holders.length;
        }
        pengupins.airdropPenguPin(_id, _holders);
    }

    // ========================================
    //     OWNER FUNCTIONS
    // ========================================

    // Function that allows the contract owner to nominate an admin
    /**
     * @notice Adds an admin to the contract
     * @param _newAdmin address of the admin to be added
     * @param _tokenId token ID that the admin can airdrop
     * @param _amount amount of tokens that the admin can airdrop
     */
    function addAdminForTokenId(
        address _newAdmin,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        if (_newAdmin == address(0)) revert InvalidAddress();
        adminAllowance[_newAdmin][_tokenId] = _amount;
    }

    /**
     * @notice Removes an admin from the contract
     * @param _oldAdmin address of the admin to be removed
     * @param _tokenId token ID that the admin can airdrop
     */
    function removeAdminForTokenId(
        address _oldAdmin,
        uint256 _tokenId
    ) external onlyOwner {
        if (adminAllowance[_oldAdmin][_tokenId] == 0) revert NotAnAdmin();
        adminAllowance[_oldAdmin][_tokenId] = 0;
    }

    /**
     * @notice Burns a token with the given ID from holder's address
     * @param _holder address of the token holder
     * @param _id token ID to be burned
     */
    function adminBurnPenguPin(
        address _holder,
        uint256 _id
    ) external onlyOwner {
        pengupins.adminBurnPenguPin(_holder, _id);
    }

    /**
     * @notice Pauses the pengupin contract
     */
    function pause() public onlyOwner {
        pengupins.pause();
    }

    /**
     * @notice Unpauses the pengupin contract
     */
    function unpause() public onlyOwner {
        pengupins.unpause();
    }

    /**
     * @notice Sets the address of the pengupins contract
     * @param _pengupinsAddress address of the pengupins contract
     */
    function setPengupinsAddress(address _pengupinsAddress) external onlyOwner {
        if (pengupinsAddressSet) revert AddressAlreadySet();
        if (_pengupinsAddress == address(0)) revert InvalidAddress();
        pengupinsAddressSet = true;
        pengupins = IpenguPins(_pengupinsAddress);
    }

    /**
     * @notice Transfers ownership of the pengupins contract
     * @param _newOwner address of the new owner
     */
    function transferOwnershipOfPengupins(
        address _newOwner
    ) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidAddress();
        pengupins.transferOwnership(_newOwner);
    }

    /**
     * @notice Sets the base URI of the pengupins contract
     * @param _base base URI of the pengupins contract
     * @param _suffix suffix URI of the pengupins contract
     */
    function setURI(
        string calldata _base,
        string calldata _suffix
    ) external onlyOwner {
        pengupins.setURI(_base, _suffix);
    }

    /**
     * @notice Updates the version of the signature that the pengupin contract uses
     * @param _newVersion new version of the signature
     */
    function updateSignVersion(string calldata _newVersion) external onlyOwner {
        pengupins.updateSignVersion(_newVersion);
    }

    /**
     * @notice Updates the wallet that the pengupin contract uses to verify signatures
     * @param _newSignerWallet address of the new wallet
     */
    function updateSignerWallet(address _newSignerWallet) external onlyOwner {
        pengupins.updateSignerWallet(_newSignerWallet);
    }
}