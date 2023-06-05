// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC1155} from "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract HKNFT is ERC1155, DefaultOperatorFilterer, Ownable  {
    string public name = "HKNFT";
    string public symbol = "HKNFT";
    string public contractURL;
    uint256 public price;
    uint256 public mintStarted;

    uint256 private currentTokenId;
    uint256 private maxSupply;
    string private baseURI;

    constructor(string memory _baseURI) ERC1155(string(abi.encodePacked(_baseURI, "{id}.json"))) {
        currentTokenId = 1;
        mintStarted = 0;
        maxSupply = 989;
        baseURI = _baseURI;
        price = 300000000000000000;
    }

    function setMintStarted(uint256 _started) public onlyOwner {
        mintStarted = _started;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Invalid price provided");
        price = _newPrice;
    }

    function setBaseUri(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(currentTokenId <= _maxSupply, "Invalid supply provided");
        maxSupply = _maxSupply;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId - 1;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(0 < _tokenId && _tokenId < currentTokenId, "NFT does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function airdrop(address[] calldata _list, uint256[] calldata _quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _list.length; i++) {
            for (uint256 j = 0; j < _quantity[i]; j++) {
                _mint(_list[i], currentTokenId, 1, "");
                currentTokenId++;
            }
        }
    }

    function mint(uint256 _quantity) 
        external 
        payable
    {
        require(mintStarted == 1, "Mint is not started");
        require(totalSupply() + _quantity <= maxSupply, "NFT is sold out");
        require(msg.value >= _quantity * price, "Not enough to pay for that");

        for (uint256 i = 0; i < _quantity; i++) {
            _mint(msg.sender, currentTokenId, 1, "");
            currentTokenId++;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}