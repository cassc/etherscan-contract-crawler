// SPDX-License-Identifier: The MIT License (MIT)





//  __/\\\\\\\\\\\\\\\____________/\\\\\\\\\\\\\\\____________/\\\\\\\\\\\\\\\_        
//   _\////////////\\\____________\////////////\\\____________\////////////\\\__       
//    ___________/\\\/_______________________/\\\/_______________________/\\\/___      
//     _________/\\\/_______________________/\\\/_______________________/\\\/_____     
//      _______/\\\/_______________________/\\\/_______________________/\\\/_______    
//       _____/\\\/_______________________/\\\/_______________________/\\\/_________   
//        ___/\\\/_______________________/\\\/_______________________/\\\/___________  
//         __/\\\\\\\\\\\\\\\____________/\\\\\\\\\\\\\\\____________/\\\\\\\\\\\\\\\_ 
//          _\///////////////____________\///////////////____________\///////////////__





pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMinter {
    function owner() external returns (address);
}

/**
 * @title ZZZs Token
 * 
 * @notice The official Dream World rewards token.
 * 
 * @author M. Burke
 * 
 * @custom:security-contact [email protected]
 */
contract ZZZsToken is ERC20, ERC20Burnable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("ZZZsToken", "ZZZ") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /** @dev A note on roles and the owner.
     *
     *      Special care must be taken if transfering ownership via the `Ownable`
     *      lib. It is very likely specific roles should also be granted to the new
     *      owner, at that time.
     */

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /** @notice `grantMinter` is used to allow a staking contract to mint ZZZs
     *           to users as a reward.
     */
    function grantMinter(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IMinter minter = IMinter(_addr);

        require(
            minter.owner() == owner(),
            "Owner of minting contract must be owner of ZZZs."
        );
        require(_isContract(_addr), "minter must be contract");

        _grantRole(MINTER_ROLE, _addr);
    }

    /** @notice `revokeMinter` is used to discontinue minting privilege with
     *           a staking contract.
     */
    function revokeMinter(address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, _addr);
    }

    /**
     * @dev This helper function is used to ensure new addresses being granted
     *      the MINTER_ROLE are not EOA's.
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint32 size;

        assembly {
            size := extcodesize(_addr)
        }

        return (size > 0);
    }
}