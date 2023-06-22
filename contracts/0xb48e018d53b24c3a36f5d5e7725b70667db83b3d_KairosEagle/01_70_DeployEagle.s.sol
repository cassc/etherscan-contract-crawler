// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

//                            [email protected]@@@@#########@@@@a.
//                        [email protected]@######@@@[email protected]@mm######@@@a.
//                   .a####@@@@@@@@@@@@@@@@@@@[email protected]@##@@v;%%,.
//                .a###[email protected]@@@@@@@[email protected]@@@#@v;%%%vv%%,
//             .a##[email protected]@@@@@@@vv%%%%;S,  .S;%%[email protected]@#v;%%'/%vvvv%;
//           .a##@[email protected]@@@@vv%%vvvvvv%%;SssS;%%[email protected];%%./%vvvvvv%;
//         ,a##[email protected]@@vv%%%@@@@@@@@@@@@mmmmmmmmmvv;%%%%vvvvvvvvv%;
//         .a##@@@@@@@@@@@@@@@@@@@@@@@mmmmmvv;%%%%%vvvvvvvvvvv%;
//        ###[email protected]@@v##@[email protected]@@@@@@@@@mmv;%;%;%;%;%;%;%;%;%;%;%,%vv%'
//       a#[email protected]@@@v##[email protected]@@@@@@@###@@@@@%v%v%v%v%v%v%v%      ;%%;'
//      ',[email protected]@@@@@@[email protected]@@@@@@@v###[email protected]@@nvnvnvnvnvnvnvnv'     .%;'
//      a###@@@@@@@###[email protected]@@v##[email protected]@@mnmnmnmnmnmnmnmnmn.     ;'
//     ,###[email protected]@@@v##[email protected]@@@@@[email protected]@@@v##[email protected]@@@@v###[email protected]@@##@.
//     ###[email protected]@@@@@[email protected]@###[email protected]@@@@@@@[email protected]@@@@@v##[email protected]@@v###[email protected]@.
//    [email protected]@@@@@@@@@v##[email protected]@@@@@@@@@@@@@;@@@[email protected]@@@v##[email protected]@@@@@a
//   ',@@@@@@;@@@@@@[email protected]@@@@@@@@@@@@@@;%@@@@@@@@@[email protected]@@@;@@@@@a
//  [email protected]@@@@@;%@@;@@@@@@@;;@@@@@;@@@@;%%;@@@@@;@@@@;@@@;@@@@@@.
// ,[email protected]@@;vv;@%;@@@@@;%%v%;@@@;@@@;%vv%%;@@@;%;@@;%@@@;%;@@;%@@a
//   [email protected]@@@@@;%@@;@@@@@@@;;@@@@@;@@@@;%%;@@@@@;@@@@;@@@;@@@@@@.
// ,[email protected]@@;vv;@%;@@@@@;%%v%;@@@;@@@;%vv%%;@@@;%;@@;%@@@;%;@@;%@@a
//  [email protected];vv;%%%;@@;%%;vvv;%%@@;%;@;%vvv;%;@@;%%%;@;%;@;%%%@@;%%;.`
// ;@;%;vvv;%;@;%%;vv;%%%%v;%%%;%vv;%%v;@@;%vvv;%;%;%;%%%;%%%%;.%,
// %%%;vv;%;vv;%%%v;%%%%;vvv;%%%v;%%%;vvv;%;vv;%%%%%;vv;%%%;vvv;.%%%,
// ;vvv;%%;vv;%%;vv;%%%;vv;%%%;vvv;%;vv;%;vv;%;%%%;vv;%%%%;vv;%%.%v;v%
// vv;%;vvv;%;vv;;%%%%%%;%%%%;vv;%%%%;%%%%;%%;%%;%%;vv;%%%%;%%%;v.%vv;
// ;%%%%;%%%%%;%%%%%;%%%%;%%%%;%%%;%%%;%%%%%%%;%%%%%;%%%;%%%%;%%;.%%;%

// &&&&@7   :[email protected]@@@P.     [email protected]@@@@@B       [email protected]&&@G  ?B&@@@@@@@@@@&#Y.       :!YGB#BG5?~       ^5#&@@@@@@@&7
// @@@@@7  ^#@@@@5.     [email protected]@@@@@@@?      [email protected]@@@B  ^^#@@@@@##&@@@@@P     :Y&@@@@@@@@@@BJ.   ^&@@@@@####B!
// @@@@@7 ~&@@@@?      .#@@@&&@@@&:     [email protected]@@@B    #@@@@5 [email protected]@@@#     [email protected]@@@@@@@@@#~  [email protected]@@@@J.
// @@@@@7~&@@@&~       [email protected]@@@[email protected]@@@5     [email protected]@@@B   .#@@@@5   [email protected]@@@#     .!^[email protected]@@@@@@@@@#: :[email protected]@@@&BY!:
// @@@@@[email protected]@@@#:      [email protected]@@@#. #@@@@~    [email protected]@@@B   .#@@@@5~YP&@@@#7  :[email protected]@@@@@@@@@@@@@@~  .?G&@@@@@&BJ:
// @@@@@7 [email protected]@@@#^     [email protected]@@@[email protected]@@@#7!. [email protected]@@@B   .#@@@@[email protected]@@@G.  !&@@@@@@@@@@@@@@@@@@#:     [email protected]@@@@B
// @@@@@7  [email protected]@@@&~   [email protected]@@@@@@@@@@@@@@?  [email protected]@@@B   .#@@@@5 [email protected]@@@Y   ^Y#@@@@@@@@@@@@@@@#~   .:....:[email protected]@@@&
// @@@@@7   [email protected]@@@&! :&@@@@[email protected]@@@&:  [email protected]@@@B   .#@@@@5  :[email protected]@@@Y    ~#@@@@@@@@@@@@BJ.   .#&&&&&&@@@@@5
// ####&7    J&&&&#^Y&&&&B.     G&##&J  J&##&G   .G###&Y   ^B&&&&?    .~7JJYJPBG5?~      .B&&&&&&&#BP!

// solhint-disable no-console
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Diamond, DiamondArgs} from "diamond/contracts/Diamond.sol";
import {DiamondCutFacet} from "diamond/contracts/facets/DiamondCutFacet.sol";
import {OwnershipFacet} from "diamond/contracts/facets/OwnershipFacet.sol";
import {DiamondLoupeFacet} from "diamond/contracts/facets/DiamondLoupeFacet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDiamondCut} from "diamond/contracts/interfaces/IDiamondCut.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibDiamond} from "diamond/contracts/libraries/LibDiamond.sol";
import {IERC173} from "diamond/contracts/interfaces/IERC173.sol";
import {IERC165} from "diamond/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "diamond/contracts/interfaces/IDiamondLoupe.sol";

import {DiamondERC721} from "../SupplyPositionLogic/DiamondERC721.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {ContractsCreator} from "../ContractsCreator.sol";
import {KairosEagleFacet} from "./KairosEagle.sol";
import {loupeFS, ownershipFS, cutFS, getSelector} from "../utils/FuncSelectors.h.sol";

contract KairosEagle is Diamond {
    /* solhint-disable-next-line no-empty-blocks */
    constructor(IDiamondCut.FacetCut[] memory cuts, DiamondArgs memory _args) Diamond(cuts, _args) {}
}

contract EagleInitializer {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        SupplyPosition storage sp = supplyPositionStorage();
        sp.name = "Kairos Eagle";
        sp.symbol = "KEG";
    }
}

contract DeployEagle is Script, ContractsCreator {
    KairosEagleFacet internal eagle;
    EagleInitializer internal eagleInitializer;

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(privateKey);
        cut = DiamondCutFacet(0xc5126Eb24430d459Cd810B882C3AD286D380B6bD);
        loupe = DiamondLoupeFacet(0x47Ae465f27c69659e7D5012c4e2a6732A8aA8370);
        ownership = OwnershipFacet(0xC433107B136b6ea1Abb1b99E0A0a39459687599c);
        eagle = new KairosEagleFacet(IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
        eagleInitializer = new EagleInitializer();

        DiamondArgs memory args = DiamondArgs({
            owner: vm.addr(privateKey),
            init: address(eagleInitializer),
            initCalldata: abi.encodeWithSelector(eagleInitializer.init.selector)
        });

        new KairosEagle(eagleFacetCuts(), args);
        console.logBytes(abi.encode(eagleFacetCuts(), args));
    }

    function eagleFacetCuts() internal view returns (IDiamondCut.FacetCut[] memory) {
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](4);

        facetCuts[0] = getAddFacetCut(address(loupe), loupeFS());
        facetCuts[1] = getAddFacetCut(address(ownership), ownershipFS());
        facetCuts[2] = getAddFacetCut(address(cut), cutFS());
        facetCuts[3] = getAddFacetCut(address(eagle), eagleFS());

        return facetCuts;
    }

    function eagleFS() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](18);

        functionSelectors[0] = IERC721.balanceOf.selector;
        functionSelectors[1] = IERC721.ownerOf.selector;
        functionSelectors[2] = DiamondERC721.name.selector;
        functionSelectors[3] = DiamondERC721.symbol.selector;
        functionSelectors[4] = IERC721.approve.selector;
        functionSelectors[5] = IERC721.getApproved.selector;
        functionSelectors[6] = IERC721.setApprovalForAll.selector;
        functionSelectors[7] = IERC721.isApprovedForAll.selector;
        functionSelectors[8] = IERC721.transferFrom.selector;
        functionSelectors[9] = getSelector("safeTransferFrom(address,address,uint256)");
        functionSelectors[10] = getSelector("safeTransferFrom(address,address,uint256,bytes)");
        functionSelectors[11] = KairosEagleFacet.buy.selector;
        functionSelectors[12] = KairosEagleFacet.setRaffle.selector;
        functionSelectors[13] = KairosEagleFacet.withdrawFunds.selector;
        functionSelectors[14] = KairosEagleFacet.setBaseMetadataUri.selector;
        functionSelectors[15] = KairosEagleFacet.tokenURI.selector;
        functionSelectors[16] = KairosEagleFacet.totalSupply.selector;
        functionSelectors[17] = KairosEagleFacet.getHardCap.selector;

        return functionSelectors;
    }
}