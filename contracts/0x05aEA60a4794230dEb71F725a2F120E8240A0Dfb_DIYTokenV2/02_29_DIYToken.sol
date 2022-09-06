// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./libraries/ERC20TaxTokenU.sol";
import "./DIYFactory.sol";

contract DIYToken is ERC20TaxTokenU, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    mapping(uint8 => uint256) public authMinted;
    address factoryAddress;
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        TaxFee[] memory _taxFees
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __TaxToken_init(_taxFees);
        __Pausable_init();

        _mint(_msgSender(), initialSupply);
        addAuthorized(_msgSender());

        startTaxToken(true);
        setTaxExclusion(address(this), true);
        setTaxExclusion(_msgSender(), true);
        factoryAddress = address(0x0);
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function updateFactoryAddress(address _factoryAddress) public onlyAuthorized {
        factoryAddress = _factoryAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function authMint(uint8 _type, address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        authMinted[_type] = authMinted[_type].add(_amount);
    }

    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        uint256 _transAmount = _amount;
        if (isTaxTransable(_from)) {
            uint256 taxAmount = super.calcTransFee(_amount);
            transFee(_from, taxAmount);
            _transAmount = _amount.sub(taxAmount);
        }
        super._transfer(_from, _to, _transAmount);
    }
}