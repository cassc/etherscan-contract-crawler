// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";


contract NFT is ERC721Enumerable, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    string private baseURI;
    uint256 public maxSupply = 8500;
    bool public paused = false;
    uint256 public maxMintPerAccount = 3;
    uint256 public reservedSupplyLimit = 250;
    uint256 public reservedSupplyMinted = 0;

    mapping(address => uint256) public mintsPerAccount;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        _setDefaultRoyalty(owner(), 700);
        _safeMint(msg.sender, reservedSupplyLimit+1);
        _safeMint(
            0x279a8aB00906E2C1AA3C7b7c88b4F04E158D9d7d,
            reservedSupplyLimit + 2
        );

        //  for (uint i=3; i<53 ; i++){

        //     _safeMint(msg.sender, i);

        //  }
    }




function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }




    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyaltyPercentage(uint96 _percentage) public onlyOwner {
        require(
            _percentage >= 0 && _percentage <= 100,
            "Royalty percentage should be between 0 and 100"
        );
        _setDefaultRoyalty(owner(), _percentage * 100);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _amount) public {

        uint256 supply = totalSupply() + reservedSupplyLimit- reservedSupplyMinted;

        require(supply + _amount <= maxSupply, "Max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(
                mintsPerAccount[msg.sender] + _amount <= maxMintPerAccount,
                "Maximum mint per wallet limit exceeded"
            );

            mintsPerAccount[msg.sender] += _amount;

        } 

        
            for (uint256 i = 1; i <= _amount; i++) {
                uint256 tokenId = supply + i;
                _safeMint(msg.sender, tokenId);
            }
    }


        function mintReserved(uint256 _amount) onlyOwner public {
        
    
            uint256 reserveMinted = reservedSupplyMinted;

            require(
                reserveMinted + _amount <= reservedSupplyLimit,
                "Amount exceeded reserved supply"
            );

            reservedSupplyMinted+= _amount;

            for (uint256 i = 1; i <= _amount; i++) {
                uint256 tokenId = reserveMinted + i;
                _safeMint(msg.sender, tokenId);
            }

        
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    // function getCost() public view returns (uint256) {
    //     return cost;
    // }

    // function setFreeSupplyLimit(uint256 _freeSupplyLimit) public onlyOwner {
    //     require(
    //         _freeSupplyLimit >= maxSupply,
    //         "Free supply limit should be less than or equal to the max supply"
    //     );
    //     freeSupplyLimit = _freeSupplyLimit;
    // }

    // function setCost(uint256 _newCost) public onlyOwner {
    //     cost = _newCost;
    // }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawableAmount() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}