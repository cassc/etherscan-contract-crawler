// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./CZUsd.sol";
import "./SilverDollarTypePriceSheet.sol";
import "./JsonNftTemplate.sol";

import "hardhat/console.sol";

contract CzUstsdReserves is Ownable {
    using SafeERC20 for IERC20;

    enum CURRENCY {CZUSD, BUSD}

    uint16 public buyFeeCzBP = 0;
    uint32 public buyFeeCzCents = 99;
    uint16 public buyFeeRcBP = 0;
    
    uint16 public sellFeeCzBP = 1025;
    uint32 public sellFeeCzCents = 0;
    uint16 public sellFeeRcBP = 125;

    address public rcWallet = 0xfC74a37FFF6EA97fF555e5ff996193e12a464431;
    address public czWalletBusdReceiver = 0x365FEe072022eCa1f569D41fA7Fca8adaedEd6d9;

    IERC20 public constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    CZUsd public constant CZUSD = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);

    JsonNftTemplate public constant USTSD = JsonNftTemplate(0xA2eCD85433C8F8Ffd6Cc3573A913AC0F0092b9f2);
    SilverDollarTypePriceSheet public constant USTSD_PRICE_ORACLE = SilverDollarTypePriceSheet(0x8b153af72F610F1e541C7B4E24cd856BD84C5068);

    constructor() Ownable() {}

    function buy(uint[] calldata _ids, CURRENCY _currency) external {
        uint256 priceWad = _centsToWad(USTSD_PRICE_ORACLE.getCoinNftSum(USTSD, _ids));
        uint256 czFeesWad = _ids.length*_centsToWad(buyFeeCzCents) + (priceWad*uint256(buyFeeCzBP)/10000);
        uint256 rcFeesWad = (priceWad*buyFeeRcBP/10000);
        if(CURRENCY.CZUSD == _currency) {
            CZUSD.burnFrom(msg.sender,priceWad+czFeesWad);
            rcFeesWad != 0 && CZUSD.transferFrom(msg.sender,rcWallet,rcFeesWad);
        } else {
            BUSD.transferFrom(msg.sender,czWalletBusdReceiver,priceWad+czFeesWad);
            rcFeesWad != 0 && BUSD.transferFrom(msg.sender,rcWallet,rcFeesWad);
        }
        for(uint i = 0; i<_ids.length; i++) {
            USTSD.transferFrom(address(this), msg.sender, _ids[i]);
        }
    }

    function sell(uint[] calldata _ids) external {
        uint256 priceWad = _centsToWad(USTSD_PRICE_ORACLE.getCoinNftSum(USTSD, _ids));
        uint256 czFeesWad = _ids.length*_centsToWad(sellFeeCzCents) + (priceWad*sellFeeCzBP/10000);
        uint256 rcFeesWad = (priceWad*sellFeeRcBP/10000);

        CZUSD.transfer(msg.sender,priceWad-czFeesWad-rcFeesWad);
        rcFeesWad != 0 && CZUSD.transfer(rcWallet,rcFeesWad);

        for(uint i = 0; i<_ids.length; i++) {
            USTSD.transferFrom(msg.sender, address(this), _ids[i]);
        }
    }


    function _centsToWad(uint32 _cents) internal pure returns (uint256 wad_) {
        return uint256(_cents) * 1 ether / 100;
    }

    function recoverERC20(address _tokenAddress) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function recoverERC721(address _tokenAddress, uint[] calldata _ids) external onlyOwner {
        for(uint i = 0; i<_ids.length; i++) {
            IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _ids[i]);
        }
    }

    function setFees(uint16 _buyFeeCzBP, uint32 _buyFeeCzCents, uint16 _buyFeeRcBP, uint16 _sellFeeCzBP, uint32 _sellFeeCzCents, uint16 _sellFeeRcBP) external onlyOwner {
        buyFeeCzBP = _buyFeeCzBP;
        buyFeeCzCents = _buyFeeCzCents;
        buyFeeRcBP = _buyFeeRcBP;
        sellFeeCzBP = _sellFeeCzBP;
        sellFeeCzCents = _sellFeeCzCents;
        sellFeeRcBP = _sellFeeRcBP;
    }

    function setAddresses(address _rcWallet, address _czWallet) external onlyOwner {
        rcWallet = _rcWallet;
        czWalletBusdReceiver = _czWallet;
    }


}