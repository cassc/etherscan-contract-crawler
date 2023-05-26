// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IBreederToken.sol";

contract BreederToken is
    Context,
    AccessControlEnumerable,
    ERC20Votes,
    IBreederToken
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    modifier onlyHasRole(bytes32 _role) {
        require(
            hasRole(_role, _msgSender()),
            "BreederToken.onlyHasRole: msg.sender does not have role"
        );
        _;
    }

    constructor() ERC20Permit("BreederDAO") ERC20("BreederDAO", "BREED") {
        _mint(_msgSender(), 1_000_000_000 * 1e18);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address _to, uint256 _amount)
        external
        override
        onlyHasRole(MINTER_ROLE)
    {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount)
        external
        override
        onlyHasRole(BURNER_ROLE)
    {
        _burn(_from, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        require(
            _to != address(this),
            "BreederToken._transfer: transfer to self not allowed"
        );
        super._transfer(_from, _to, _amount);
    }
}