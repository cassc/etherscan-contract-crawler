// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './IERC721AirdropTarget.sol';
import './ERC20Spendable.sol';
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721AirdropTarget is Ownable, ERC165, IERC721, IERC1155Receiver, IERC721Receiver, IERC721AirdropTarget {
    uint256 constant TokensPerblock = 1.75e-4 ether;

    address[] public availableAirdrops;
    mapping(address => uint256) public airdroppedQuantity;
    mapping(address => mapping(uint256 => uint256)) public claimedQuantities;
    mapping(address => uint256) totalClaimed;

    uint mutex = 1;
    modifier reentrancyGuard {
        require(mutex == 1);
        mutex = 2;
        _;
        mutex = 1;
    }

    function onERC721Received(address,address,uint256,bytes calldata) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address,address,uint256,uint256,bytes calldata) public pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address,address,uint256[] calldata,uint256[] calldata, bytes calldata) public pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function _beforeHarvestERC721(address collection, uint256 tokenID) internal virtual;
    function _beforeHarvestERC1155(address collection, uint256 tokenID, uint256 quantity) internal virtual;

    function harvestERC721Airdrop(address collection, uint256 tokenID) external {
        _beforeHarvestERC721(collection, tokenID);
        IERC721(collection).safeTransferFrom(address(this), _msgSender(), tokenID);
        emit ERC721AirdropHarvested(collection, _msgSender(), tokenID);
    }

    function harvestERC1155Airdrop(address collection, uint256 tokenID, uint256 quantity) external {
        _beforeHarvestERC1155(collection, tokenID, quantity);
        IERC1155(collection).safeTransferFrom(address(this), _msgSender(), tokenID, quantity, "");
        emit ERC1155AirdropHarvested(collection, _msgSender(), tokenID, quantity);
    }

    function noticeAirdrop(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this)) + totalClaimed[tokenAddress];
        if(airdroppedQuantity[tokenAddress] == 0 && balance > 0) {
            availableAirdrops.push(tokenAddress);
        }
        airdroppedQuantity[tokenAddress] = balance;
    }
    
    function pullAirdrop(address tokenAddress, uint256 quantity) external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(_msgSender(), address(this), quantity);
        if(airdroppedQuantity[tokenAddress] == 0) {
            availableAirdrops.push(tokenAddress);
        }
        airdroppedQuantity[tokenAddress] += quantity;
    }

    function claimableAirdrops(address airdropToken, uint256 tokenID) public view returns (uint256){
        uint256 claimed = claimedQuantities[airdropToken][tokenID];
        uint256 claimable = airdroppedQuantity[airdropToken] / maxSupply();
        return claimable - claimed;
    }

    function harvestAirdrops(address[] memory airdropTokens, uint256[] memory tokenIDs) public reentrancyGuard {
        uint256 allClaimed = 0;
        for(uint a = 0; a < airdropTokens.length; a++) {
            require(airdroppedQuantity[airdropTokens[a]] > 0, "Airdrop not found");
            uint totalClaimable;
            for(uint t = 0; t < tokenIDs.length; t++) {
                require(ownerOf(tokenIDs[t]) == _msgSender(), "Not owner of TokenID");
                uint256 claimable = claimableAirdrops(airdropTokens[a], tokenIDs[t]);
                if(claimable > 0) {
                    claimedQuantities[airdropTokens[a]][tokenIDs[t]] += claimable;
                    totalClaimed[airdropTokens[a]] += claimable;
                    totalClaimable += claimable;
                }
            }
            IERC20(airdropTokens[a]).transfer(_msgSender(),totalClaimable);
            allClaimed += totalClaimable;
            emit ERC20AirdropHarvested(airdropTokens[a], _msgSender(), tokenIDs, totalClaimable);
        }

        require(allClaimed > 0, "No tokens harvested");
    }

    function maxSupply() public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == type(IERC721AirdropTarget).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}