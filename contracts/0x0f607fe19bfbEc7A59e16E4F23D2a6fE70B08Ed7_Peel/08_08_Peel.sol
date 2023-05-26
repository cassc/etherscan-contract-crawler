// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Peel is ERC20Upgradeable, OwnableUpgradeable {
    struct Supply {
        uint256 cap;
        uint256 total;
    }
    mapping(address => Supply) public bridges; // bridge address -> supply

    mapping(address => bool) public admins;

    event SetAdmin(address indexed user, bool indexed auth);
    event BridgeSupplyCapUpdated(address bridge, uint256 supplyCap);

    modifier onlyAdmin() {
        require(
            owner() == msg.sender || admins[msg.sender],
            "caller is not admin"
        );
        _;
    }

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
    }

    function mintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setAdmin(address _user, bool _auth) external onlyOwner {
        require(_user != address(0), "invalid user");
        admins[_user] = _auth;
        emit SetAdmin(_user, _auth);
    }

    /**
     * @notice Mints tokens to an address. Increases total amount minted by the calling bridge.
     * @param _to The address to mint tokens to.
     * @param _amount The amount to mint.
     */
    function mint(address _to, uint256 _amount) external returns (bool) {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        b.total += _amount;
        require(b.total <= b.cap, "exceeds bridge supply cap");
        _mint(_to, _amount);
        return true;
    }

    /**
     * @notice Burns tokens for msg.sender.
     * @param _amount The amount to burn.
     */
    function burn(uint256 _amount) external returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    /**
     * @notice Burns tokens from an address. Decreases total amount minted if called by a bridge.
     * Alternative to {burnFrom} for compatibility with some bridge implementations.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burn(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @notice Burns tokens from an address. Decreases total amount minted if called by a bridge.
     * See {_burnFrom}.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function burnFrom(address _from, uint256 _amount) external returns (bool) {
        return _burnFrom(_from, _amount);
    }

    /**
     * @dev Burns tokens from an address, deducting from the caller's allowance.
     *      Decreases total amount minted if called by a bridge.
     * @param _from The address to burn tokens from.
     * @param _amount The amount to burn.
     */
    function _burnFrom(address _from, uint256 _amount) internal returns (bool) {
        Supply storage b = bridges[msg.sender];
        if (b.cap > 0 || b.total > 0) {
            // set cap to 1 would effectively disable a deprecated bridge's ability to burn
            require(b.total >= _amount, "exceeds bridge minted amount");
            unchecked {
                b.total -= _amount;
            }
        }
        _spendAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
        return true;
    }

    /**
     * @notice Updates the supply cap for a bridge.
     * @param _bridge The bridge address.
     * @param _cap The new supply cap.
     */
    function updateBridgeSupplyCap(address _bridge, uint256 _cap)
        external
        onlyAdmin
    {
        // cap == 0 means revoking bridge role
        bridges[_bridge].cap = _cap;
        emit BridgeSupplyCapUpdated(_bridge, _cap);
    }
}