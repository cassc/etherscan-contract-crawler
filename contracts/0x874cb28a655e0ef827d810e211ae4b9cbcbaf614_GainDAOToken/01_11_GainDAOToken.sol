// SPDX-License-Identifier: MIT
pragma solidity =0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract GainDAOToken is Pausable, AccessControlEnumerable, ERC20Capped {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor()
        ERC20("GainDAO Token", "GAIN")
        ERC20Capped(42_000_000 * (10**18))
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());

        // when the token is deployed, it starts as paused
        _pause();
    }

    // We explicitely do not support pausing the token.
    // function pause() public {
    //     require(hasRole(PAUSER_ROLE, _msgSender()));
    //     _pause();
    // }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "GainDAOToken: _msgSender() does not have the pauser role"
        );
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "GainDAOToken: _msgSender() does not have the minter role"
        );

        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "GainDAOToken: _msgSender() does not have the burner role"
        );

        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // mint: always allowed
        // other transfers: require not paused
        if (from != address(0)) {
          require(!paused(), "GainDAOToken: paused");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}