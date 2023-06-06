// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract AlluoToken is ERC20, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CAP_CHANGER_ROLE = keccak256("CAP_CHANGER_ROLE");

    // users who can transfer tokens when contract paused
    mapping(address=>bool) public whitelist;

    // users who are blocked from transferring tokens
    mapping(address=>bool) public blocklist;
    
    // the maximum amount of tokens
    // that can only be changed by a special role
    uint256 private _cap;
    
    // is token contract paused
    bool public paused;

    /**
     * @notice not allows transfer for black listed users
     * @dev modifier for checking whether users
     * who transfering are in the blocked list 
     * @param _recipient address of tokens receiver
     */
    modifier notBlocked(address _recipient) {
        require(
            !blocklist[msg.sender] && !blocklist[_recipient], 
            "AlluoToken: You are in blocklist"
        );
        _;
    }

    /**
     * @notice allows transfer only for white listed users while paused
     * @dev modifier for checking whether users
     * who transfering are in the white list 
     * @param _recipient address of tokens receiver
     */
    modifier pausable(address _recipient) {
        if (paused) {
            require(
                whitelist[msg.sender] || whitelist[_recipient], 
                "AlluoToken: Only whitelisted users can transfer while token paused"
            );
        }
        _;
    }

    /**
     * @dev initializes a contract with a fixed cap 
     * and grants all roles to the new admin
     * @param _newAdmin  address of the new admin
     */
    constructor(address _newAdmin)
        ERC20("Alluo Token", "ALLUO")
        ERC20Permit("Alluo Token")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _grantRole(ADMIN_ROLE, _newAdmin);
        _grantRole(MINTER_ROLE, _newAdmin);
        _grantRole(BURNER_ROLE, _newAdmin);
        _grantRole(PAUSER_ROLE, _newAdmin);
        _grantRole(CAP_CHANGER_ROLE, _newAdmin);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CAP_CHANGER_ROLE, ADMIN_ROLE);
        _setCap(200000000 * 10 ** decimals());
    }

    /**
     * @dev changes max cap. Can only be called by a special role
     * @param _newCap new amount of max cap
     */
    function changeCap(uint256 _newCap) public {
        require(
            hasRole(CAP_CHANGER_ROLE, msg.sender),
            "AlluoToken: must have cap changer role"
        );

        require(
            _newCap > totalSupply() && _newCap > 0,
            "AlluoToken: wrong new cap value"
        );
        _setCap(_newCap);
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "AlluoToken: must have minter role"
        );
        require(
            totalSupply() + amount <= _cap, 
            "AlluoToken: can't mint over max cap"
        );
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        require(
            hasRole(BURNER_ROLE, msg.sender),
            "AlluoToken: must have burner role"
        );
        _burn(account, amount);
    }

    /**
     * @dev changes pause state of contract. Can only be called by a pauser role
     * @param _state new pause state
     */
    function setPause(bool _state) public {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "AlluoToken: must have pauser role"
        );
        paused = _state;
    }

    /**
     * @dev changes status of a user in the whitelist.
     * Can only be called by the admin
     * @param _user address of the user 
     * @param _state new user status in whitelist
     */
    function setWhiteStatus(address _user, bool _state) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "AlluoToken: must have admin role"
        );
        whitelist[_user] = _state;
    }

    /**
     * @dev changes status of a user in the block list.
     * Can only be called by the admin
     * @param _user address of the user 
     * @param _state new user status in block list
     */
    function setBlockStatus(address _user, bool _state) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "AlluoToken: must have admin role"
        );
        blocklist[_user] = _state;
    }

    /**
     * @dev calcAvailableToken - calculate available tokens
     * @return current max total supply of token.
     */
    function maxTotalSupply() public view virtual returns (uint256) {
        return _cap;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) 
    internal
    notBlocked(to)
    pausable(to)
    override 
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev changes max cap
     * @param _newCap new amount of max cap
     */
    function _setCap(uint256 _newCap)
        internal
    {
        _cap = _newCap;
    }
 
    /**
     * @dev unlock accidentally sent tokens at the token contract address.
     * Can only be called by the admin
     * @param _token addres of unlocked token.
     * @param _to  receiver of tokens.
     * @param _amount  of unlocked tokens.
     */
    function unlockERC20(address _token, address _to, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        IERC20(_token).transfer(_to, _amount);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint (address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

}