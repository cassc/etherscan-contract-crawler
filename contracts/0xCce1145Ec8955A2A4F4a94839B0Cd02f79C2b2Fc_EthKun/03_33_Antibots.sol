// SPDX-License-Identifier: MIT
//
// [ @ _ @ ]
//
// Antibots by @eddietree

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AntibotRenderer.sol";

contract Antibots is BotRenderer, ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    constructor() ERC721("Antibots", "ANTIBOTS") {}

    bool public redeemEnabled = true;

    // original arbibots contract
    IERC721Enumerable public contractArbibots;
    bytes4 constant sigFunc_ownerOf = bytes4(keccak256("ownerOf(uint256)"));
    bytes4 constant sigFunc_balanceOf = bytes4(keccak256("balanceOf(address)"));
    bytes4 constant sigFunc_tokenOfOwnerByIndex = bytes4(keccak256("tokenOfOwnerByIndex(address,uint256)"));
    bytes4 constant sigVariable_seeds = bytes4(keccak256("seeds(uint256)")); // mapping(uint256 => uint256) public seeds;

    event AntibotRedeemed(uint256 indexed tokenId); // emitted when Antibot is redeemed
    event AntibotNinjaFlipped(uint256 indexed tokenId); // emitted when Antibot is flipped!

    function _ninjaFlip(uint256 tokenId) internal {
        require(_exists(tokenId), "Nonexistent token");

        flipped[tokenId] = !flipped[tokenId];
        emit AntibotNinjaFlipped(tokenId);
    }

    function ninjaFlip(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not yours homie.");
        _ninjaFlip(tokenId);
    }

    function ninjaFlipMany(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not yours homie.");
            _ninjaFlip(tokenId);
        }
    }

    function ninjaFlipAll() external {
        uint256 num = balanceOf(msg.sender);
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            _ninjaFlip(tokenId);
        }
    }

    function ninjaFlipAdmin(uint256 tokenId) external onlyOwner {
        _ninjaFlip(tokenId);
    }

    function _redeem(uint256 tokenId, address to) internal {
        require(!_exists(tokenId), "Already redeemed!");

        _mint(to, tokenId);
        seeds[tokenId] = fetchSeedForToken(tokenId);

        emit AntibotRedeemed(tokenId);
    }

    function redeemIndividual(uint256 tokenId) external {
        require(msg.sender == fetchOwnerOfArbibot(tokenId), "Not yours homie.");
        require(redeemEnabled, "Not enabled!");
        _redeem(tokenId, msg.sender);
    }

    // redeem all 
    function redeem() external {
        require(redeemEnabled, "Not enabled!");

        uint256 num = fetchNumArbibotsOwnedBy(msg.sender);
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = fetchArbibotTokenOfOwnerByIndex(msg.sender, i);

            // only redeem if it hasnt been redeemed yet
            if (!_exists(tokenId))
                _redeem(tokenId, msg.sender);
        }
    }

    function redeemMany(uint256[] calldata tokenIds) external {
        require(redeemEnabled, "Not enabled!");

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == fetchOwnerOfArbibot(tokenId), "Not yours homie.");
            _redeem(tokenId, msg.sender);
        }
    }

    // returns array of redeemable tokenIds and count of redeemable tokens
    // note: count can be less than memory.length
    function getAllRedeemableTokens() external view returns (uint256[] memory, uint count) {

        uint256 num = fetchNumArbibotsOwnedBy(msg.sender);
        uint256[] memory redeemableTokens = new uint256[](num);

        count = 0;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = fetchArbibotTokenOfOwnerByIndex(msg.sender, i);

            // only redeem if it hasnt been redeemed yet
            if (!_exists(tokenId)) {
                redeemableTokens[count] = tokenId;
                count++;
            }
        }

        return (redeemableTokens, count);
    }

    /*function adminRedeem(uint256 tokenId) external onlyOwner { // for testing
        _redeem(tokenId, msg.sender);
    }

    function adminRedeemMany(uint256[] calldata tokenIds) external { // for testing
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _redeem(tokenId, msg.sender);
        }
    }*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _render(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRedeemEnabled(bool newEnabled) external onlyOwner {
        redeemEnabled = newEnabled;
    }

    function setContractArbibots(address newAddress) external onlyOwner {
        contractArbibots = IERC721Enumerable(newAddress);
    }

    function fetchSeedForToken(uint256 tokenId) internal returns (uint256) { 
        if (address(contractArbibots) == address(0)) {
            return tokenId;
        }

        bytes memory data = abi.encodeWithSelector(sigVariable_seeds, tokenId);
        (bool success, bytes memory returnedData) = address(contractArbibots).call(data);
        require(success);

        uint256 seed = abi.decode(returnedData, (uint256));
        return seed;
    }

    function fetchOwnerOfArbibot(uint256 arbibotTokenId) public view returns (address) {
        if (address(contractArbibots) == address(0)) {
            return address(0);
        }

        return contractArbibots.ownerOf(arbibotTokenId);
    }

    function fetchNumArbibotsOwnedBy(address from) public view returns (uint256) {
        if (address(contractArbibots) == address(0)) {
            return 0;
        }

        return contractArbibots.balanceOf(from);
    }

    function fetchArbibotTokenOfOwnerByIndex(address from, uint256 index) public view returns (uint256) {
        if (address(contractArbibots) == address(0)) {
            return 0;
        }

        return contractArbibots.tokenOfOwnerByIndex(from, index);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}