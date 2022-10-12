// SPDX-License-Identifier: MIT
//
//--------------------------
// 44 65 66 69 4d 6f 6f 6e
//--------------------------
//
// ERC20 token contract
// [+] Role-based access control

pragma solidity ^0.8.4;

import "../libs/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../libs/@openzeppelin/contracts/access/AccessControl.sol";

contract ShelterzToken is ERC20, ERC20Burnable, AccessControl {

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- GLOBAL PARAMETERS
    // -------------------------------------------------------------------------------------------------------

    bytes32 constant public                   MINTER = keccak256("MINTER");
    uint256 constant public                   MAX_SUPPLY = 1000000000 ether;




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- TRACKING
    // -------------------------------------------------------------------------------------------------------

    address[] public                          contractManagers;
    mapping(address => uint256)               isManager;




    // FUNCTIONS
    //
    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Constructor
    // -------------------------------------------------------------------------------------------------------

    constructor()
        ERC20("SHELTERZ", "TERZ") {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            contractManagers.push(address(0x00));
    }




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- User managment
    // -------------------------------------------------------------------------------------------------------

    // @notice                                returns privileged addresses that can call this contract
    function                                  returnContractManagers() public view returns(address[] memory) {
      return(contractManagers);
    }




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Admin
    // -------------------------------------------------------------------------------------------------------

    // @notice                                allows to mint new tokens tokens
    // @param                                 [address] to => address to mint tokens to
    // @param                                 [uint256] amount  => amount of tokens to mint
    function mint(address to, uint256 amount) public onlyRole(MINTER) {
      require(totalSupply() + amount <= MAX_SUPPLY, "Max supply is reached!");
      _mint(to, amount);
    }

    // @notice                                allows certain addresses (i.e. ico contracts) to recieve tokens
    //                                        at init to set up ICO fund
    // @param                                 [address] account => address to grant role to
    // @param                                 [uint256] amount  => amount allowed to spend
    function                                  grantManagerToContractInit(address account, uint256 amount) external {
      uint256                                 index = contractManagers.length;

      require(hasRole(DEFAULT_ADMIN_ROLE, tx.origin) == true, "Caller is not admin!");
      require(isManager[account] == 0, "Account already a manager!");

      _approve(address(this), account, amount);
      contractManagers.push(account);
      isManager[account] = index;
      _grantRole(MINTER, account);
    }

    // @notice                                revokes the ability to spend tokens after init
    // @param                                 [address] account => address to revoke role from
    function                                  revokeManagerAfterContractInit(address account) external {
      uint256                                 index = isManager[account];

      require(hasRole(DEFAULT_ADMIN_ROLE, tx.origin) == true, "Caller is not admin!");
      require(index > 0, "Account not a manager!");

      delete contractManagers[index];
      isManager[account] = 0;
      _revokeRole(MINTER, account);
    }

    // @notice                                allows an address (ico contract) to manage tokens
    // @param                                 [bytes32] role    => role to grant (admin or manager)
    // @param                                 [address] account => address to grant role to
    function                                  grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
      uint256                                 index = contractManagers.length;

      if (role == MINTER) {
        require(isManager[account] == 0, "Account already a manager!");
        contractManagers.push(account);
        isManager[account] = index;
      }
      _grantRole(role, account);
    }

    // @notice                                revokes privileged access from address
    // @param                                 [bytes32] role    => role to revoke (admin or manager)
    // @param                                 [address] account => address to revoke role from
    function                                  revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
      uint256                                 index = isManager[account];

      if (role == MINTER) {
        require(index > 0, "Account not a manager!");
        delete contractManagers[index];
        isManager[account] = 0;
      }
      _revokeRole(role, account);
    }
}