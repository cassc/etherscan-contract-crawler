// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {LSSVMPairFactory} from "../LSSVMPairFactory.sol";
import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairETH} from "../LSSVMPairETH.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";

contract Migratoor is ERC721Holder {
    LSSVMPairFactory constant _FACTORY =
        LSSVMPairFactory(payable(0xA020d57aB0448Ef74115c112D18a9C231CC86000));

    mapping(address => uint256[]) idsForMigration;

    function setIdsForMigration(uint256[] calldata ids) external {
        idsForMigration[msg.sender] = ids;
    }

    function onOwnershipTransfer(address oldOwner) external payable {
        uint256[] memory ids = idsForMigration[oldOwner];
        LSSVMPair caller = LSSVMPair(msg.sender);
        LSSVMPairETH(payable(address(caller))).withdrawAllETH();
        IERC721 nft = IERC721(address(caller.nft()));
        caller.withdrawERC721(nft, ids);
        nft.setApprovalForAll(address(_FACTORY), true);
        LSSVMPair pair = _FACTORY.createPairERC721ETH{
            value: address(this).balance
        }(
            nft,
            ICurve(getBondingCurve(address(caller.bondingCurve()))),
            payable(oldOwner),
            caller.poolType(),
            caller.delta(),
            caller.fee(),
            caller.spotPrice(),
            address(0),
            ids
        );
        pair.transferOwnership(oldOwner, "");
        caller.transferOwnership(oldOwner, "");
        delete idsForMigration[oldOwner];
    }

    function getBondingCurve(address a) private pure returns (address) {
        // Exponential curve
        if (a == 0x432f962D8209781da23fB37b6B59ee15dE7d9841) {
          return 0xfa056C602aD0C0C4EE4385b3233f2Cb06730334a;
        } 
        // Linear curve
        else if (
            a == 0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee
        ) {
          return 0xe5d78fec1a7f42d2F3620238C498F088A866FdC5;
        }
        // xyk curve
        else if (
          a == 0x7942E264e21C5e6CbBA45fe50785a15D3BEb1DA0
        ) {
          return 0xc7fB91B6cd3C67E02EC08013CEBb29b1241f3De5;
        }
        else {
          revert();
        }
    }

    receive() external payable {}
}