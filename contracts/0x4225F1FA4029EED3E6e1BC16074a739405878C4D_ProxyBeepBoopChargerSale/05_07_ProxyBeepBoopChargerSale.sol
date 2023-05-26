// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {IBeepBoopCharger} from "./interfaces/IBeepBoopCharger.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";
import {Address} from "@oz/utils/Address.sol";

contract ProxyBeepBoopChargerSale is Ownable {
    /// @notice The exo suit contract
    IBeepBoopCharger public immutable charger;

    /// @notice BattleZone
    IBattleZone public immutable battleZone;

    constructor(address charger_, address battleZone_) {
        charger = IBeepBoopCharger(charger_);
        battleZone = IBattleZone(battleZone_);
    }

    /**
     * @notice Purchase a suit (max 5 using in-game)
     */
    function mint(uint256 quantity) public payable {
        require(msg.value >= charger.mintPrice() * quantity, "Not enough ETH");
        uint256 totalSupply = charger.totalSupply();
        charger.adminMint(address(battleZone), quantity);
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i; i < quantity; ) {
            unchecked {
                tokenIds[i] = totalSupply + i + 1;
                ++i;
            }
        }
        battleZone.depositFor(address(charger), msg.sender, tokenIds);
    }

    /**
     * @notice Contract withdrawal
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(0xEE547a830A9a54653de3D40A67bd2BC050DAeD81),
            (balance * 80) / 100
        );
        Address.sendValue(
            payable(0x2b6b97A1ec523e3F97FB749D5a6a8173B589834A),
            (balance * 20) / 100
        );
    }

    /**
     * @notice Modify price
     */
    function setMintPrice(uint256 price) public onlyOwner {
        charger.setMintPrice(price);
    }

    /**
     * @notice Transfer back the ownership of the contract
     */
    function transferNftContractOwnership() public onlyOwner {
        charger.transferOwnership(msg.sender);
    }
}