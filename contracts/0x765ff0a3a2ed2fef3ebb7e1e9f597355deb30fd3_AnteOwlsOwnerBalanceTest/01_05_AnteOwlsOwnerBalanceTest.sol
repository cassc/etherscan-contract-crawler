// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


/// @title Checks that Owls Nft Owner holds at least 10 OWLs
/// @author 0x0b1C4725Fb3ff89d5E3172a67022b61c1127d014
/// @notice Ante Test to check
contract AnteOwlsOwnerBalanceTest is AnteTest("Owls NFT Owner's Owls NFT balance remains >= 10") {
    // https://etherscan.io/address/0x74beEE74A44b713487D42473784b5CBDc547355E
    address public constant HOLDER_ADDRESS = 0x74beEE74A44b713487D42473784b5CBDc547355E;

    // https://etherscan.io/address/0xe2e27b49e405f6c25796167b2500c195f972ebac
    IERC721 public constant NFT = IERC721(0xe2e27b49e405f6c25796167B2500C195F972eBac);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = 10;

        protocolName = "Owls";

        testedContracts = [address(NFT), HOLDER_ADDRESS];
    }

    /// @notice test to check if Owls Owner owns >= 10 [NFT]s
    /// @return true if Owls balance of 0x74beEE74A44b713487D42473784b5CBDc547355E is >= 10
    function checkTestPasses() public view override returns (bool) {
        return (NFT.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}