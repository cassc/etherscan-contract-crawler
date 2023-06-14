// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {LSSVMPairFactory} from "../LSSVMPairFactory.sol";
import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairETH} from "../LSSVMPairETH.sol";

contract Migratoor is ERC721Holder {
    LSSVMPairFactory constant _FACTORY =
        LSSVMPairFactory(payable(0xA020d57aB0448Ef74115c112D18a9C231CC86000));

    mapping(address => uint256[]) idsForMigration;

    function setIdsForMigration(uint256[] calldata ids) external {
        idsForMigration[msg.sender] = ids;
    }

    function onOwnershipTransfer(address oldOwner) external payable {
        uint256[] memory ids = idsForMigration[msg.sender];
        LSSVMPair caller = LSSVMPair(msg.sender);
        LSSVMPairETH(payable(address(caller))).withdrawAllETH();
        caller.withdrawERC721(IERC721(address(caller.nft())), ids);
        LSSVMPair pair = _FACTORY.createPairERC721ETH{
            value: address(this).balance
        }(
            IERC721(address(caller.nft())),
            caller.bondingCurve(),
            payable(oldOwner),
            caller.poolType(),
            caller.delta(),
            caller.fee(),
            caller.spotPrice(),
            address(0),
            ids
        );
        pair.transferOwnership(oldOwner, "");
        delete idsForMigration[msg.sender];
    }

    receive() external payable {}
}