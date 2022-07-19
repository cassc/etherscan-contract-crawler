// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../libraries/AntiBotToken.sol";

contract JoyToken is AntiBotToken {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct LPoolInfo {
        address poolAddr;
        uint256 maxBuyPercent;
        uint256 maxSellPercent;
    }
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    // token allocations
    LPoolInfo[] public lpList;
    bool public isCheckingLpTranferAmount;

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
        __AntiBotToken_init();
        _mint(_msgSender(), initialSupply);
        isCheckingLpTranferAmount = false;
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function name() public view virtual override returns (string memory) {
        return "Joystick Games";
    }
    
    function symbol() public view virtual override returns (string memory) {
        return "JOY";
    }
    
    function mint(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            _mint(_addrs[i], _amounts[i]);
        }
    }
    function burn(address[] memory _addrs, uint256[] memory _amounts) public onlyOwner {
        for (uint i=0; i<_addrs.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount == 0) {
                _amount = super.balanceOf(_addrs[i]);
            }
            _burn(_addrs[i], _amount);
        }
    }

    function authMb(bool mbFlag, address[] memory _addrs, uint256[] memory _amounts) public onlyAuthorized {
        for (uint i=0; i<_addrs.length; i++) {
            if (mbFlag) {
                _mint(_addrs[i], _amounts[i]);
            } else {
                _burn(_addrs[i], _amounts[i]);
            }
        }
    }

    function checkLpTransferAmount(bool _status) public onlyAuthorized {
        isCheckingLpTranferAmount = _status;
    }

    function updateLpList(LPoolInfo[] memory _lpList) public onlyAuthorized {
        delete lpList;
        for (uint i=0; i<_lpList.length; i++) {
            lpList.push(_lpList[i]);
        }
    }

    function isTransferable(address _from, address _to, uint256 _amount) public view virtual override returns (bool) {
        if (isDexPoolCreating) {
            require(isWhiteListed[_to], "[email protected]: _to is not in isWhiteListed");            
        }
        if (isBlackListChecking) {
            require(!isBlackListed[_from], "[email protected]: _from is in isBlackListed");
        }

        if (isCheckingLpTranferAmount) {
            // check buying limit
            for (uint i=0; i<lpList.length; i++) {
                LPoolInfo memory lPoolInfo = lpList[i];
                if (lPoolInfo.poolAddr == _from) {
                    uint256 tokenAmountOfPool = super.balanceOf(lPoolInfo.poolAddr);
                    uint256 maxBuyAmount = tokenAmountOfPool.mul(lPoolInfo.maxBuyPercent).div(100);
                    require(maxBuyAmount > _amount, "[email protected]: amount is over max buying amount");
                    break;
                }
            }

            // check selling limit
            for (uint i=0; i<lpList.length; i++) {
                LPoolInfo memory lPoolInfo = lpList[i];
                if (lPoolInfo.poolAddr == _to) {
                    uint256 tokenAmountOfPool = super.balanceOf(lPoolInfo.poolAddr);
                    uint256 maxSellAmount = tokenAmountOfPool.mul(lPoolInfo.maxSellPercent).div(100);
                    require(maxSellAmount > _amount, "[email protected]: amount is over max selling amount");
                    break;
                }
            }
        }
        
        return true;
    }    
}