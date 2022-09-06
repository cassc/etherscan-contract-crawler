// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC721Upgradeable as IERC721} from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import {OwnableUpgradeable as Ownable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import { ILendPoolAddressesProvider } from './BendDAO/ILendPoolAddressesProvider.sol';
import { IBNFTRegistry } from './BendDAO/IBNFTRegistry.sol';
import { MondayAPE } from './MondayAPE.sol';
import { Controller } from './Controller.sol';

contract FreeMint is Ownable, Controller {
    uint16 constant private MAX_SUPPLY = 2500;
    uint8 constant private MAX_PER_ONE = 5;
    struct MintConfig {
        uint32 startTime;
        uint32 endTime;
        uint16 maxSupply;
        uint8 maxPerOne;
    }
    MintConfig public mintConfig;
    ILendPoolAddressesProvider public BendDaoProvider; // bendDao BAYC
    IERC721 public BAYC; // BAYC

    function initialize(ILendPoolAddressesProvider _BendDaoProvider, IERC721 _BAYC) external initializer {
        Ownable.__Ownable_init();
        BendDaoProvider = _BendDaoProvider;
        BAYC = _BAYC;
        mintConfig = MintConfig({
            startTime: 0,
            endTime: 0,
            maxSupply: MAX_SUPPLY,
            maxPerOne: MAX_PER_ONE
        });
    }

    /**
     * @notice apeOwner return owner of APE, even though it's staked in BendDAO
     * @param tokenId ID of ape
     * @return address owner of ape
     */
    function apeOwner(uint256 tokenId) public view returns(address) {
	    address owner = BAYC.ownerOf(tokenId);
        IBNFTRegistry BNFTRegistry =  IBNFTRegistry(BendDaoProvider.getBNFTRegistry());
	    (address bBAYC,) = BNFTRegistry.getBNFTAddresses(address(BAYC));
        return owner == address(bBAYC) ? IERC721(address(bBAYC)).ownerOf(tokenId) : owner;
    }

    ///@dev mint new MondayAPE
    function mint(uint256 apeId) external {
        MintConfig memory cfg = mintConfig;
        require(block.timestamp > cfg.startTime && block.timestamp < cfg.endTime, "free mint closed");
        uint8 amount = cfg.maxPerOne;
        uint256 minted = mondayAPE.apeMinted(apeId);
        require(minted == 0, "already minted");
        require(mondayAPE.totalSupply()+amount <= cfg.maxSupply, "free mint out");
        Controller._mint(apeOwner(apeId), apeId, amount);
    }

    /* ===================== admin functions ===================== */
    function setMintTime(uint32 start, uint32 end) external onlyOwner {
        MintConfig memory cfg = mintConfig;
        require(end > start, "setMintTime");
        cfg.startTime = start;
        cfg.endTime = end;
        mintConfig = cfg;
    }

    function updateConfig(uint16 maxSupply, uint8 maxPerOne) external onlyOwner {
        MintConfig memory cfg = mintConfig;
        cfg.maxSupply = maxSupply;
        cfg.maxPerOne = maxPerOne;
        mintConfig = cfg;
    }

    function setMondayAPE(MondayAPE _mondayAPE) external onlyOwner {
        mondayAPE = _mondayAPE;
    }
}