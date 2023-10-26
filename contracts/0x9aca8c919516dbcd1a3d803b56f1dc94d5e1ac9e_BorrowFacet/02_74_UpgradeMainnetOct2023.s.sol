// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IDiamondCut} from "diamond/contracts/interfaces/IDiamondCut.sol";
import {ISignature} from "../../interface/ISignature.sol";
import {IKairos} from "../../interface/IKairos.sol";

// solhint-disable no-console
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

import {BorrowFacet} from "../../BorrowFacet.sol";
import {ContractsCreator} from "../../ContractsCreator.sol";
import {RepayFacet} from "../../RepayFacet.sol";
import {AdminFacet} from "../../AdminFacet.sol";

contract UpgradeMainnetOct2023 is Script, ContractsCreator {
    function run() public {
        // IKairos kairos = IKairos(0xa7fc58e0594C2e8ecEfFADCE2B3d606Baf782520); // ethereum mainnet
        // IKairos kairos = IKairos(0x873b6390626ce29976372779ec2722e0117ec375); // polygon mainnet

        uint256 privateKey = vm.envUint("DEPLOYER_KEY");
        bytes4[] memory borrowSelectorsToDelete = new bytes4[](2);
        borrowSelectorsToDelete[0] = 0x1fbc8a74; // old offerDigest
        borrowSelectorsToDelete[1] = 0xb1ce7a6a; // old borrow
        bytes4[] memory singleBorrowSelectorToUpgrade = new bytes4[](1);
        singleBorrowSelectorToUpgrade[0] = BorrowFacet.onERC721Received.selector;
        bytes4[] memory borrowSelectorsToAdd = new bytes4[](4);
        borrowSelectorsToAdd[0] = ISignature.apiCoSignedPayloadDigest.selector;
        borrowSelectorsToAdd[1] = BorrowFacet.transferBorrowerRights.selector;
        borrowSelectorsToAdd[2] = BorrowFacet.borrow.selector;
        borrowSelectorsToAdd[3] = ISignature.offerDigest.selector;
        bytes4[] memory singleRepaySelectorToAdd = new bytes4[](1);
        singleRepaySelectorToAdd[0] = RepayFacet.toRepay.selector;
        bytes4[] memory singleAdminSelectorToAdd = new bytes4[](1);
        singleAdminSelectorToAdd[0] = AdminFacet.setApiAddress.selector;
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](5);

        vm.startBroadcast(privateKey);
        borrow = new BorrowFacet();
        repay = new RepayFacet();
        admin = new AdminFacet();

        facetCuts[0] = getRemoveFacetCut(borrowSelectorsToDelete);
        facetCuts[1] = getUpgradeFacetCut(address(borrow), singleBorrowSelectorToUpgrade);
        facetCuts[2] = getAddFacetCut(address(borrow), borrowSelectorsToAdd);
        facetCuts[3] = getAddFacetCut(address(repay), singleRepaySelectorToAdd);
        facetCuts[4] = getAddFacetCut(address(admin), singleAdminSelectorToAdd);

        vm.stopBroadcast();

        console.logBytes(abi.encodeWithSelector(IDiamondCut.diamondCut.selector, facetCuts, address(0), new bytes(0)));

        // kairos.setApiAddress(0xc0e8DD6b53DF5451EB35A00707ae2b0675F41Bd3); // prod api signer
    }
}