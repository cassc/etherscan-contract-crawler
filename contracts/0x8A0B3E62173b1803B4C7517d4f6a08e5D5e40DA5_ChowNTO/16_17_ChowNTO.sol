// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.17;

import "./ERC721EnumerableEx.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ChowNTO is Ownable, ERC721Enumerable, ERC721EnumerableEx {
    using SafeMath for uint256;

    // Randomizer nonce
    uint256 internal nonce = 0;

    // Maximum total supply
    uint256 public constant MAX_TOKENS = 130000;

    uint256[MAX_TOKENS] internal indices;
 
    // Total supply of each stage
    mapping(uint8 => uint256) public stageSupplies;

    mapping(address => bool) internal admins;
  
   // Current amount minted
    uint256 public numTokens;
 
    // Is token minting enabled (can be disabled by admin)
    bool public mintEnabled; 
 
    // Base metadata url (can be changed by owner)
    string public baseUrl = "https://nto.choise.com/choby/api"; 

    modifier onlyAdmin() {
      require(admins[msg.sender], "Caller is not admin");
      _;
    }
 
    constructor() ERC721("Chobies NTO Collection", "Choby") { 
      mintEnabled = true;
      admins[msg.sender] = true;
    }

    ///
    /// Internal functions
    ///

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }
 
    function randomIndex() internal returns (uint256) {
        uint256 totalSize = MAX_TOKENS - numTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    function _internalMint(address to, uint8 _stage) internal returns (uint256) {
        require(numTokens < MAX_TOKENS, "Token limit");

        //Get random token
        uint256 id = randomIndex();
        //Change total token amount
        numTokens++;

        //Change supply of stage
        stageSupplies[_stage]++; 
 
        //Mint token
        _mint(to, id);
        return id;
    }

    function _doMint(uint256 _amount, address _to, uint8 _stage) internal returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 tokenId;
        for (uint8 i = 0; i < _amount; i++) {
            tokenId = _internalMint(_to, _stage);
            tokenIds[i] = (tokenId);
        }
        return tokenIds;
    }

    ///
    /// Public functions
    ///

    /*
     * @dev Airdrop selected amount of tokens from the collection
     * @param _to
     * @param _amount
     * @param _stage minting stage
    */
    function airdrop(address _to, uint256 _amount, uint8 _stage) public onlyAdmin returns(uint256[] memory) {
        require(mintEnabled, "Minting disabled");
        require(_to != address(0), "Cannot mint to empty");
        require(_amount <= 20, "Maximum 20 tokens per mint");
        require(_stage >= 1 && _stage <= 6, "Unsupported stage"); 
        
        uint256[] memory tokenIds = _doMint(_amount, _to, _stage);
        return tokenIds;        
    }

    function getStageSupplies(uint8 _stage) public view returns(uint256) {
        return stageSupplies[_stage];
    }

    ///
    /// Admin functions
    ///

    /*
    *  @dev Enable or disable minting
    * @param _status bool minting status
    */
    function setMintingStatus(bool _status) public onlyOwner {
        mintEnabled = _status;
    }

    /*
     * Update base url
     */
    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    function addAdmin(address _admin) public onlyOwner {
      admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
      admins[_admin] = false;
    }
 
    function isAdmin(address _acount) public view returns(bool) {
      return admins[_acount];
    }
 
    ///
    /// Fallback function
    ///

    /*
     * Fallback to mint
     */
    fallback() external payable {
        revert();
    }

    /*
     * Fallback to mint
     */
    receive() external payable {
        revert();
    }

    ///
    /// Overrides
    ///
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }
}