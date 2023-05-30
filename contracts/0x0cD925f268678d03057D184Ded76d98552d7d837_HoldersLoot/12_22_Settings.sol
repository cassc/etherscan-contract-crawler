// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Openzeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";

// PlaySide Contracts
import "./Roles.sol";

contract Settings is AccessControl, Roles
{
    // The base URI for each token
    string public baseURI       	= "https://dwtd.playsidestudios-devel.com/loot/founders/metadata/";

    // The signing address on server side. This address signs the data on the server when users are trying to mintClaim
    address public signerAddress    = 0x6aE227412369c26Ab99cD457c393234f1b5a1a13;

    // If the daily store is active
    bool public dailyStoreActive    = false;

	// This is a hard coded reference to the current network that this contract is being deployed to
	// 	!!! ENSURE YOU CHANGE THIS WHEN DEPLOYING A NEW CONTRACT !!!
	uint256 public blockchain = 1;

	// If the claim function is active or not, this is a safeguard to pause this functionality
	// 	Prefer pausing the contract instead though
	bool public claimActive = true;

    constructor()
    {
        // Set Signer / Server Permissions
        _grantRole(Roles.ROLE_SERVER, signerAddress);
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        SERVER
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Sets the daily store active, this will allow the mintDailyStore function to be called.
    /// @param active: The next status of the dailyStoreActive bool. 
    /// True: The mintDailyStore will become active and users can mint whatever they want from the daily store array.
    /// False: This will lock the daily store function stopping users from using the mint function.
    function setDailyStoreActive(bool active) public onlyRole(Roles.ROLE_SERVER) {
        dailyStoreActive = active;
    }

	/// @dev Sets the claim mint function active or not
	/// @param active: The next status of the claim active mint function
	// 		Used to pause or unpause the mint claim function
	function setClaimActive(bool active) public onlyRole(Roles.ROLE_SERVER) {
		claimActive = active;
	}

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        SAFE
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Sets the current signer address, this is the address that signs on the server side to validate signatures
    /// @param newSignerAddress: The address that signs the data that is passed from the dapp to the contract.
    function setSignerAddress(address newSignerAddress) public onlyRole(Roles.ROLE_SAFE) {
        signerAddress = newSignerAddress;
    }

}