// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMetadata.sol";

//
//  _____ _____ _____ _____ _____
// |     |  _  |  |  |   __|   __|
// |   --|     |  |  |__   |   __|
// |_____|__|__|_____|_____|_____|
//
//
//  @creator: Pak
//  @author: NFT Studios

contract Cause is ERC1155Supply, ERC1155Burnable, Ownable {
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    using Strings for uint256;

    mapping(uint256 => bool) public enabledTokens;
    mapping(uint256 => uint256) public pricePerToken;
    mapping(uint256 => bool) public isTokenTransferrable;

    IMetadata metadataContract;

    constructor() ERC1155("") {}

    function withdraw(address _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    function setMetadataContract(address _address) external onlyOwner {
        metadataContract = IMetadata(_address);
    }

    function enableToken(uint256 _tokenId, uint256 _price) external onlyOwner {
        enabledTokens[_tokenId] = true;
        pricePerToken[_tokenId] = _price;
    }

    function disableToken(uint256 _tokenId) external onlyOwner {
        enabledTokens[_tokenId] = false;
    }

    function enableTokenTransfer(uint256 _tokenId) external onlyOwner {
        isTokenTransferrable[_tokenId] = true;
    }

    function disableTokenTransfer(uint256 _tokenId) external onlyOwner {
        isTokenTransferrable[_tokenId] = false;
    }

    function mint(uint256 _tokenId, uint256 _quantity) external payable {
        require(
            enabledTokens[_tokenId],
            "The given token ID can not be minted"
        );

        require(
            msg.value >= pricePerToken[_tokenId] * _quantity,
            "Not enough ether sent to mint"
        );

        _mint(msg.sender, _tokenId, _quantity, "");
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return metadataContract.getTokenURI(_tokenId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        for (uint256 i; i < ids.length; i++) {
            require(
                from == address(0) || isTokenTransferrable[ids[i]],
                "This token can not be transferred at this time"
            );
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (to == DEAD_ADDRESS || to == NULL_ADDRESS) {
            burn(from, id, amount);

            return;
        }

        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (to == DEAD_ADDRESS || to == NULL_ADDRESS) {
            burnBatch(from, ids, amounts);

            return;
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}