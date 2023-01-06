// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMillixBridge {
    /**
     * @dev Emitted when `amount` tokens are moved from account (`from`) to millix network address (`to`)
     */
    event UnwrapMillix(address indexed from, string to, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are minted from millix transaction (`txhash`)
     */
    event MintWrappedMillix(string txhash);

    function unwrap(uint256 amount, string calldata to) external payable;
}

/// @custom:security-contact [email protected]
contract WrappedMillix is ERC20, Pausable, Ownable, IMillixBridge {
    uint256 public constant MAX_SUPPLY = 9 * 10**15;
    uint32 private _burnFees = 662780;
    mapping(address => bool) private _vesting;

    constructor() ERC20("WrappedMillix", "WMLX") {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address to,
        uint256 amount,
        string memory txhash
    ) public onlyOwner {
        require(
            totalSupply() + amount < MAX_SUPPLY,
            "total supply cannot be greater than 9e15"
        );
        _mint(to, amount);
        emit MintWrappedMillix(txhash);
    }

    /**
     * @dev Set current burn fees.
     */
    function setBurnFees(uint32 fees) public onlyOwner {
        require(fees >= 0, "burn fees cannot be negative");
        _burnFees = fees;
    }

    /**
     * @dev Returns current burn fees.
     */
    function burnFees() public view virtual returns (uint32) {
        return _burnFees;
    }

    /**
     * @dev Returns true if an address is vested
     */
    function isVested(address addr) public view returns (bool) {
        return _vesting[addr];
    }

    /**
     * @dev Add address to vesting list
     */
    function setVestingState(address addr, bool vested) public onlyOwner {
        _vesting[addr] = vested;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(
            !_vesting[from],
            "address from is in the list of vesting addresses"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    function unwrap(uint256 amount, string calldata to) public payable {
        require(
            msg.value >= _burnFees,
            "transaction value does not cover the MLX unwrap fees"
        );
        _burn(_msgSender(), amount);
        payable(owner()).transfer(msg.value);
        emit UnwrapMillix(_msgSender(), to, amount);
    }
}