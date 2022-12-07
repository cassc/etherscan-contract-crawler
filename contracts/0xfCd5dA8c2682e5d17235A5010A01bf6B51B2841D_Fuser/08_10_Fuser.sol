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
    // @dev Crazy panda genesis erc721
    IPanda public crazyPanda;

    // @dev Crazy panda max total supply
    uint256 public maxCrazyPandaSupply;

    /**
     * @notice Constructor
     * @param _farms Panda farms collection
     * @param _genesisPanda Genesis panda collection
     * @param _redPanda Red panda collection
     * @param _crazyPanda Crazy panda collection
     * @param _maxCrazyPandaSupply Crazy panda max total supply
     */
    constructor(
        IPandaFarms _farms,
        IPanda _genesisPanda,
        IPanda _redPanda,
        IPanda _crazyPanda,
        uint256 _maxCrazyPandaSupply
    ) {
        farms = _farms;
        genesisPanda = _genesisPanda;
        redPanda = _redPanda;
        crazyPanda = _crazyPanda;
        maxCrazyPandaSupply = _maxCrazyPandaSupply;
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
     * @notice Set Crazy Panda collection
     * @param newCrazyPanda Crazy Panda collection address
     */
    function setCrazyPanda(IPanda newCrazyPanda) external onlyOwner {
        crazyPanda = newCrazyPanda;
    }

    /**
     * @notice Set max Crazy Panda supply
     * @param newMaxCrazyPandaSupply Crazy Panda max supply
     */
    function seMaxCrazyPandaSupply(uint256 newMaxCrazyPandaSupply) external onlyOwner {
        maxCrazyPandaSupply = newMaxCrazyPandaSupply;
    }

    /**
     * @notice Claim Red Panda nft
     * @param tokenId Token Id of Genesis Panda
     */
    function claimRedPanda(uint256 tokenId) external {
        address sender = msg.sender;
        require(genesisPanda.ownerOf(tokenId) == msg.sender, "claimRedPanda: you are not owner of this panda");

        farms.burn(sender, 3, 1);

        redPanda.safeMint(sender);
    }

    /**
     * @notice Claim Crazy Panda nft
     * @param tokenId Token Id of Red Panda
     */
    function claimCrazyPanda(uint256 tokenId) external {
        address sender = msg.sender;
        require(crazyPanda.totalSupply() < maxCrazyPandaSupply, "claimCrazyPanda: exceeds max supply");
        require(redPanda.ownerOf(tokenId) == msg.sender, "claimRedPanda: you are not owner of this panda");

        farms.burn(sender, 3, 1);

        crazyPanda.safeMint(sender);
    }


}