// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Checks that LockShiboshi holds at least 400 [NFT]s
/// @author Put your ETH address here
/// @notice Ante Test to check
contract AnteShiboshiNFTBalanceTest is AnteTest("LockShiboshi Shiboshi balance remains >= 400") {

    // https://etherscan.io/address/0xbe4e191b22368bff26aa60be498575c477af5cc3
    address public constant HOLDER_ADDRESS = 0xBe4E191B22368bfF26aA60Be498575C477AF5Cc3;

    // https://etherscan.io/token/0x11450058d796b02eb53e65374be59cff65d3fe7f
    IERC721 public constant NFT = IERC721(0x11450058d796B02EB53e65374be59cFf65d3FE7f);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = 400;

        protocolName = "Shiboshi";

        testedContracts = [address(NFT), HOLDER_ADDRESS];
    }

    /// @notice test to check if 0xBe4E191B22368bfF26aA60Be498575C477AF5Cc3 owns >= 400 [NFT]s
    /// @return true if 0x11450058d796B02EB53e65374be59cFf65d3FE7f balance of 0xBe4E191B22368bfF26aA60Be498575C477AF5Cc3 is >= 400
    function checkTestPasses() public view override returns (bool) {
        return (NFT.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}