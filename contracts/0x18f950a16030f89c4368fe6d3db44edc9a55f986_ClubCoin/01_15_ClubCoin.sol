// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ClubCoin is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    mapping(address => bool) private _lock;
    string private _name;

    function initialize() public initializer {
        __ERC20_init("CLUB Coin", "CLUB");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 401647958 * 10**decimals());
    }

    function transferBulk(address[] memory _tos, uint256[] memory _values)
        public
    {
        require(
            _tos.length == _values.length,
            "Count Recipients/values don't match"
        );
        require(_tos.length < 100, "Too many recipients");

        address sender = msg.sender;
        for (uint256 i = 0; i < _tos.length; ++i) {
            _transfer(sender, _tos[i], _values[i]);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    function setName(string memory name_) public onlyOwner {
        _name = name_;
    }

    function lockAddress(address payable addr) public onlyOwner {
        _lock[addr] = true;
    }

    function unlockAddress(address payable addr) public onlyOwner {
        delete _lock[addr];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
        require(_lock[from] != true, "Transfer Locked");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}