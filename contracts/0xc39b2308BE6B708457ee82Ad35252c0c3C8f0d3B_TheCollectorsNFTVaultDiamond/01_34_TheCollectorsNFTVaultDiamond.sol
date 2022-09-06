// SPDX-License-Identifier: UNLICENSED
// © 2022 The Collectors. All rights reserved.
pragma solidity ^0.8.13;

import "./facets/TheCollectorsNFTVaultBaseFacet.sol";
import "./facets/TheCollectorsNFTVaultLogicFacet.sol";
import "./facets/TheCollectorsNFTVaultAssetsManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultSeaportManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultTokenManagerFacet.sol";
import "./facets/TheCollectorsNFTVaultDiamondCutAndLoupeFacet.sol";
import "./LibDiamond.sol";

/*
    ████████╗██╗  ██╗███████╗
    ╚══██╔══╝██║  ██║██╔════╝
       ██║   ███████║█████╗
       ██║   ██╔══██║██╔══╝
       ██║   ██║  ██║███████╗
       ╚═╝   ╚═╝  ╚═╝╚══════╝
     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗ ██████╗ ██████╗ ███████╗
    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║   ██║██████╔╝███████╗
    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗╚════██║
    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║███████║
     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
    ███╗   ██╗███████╗████████╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
    ████╗  ██║██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
    ██╔██╗ ██║█████╗     ██║       ██║   ██║███████║██║   ██║██║     ██║
    ██║╚██╗██║██╔══╝     ██║       ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║
    ██║ ╚████║██║        ██║        ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║
    ╚═╝  ╚═══╝╚═╝        ╚═╝         ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝
    @title
    The collectors NFT Vault is the first fully decentralized product that allows a group of people to handle
    together the lifecycle of an NFT and all while using any marketplace (including Opensea).
    The big different between this protocol and others is it was built for NFT people by NFT people.
    @dev
    This contract is using the very robust and innovative EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535) which
    allows a contract to be organized in the most efficient way
*/
contract TheCollectorsNFTVaultDiamond is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    constructor(
        string memory __baseTokenURI,
        address _logicFacetAddress,
        address _assetsManagerFacetAddress,
        address _seaportManagerFacetAddress,
        address _vaultTokenManagerFacetAddress,
        address _diamondCutAndLoupeFacetAddress,
        address __nftVaultAssetHolderImpl,
        address[3] memory addresses
    ) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        // Moving tracker to 1 so we can use 0 to indicate that user doesn't have any tokens
        _as.tokenIdTracker.increment();
        // The base uri of the tokens
        _as.baseTokenURI = __baseTokenURI;
        // The implementation for asset holder. Is used to significantly reduce the creation cost of a new vault
        // Everytime a new marketplace will be added, the implementation will change
        _as.nftVaultAssetHolderImpl = __nftVaultAssetHolderImpl;
        _as.liquidityWallet = addresses[0];
        _as.stakingWallet = addresses[1];
        _as.royaltiesRecipient = addresses[2];
        _as.royaltiesBasisPoints = 250;
        _as.nftVaultTokenHandler = _vaultTokenManagerFacetAddress;
        _as.seaportAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
        _as.openseaFeeRecipients = [
            0x5b3256965e7C3cF26E11FCAf296DfC8807C01073,
            0x8De9C5A032463C561423387a9648c5C7BCC5BC90
        ];

        // Adding all logic functions
        LibDiamond.addFunctions(_logicFacetAddress, _getLogicFacetSelectors());
        // Adding all assets manager functions
        LibDiamond.addFunctions(_assetsManagerFacetAddress, _getAssetsManagerFacetSelectors());
        // Adding all Seaport manager functions
        // In the future more marketplaces will be added
        LibDiamond.addFunctions(_seaportManagerFacetAddress, _getSeaportManagerFacetSelectors());
        // Adding all NFT vault token functions
        LibDiamond.addFunctions(_vaultTokenManagerFacetAddress, _getNFTVaultTokenManagerFacetSelectors());
        // Adding all diamond cut and loupe functions
        LibDiamond.addFunctions(_diamondCutAndLoupeFacetAddress, _getDiamondCutAndLoupeFacetSelectors());
    }

    // =========== Diamond ===========

    /*
        @dev
        Adding all functions of logic facet
    */
    function _getLogicFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](21);
        selectors[0] = TheCollectorsNFTVaultLogicFacet.setLiquidityWallet.selector;
        selectors[1] = TheCollectorsNFTVaultLogicFacet.setStakingWallet.selector;
        selectors[2] = TheCollectorsNFTVaultLogicFacet.createVault.selector;
        selectors[3] = TheCollectorsNFTVaultLogicFacet.joinPublicVault.selector;
        selectors[4] = TheCollectorsNFTVaultLogicFacet.addParticipant.selector;
        selectors[5] = TheCollectorsNFTVaultLogicFacet.setTokenInfoAndMaxBuyPrice.selector;
        selectors[6] = TheCollectorsNFTVaultLogicFacet.setListingPrice.selector;
        selectors[7] = TheCollectorsNFTVaultLogicFacet.vote.selector;
        selectors[8] = TheCollectorsNFTVaultLogicFacet.fundVault.selector;
        selectors[9] = TheCollectorsNFTVaultLogicFacet.withdrawFunds.selector;
        selectors[10] = TheCollectorsNFTVaultLogicFacet.assetsHolders.selector;
        selectors[11] = TheCollectorsNFTVaultLogicFacet.vaults.selector;
        selectors[12] = TheCollectorsNFTVaultLogicFacet.vaultTokens.selector;
        selectors[13] = TheCollectorsNFTVaultLogicFacet.vaultsExtensions.selector;
        selectors[14] = TheCollectorsNFTVaultLogicFacet.liquidityWallet.selector;
        selectors[15] = TheCollectorsNFTVaultLogicFacet.stakingWallet.selector;
        selectors[16] = TheCollectorsNFTVaultLogicFacet.getVaultParticipants.selector;
        selectors[17] = TheCollectorsNFTVaultLogicFacet.getParticipantPercentage.selector;
        selectors[18] = TheCollectorsNFTVaultLogicFacet.getTokenPercentage.selector;
        selectors[19] = TheCollectorsNFTVaultLogicFacet.salvageERC721Token.selector;
        selectors[20] = TheCollectorsNFTVaultLogicFacet.salvageETH.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of assets manager facet
    */
    function _getAssetsManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = TheCollectorsNFTVaultAssetsManagerFacet.migrate.selector;
        selectors[1] = TheCollectorsNFTVaultAssetsManagerFacet.buyNFTFromVault.selector;
        selectors[2] = TheCollectorsNFTVaultAssetsManagerFacet.sellNFTToVault.selector;
        selectors[3] = TheCollectorsNFTVaultAssetsManagerFacet.unstakeCollector.selector;
        selectors[4] = TheCollectorsNFTVaultAssetsManagerFacet.stakeCollector.selector;
        selectors[5] = TheCollectorsNFTVaultAssetsManagerFacet.withdrawNFTToOwner.selector;
        selectors[6] = TheCollectorsNFTVaultAssetsManagerFacet.validateSale.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getSeaportManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = TheCollectorsNFTVaultSeaportManagerFacet.buyNFTOnSeaport.selector;
        selectors[1] = TheCollectorsNFTVaultSeaportManagerFacet.buyAdvancedNFTOnSeaport.selector;
        selectors[2] = TheCollectorsNFTVaultSeaportManagerFacet.buyMatchedNFTOnSeaport.selector;
        selectors[3] = TheCollectorsNFTVaultSeaportManagerFacet.listNFTOnSeaport.selector;
        selectors[4] = TheCollectorsNFTVaultSeaportManagerFacet.cancelNFTListingOnSeaport.selector;
        selectors[5] = TheCollectorsNFTVaultSeaportManagerFacet.setOpenseaFeeRecipients.selector;
        selectors[6] = TheCollectorsNFTVaultSeaportManagerFacet.setSeaportAddress.selector;
        selectors[7] = TheCollectorsNFTVaultBaseFacet.isVaultPassedSellOrCancelSellOrderConsensus.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getNFTVaultTokenManagerFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](22);
        selectors[0] = TheCollectorsNFTVaultTokenManagerFacet.claimVaultTokenAndGetLeftovers.selector;
        selectors[1] = TheCollectorsNFTVaultTokenManagerFacet.redeemToken.selector;
        selectors[2] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesRecipient.selector;
        selectors[3] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesRecipient.selector;
        selectors[4] = TheCollectorsNFTVaultTokenManagerFacet.setRoyaltiesBasisPoints.selector;
        selectors[5] = TheCollectorsNFTVaultTokenManagerFacet.royaltiesBasisPoints.selector;
        selectors[6] = TheCollectorsNFTVaultTokenManagerFacet.royaltyInfo.selector;
        selectors[7] = TheCollectorsNFTVaultTokenManagerFacet.getCollectionOwnership.selector;
        selectors[8] = TheCollectorsNFTVaultTokenManagerFacet.setBaseTokenURI.selector;
        selectors[9] = IERC721.balanceOf.selector;
        selectors[10] = IERC721.ownerOf.selector;
        selectors[11] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
        selectors[12] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        selectors[13] = IERC721.transferFrom.selector;
        selectors[14] = IERC721.approve.selector;
        selectors[15] = IERC721.setApprovalForAll.selector;
        selectors[16] = IERC721.getApproved.selector;
        selectors[17] = IERC721.isApprovedForAll.selector;
        selectors[18] = TheCollectorsNFTVaultTokenManagerFacet.supportsInterface.selector;
        selectors[19] = TheCollectorsNFTVaultTokenManagerFacet.tokenURI.selector;
        selectors[20] = TheCollectorsNFTVaultTokenManagerFacet.getCollectionVaults.selector;
        selectors[21] = TheCollectorsNFTVaultBaseFacet.isVaultSoldNFT.selector;
        return selectors;
    }

    /*
        @dev
        Adding all functions of opensea manager facet
    */
    function _getDiamondCutAndLoupeFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = TheCollectorsNFTVaultDiamondCutAndLoupeFacet.facetAddress.selector;
        return selectors;
    }

    // =========== Lifecycle ===========

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // To learn more about this implementation read EIP 2535
    fallback() external payable {
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}