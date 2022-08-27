// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/ISarugami.sol";
import "./lib/ISarugamiGamaSummon.sol";

contract SaleGama is Ownable, ReentrancyGuard {
    bool public isMintActive = false;
    uint256 public lockedAmountHolders = 2510;
    uint256 public minted = 0;
    uint256 public serviceFee = 6000000000000000;

    bytes32 public merkleRootRegularWhitelist = "0x";
    bytes32 public merkleRootAlphaWhitelist = "0x";

    uint256 public startMint = 1661626800;
    uint256 public alphaSeconds = 7200;//2 hours
    uint256 public whitelistSeconds = 86400;//24 hours

    mapping(uint256 => bool) public nftsClaimed;
    mapping(address => bool) public walletsClaimed;
    ISarugami public sarugami;
    ISarugamiGamaSummon public summon;

    constructor(
        address sarugamiAddress,
        address summonAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
        summon = ISarugamiGamaSummon(summonAddress);
    }

    function mintHolder(uint256[] memory ids) public payable nonReentrant {
        require(isMintActive == true, "Holder free mint not open");
        require(msg.value == serviceFee, "ETH sent does not match the Service Fee");
        require(block.timestamp > startMint, "Sale not open");

        for (uint i = 0; i < ids.length; i++) {
            require(sarugami.ownerOf(ids[i]) == _msgSender(), "You are not the owner");
            require(nftsClaimed[ids[i]] == false, "Already claimed");
            nftsClaimed[ids[i]] = true;
        }

        summon.mint(msg.sender, ids.length);
    }

    function mintWhitelist(bytes32[] calldata merkleProof) public payable nonReentrant {
        require(isMintActive == true, "Mint is not active");
        require(walletsClaimed[msg.sender] == false, "Max 1 per wallet");
        require(msg.value == serviceFee, "ETH sent does not match the Service Fee");
        require(block.timestamp > startMint, "Sale not open");
        require(minted+1 < lockedAmountHolders, "Limit reached, Holders have 24 hours to mint, then the remaining supply will be unlocked");

        if(block.timestamp < startMint + alphaSeconds){
            require(isWalletOnAlphaWhitelist(merkleProof, msg.sender) == true, "Invalid proof, Alpha whitelist is minting now");
        } else {
            if (block.timestamp > startMint + alphaSeconds && block.timestamp < startMint + whitelistSeconds) {
                require(isWalletOnAlphaWhitelist(merkleProof, msg.sender) == true || isWalletOnRegularWhitelist(merkleProof, msg.sender) == true, "Invalid proof, your wallet isn't listed in any whitelist");
            }
        }

        minted += 1;
        walletsClaimed[msg.sender] = true;
        summon.mint(msg.sender, 1);
    }

    function isWalletOnAlphaWhitelist(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRootAlphaWhitelist, leaf);
    }

    function isWalletOnRegularWhitelist(
        bytes32[] calldata merkleProof,
        address wallet
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));
        return MerkleProof.verify(merkleProof, merkleRootRegularWhitelist, leaf);
    }

    function changePriceServiceFee(uint256 newPrice) external onlyOwner {
        serviceFee = newPrice;
    }

    function changeAlphaSeconds(uint256 newTimestamp) external onlyOwner {
        alphaSeconds = newTimestamp;
    }

    function changeWhitelistSeconds(uint256 newTimestamp) external onlyOwner {
        whitelistSeconds = newTimestamp;
    }

    function changeStartMint(uint256 newTimestamp) external onlyOwner {
        startMint = newTimestamp;
    }

    function changeLockedAmountHolders(uint256 newLock) external onlyOwner {
        lockedAmountHolders = newLock;
    }

    function setMerkleTreeRegularWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootRegularWhitelist = newMerkleRoot;
    }

    function setMerkleTreeAlphaWhitelist(bytes32 newMerkleRoot) external onlyOwner {
        merkleRootAlphaWhitelist = newMerkleRoot;
    }

    function mintGiveAwayWithAddresses(address[] calldata supporters) external onlyOwner {
        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < supporters.length; index++) {
            minted += 1;
            summon.mint(supporters[index], 1);
        }
    }

    function changeMintStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }

    function removeFunds() external onlyOwner {
        uint256 funds = address(this).balance;

        (bool devShare,) = 0xDEcB0fB8d7BB68F0CE611460BE8Ca0665A72d47E.call{
        value : funds * 10 / 100
        }("");

        (bool operationalShare,) = 0x7F1a6c8DFF62e1595A699e9f0C93B654CcfC5Fe1.call{
        value : funds * 15 / 100
        }("");

        (bool modsShare,) = 0x4f45a514EeB7D4a6614eC1F76eec5aB75922A86D.call{
        value : funds * 5 / 100
        }("");

        (bool artistShare,) = 0x289660e62ff872536330938eb843607FC53E0a34.call{
        value : funds * 30 / 100
        }("");

        (bool costShare,) = 0xc27aa218950d40c2cCC74241a3d0d779b52666f3.call{
        value : funds * 10 / 100
        }("");

        (bool artistAndOperationalShare,) = 0xDEEf09D53355E838db08E1DBA9F86a5A7DfF2124.call{
        value : address(this).balance
        }("");

        require(
            devShare &&
            modsShare &&
            artistShare &&
            operationalShare &&
            costShare &&
            artistAndOperationalShare,
            "funds were not sent properly"
        );
    }
}