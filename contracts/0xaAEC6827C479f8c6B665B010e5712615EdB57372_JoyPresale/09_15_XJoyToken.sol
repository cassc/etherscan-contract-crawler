// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/BlackListToken.sol";
import "../presale/JoyPresale.sol";

contract XJoyToken is BlackListToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////
    uint256 public manualMinted;
    address public privatePresaleAddress;
    address public seedPresaleAddress;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __BlackList_init();
        _mint(_msgSender(), initialSupply);
        addAuthorized(_msgSender());
        manualMinted = 0;
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////
    function name() public view virtual override returns (string memory) {
        return "xJOY Token";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "xJOY";
    }
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function manualMint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
        manualMinted = manualMinted.add(_amount);
    }

    // add purchaser
    function addPurchaser(address addr) public onlyAuthorized {
      addBlackList(addr);
    }

    function updatePresaleAddresses(address _privatePresaleAddress, address _seedPresaleAddress) public onlyAuthorized {
        privatePresaleAddress = _privatePresaleAddress;
        seedPresaleAddress = _seedPresaleAddress;
    }

    function isTransferable(address _from, address _to, uint256 _amount) public view virtual override returns (bool) {
        JoyPresale privatePresale = JoyPresale(privatePresaleAddress);
        JoyPresale seedPresale = JoyPresale(seedPresaleAddress);

        bool isLockedInPrivatePresale = privatePresale.checkLockingPeriod(_from);
        bool isLockedInSeedPresale = seedPresale.checkLockingPeriod(_from);

        require(isWhiteListed[_from] || isWhiteListed[_to] || (!isLockedInPrivatePresale && !isLockedInSeedPresale), "[email protected]: _from is in locked in presale SC");

        // if (isBlackListChecking) {
        //     // require(!isBlackListed[_from], "[email protected]: _from is in isBlackListed");
        //     // require(!isBlackListed[_to] || isWhiteListed[_to], "[email protected]: _to is in isBlackListed");
        //     require(!isBlackListed[_from] || isWhiteListed[_to], "[email protected]: _from is in isBlackListed");
        // }
        return true;
    }
}