// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// Contract imports

import "./ERC721A.sol";
import "./OperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Contract Constructor Variables

contract CanStyleClub is ERC721A, Ownable, ERC2981, ReentrancyGuard, OperatorFilterer {

    uint256 public cost = 0.0083 ether;
    uint256 public maxSupply = 10000;
    uint256 public MaxMintPerTransaction = 10;
    uint256 public FreeGivingAmount = 777;
    uint256 public MaxPerWallet = 100;
    uint256 public FreeAmount = 1;

    string public baseURI;
    string public baseExtension = ".json";

    bool public mintIsActive = false;
    bool public operatorFilteringEnabled = true;
  
    // Constructor Variables

    constructor(
        string memory _initBaseURI,
        address _artist
    ) ERC721A ("Can Style Club", "CSC") {
        setBaseURI(_initBaseURI);
        setDefaultRoyalty(_artist, 500);
        _registerForOperatorFiltering();
    }

    // Mint functions
    /**
     * @notice Mint quantity must be 1 or greater.
     * 'numberOfTokens' the number of tokens to claim in transaction.
     */

    function mint(uint numberOfTokens) public payable {

        uint256 supply = totalSupply();

            // Mint functions requirements

            require(supply < maxSupply, "Currently sold out");
            require(mintIsActive, "Sale must be active to mint tokens");
            require(supply + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");

        uint256 totalNumberMinted = _numberMinted(msg.sender);

            require(numberOfTokens <= MaxMintPerTransaction, "Purchase would exceed max per transaction");
            require(totalNumberMinted + numberOfTokens <= MaxPerWallet, "Purchase would exceed max per wallet");

            if (supply >= FreeGivingAmount) {
            // Changing mint cost for all tokens when supply exceeds FreeGivingAmount
            require(msg.value == numberOfTokens * cost, "Didn't send enough ETH");

                } else {

            // Changing mint cost for tokens excluding the free mints
            require(msg.value == (numberOfTokens - FreeAmount) * cost, "Didn't send enough ETH");
            }

        _mint(msg.sender, numberOfTokens);
    }

    // Set metadata link for tokenid

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    // System Contract Functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Operations Override functions

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
            ) public view virtual override (ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // Safe Transfer From functions 

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Operator Filter Registry    

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // Owner functions

    function reserve(uint256 numberForMint) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply < maxSupply, "Currently sold out");
        require(supply + numberForMint <= maxSupply, "Mint would exceed max tokens");
        _safeMint(msg.sender, numberForMint);
    }

    function airdrop(address airAddress, uint256 numberForMint) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply < maxSupply, "Currently sold out");
        require(supply + numberForMint <= maxSupply, "Airdrop would exceed max tokens");
        _safeMint(airAddress, numberForMint);
    }

    function setMaxMintPerTransaction(uint256 _MaxMintlimit) public onlyOwner {
        require(MaxMintPerTransaction != _MaxMintlimit, "New MaxMintlimit is the same as the existing one");
        MaxMintPerTransaction = _MaxMintlimit;
    }

    function setMaxPerWallet(uint256 _MaxPerWalletlimit) public onlyOwner {
        require(MaxPerWallet != _MaxPerWalletlimit, "New MaxPerWalletlimit is the same as the existing one");
        MaxPerWallet = _MaxPerWalletlimit;
    }

    function setMintFee(uint256 _mintFee) public onlyOwner {
        require(_mintFee > 0, "The cost of minting a token should be greater than 0");
        cost = _mintFee;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMintIsActive(bool newState) public onlyOwner {
        mintIsActive = newState;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFreeAmount(uint256 newAmountFree) public onlyOwner {
        FreeAmount = newAmountFree;
    }

    function setFreeGivingAmount(uint256 newFreeGivingAmount) public onlyOwner {
        FreeGivingAmount = newFreeGivingAmount;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }
}