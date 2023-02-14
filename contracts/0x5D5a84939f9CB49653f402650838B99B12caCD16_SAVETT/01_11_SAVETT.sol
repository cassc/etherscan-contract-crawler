// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "./OperatorFilter/DefaultOperatorFilterer.sol";
import '@openzeppelin/contracts/access/Ownable.sol'; 
import "@openzeppelin/contracts/utils/Strings.sol";                                                
                 
contract SAVETT is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    // Constants
    uint256 public constant MAX_TOKEN_CNT = 6969;
    // Maximum amount for the team
    uint256 public constant MAX_TEAM_TOKENS = 50;
    // Max mint per wallet
    uint256 public constant MAX_CAP_PER_WALLET = 5;
    // Price - TBA
    uint256 public _price = 0 ether;
    // Team mint counter
    uint256 public _teamMinted = 0;
    // Base token URI
    string public _baseTokenURI;
    // Mint date (unix epoch time)
    uint256 public _mintStartTS;
    // Keep track of minted per wallet
    mapping(address => uint256) public _mintedPerWallet;
    // Common placeholder for non-revealed assets
    string private _nonRevealedURI;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    /**
     *  @notice Minting function for the team
     *
     *  @param amount - Amount to mint
     */
    function teamMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_TOKEN_CNT, "Sold out");
        require(_teamMinted + amount <= MAX_TEAM_TOKENS, "Team allocation gone");
        // Mint amount
        _mint(msg.sender, amount);
        _teamMinted += amount;
    }

    /**
     *  @notice Public minting function
     *
     *  @param amount - Amount to mint
     */
    function publicMint(uint256 amount) external payable {
        require(_mintStartTS != 0, "Mint start not set");
        require(block.timestamp >= _mintStartTS, "Minting is not open");
        require(totalSupply() + amount <= MAX_TOKEN_CNT, "Cannot run over the max cap");
        require(_mintedPerWallet[msg.sender] + amount <= MAX_CAP_PER_WALLET, "One address cannot mint that many");
        require(msg.value == (_price * amount), "Invalid amount sent");

        _mintedPerWallet[msg.sender] += amount;

        // Mint amount
        _mint(msg.sender, amount);
    }

    /**
     *  @notice Check if minting is open - helper for FE
     *
     */
    function isPublicMintStarted() external view returns(bool) {
        if(
            _mintStartTS == 0 
            || 
            (_mintStartTS != 0 && block.timestamp < _mintStartTS) 
            ) 
        {
            return false;
        }
        return true;
    }

    /**
     *  @notice Checking function if user whether user can mint or not (allocation, etc.) - helper for FE
     *
     *  @param amount - Amount to mint
     *  @param user - User who wants to mint
     */
    function checkIfUserCanMint(uint256 amount, address user) external view returns(bool result) {

        uint256 mintedCnt = _mintedPerWallet[user]; 

        if(
            totalSupply() + amount <= MAX_TOKEN_CNT 
            && 
            mintedCnt + amount <= MAX_CAP_PER_WALLET
        ) 
        {
            result = true;
        }

    }

    /**
     *  @notice Set baseURI
     *
     *  @param baseURI - New base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     *  @notice Set non-revealed URI
     *
     *  @param nonRevealedURI - New non-revealed URI
     */
    function setNonRevealedURI(string memory nonRevealedURI) external onlyOwner {
        _nonRevealedURI = nonRevealedURI;
    }

    /**
     *  @notice Set mint related data
     *
     *  @param mintStartTS - TS of mint start
     *  @param price - Price
     *  @param nonRevealedURI - nonRevealedURI
     */
    function setMintStructure(uint256 mintStartTS, uint256 price, string memory nonRevealedURI) external onlyOwner {
        _mintStartTS = mintStartTS;
        _price = price;
        _nonRevealedURI = nonRevealedURI;
    }

    /**
     *  @notice Withdraw funds from contract
     *
     *  @param amount - Withdraw amount
     *  @param ww - Withdraw wallet
     */
    function withdraw(uint256 amount, address ww) external onlyOwner {
        (bool success, ) = ww.call{value:amount}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev ERC721A Override - to include a common _nonRevealedURI
     *
     * @param tokenId - TokenID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721B: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : _nonRevealedURI;
    }

    /**
     *  @notice Return uri of tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     *  @notice DefaultOperatorFilterer overrides - to enforce OS royalties
     */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}