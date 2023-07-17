// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {GenArtAccess} from "../access/GenArtAccess.sol";
import {GenArtCurated} from "../app/GenArtCurated.sol";
import {IGenArtMintAllocator} from "../interface/IGenArtMintAllocator.sol";
import {IGenArtInterfaceV4} from "../interface/IGenArtInterfaceV4.sol";
import {IGenArtERC721} from "../interface/IGenArtERC721.sol";
import {IGenArtPaymentSplitterV5} from "../interface/IGenArtPaymentSplitterV5.sol";
import {GenArtMinterBase} from "./GenArtMinterBase.sol";

contract GenArtMinterSobelClaim is GenArtMinterBase {
    uint256 public startTime;
    address public mintAllocContract;
    address public sobelContract;
    uint256 public maxSobelId;

    mapping(uint256 => bool) public mintedIds;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address sobelContract_,
        address mintAllocContract_,
        uint256 startTime_,
        uint256 maxSobelId_
    ) GenArtMinterBase(genartInterface_, genartCurated_) {
        startTime = startTime_;
        mintAllocContract = mintAllocContract_;
        sobelContract = sobelContract_;
        maxSobelId = maxSobelId_;
    }

    function getPrice(address) public view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(uint256 amount) internal view {
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            sobelContract
        ).getInfo();
        require(
            totalSupply + amount <= maxSupply,
            "not enough mints available"
        );
        require(startTime <= block.timestamp, "mint not started yet");
    }

    /**
     * @dev Mint a token
     */
    function mintOne(address, uint256) external payable override {
        revert("not implemented");
    }

    /**
     * @dev Mint many tokens
     */
    function mint(address, uint256) external payable override {
        revert("not implemented");
    }

    /**
     * @dev Claim
     */
    function claim(uint256 amount) external {
        _checkMint(amount);
        address sender = msg.sender;
        uint256[] memory tokens = IGenArtERC721(sobelContract).getTokensByOwner(
            sender
        );
        uint256 minted;
        uint256 i;
        while (minted < amount && i < tokens.length) {
            uint256 token = tokens[i];
            if (!mintedIds[token] && token <= maxSobelId) {
                IGenArtERC721(sobelContract).mint(sender, 0);
                IGenArtMintAllocator(mintAllocContract).update(
                    sobelContract,
                    0,
                    1
                );
                minted++;
            }
            i++;
        }
        require(minted > 0, "no mints available");
    }

    function setPricing(
        address,
        bytes memory
    ) external pure override returns (uint256) {
        revert("not implemented");
    }
}