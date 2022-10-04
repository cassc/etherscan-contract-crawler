// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/getter/IGetterLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";
import "./IHumanboundBurnLogic.sol";

contract HumanboundBurnLogic is HumanboundBurnExtension, Burn {
    modifier onlyOperator() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        require(_lastExternalCaller() == state.operator, "HumanboundBurnLogic: unauthorised");
        _;
    }

    function burn(uint256 tokenId, string memory burnProofURI) external onlyOperator {
        _burn(tokenId);

        emit BurntWithProof(tokenId, burnProofURI);
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == IGetterLogic(address(this)).ownerOf(tokenId), "HumanboundBurnLogic: not token owner");

        _burn(tokenId);

        emit BurntByOwner(tokenId);
    }
}