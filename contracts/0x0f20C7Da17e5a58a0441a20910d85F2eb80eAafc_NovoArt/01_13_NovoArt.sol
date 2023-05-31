// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NovoArt is ERC1155Supply, Ownable {
        
    uint256 private mintedTokens;
    uint256 private startingIndex;
    uint8[] private TOKEN_IDS = [67, 21, 24, 23, 64, 34, 17, 12, 11, 48, 52, 44, 65, 16, 40, 41, 51, 71, 39, 34, 40, 54, 65, 52, 24, 17, 33, 29, 52, 45, 30, 23, 42, 10, 51, 69, 23, 14, 41, 53, 21, 18, 64, 59, 60, 60, 22, 63, 40, 19, 68, 25, 28, 56, 18, 12, 14, 52, 11, 11, 40, 21, 65, 51, 40, 66, 41, 14, 62, 18, 38, 33, 43, 63, 11, 45, 39, 63, 42, 41, 2, 10, 18, 68, 42, 49, 2, 38, 2, 35, 65, 65, 65, 24, 3, 52, 51, 54, 56, 48, 33, 52, 54, 35, 46, 48, 59, 4, 56, 54, 59, 34, 46, 42, 21, 19, 19, 54, 64, 33, 32, 27, 14, 19, 52, 51, 36, 22, 11, 14, 5, 46, 60, 56, 28, 39, 3, 56, 11, 3, 36, 51, 69, 38, 71, 49, 30, 12, 26, 37, 25, 64, 38, 23, 44, 11, 65, 40, 68, 54, 33, 11, 63, 42, 45, 51, 36, 54, 38, 33, 17, 61, 13, 71, 6, 4, 34, 51, 36, 38, 56, 63, 33, 65, 24, 68, 15, 20, 21, 40, 24, 51, 64, 71, 17, 43, 3, 19, 36, 54, 21, 63, 64, 56, 47, 45, 21, 63, 71, 11, 18, 40, 14, 29, 28, 42, 14, 33, 47, 66, 11, 51, 49, 34, 51, 52, 14, 11, 20, 22, 42, 60, 63, 64, 56, 42, 68, 21, 64, 27, 33, 44, 27, 38, 58, 71, 39, 29, 69, 28, 63, 12, 49, 38, 12, 69, 52, 54, 54, 14, 69, 33, 66, 28, 21, 48, 14, 33, 42, 66, 51, 2, 12, 55, 27, 54, 6, 63, 64, 2, 25, 68, 19, 14, 22, 2, 29, 14, 17, 68, 35, 64, 11, 14, 66, 68, 30, 52, 2, 12, 27, 51, 39, 65, 52, 12, 38, 21, 33, 59, 36, 63, 11, 54, 64, 65, 57, 41, 23, 40, 42, 12, 28, 44, 65, 33, 19, 63, 52, 11, 60, 54, 62, 45, 38, 22, 17, 12, 64, 14, 39, 33, 3, 28, 64, 51, 14, 38, 21, 63, 21, 11, 14, 47, 19, 11, 46, 54, 41, 64, 1, 33, 25, 64, 33, 33, 24, 59, 20, 3, 44, 42, 51, 63, 21, 24, 46, 48, 46, 33, 64, 35, 52, 12, 33, 51, 12, 68, 52, 70, 12, 20, 46, 63, 42, 46, 2, 6, 54, 38, 36, 51, 51, 51, 33, 42, 35, 66, 18, 56, 63, 14, 48, 14, 51, 14, 33, 14, 10, 26, 12, 14, 21, 47, 38, 21, 56, 24, 51, 65, 24, 57, 14, 56, 12, 10, 33, 44, 17, 14, 2, 56, 17, 55, 65, 19, 48, 64, 51, 42, 65, 14, 14, 21, 60, 12, 53, 63, 14, 11, 34, 42, 33, 38, 19, 14, 40, 33, 68, 21, 12, 40, 36, 12, 29, 22, 54, 11, 21, 44, 66, 54, 19, 26, 68, 12, 17, 6, 43, 33, 3, 22, 64, 15, 59, 40, 11, 48, 18, 48, 69, 40, 21, 56, 25, 65, 3, 33, 52, 24, 24, 42, 21, 68, 42, 51, 21, 64, 33, 16, 63, 52, 69, 56, 21, 14, 2, 16, 71, 56, 42, 33, 11, 10, 51, 64, 33, 46, 45, 44, 21, 68, 2, 15, 56, 20, 42, 2, 46, 45, 64, 64, 14, 63, 27, 21, 48, 14, 24, 58, 17, 44, 64, 52, 53, 48, 58, 64, 2, 63, 66, 70, 68, 42, 46, 14, 14, 48, 19, 49, 68, 28, 52, 11, 14, 56, 11, 54, 23, 64, 68, 3, 26, 42, 38, 2, 22, 3, 21, 20, 65, 40, 57, 12, 44, 36, 17, 52, 21, 42, 4, 29, 42, 64, 26, 41, 23, 48, 38, 65, 46, 21, 3, 45, 33, 15, 12, 42, 56, 12, 14, 61, 2, 16, 48, 63, 40, 54, 39, 43, 51, 70, 41, 52, 20, 14, 16, 18, 52, 16, 46, 34, 56, 14, 29, 21, 52, 11, 65, 58, 63, 4, 25, 12, 17, 11, 59, 12, 66, 52, 10, 33, 66, 33, 54, 11, 59, 65, 14, 56, 22, 51, 52, 27, 51, 17, 52, 65, 13, 10, 27, 52, 54, 59, 33, 56, 52, 19, 65, 11, 2, 64, 52, 25, 25, 40, 18, 60, 21, 42, 53, 21, 40, 33, 34, 51, 40, 48, 65, 25, 23, 48, 38, 47, 22, 66, 68, 55, 25, 18, 68, 14, 40, 52, 60, 62, 52, 71, 3, 68, 69, 24, 54, 4, 21, 42, 27, 58, 54, 51, 68, 68, 19, 3, 10, 12, 33, 11, 54, 11, 25, 42, 21, 12, 68, 69, 21, 12, 51, 64, 33, 15, 36, 51, 64, 29, 54, 40, 66, 46, 18, 40, 21, 51, 41, 17, 16, 3, 48, 12, 8, 46, 63, 46, 2, 12, 52, 21, 33, 65, 36, 23, 16, 25, 51, 19, 11, 51, 11, 63, 23, 36, 4, 36, 52, 52, 66, 66, 65, 21, 51, 42, 27, 39, 60, 44, 12, 21, 63, 19, 5, 25, 42, 42, 19, 71, 38, 65, 33, 71, 68, 42, 44, 51, 11, 25, 39, 52, 66, 12, 18, 33, 11, 46, 64, 45, 2, 48, 44, 25, 11, 11, 62, 12, 6, 65, 70, 52, 40, 14, 53, 24, 29, 4, 52, 12, 36, 42, 63, 12, 68, 19, 38, 66, 11, 18, 12, 4, 7, 68, 46, 3, 66, 33, 63, 12, 13, 24, 63, 56, 29, 19, 17, 10, 59, 18, 56, 34, 5, 26, 2, 44, 40, 54, 62, 45, 66, 64, 64, 36, 33, 26, 21, 11, 10, 44, 38, 52, 2, 16, 33, 12, 11, 64, 11, 20, 42, 48, 33, 42, 69, 65, 54, 51, 61, 4, 65, 65, 28, 65, 34, 19, 66, 41, 56, 52, 64, 12, 21, 14, 40, 51, 20, 54, 51, 12, 12, 26, 51, 21, 28, 9, 66, 70, 26, 11, 60, 46, 54, 42, 52, 20, 4, 26, 43, 18, 39, 63, 63, 48, 16, 46, 40, 33, 64, 56, 33, 54, 52, 11];
    uint constant MAX_TOKENS = 1000;
    uint constant BURN_ID = 1;
    uint public constant MAX_PURCHASE = 21; // set 1 to high to avoid some gas
    bool public saleIsActive;
    address public exchangeToken = 0x720AF3838D32F3b9eDD72C64Dc2b06d0a07D281C; 
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC1155("ipfs://QmScbnmSFPRdPtF7eJdKvUHzbA1QNBL4vEiZZfWK8Lf6vo/") { 
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    /**
     * @dev airdrop a specific token to a list of addresses, no burn needed
     */
    function airdrop(address[] calldata addresses) public onlyOwner{
        require(mintedTokens + 1 <= MAX_TOKENS, "Would exceed max supply of tokens!");
        unchecked {
            for (uint i=0; i < addresses.length;) {
                _mint(addresses[i], TOKEN_IDS[getCorrectedId(mintedTokens)], 1, "");
                mintedTokens++;
                i++;
            }
        }
    }

    /**
     * Exchange your tokens here. note that you NEED to set an opproval for all on the burn token first!
     */
    function exchange(uint256 numberOfTokens) external returns(uint256[] memory){
        require(saleIsActive,"Exchange NOT active yet");
        require(mintedTokens + numberOfTokens <= MAX_TOKENS, "Would exceed max supply of tokens!");
        require(numberOfTokens < MAX_PURCHASE, "Can only exchange 25 tokens at a time");
        require(msg.sender == tx.origin, "No Contracts allowed.");
        uint256[] memory result = new uint256[](numberOfTokens);
        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                uint256 token = getCorrectedId(mintedTokens);
                _mint(msg.sender, TOKEN_IDS[token], 1, "");
                result[i]=token;
                mintedTokens++;
                i++;
            }
        }
        ERC1155(exchangeToken).safeTransferFrom(msg.sender,DEAD,BURN_ID,numberOfTokens,"");
        return result;
    }

    function getCorrectedId(uint256 id) private view returns (uint256) {
        return (id+startingIndex)%MAX_TOKENS;
    }

    function name() public pure returns (string memory) {
        return "NovoArt";
    }

    function symbol() public pure returns (string memory) {
        return "NART";
    }

        /**    
    * Set mintPass contract address
    */
    function setExchangeToken(address newAddress) external onlyOwner {
         exchangeToken = newAddress;
    }
    
    /**
    *  @dev set token base uri
    */
    function setURI(string memory baseURI) public onlyOwner {
        _setURI(baseURI);
    }
     
    /**
     * @dev removing the token substituion and replacing it with the implementation of the ERC721
     */
    function uri(uint256 token) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(token);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(token))) : "";
    }
        /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");
        startingIndex = uint(blockhash(block.number - 1)) % MAX_TOKENS;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = 37;
        }
    }
    /**
     * @dev Gets the total amount of existing tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function mintedSupply() public view virtual returns (uint256) {
        return mintedTokens;
    }
}