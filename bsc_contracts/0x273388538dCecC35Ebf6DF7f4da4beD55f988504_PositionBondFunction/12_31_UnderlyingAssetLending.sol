pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Issuer} from "../Issuer.sol";

import {BondMath} from "../../lib/BondMath.sol";
import {BondTransfer} from "../../lib/BondTransfer.sol";
import "../../interfaces/IPosiNFTFactory.sol";

abstract contract UnderlyingAssetLending {
    using SafeERC20 for IERC20;

    event LiquidationUnderlyingAssetClaimed(
        address user,
        uint256 bondAmount,
        uint256 collateralAmount
    );

    address private _underlyingAsset;

    uint256[] private _posiNFTsID;

    // collateral
    uint256 private _underlyingAmount;

    // not sub
    uint256 public initUnderlyingAmount;

    // 0 is Token, 1 is PosiNFT, 2 is Ether
    uint256 private underlyingAssetType;


    function initUnderlyingAssetLending(
        uint256 underlyingAssetType_,
        address underlyingAsset_,
        uint256 underlyingAmount_,
        uint256[] memory posiNFTsID_
    ) internal {
        underlyingAssetType = underlyingAssetType_;
        _underlyingAsset = underlyingAsset_;
        _posiNFTsID = posiNFTsID_;
    }

    function claimUnderlyingAsset() public virtual {
        _transferOut1(_underlyingAmount);
    }

    function underlyingAsset() public view virtual returns (address, uint256) {
        return (_underlyingAsset, _underlyingAmount);
    }

    function _underlyingAssetAmount() internal view virtual returns (uint256) {
        return _underlyingAmount;
    }

    function getUnderlyingAssetType() public view virtual returns (uint256) {
        return underlyingAssetType;
    }

    function getNfts() public view virtual returns (uint256[] memory) {
        return _posiNFTsID;
    }

    function _addCollateral(
        uint256[] memory amountTransferAdded,
        uint256 amountAdded
    ) internal virtual {
        if (underlyingAssetType == 0) {
            uint256 balanceBefore = IERC20(_underlyingAsset).balanceOf(
                address(this)
            );
            BondTransfer._transferInToken(
                _underlyingAsset,
                amountTransferAdded[0],
                msg.sender
            );
            amountAdded =
                IERC20(_underlyingAsset).balanceOf(address(this)) -
                balanceBefore;
        } else if (underlyingAssetType == 1) {
            require(
                amountTransferAdded.length + _posiNFTsID.length <= 30,
                "!NFT"
            );
            BondTransfer._transferInPosiNFTs(
                _underlyingAsset,
                amountTransferAdded,
                msg.sender
            );
            for (uint256 i = 0; i < amountTransferAdded.length; i++) {
                _posiNFTsID.push(amountTransferAdded[i]);
            }
        } else if (underlyingAssetType == 2) {
            require(msg.value >= amountAdded, "!ether");
        }
        _underlyingAmount += amountAdded;
        initUnderlyingAmount += amountAdded;
    }

    function _removeCollateral(
        uint256[] memory amountTransferRemoved,
        uint256 amountRemoved
    ) internal virtual {
        if (underlyingAssetType == 0) {
            _transferOut1(amountRemoved);
        } else if (underlyingAssetType == 1) {
            uint256[] memory nftIdsRemoved = new uint256[](
                amountTransferRemoved.length
            );
            for (uint256 i = 0; i < amountTransferRemoved.length; i++) {
                nftIdsRemoved[i] = _posiNFTsID[amountTransferRemoved[i]];
                _posiNFTsID[amountTransferRemoved[i]] = 0;
            }
            for (uint256 i = 0; i < nftIdsRemoved.length; i++) {
                IERC721(_underlyingAsset).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftIdsRemoved[i]
                );
            }
            uint256[] memory nftIdsPop = new uint256[](
                _posiNFTsID.length - amountTransferRemoved.length
            );

            uint256 index = 0;
            for (uint256 i = 0; i < _posiNFTsID.length; i++) {
                if (_posiNFTsID[i] != 0) {
                    nftIdsPop[index] = _posiNFTsID[i];
                    index++;
                }
            }

            _posiNFTsID = nftIdsPop;
        }
//        else if (underlyingAssetType == 2) {
//            _transferOut1(amountTransferRemoved[0]);
//        }
        _underlyingAmount -= amountRemoved;
        initUnderlyingAmount -= amountRemoved;
    }

    function _transferUnderlyingAsset() internal virtual {}

    function _issuer() internal view virtual returns (address) {}

    function _transferUnderlyingAssetLiquidated(
        uint256 bondBalance,
        uint256 bondSupply
    ) internal {
        uint256 calculatedUnderlyingAsset = BondMath.calculateUnderlyingAsset(
            bondBalance,
            bondSupply,
            _underlyingAmount
        );
        _underlyingAmount -= calculatedUnderlyingAsset;
        _transferOut1(calculatedUnderlyingAsset);
        emit LiquidationUnderlyingAssetClaimed(
            msg.sender,
            bondBalance,
            calculatedUnderlyingAsset
        );
    }

    function _transferOut1(uint256 amount) internal {
        if (underlyingAssetType == 0) {
            BondTransfer._transferOutToken(
                _underlyingAsset,
                amount,
                msg.sender
            );
        } else if (underlyingAssetType == 1) {
            BondTransfer._transferOutPosiNFT(
                _underlyingAsset,
                _posiNFTsID,
                msg.sender
            );
        }
//        else if (underlyingAssetType == 2) {
//            BondTransfer._transferOutEther(msg.sender, amount);
//        }
    }

    function decompose(address positionFactory, address tokenPar) internal {
        IERC721(_underlyingAsset).setApprovalForAll(
            address(positionFactory),
            true
        );
        for (uint256 i = 0; i < _posiNFTsID.length; i++) {
            bool done = IPosiNFTFactory(positionFactory).burn(_posiNFTsID[i]);
        }
        underlyingAssetType = 0;
        _underlyingAsset = tokenPar;
    }

    function updateUnderlyingAmount(uint256 underlyingAmount_) internal {
        _underlyingAmount = underlyingAmount_;
        initUnderlyingAmount = underlyingAmount_;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}