//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@chocolate-factory/contracts/admin-manager/AdminManagerUpgradable.sol";
import "erc721a/contracts/IERC721A.sol";

contract AirdropTransferUpgradeable is
    Initializable,
    AdminManagerUpgradable
{

    IERC721A public nft;

    function initialize() initializer public {
        __AdminManager_init();
    }

    struct Airdrop {
        uint256 amount;
        address to;
    }

    uint256 public startingId;

    function airdrop(
        Airdrop[] calldata airdrops,
        address from
    ) external onlyAdmin {
        for(uint256 i; i < airdrops.length; i++) {
            Airdrop memory _airdrop = airdrops[i];
            for(uint256 j; j < _airdrop.amount; j++) {
                nft.safeTransferFrom(from, _airdrop.to, startingId);
                startingId++;
            }            
        }
    }

    function setNFT(IERC721A _nft) external onlyAdmin {
        nft = _nft;
    }

    function setStartingId(uint256 _id) external onlyAdmin {
        startingId = _id;
    }
}