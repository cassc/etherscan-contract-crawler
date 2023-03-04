// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/// @title Checks that [HOLDER] holds at least [THRESHOLD] [NFT]s
/// @notice Ante Test to check
contract AnteNFTBalanceTest is
    AnteTest("[HOLDER] [NFT] balance remains >= [THRESHOLD]")
{
    address public factory;
    address public nftHolder;
    IERC721 public nft;
    uint256 public thresholdBalance;

    constructor(
        address _nftAddress,
        address _holderAddress,
        uint256 _thresholdBalance,
        address _testAuthor
    ) {
        factory = msg.sender;
        nft = IERC721(_nftAddress);
        nftHolder = _holderAddress;
        thresholdBalance = _thresholdBalance;

        try IERC721Metadata(_nftAddress).name() returns (string memory name) {
            protocolName = name;
        } catch {}

        bytes memory bProtocolName = bytes(protocolName);
        if (bProtocolName.length == 0) {
            try IERC721Metadata(_nftAddress).symbol() returns (
                string memory symbol
            ) {
                protocolName = symbol;
            } catch {
                protocolName = "NFT";
            }
        }

        testedContracts = [_nftAddress, _holderAddress];
        testAuthor = _testAuthor;
    }

    /// @notice test to check if [HOLDER] owns >= [THRESHOLD] [NFT]s
    /// @return true if [NFT] balance of [HOLDER] is >= [THRESHOLD]
    function checkTestPasses() public view override returns (bool) {
        return nft.balanceOf(nftHolder) >= thresholdBalance;
    }
}