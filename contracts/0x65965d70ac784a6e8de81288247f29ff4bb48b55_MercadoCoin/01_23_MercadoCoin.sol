// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

/**
 * @dev {ERC20PresetMinterPauserUpgradeable} token whose ownership and minting capabilities are transferred to a specified owner.
 * @dev {ERC20PermitUpgradeable} enables permit based interactions
 **/
contract MercadoCoin is ERC20PresetMinterPauserUpgradeable, ERC20PermitUpgradeable {
    
    mapping(address => bool) internal _denylist;

    event Denylisted(address indexed _account);
    event UnDenylisted(address indexed _account);

    bytes32 public constant DENYLISTER_ROLE = keccak256("DENYLISTER_ROLE");
    /**
     * @dev Used to prevent implementation manipulation
     */
    constructor() initializer {}

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE` and `DENYLISTER_ROLE` to the
     * owner specified in the owner param.
     * @param owner is the owner of the contract after initialization
     * See {ERC20-constructor}.
     */
    function initialize(string memory name, string memory symbol, address owner) public initializer {
        require(owner != address(0x0), "New owner cannot be 0");
        __ERC20PresetMinterPauser_init(name, symbol);
        __ERC20Permit_init(name);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);
        _setupRole(DENYLISTER_ROLE, owner);
        revokeRole(PAUSER_ROLE, _msgSender());
        revokeRole(MINTER_ROLE, _msgSender());
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
     }

    /**
     * @dev Adds account to denylist
     * @param _account The address to denylist
    */
    function denylist(address _account) public {
        require(hasRole(DENYLISTER_ROLE, msg.sender), "Caller is not a  Denylister");
        _denylist[_account] = true;
        emit Denylisted(_account);
    }

    /**
     * @dev Removes account from denylist
     * @param _account The address to remove from the denylist
    */
    function unDenylist(address _account) public {
        require(hasRole(DENYLISTER_ROLE, msg.sender), "Caller is not a  Denylister");
        _denylist[_account] = false;
        emit UnDenylisted(_account);
    }

    function isDenylisted(address _account) public view returns (bool) {
        return _denylist[_account];
    }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PresetMinterPauserUpgradeable) {
        require (!isDenylisted(to), "Token transfer not possible. Receiver is DENYLISTED");        
        require (!isDenylisted(from), "Token transfer not possible. Sender is DENYLISTED");
        ERC20PresetMinterPauserUpgradeable._beforeTokenTransfer(from, to, amount);
    }
}