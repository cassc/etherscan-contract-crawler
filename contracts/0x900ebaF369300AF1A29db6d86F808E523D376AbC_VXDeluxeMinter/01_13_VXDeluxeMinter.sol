//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../interfaces/BearsDeluxeI.sol";
import "../../interfaces/HoneyTokenI.sol";
import "../../interfaces/VXDeluxeI.sol";
import "../../interfaces/ClaimVXDeluxeI.sol";
import "hardhat/console.sol";

contract VXDeluxeMinter is ReentrancyGuard, Ownable {

    HoneyTokenI public honey;
    VXDeluxeI public vxDeluxe;

    uint256 public price = 0.069 ether;
    uint256 public honeyPrice = 100 ether;

    event MintedBears(address indexed _owner, uint16[] _ids, uint16[] _bearsIds);
    event ChangedPrice(uint256 _price);
    event SetContract(address _contract, string _type);

    error AlreadyMinted();
    error MaxSupplyReached();
    error WrongAmount();

    function claimBearsDeluxe(uint16[] calldata _tokenIds, bool _payHoney) external payable nonReentrant {
        uint256 i;
        uint256 totalPriceToPay;
        for (i; i < _tokenIds.length; ) {
            unchecked {
                uint16 currentToken = _tokenIds[i];
                if (vxDeluxe.exists(currentToken)) revert AlreadyMinted();
                if (_payHoney == false) {
                    totalPriceToPay += price;
                } else {
                    totalPriceToPay += honeyPrice;
                }
                i++;
            }
        }
        if (_payHoney == false) {
            if (msg.value != totalPriceToPay) revert WrongAmount();
        } else {
            if (honey.balanceOf(msg.sender) < totalPriceToPay) revert WrongAmount();
            honey.burn(msg.sender, totalPriceToPay);
        }
        vxDeluxe.mintBatch(msg.sender, _tokenIds);
        emit MintedBears(msg.sender, _tokenIds, _tokenIds);
    }

    function setHoney(HoneyTokenI _honey) external onlyOwner {
        honey = _honey;
        emit SetContract(address(_honey), "HoneyToken");
    }

    function setVXBears(VXDeluxeI _vxDeluxe) external onlyOwner {
        vxDeluxe = _vxDeluxe;
        emit SetContract(address(_vxDeluxe), "VXDeluxe");
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit ChangedPrice(_newPrice);
    }

    function setHoneyPrice(uint256 _newPrice) external onlyOwner {
        honeyPrice = _newPrice;
        emit ChangedPrice(_newPrice);
    }

}