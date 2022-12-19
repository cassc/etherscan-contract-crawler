//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/* Diamond */
import {LibDiamond} from "../external/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";
import {DiamondLoupeFacet} from "../external/diamond/facets/DiamondLoupeFacet.sol";
import {IDiamondCut} from "../external/diamond/interfaces/IDiamondCut.sol";

/* ERC165 */
import {IERC165} from "../external/diamond/interfaces/IERC165.sol";
import {IGroup} from "../interfaces/IGroup.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {IEIP712} from "../interfaces/IEIP712.sol";
import {IEIP712Transaction} from "../interfaces/IEIP712Transaction.sol";
import {IEIP712Proposition} from "../interfaces/IEIP712Proposition.sol";
import {IGovernance} from "../interfaces/IGovernance.sol";
import {ISignature} from "../interfaces/ISignature.sol";
import {IERC1271} from "../interfaces/IERC1271.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";
import {IERC721TokenReceiver} from "../interfaces/IERC721TokenReceiver.sol";
import {IOwnership} from "../interfaces/IOwnership.sol";
import {IAnticFee} from "../interfaces/IAnticFee.sol";
import {IDeploymentRefund} from "../interfaces/IDeploymentRefund.sol";
import {IReceive} from "../interfaces/IReceive.sol";
import {IGroupState} from "../interfaces/IGroupState.sol";
import {IWalletHash} from "../interfaces/IWalletHash.sol";
import {IAnticFeeCollectorProvider} from "../external/diamond/interfaces/IAnticFeeCollectorProvider.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for diamond initialization
library LibDiamondInitializer {
    struct DiamondInitData {
        IDiamondLoupe diamondLoupeFacet;
    }

    struct DiamondStorage {
        bool initialized;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibDiamondInitializer");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    modifier initializer() {
        LibDiamondInitializer.DiamondStorage storage ds = LibDiamondInitializer
            .diamondStorage();
        require(!ds.initialized, "LibDiamondInitializer: Initialized");
        _;
        ds.initialized = true;
    }

    function _diamondInit(DiamondInitData memory initData)
        internal
        initializer
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // ERC165
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IGroup).interfaceId] = true;
        ds.supportedInterfaces[type(IWallet).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712Transaction).interfaceId] = true;
        ds.supportedInterfaces[type(IGovernance).interfaceId] = true;
        ds.supportedInterfaces[type(ISignature).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1271).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155TokenReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721TokenReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712Proposition).interfaceId] = true;
        ds.supportedInterfaces[type(IOwnership).interfaceId] = true;
        ds.supportedInterfaces[type(IAnticFee).interfaceId] = true;
        ds.supportedInterfaces[type(IDeploymentRefund).interfaceId] = true;
        ds.supportedInterfaces[type(IReceive).interfaceId] = true;
        ds.supportedInterfaces[type(IGroupState).interfaceId] = true;
        ds.supportedInterfaces[type(IWalletHash).interfaceId] = true;
        ds.supportedInterfaces[
            type(IAnticFeeCollectorProvider).interfaceId
        ] = true;

        // DiamondLoupe facet cut
        bytes4[] memory functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(initData.diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }
}