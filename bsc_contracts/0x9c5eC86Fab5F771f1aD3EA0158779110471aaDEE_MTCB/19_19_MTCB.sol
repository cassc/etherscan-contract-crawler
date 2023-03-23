//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract MTCB is
    ERC20Upgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable
{
    mapping(address => bool) private _isBlackList;

    function initialize(address owner) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        __ERC20_init("MTCB", "MTCB");
        __UUPSUpgradeable_init();
        __ERC20Burnable_init();
        _mint(owner, 500000000 * 10 ** 18);
    }

    function addBlackList(
        address _evilUser
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlackList[_evilUser] = true;
    }

    function removeBlackList(
        address _clearedUser
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlackList[_clearedUser] = false;
    }

    function isBlackListed(address user) public view returns (bool) {
        return _isBlackList[user];
    }

    function transfer(address to, uint amount) public override returns (bool) {
        require(isBlackListed(_msgSender()) == false);
        require(isBlackListed(to) == false);
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(isBlackListed(_msgSender()) == false);
        require(isBlackListed(to) == false);
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}