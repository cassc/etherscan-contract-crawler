// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract SilksMigrateToInterface {
    function mintTransfer(address to, uint256 amount) public virtual;
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract SkyFalls is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    uint256 skyFallsTokenId = 0;
    uint256 amountMinted = 0;

    // Note: In the claim function the maximum number of tokens will be based on whether not the avatar id being used
    // is equal to or below this value. Transferring SkyFall tokens to an address without using a avatar can be done
    // by the contract owner using the airdropGiveaway function. There is not limit on how many can be given away there.
    uint256 maxTokenId = 5000;

    address silksMigrateToContractAddress;
    address silksAvatarContractAddress;

    mapping (uint256 => bool) usedToken;

    bool claimStarted = false;
    bool migrationStarted = false;

    string public name = "Silks - Sky Falls";

    constructor() ERC1155("https://claim.silks.io/api/metadata") {
        silksAvatarContractAddress = 0xA03e357A09E761E8d486A1419c74bf42e8D1B064;
    }

    function setSilksAvatarContractAddress(address contractAddress) public onlyOwner {
        silksAvatarContractAddress = contractAddress;
    }

    // Set authorized contract address for minting the ERC-721 token
    function setSilksMigrateToContract(address contractAddress) public onlyOwner {
        silksMigrateToContractAddress = contractAddress;
    }

    function setMaxTokenId(uint256 _maxTokenId) public onlyOwner {
        maxTokenId = _maxTokenId;
    }

    // Toggle whether contract claiming is allowed
    function toggleClaiming() public onlyOwner {
        claimStarted = !claimStarted;
    }

    function isClaimingStarted() public view virtual returns (bool) {
        return claimStarted;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }

    // Claim Batch function
    function claim(uint256[] calldata tokenIds) public returns(uint256) {
        require(claimStarted == true, "Claiming has not started");
        require(tokenIds.length > 0, "No tokens detected");

        uint256 amount = 0;
        ERC721 silksGenesisAvatarContract = ERC721(silksAvatarContractAddress);

        // Verify token ownership and if already redeemed
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(silksGenesisAvatarContract.ownerOf(tokenIds[i]) == msg.sender, "Doesn't own the token");
            require(checkIfRedeemed(tokenIds[i]) == false, "Token already redeemed");
            require(tokenIds[i] <= maxTokenId, "Token not valid");
            usedToken[tokenIds[i]] = true;
            amount += 1;
        }

        uint256 prevSkyFallTokenId = skyFallsTokenId;
        skyFallsTokenId++;
        amountMinted = amountMinted + amount;
        _mint(msg.sender, skyFallsTokenId, amount, "");

        return prevSkyFallTokenId;
    }

    // Allowing direct drop for gievaway
    function airdropGiveaway(address[] calldata to, uint256[] calldata amountToMint) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            skyFallsTokenId++;
            amountMinted = amountMinted + amountToMint[i];
            _mint(to[i], skyFallsTokenId, amountToMint[i], "");
        }
    }

    // Allow to use the ERC-1155 to get the SilksLand ERC-721 final token
    function migrateTokens(uint256[] calldata ids, uint256[] calldata amounts) public {
        require(migrationStarted == true, "Migration has not started");
        require(ids.length == amounts.length, "Mismatch between ids and amounts lengths");

        uint256 mintAmount = 0;
        for (uint256 i = 0; i < ids.length; i++){
            require(balanceOf(msg.sender, ids[i]) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
            require(balanceOf(msg.sender, ids[i]) >= amounts[i], "Amount exceeds balance");
            mintAmount += amounts[i];
        }

        burnBatch(msg.sender, ids, amounts); // Burn N number of ERC-1155 token

        SilksMigrateToInterface silksLandContract = SilksMigrateToInterface(silksMigrateToContractAddress);
        silksLandContract.mintTransfer(msg.sender, mintAmount); // Return the minted IDs
    }

    // Allow to use the ERC-1155 to get the SilksLand ERC-721 final token (Forced)
    function forceMigrateToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Kept so no one can't force someone else to open a SilksLand
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        SilksMigrateToInterface silksLandContract = SilksMigrateToInterface(silksMigrateToContractAddress);
        silksLandContract.mintTransfer(msg.sender, 1); // Mint the ERC-721 token
    }

    // Check if the Silk Avatar has been used to mint an ERC-1155
    function checkIfRedeemed(uint256 _tokenId) view public returns(bool) {
        return usedToken[_tokenId];
    }

    function checkIfRedeemedBatch(uint256[] calldata _tokenIds) view public returns(bool[] memory) {
        bool[] memory checks = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++){
            checks[i] = usedToken[_tokenIds[i]];
        }
        return checks;
    }

    // Get amount of 1155 minted
    function getAmountMinted() view public returns(uint256) {
        return amountMinted;
    }

    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}