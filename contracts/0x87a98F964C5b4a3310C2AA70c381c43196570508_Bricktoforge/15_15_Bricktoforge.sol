// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Bricktoforge is Ownable {
    bool public isActive = false;
    address private immutable _bricktopiansAddress;
    uint256[] private tokens;

    mapping(uint256 => uint256) public tokenPairs;
    address private immutable _self;

    constructor(address bricktopiansAddress) {
        require(bricktopiansAddress != address(0), "Bricktoforge: Invalid address");
        _bricktopiansAddress = bricktopiansAddress;
        _self = address(this);
    }

    function forge(uint256 burnTokenId, uint256 upgradeTokenId)
        external
    {
        require(isActive, "forge: The forge is not active");
        require(burnTokenId != upgradeTokenId, "forge: Cannot forge the same token");
        
        require(
            IERC721(_bricktopiansAddress).ownerOf(upgradeTokenId) == _msgSender(),
            "forge: Sender must be the owner of the upgrade token"
        );

        tokenPairs[burnTokenId] = upgradeTokenId;
        IERC721(_bricktopiansAddress).safeTransferFrom(_msgSender(), _self, burnTokenId);

        emit Forged(_msgSender(), burnTokenId, upgradeTokenId);
    }

    function transfer(
        uint256 tokenId,
        address to
    ) external onlyOwner() {
        require(isActive, "transfer: The forge is not active");
        IERC721(_bricktopiansAddress).safeTransferFrom(_self, to, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "tokensOfOwner: Invalid address");
        uint256 tokenCount = IERC721(_bricktopiansAddress).balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;
        for (index = 0; index < tokenCount; index++) {
            result[index] = ERC721Enumerable(_bricktopiansAddress)
                .tokenOfOwnerByIndex(owner, index);
        }
            
        return result;
    }

    function burn(uint256 tokenId) external onlyOwner {
        ERC721Burnable(_bricktopiansAddress).burn(tokenId);
    }

    function burnTokens(uint256 start, uint256 length) external onlyOwner {        
        tokens = this.tokensOfOwner(_self);
        assert(start+length <= tokens.length);

        for (uint256 i = start; i < length; i++) {
            ERC721Burnable(_bricktopiansAddress).burn(tokens[i]);
        }
    }

    function toggleIsActive() external onlyOwner {
        isActive = !isActive;

        emit Activated(isActive);
    }

    event Forged(address indexed from, uint256 burnTokenId, uint256 upgradeTokenId);
    event Activated(bool isActive);
}