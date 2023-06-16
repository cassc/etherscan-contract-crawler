// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VhighAvatarGen1.sol";
import "./VAG1SBT.sol";
import "./VhighID.sol";

contract VASBTMint is Ownable, ERC721Holder, Pausable, ReentrancyGuard {
    uint256 public mintPrice;
    uint256 public constant freeMintPrice = 0 ether;

    VhighAvatarGen1 public immutable vag1NFT;
    VAG1SBT public immutable vag1SBT;
    VhighID public immutable vhighID;

    mapping(address => bool) public freeMintList;

    event Mint(
        address indexed user,
        uint256 vhighIDTokenId,
        uint256 vag1SBTTokenId,
        uint256 timestamp
    );

    constructor(
        address vag1NFTAddress,
        address vag1SBTAddress,
        address vhighIDAddress
    ) {
        _pause();

        vag1NFT = VhighAvatarGen1(vag1NFTAddress);
        vag1SBT = VAG1SBT(vag1SBTAddress);
        vhighID = VhighID(vhighIDAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function addAddressesToFreeMintList(
        address[] calldata users
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            freeMintList[users[i]] = true;
        }
    }

    function removeAddressesFromFreeMintList(
        address[] calldata users
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            freeMintList[users[i]] = false;
        }
    }

    function mintPriceOf(address user) public view returns (uint256) {
        if (freeMintList[user]) {
            return freeMintPrice;
        }
        return mintPrice;
    }

    function mint(uint256 tokenId) external payable whenNotPaused nonReentrant {
        require(
            msg.value >= mintPriceOf(_msgSender()),
            "VASBTMint: Insufficient ETH sent"
        );
        uint256 refund = msg.value - mintPriceOf(_msgSender());

        require(
            vag1NFT.ownerOf(tokenId) == _msgSender(),
            "VASBTMint: Not the VAG1NFT holder"
        );
        require(
            vag1SBT.balanceOf(_msgSender()) == 0,
            "VASBTMint: Already minted VAG1SBT"
        );
        require(
            vhighID.balanceOf(_msgSender()) == 0,
            "VASBTMint: Already minted VhighID"
        );

        uint256 vag1TokenId = tokenId;
        uint256 vhighIDTokenId = vhighID.totalSupply();
        vag1NFT.safeTransferFrom(_msgSender(), address(this), vag1TokenId);
        vag1SBT.mint(_msgSender(), vag1TokenId);
        vhighID.mint(_msgSender());

        if (refund > 0) {
            _refund(_msgSender(), refund);
        }

        emit Mint(_msgSender(), vhighIDTokenId, vag1TokenId, block.timestamp);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "VASBTMint: Transfer failed");
    }

    function _refund(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "VASBTMint: Refund failed");
    }
}