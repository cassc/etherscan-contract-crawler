// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "./interfaces/IPanda.sol";
import "./interfaces/IPandaFarms.sol";

contract Fuser is Ownable {

    // @dev Panda Farms erc1155
    IPandaFarms public farms;
    // @dev Genesis panda erc721
    IPanda public genesisPanda;
    // @dev Red panda genesis erc721
    IPanda public redPanda;
    // @dev Trash panda genesis erc721
    IPanda public trashPanda;

    mapping(uint256 => bool) public claimedRedPanda;
    mapping(uint256 => bool) public claimedTrashPanda;

    event ClaimRed(uint256 genesisId);
    event ClaimTrash(uint256 redId);

    // @dev Trash panda max total supply
    uint256 public maxTrashPandaSupply;

    /**
     * @notice Constructor
     * @param _farms Panda farms collection
     * @param _genesisPanda Genesis panda collection
     * @param _redPanda Red panda collection
     * @param _trashPanda Trash panda collection
     * @param _maxTrashPandaSupply Trash panda max total supply
     */
    constructor(
        IPandaFarms _farms,
        IPanda _genesisPanda,
        IPanda _redPanda,
        IPanda _trashPanda,
        uint256 _maxTrashPandaSupply
    ) {
        farms = _farms;
        genesisPanda = _genesisPanda;
        redPanda = _redPanda;
        trashPanda = _trashPanda;
        maxTrashPandaSupply = _maxTrashPandaSupply;
    }

    /**
     * @notice Set Panda farms collection
     * @param newFarms Panda farms collection address
     */
    function setFarms(IPandaFarms newFarms) external onlyOwner {
        farms = newFarms;
    }

    /**
     * @notice Set Genesis Panda collection
     * @param newGenesisPanda Genesis Panda collection address
     */
    function setGenesisPanda(IPanda newGenesisPanda) external onlyOwner {
        genesisPanda = newGenesisPanda;
    }

    /**
     * @notice Set Red Panda collection
     * @param newRedPanda Red Panda collection address
     */
    function setRedPanda(IPanda newRedPanda) external onlyOwner {
        redPanda = newRedPanda;
    }

    /**
     * @notice Set Trash Panda collection
     * @param newTrashPanda Trash Panda collection address
     */
    function setTrashPanda(IPanda newTrashPanda) external onlyOwner {
        trashPanda = newTrashPanda;
    }

    /**
     * @notice Set max Trash Panda supply
     * @param newMaxTrashPandaSupply Trash Panda max supply
     */
    function seMaxTrashPandaSupply(uint256 newMaxTrashPandaSupply) external onlyOwner {
        maxTrashPandaSupply = newMaxTrashPandaSupply;
    }

    /**
     * @notice Claim Red Panda nft
     * @param tokenId Token Id of Genesis Panda
     */
    function claimRedPanda(uint256 tokenId) external {
        address sender = msg.sender;
        require(genesisPanda.ownerOf(tokenId) == msg.sender, "claimRedPanda: you are not owner of this panda");
        require(!claimedRedPanda[tokenId], "claimRedPanda: already claimed");

        farms.burn(sender, 3, 1);

        redPanda.safeMint(sender);
        claimedRedPanda[tokenId] = true;
    }

    /**
     * @notice Claim Trash Panda nft
     * @param tokenId Token Id of Red Panda
     */
    function claimTrashPanda(uint256 tokenId) external {
        address sender = msg.sender;
        require(trashPanda.totalSupply() < maxTrashPandaSupply, "claimTrashPanda: exceeds max supply");
        require(redPanda.ownerOf(tokenId) == msg.sender, "claimTrashPanda: you are not owner of this panda");
        require(!claimedTrashPanda[tokenId], "claimTrashPanda: already claimed");

        farms.burn(sender, 3, 1);

        trashPanda.safeMint(sender);
        claimedTrashPanda[tokenId] = true;
    }

}