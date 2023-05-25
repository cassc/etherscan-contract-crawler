// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract UCToken is
    Context,
    AccessControlEnumerable,
    ERC20,
    ERC20Burnable,
    ERC20Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => uint256) private _locks;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Restricted to admins.");
        _;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("UnitedCrowd Token", "UCT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // add sender also as a minter
        _setupRole(MINTER_ROLE, _msgSender());

        // add sender also as a pauser
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "UCToken: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "UCToken: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "UCToken: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {

        require(
            _locks[from] < block.timestamp,
            "Tokens for this account are still locked"
        );

        super._beforeTokenTransfer(from, to, amount);
    }

    function addLock(
        address beneficiary,
        uint256 releaseTime
    ) public virtual onlyAdmin {
        require(
            _locks[beneficiary] == 0,
            "A Lock was already created for this beneficiary"
        );

        require(
            releaseTime > block.timestamp,
            "Can't create a lock for the past"
        );

        _locks[beneficiary] = releaseTime;
    }

    function getLock(address beneficiary) public view returns (uint256) {
      return _locks[beneficiary];
    }

    function isLocked(address beneficiary) public view returns (bool) {
      return _locks[beneficiary] > block.timestamp;
    }

    function removeLock(
        address beneficiary
    ) public virtual onlyAdmin {
        require(
            _locks[beneficiary] == 0,
            "A Lock was not created yet for this beneficiary"
        );

        _locks[beneficiary] = 0;
    }

}