// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./interfaces/IAdmin.sol";
import "./interfaces/IGenesis.sol";

/**
 *  @title  Dev Validatable
 *
 *  @author IHeart Team
 *
 *  @dev This contract is using as abstract smartcontract
 *  @notice This smart contract provide the validatable methods and modifier for the inheriting contract.
 */
contract Validatable is Initializable, ContextUpgradeable {
    /**
     *  @notice Address of Admin contract
     */
    IAdmin public admin;

    event SetPause(bool indexed isPause);

    /*------------------Initializer------------------*/

    function __Validatable_init(IAdmin _admin) internal onlyInitializing {
        __Context_init();

        admin = _admin;
    }

    /*------------------Check Admins------------------*/

    modifier onlyOwner() {
        require(admin.owner() == _msgSender(), "Caller is not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admin.isAdmin(_msgSender()), "Caller is not owner or admin");
        _;
    }

    /*------------------Common Checking------------------*/

    modifier notZeroAddress(address _account) {
        require(_account != address(0), "Invalid address");
        _;
    }

    modifier notZero(uint256 _amount) {
        require(_amount > 0, "Invalid amount");
        _;
    }

    modifier validGenesis(address _address) {
        require(
            ERC165CheckerUpgradeable.supportsInterface(_address, type(IGenesis).interfaceId),
            "Invalid Genesis contract"
        );
        _;
    }
}