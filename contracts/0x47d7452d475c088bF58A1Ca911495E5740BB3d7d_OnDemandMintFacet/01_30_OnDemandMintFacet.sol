// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OnDemandMintLib} from "./OnDemandMintLib.sol";
import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {PausableModifiers} from "../Pausable/PausableModifiers.sol";
import {SaleStateModifiers} from "../BaseNFTModifiers.sol";

contract OnDemandMintFacet is
    AccessControlModifiers,
    PausableModifiers,
    SaleStateModifiers
{
    function setMintSigner(address _signer) external onlyOwner whenNotPaused {
        OnDemandMintLib.setMintSigner(_signer);
    }

    function getMintSigner() public view returns (address) {
        return OnDemandMintLib.getMintSigner();
    }

    function onDemandMint(
        string memory _tokenURI,
        bytes memory approvalSignature
    ) public payable whenNotPaused onlyAtSaleState(6) {
        OnDemandMintLib.onDemandMint(_tokenURI, approvalSignature);
    }

    function mintNonceForAddress(address minter) public view returns (uint256) {
        return OnDemandMintLib.onDemandMintStorage()._userNonces[minter];
    }
}