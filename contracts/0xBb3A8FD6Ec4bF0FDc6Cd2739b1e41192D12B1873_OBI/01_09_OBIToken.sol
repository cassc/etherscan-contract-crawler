// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract OBI is ERC20, AccessControl {

    /// @notice Role definitions
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /// @notice The maximum cap for the token supply.
    /// @dev This is a constant value set to 2 BILLION.
    uint256 public constant MAX_CAP = 2_000_000_000e18 ;  

   /// @notice the multisig address that holds the OBI Tokens
    address public constant ORBOFI_MULTISIG = 0x44Ef9DCec2CbAb655A6692D3E3e1810f7470f3B6; 

    /// @notice Event emitted when a Burner role is granted to an address.
    /// @param beneficiary The address that is granted the Burner role.
    /// @param caller The address that performed the role grant operation.
    event BurnerRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );

    /// @notice Event emitted when a Burner role is removed from an address.
    /// @param beneficiary The address that had the Burner role revoked.
    /// @param caller The address that performed the role revocation operation.
    event BurnerRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );


    /// @notice Event emitted when tokens are burnt.
    event Burned(address from, uint256 to);
 
    /// @notice This function is the constructor for a smart contract that inherits from the ERC20 contract.
    /// @dev Initializes the new token with the provided name, symbol, decimals.
    /// Grants the DEFAULT_ADMIN_ROLE to the creator of the ORBOFI_MULTISIG.
    /// @param _name The name of the token.
    /// @param _symbol The symbol for the token.
    /// @param _decimals The number of decimals the token uses, determining its smallest divisible unit.
    
    constructor(
        string memory _name, 
        string memory _symbol,
        uint8 _decimals
        )

        ERC20(_name, _symbol, _decimals) {
        _grantRole(DEFAULT_ADMIN_ROLE, ORBOFI_MULTISIG); 
        _mint(ORBOFI_MULTISIG, MAX_CAP);

    }


    /// @notice Allows an admin to set a new burner role for the token.
    /// @dev Only an address with the DEFAULT_ADMIN_ROLE can successfully call this function.
    /// Emits a BurnerRoleGranted event upon success.
    /// @param _burner The address to be granted the BURNER_ROLE.
    function setBurnerRole(address _burner) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "OBI: must have admin role to set burner role");
        require(_burner != address(0), "OBI: cannot be a zero address");
        grantRole(BURNER_ROLE, _burner);
        emit BurnerRoleGranted(_burner, msg.sender);
    }

    /// @notice Allows an admin to revoke the burner role from an address.
    /// @dev Only an address with the DEFAULT_ADMIN_ROLE can successfully call this function.
    /// Emits a BurnerRoleRemoved event upon success.
    /// @param _burner The address from which the BURNER_ROLE will be revoked.
    function revokeBurnerRole(address _burner) external  {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "OBI: must have admin role to revoke burner role");
        require(_burner != address(0), "OBI: cannot be a zero address");
        revokeRole(BURNER_ROLE, _burner);
        emit BurnerRoleRemoved(_burner, msg.sender);
    }

    /// @notice Allows a burner to burn a specific amount of tokens from an address.
    /// @dev Only an address with the BURNER_ROLE can successfully call this function. 
    /// The `_from` address must not be a zero address.
    /// @param _from The address from which the tokens will be burned.
    /// @param _amount The amount of tokens to burn.
    function burn(address _from, uint256 _amount) external  {
        require(hasRole(BURNER_ROLE, msg.sender), "OBI: must have burner role to burn");
        require(_from != address(0), "OBI: cannot burn from zero address");
        _burn(_from, _amount);

        emit Burned(_from, _amount);



    }


}