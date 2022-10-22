// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RoleFixedNoMintNoBurnNoPause is ERC20, AccessControl {
    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }
}

contract FactoryRoleFixedNoMintNoBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleFixedNoMintNoBurnNoPause) {
        return new RoleFixedNoMintNoBurnNoPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleFixedNoMintCanBurnNoPause is ERC20, AccessControl, ERC20Burnable {
    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }
}

contract FactoryRoleFixedNoMintCanBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleFixedNoMintCanBurnNoPause) {
        return new RoleFixedNoMintCanBurnNoPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleFixedNoMintNoBurnCanPause is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleFixedNoMintNoBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleFixedNoMintNoBurnCanPause) {
        return new RoleFixedNoMintNoBurnCanPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleFixedNoMintCanBurnCanPause is ERC20, Pausable, AccessControl, ERC20Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleFixedNoMintCanBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleFixedNoMintCanBurnCanPause) {
        return new RoleFixedNoMintCanBurnCanPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleUnlimitCanMintCanBurnCanPause is ERC20, Pausable, AccessControl, ERC20Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleUnlimitCanMintCanBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleUnlimitCanMintCanBurnCanPause) {
        return new RoleUnlimitCanMintCanBurnCanPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleUnlimitCanMintNoBurnCanPause is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleUnlimitCanMintNoBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleUnlimitCanMintNoBurnCanPause) {
        return new RoleUnlimitCanMintNoBurnCanPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleUnlimitCanMintNoBurnNoPause is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}

contract FactoryRoleUnlimitCanMintNoBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleUnlimitCanMintNoBurnNoPause) {
        return new RoleUnlimitCanMintNoBurnNoPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleUnlimitCanMintCanBurnNoPause is ERC20, AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}

contract FactoryRoleUnlimitCanMintCanBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals
    ) public returns (RoleUnlimitCanMintCanBurnNoPause) {
        return new RoleUnlimitCanMintCanBurnNoPause(name, symbol, initialSupply, owner, decimals);
    }
}

contract RoleCappedCanMintCanBurnCanPause is ERC20, Pausable, AccessControl, ERC20Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals,
        uint256 _cap
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        require(_cap > 0, "ERC20Capped: cap is 0");
        s_cap = _cap;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleCappedCanMintCanBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals,
        uint256 _cap
    ) public returns (RoleCappedCanMintCanBurnCanPause) {
        return
            new RoleCappedCanMintCanBurnCanPause(
                name,
                symbol,
                initialSupply,
                owner,
                decimals,
                _cap
            );
    }
}

contract RoleCappedCanMintNoBurnCanPause is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals,
        uint256 _cap
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        require(_cap > 0, "ERC20Capped: cap is 0");
        s_cap = _cap;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryRoleCappedCanMintNoBurnCanPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals,
        uint256 _cap
    ) public returns (RoleCappedCanMintNoBurnCanPause) {
        return
            new RoleCappedCanMintNoBurnCanPause(name, symbol, initialSupply, owner, decimals, _cap);
    }
}

contract RoleCappedCanMintCanBurnNoPause is ERC20, AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals,
        uint256 _cap
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        require(_cap > 0, "ERC20Capped: cap is 0");
        s_cap = _cap;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
}

contract FactoryRoleCappedCanMintCanBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals,
        uint256 _cap
    ) public returns (RoleCappedCanMintCanBurnNoPause) {
        return
            new RoleCappedCanMintCanBurnNoPause(name, symbol, initialSupply, owner, decimals, _cap);
    }
}

contract RoleCappedCanMintNoBurnNoPause is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 _decimals,
        uint256 _cap
    ) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        s_decimals = _decimals;
        require(_cap > 0, "ERC20Capped: cap is 0");
        s_cap = _cap;
        _mint(owner, initialSupply * (10**decimals()));
    }

    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
}

contract FactoryRoleCappedCanMintNoBurnNoPause {
    function create(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner,
        uint8 decimals,
        uint256 _cap
    ) public returns (RoleCappedCanMintNoBurnNoPause) {
        return
            new RoleCappedCanMintNoBurnNoPause(name, symbol, initialSupply, owner, decimals, _cap);
    }
}