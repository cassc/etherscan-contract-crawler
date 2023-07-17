// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//          .--.  ,---.  _______   ,--,  ,---.  .-. .-.   .---. .-. .-.       //
//         / /\ \ | .-.\|__   __|.' .')  | .-.\ | | | |  ( .-._)| | | |       //
//        / /__\ \| `-'/  )| |   |  |(_) | `-'/ | | | | (_) \   | `-' |       //
//        |  __  ||   (  (_) |   \  \    |   (  | | | | _  \ \  | .-. |       //
//        | |  |)|| |\ \   | |    \  `-. | |\ \ | `-')|( `-'  ) | | |)|       //
//        |_|  (_)|_| \)\  `-'     \____\|_| \)\`---(_) `----'  /(  (_)       //
//                    (__)                   (__)              (__)           //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import "./ERC721PartnerSeaDrop.sol";
import "./interfaces/IArtcrush.sol";

/**
 * @title Artcrush Membership NFT
 * @author mouradif.eth
 */
contract Artcrush is ERC721SeaDrop, IArtcrush {

    uint256 private _airdropSupply;

    constructor(address[] memory allowedSeaDrop) ERC721SeaDrop(
        "ARTCRUSH MEMBERSHIP NFT",
        "CRUSH",
        allowedSeaDrop
    ) {}

    function updateTokenGatedDrop(
        address,
        address,
        TokenGatedDropStage calldata
    ) external virtual override {
        revert NotImplemented();
    }

    function updateSignedMintValidationParams(
        address,
        address,
        SignedMintValidationParams memory
    ) external virtual override {
        revert NotImplemented();
    }

    function airdrop(
        address to,
        uint256 qty
    ) external onlyOwner {
        if (_airdropSupply + qty > 1000) {
            revert WouldExceedMaxSupply();
        }
        _airdropSupply += qty;
        _safeMint(to, qty);
    }
}