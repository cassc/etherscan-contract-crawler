// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../interfaces/IinternetBond_R1.sol";
import "../interfaces/ICertToken.sol";
import "../interfaces/IOwnable.sol";

contract aMATICc_R1 is OwnableUpgradeable, ERC165Upgradeable, ERC20Upgradeable, ICertToken {
    /**
     * Variables
     */

    address public pool;
    address public bondToken; // also known as aMATICb

    /**
     * Modifiers
     */

    modifier onlyMinter() {
        require(
           msg.sender == pool ||
           msg.sender == bondToken,
           "onlyMinter: not allowed"
        );
        _;
    }

    function initialize(address polygonPool, address _bondToken) public initializer {
        __Ownable_init();
        __ERC20_init_unchained("Ankr MATIC Reward Bearing Certificate", "aMATICc");
        pool = polygonPool;
        bondToken = _bondToken;
        uint256 initSupply = IinternetBond_R1(bondToken).totalSharesSupply();
        // mint init supply if not inizialized
        super._mint(address(bondToken), initSupply);
    }

    function bondTransferTo(address account, uint256 amount) external override onlyMinter {
        super._transfer(address(bondToken), account, amount);
    }

    function bondTransferFrom(address account, uint256 amount) external override onlyMinter {
        super._transfer(account, address(bondToken), amount);
    }

    function ratio() public view override returns (uint256) {
        return IinternetBond_R1(bondToken).ratio();
    }

    function burn(address account, uint256 amount) external override onlyMinter {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external override onlyMinter {
        _mint(account, amount);
    }

    function changePoolContract(address newPool) external override onlyOwner {
        address oldPool = pool;
        pool = newPool;
        emit PoolContractChanged(oldPool, newPool);
    }

    function changeBondToken(address newBondToken) external override onlyOwner {
        address oldBondToken = bondToken;
        bondToken = newBondToken;
        emit BondTokenChanged(oldBondToken, newBondToken);
    }

    function balanceWithRewardsOf(address account) public view override returns (uint256) {
        uint256 shares = this.balanceOf(account);
        return IinternetBond_R1(bondToken).sharesToBalance(shares);
    }

    function isRebasing() public pure override returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(ICertToken).interfaceId;
    }

    function name() public pure override returns (string memory) {
        return "Ankr Reward Bearing MATIC";
    }
}