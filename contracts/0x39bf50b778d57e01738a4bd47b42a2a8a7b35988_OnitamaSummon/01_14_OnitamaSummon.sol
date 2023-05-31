//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./AbstractERC1155Factory.sol";

/*
 * @title ERC1155 token for OnitamaSummon
 * @author WayneHong @ Norika
 */

abstract contract OnitamaNFT is IERC721 {

}

contract OnitamaSummon is AbstractERC1155Factory {
    using Strings for uint256;

    uint256 public COMBINE_TOKEN_0_REQUIRED = 10;
    mapping(uint256 => bool) isNFTCombined;
    OnitamaNFT nft;

    event UpgradeOnitama(uint256 tokenId, uint256 id);

    constructor(address onitamaAddr)
        ERC1155Oni("ipfs://QmUSUcPuK5HCydyKt3gbE3ceqkHz1SwFrJNAgw5eWkFhoW/")
    {
        name_ = "Onitama Summon";
        symbol_ = "ONIS";
        nft = OnitamaNFT(onitamaAddr);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    function mintForAirdrop(
        address[] memory addresses,
        uint256 id,
        uint256[] memory amounts
    ) external onlyOwner {
        _airdrop(addresses, id, amounts);
    }

    function isAbleToCombineTokens(address addr, uint256 generateAmount)
        public
        view
        returns (bool)
    {
        uint256 tokenBalance = balanceOf(addr, 0);
        return
            generateAmount > 0 &&
            tokenBalance >= (COMBINE_TOKEN_0_REQUIRED * generateAmount);
    }

    function combineTokens(uint256 generateAmount) external callerIsUser {
        require(generateAmount > 0, "Require at least 1");
        require(
            isAbleToCombineTokens(msg.sender, generateAmount),
            "Cannot combine tokens"
        );

        _burn(msg.sender, 0, generateAmount * COMBINE_TOKEN_0_REQUIRED);
        _mint(msg.sender, 1, generateAmount, "");
    }

    function burnForCombineNFT(uint256 id, uint256 tokenId)
        external
        callerIsUser
    {
        require(balanceOf(msg.sender, id) > 0, "Require at least 1");
        require(nft.ownerOf(tokenId) == msg.sender, "Not the Onitama owner");
        require(isNFTCombined[tokenId] == false, "This Onitama is upgraded");

        _burn(msg.sender, id, 1);
        isNFTCombined[tokenId] = true;
        emit UpgradeOnitama(tokenId, id);
    }
}