// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {IInitERC721KFNC} from "../interfaces/IInitERC721KFNC.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract InitERC721KFNCFacet is Base {
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_2981 = 0x2a55205a;

    /// @notice Initializer due to this being an upgradeable contract
    /// @param name_ Name of the contract
    /// @param symbol_ An abbreviated name for NFTs in this contract
    function initERC721KFNC(string memory name_, string memory symbol_, string memory baseURI_,uint256 startingTokenId_) external {
        if(s.nftStorage.initialized) revert IInitERC721KFNC.PreviouslyInitialized();
        s.nftStorage.initialized = true;
        s.nftStorage.name = name_;
        s.nftStorage.symbol = symbol_;
        s.nftStorage.baseURI = baseURI_;
        s.nftStorage.nextTokenId = s.nftStorage.startingTokenId = startingTokenId_;
        s.nftStorage.transfersEnabled = false;
        s.royaltyStorage.denominator = 10000;
        s.royaltyStorage.receiver = address(this);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // adding ERC165 data
        ds.supportedInterfaces[_INTERFACE_ID_ERC165] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[_INTERFACE_ID_ERC721_RECEIVER] = true;
        ds.supportedInterfaces[_INTERFACE_ID_ERC721_METADATA] = true;
        ds.supportedInterfaces[_INTERFACE_ID_ERC721_2981] = true;
        ds.supportedInterfaces[_INTERFACE_ID_ERC721] = true;
    }
}