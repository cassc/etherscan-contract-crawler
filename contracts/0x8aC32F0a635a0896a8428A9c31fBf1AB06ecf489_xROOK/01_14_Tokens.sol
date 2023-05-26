// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./CanReclaimTokens.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract StandardToken is ERC20, ERC20Burnable, CanReclaimTokens {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint8 _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _setupRole(MINTER_ROLE, _msgSender());

        _decimals = decimals_;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function addMinter(address _newMinter) onlyMinter external {
        grantRole(MINTER_ROLE, _newMinter);
        grantRole(DEFAULT_ADMIN_ROLE, _newMinter);
    }

    function renounceMinter() onlyMinter external {
        renounceRole(MINTER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address account, uint256 amount) onlyMinter public returns (bool) {
        _mint(account, amount);
        return true;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
}

contract RookToken is StandardToken {
    constructor() StandardToken("Rook Token", "ROOK", 18) {}
}


contract KToken is StandardToken {
    address private _underlying;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address underlying_) StandardToken(name_, symbol_, decimals_) {
        require(underlying_ != address(0x0), "underlying address cannot be 0x0");
        _underlying = underlying_;
    }

    /// @return The address of the underlying token.
    function underlying() public view returns (address) {
        return _underlying;
    }
}

contract kEther is KToken {
    constructor() KToken("kEther", "kETH", 18, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {}
}

contract kWrappedEther is KToken {
    constructor(address underlying_) KToken("kWrappedEther", "kwETH", 18, underlying_) {}
}

contract kUSDC is KToken {
    constructor(address underlying_) KToken("kUSDCoin", "kUSDC", 6, underlying_) {}
}

contract kWBTC is KToken {
    constructor(address underlying_) KToken("kWrappedBitcoin", "kWBTC", 8, underlying_) {}
}

contract kBTC is KToken {
    constructor(address underlying_) KToken("kBitcoin", "kBTC", 8, underlying_) {}
}

contract kDAI is KToken {
    constructor(address underlying_) KToken("kDAI", "kDAI", 18, underlying_) {}
}

contract xROOK is KToken {
    constructor(address underlying_) KToken("xROOK", "xROOK", 18, underlying_) {}
}