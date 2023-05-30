// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICryptoFoxesOriginsV2.sol";
import "./interfaces/ICryptoFoxesStakingV2.sol";
import "./CryptoFoxesUtility.sol";

// @author: miinded.com
contract CryptoFoxesSlots is Ownable, CryptoFoxesUtility {
    ICryptoFoxesStakingV2 public cryptoFoxesStakingV2;
    ICryptoFoxesOriginsV2 public cryptoFoxesOrigin;
    uint256 constant basePrice = 10 ** 18;
    uint256[21] private slotPrice;

    constructor(address _cryptoFoxesOrigin, address _cryptoFoxesStakingV2) {
        cryptoFoxesOrigin = ICryptoFoxesOriginsV2(_cryptoFoxesOrigin);
        cryptoFoxesStakingV2 = ICryptoFoxesStakingV2(_cryptoFoxesStakingV2);

        slotPrice[10] = 600 * basePrice;
        slotPrice[11] = 760 * basePrice;
        slotPrice[12] = 970 * basePrice;
        slotPrice[13] = 1230 * basePrice;
        slotPrice[14] = 1560 * basePrice;
        slotPrice[15] = 1980 * basePrice;
        slotPrice[16] = 2520 * basePrice;
        slotPrice[17] = 3190 * basePrice;
        slotPrice[18] = 4060 * basePrice;
        slotPrice[19] = 5160 * basePrice;
        slotPrice[20] = 6550 * basePrice;
    }

    function unlockSlot(uint16 _tokenIdOrigin, uint8 _count) public {
        require(!disablePublicFunctions, "Function disabled");
        _unlockSlot(_msgSender(), _tokenIdOrigin, _count);
    }
    function unlockSlotByContract(address _wallet, uint16 _tokenIdOrigin, uint8 _count) public isFoxContract {
        _unlockSlot(_wallet, _tokenIdOrigin, _count);
    }

    function _unlockSlot(address _wallet, uint16 _tokenIdOrigin, uint8 _count) private {

        require(cryptoFoxesOrigin.ownerOf(_tokenIdOrigin) == _wallet, "CryptoFoxesSlots:unlockSlot Bad Owner");

        uint8 currentMaxSlot = cryptoFoxesStakingV2.getOriginMaxSlot(_tokenIdOrigin);
        if(currentMaxSlot == 0){
            currentMaxSlot = 9;
        }
        uint256 price = getTotalPrice(currentMaxSlot, _count);
        require(IERC20(address(cryptofoxesSteak)).balanceOf(_wallet) >= price, "CryptoFoxesSlots:unlockSlot balance to low");
        IERC20(address(cryptofoxesSteak)).transferFrom(_wallet, owner(), price);
        cryptoFoxesStakingV2.unlockSlot(_tokenIdOrigin, _count);
    }

    function getStepPrice(uint256 _step) public view returns(uint256){
        require(_step > 0 && _step <= 20, "CryptoFoxesSlots:unlockSlot Out of limit");

        return slotPrice[_step];
    }

    function getTotalPrice(uint8 _currentMaxSlot, uint256 _count) public view returns(uint256){
        uint256 price = 0;
        for(uint256 i = 0; i < _count; i++){
            price += slotPrice[_currentMaxSlot + i + 1];
        }
        return price;
    }
}