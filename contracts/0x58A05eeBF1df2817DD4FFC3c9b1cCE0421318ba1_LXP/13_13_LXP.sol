// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// LXP token
contract LXP is ERC20Burnable, Ownable, AccessControl {
    /// @notice only burn role can burn
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice only transfer role can transfer
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @notice record of each accounts mint allowance
    mapping (address=>uint) public mintAllowanceOf;

    /// @notice An event that emitted when LXP is minted to an account
    event MintTo(address indexed from, address indexed to, uint amount);

    /// @notice An event that emitted when mint allowance is changed
    event GrantMintAllowance(address indexed from, address indexed to, uint previousAmount, uint newAmount);

    constructor() ERC20("LXPoints", "LXP") {}

    /// @notice Set admin role
    function grantAdmin(address account) public onlyOwner {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }   

    function _grantMintAllowance(address to, uint allowance) internal {
        // sender must be admin
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LXP: must have admin role to grant mint allowance");
        mintAllowanceOf[to] = allowance;
        uint old = mintAllowanceOf[to];
        emit GrantMintAllowance(_msgSender(), to, old, allowance);
    }

    /**
     * @notice Grant mint allowance to an account
     * @param _address The account to grant mint allowance to
     * @param _amount The amount of mint allowance to grant
     */
    function grantMintAllowance(address _address, uint _amount) public {
        _grantMintAllowance(_address, _amount);
    }

    /**
     * @notice Increase mint allowance of an account
     * @param _address The account to mint LXP to
     * @param _amount The amount of LXP to mint
     */
    function increaseMintAllowance(address _address, uint _amount) public {
        _grantMintAllowance(_address, mintAllowanceOf[_address] + _amount);
    }

    /**
     * @notice Decrease mint allowance of an account
     * @param _address The account to mint LXP to
     * @param _amount The amount of LXP to mint
     */
    function decreaseMintAllowance(address _address, uint _amount) public {
        _grantMintAllowance(_address, mintAllowanceOf[_address] - _amount);
    }

    /// @notice Only transfer role can transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(hasRole(TRANSFER_ROLE, from), "LXP: can only transfer from account with transfer role");
        super._transfer(from, to, amount);
    }

    function _mint(address _account, uint256 _amount) internal override {
        address from = _msgSender();
        require(mintAllowanceOf[from] >= _amount, "Not enough mint allowance");
        mintAllowanceOf[from] -= _amount;
        super._mint(_account, _amount);
        emit MintTo(from, _account, _amount);
    }

    /**
     * @notice Mint LXP to an account
     * @param _to The account to mint LXP to
     * @param _amount The amount of LXP to mint
     */
    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

    /**
     * @notice Mint LXP to multiple accounts
     * @param _tos The accounts to mint LXP to
     * @param _amounts The amounts of LXP to mint
     */
    function batchMint(address[] calldata _tos, uint256[] calldata _amounts) public {
        require(_tos.length == _amounts.length, "LXP: to and amount length mismatch");
        for (uint256 i = 0; i < _tos.length; i++) {
            mint(_tos[i], _amounts[i]);
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * - the caller must have `BURNER_ROLE`.
     */
    function burnFrom(address account, uint256 amount) public override {
        require(hasRole(BURNER_ROLE, _msgSender()), "LXP: must have burner role to burn");
        super.burnFrom(account, amount);
    }
}