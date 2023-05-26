// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface OCPunks {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}

/**
 * =OCP=
 *   |
 *  /|
 First ETH <> BTC bridge. 17.03.2023 
 */


contract OCPBridge is Ownable, IERC721Receiver {
    uint256 public totalBridged;
    uint256 public bridgeFee = 3000000000000000; // 0.003 ETH in wei

    struct Bridge {
        uint24 tokenId;
        address owner;
        string btcAddress;
        bool locked;
    }

    event NFTBridged(address owner, uint256 tokenId);
    event NFTUnbridged(address owner, uint256 tokenId);

    OCPunks nft;

    // maps tokenId to bridge
    mapping(uint256 => Bridge) public vault;

    constructor() { 
        nft = OCPunks(0xdb804A76474532D6f72d463b7BC8E4D47c64e171);
    }

    function bridge(uint256[] calldata tokenIds, string calldata btcAddress) external payable {
        require(tokenIds.length > 0, "Must bridge at least one NFT");
        uint256 totalFee = bridgeFee * tokenIds.length;
        require(msg.value >= totalFee, "Insufficient fee");

        uint256 tokenId;
        totalBridged += tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "Not your NFT");
            require(vault[tokenId].tokenId == 0, 'Already bridged');

            nft.transferFrom(msg.sender, address(this), tokenId);
            emit NFTBridged(msg.sender, tokenId);

            vault[tokenId] = Bridge({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                btcAddress: btcAddress,
                locked: true
            });
        }
    }

    function _unbridgeMany(address account, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        totalBridged -= tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Bridge storage bridged = vault[tokenId];
            require(bridged.owner == msg.sender, "You do not own this NFT");
            require(!bridged.locked, "The NFT is locked");

            delete vault[tokenId];

            emit NFTUnbridged(account, tokenId);
            nft.transferFrom(address(this), account, tokenId);
        }
    }

    function unbridge(uint256[] calldata tokenIds) external {
        _unbridgeMany(msg.sender, tokenIds);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send to vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function isNFTLocked(uint256 tokenId) public view returns (bool) {
        return vault[tokenId].locked;
    }

    function getBTCAddress(uint256 tokenId) public view returns (string memory) {
        return vault[tokenId].btcAddress;
    }

    function setBridgeFee(uint256 newFee) public onlyOwner {
        bridgeFee = newFee;
    }

    function unlock(uint256[] calldata tokenIds) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            vault[tokenIds[i]].locked = false;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // View function to get token data for a given tokenId
    function getTokenData(uint256 tokenId) public view returns (Bridge memory) {
        return vault[tokenId];
    }
}