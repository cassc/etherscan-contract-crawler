// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "ERC721.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";
import {Ownable} from "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "ERC2981.sol";

/**
 * @title  ExampleERC721
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
 */
contract ColandNFTExclusiveCollection is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;

    string private baseURI;
    using Counters for Counters.Counter;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    string public baseExtension = ".json";
    bool public special_mint_status = false;
    bool public public_mint_status = false;
    string public notRevealedUri;
    bool public revealed = false;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public max_Normal = 9975;
    uint256 public max_special_limit = 25;
    uint256 public publicSaleCost = 0.1 ether;
    uint256 public max_per_wallet = 10000;
    uint256 public max_per_txn = 10000; 

    uint256 public specialPrice = 2.75 ether;
    uint256 public specialTotalSupply;
    uint256 public currentMintingSpecialID = 9975;

    string public contractURI;
    
    Counters.Counter private _tokenIdCounter;
    uint256 public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri

    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);   
        setRoyaltyInfo(owner(),0);
        mint(1);
    }

    function mint(uint256 _mintAmount) public payable {

        require(totalSupply + _mintAmount <= MAX_SUPPLY,"Maximum supply exceeds");

            if (msg.sender != owner()) {

                require(public_mint_status, "Public mint not available");
                require(_mintAmount + balanceOf(msg.sender) <= max_per_wallet,"Max per wallet exceeds");
                require( _mintAmount <= max_per_txn, "Per txn Limit Reached");
                require(msg.value >= (publicSaleCost * _mintAmount), "Not Enough ETH Sent");  

            }

        for (uint256 i = 1; i <= _mintAmount; i++) {

            if (_tokenIdCounter.current() < max_Normal) {
                
                if (!_exists(_tokenIdCounter.current())) {
                    _safeMint(msg.sender, _tokenIdCounter.current());
                    _tokenIdCounter.increment();
                    totalSupply++;

                } else {

                    _tokenIdCounter.increment();
                    _safeMint(msg.sender, _tokenIdCounter.current());
                    _tokenIdCounter.increment();
                    totalSupply++;

                }


            }

        }


    }

    function mintSpecial(uint256 _mintAmount) public payable {

        require(special_mint_status, "Contract is paused");
        require(totalSupply + _mintAmount <= MAX_SUPPLY,"Maximum supply exceeds");
        require(_mintAmount + balanceOf(msg.sender) <= max_per_wallet,"Max per wallet exceeds");
        require(specialTotalSupply + _mintAmount <= max_special_limit, "Number of special tokens are lesser than the requested");
        require( _mintAmount <= max_per_txn, "Per txn Limit Reached");


        if (msg.sender != owner()) {
            require(msg.value >= specialPrice * _mintAmount);
        }

    for (uint256 i = 1; i <= _mintAmount; i++) {

        if(currentMintingSpecialID >= max_Normal && currentMintingSpecialID <= MAX_SUPPLY - 1){

             totalSupply++;
             specialTotalSupply++;
             _safeMint(msg.sender, currentMintingSpecialID);
             currentMintingSpecialID++;
             
        }
    }

    }

       
    function withdraw() public payable onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPublic_mint_status(bool _public_mint_status) public onlyOwner {
        public_mint_status = _public_mint_status;
    }

    function setSpecial_mint_status(bool _special_mint_status) public onlyOwner {
        special_mint_status = _special_mint_status;
    }

    function toggleReveal() public onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setSpecialPrice(uint256 _specialPrice) public onlyOwner {
        specialPrice = _specialPrice;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMax_special_limit(uint256 _max_special_limit) public onlyOwner {
        max_special_limit = _max_special_limit;
    }

    function setMax_Normal(uint256 _max_Normal) public onlyOwner {
        max_Normal = _max_Normal;
    }

    function setCurrentMintingSpecialID(uint256 _currentMintingSpecialID) public onlyOwner {
        currentMintingSpecialID = _currentMintingSpecialID;
    }

    function setMax_per_txn(uint256 _max_per_txn) public onlyOwner {
        max_per_txn = _max_per_txn;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }
    
    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}
