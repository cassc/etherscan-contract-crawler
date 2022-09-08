// SPDX-License-Identifier: Unlicensed
// 
pragma solidity ^0.8.9;

import "./ERC721EnumerableEx.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GreenOcean  is Ownable, ERC721Burnable, ERC721EnumerableEx {
    using SafeMath for uint256;

    //Maximum total supply
    uint256 public constant MAX_TOKENS = 5000;

    //Current amount minted
    uint256 public numTokens = 0;

    //Base metadata url (can be changed by admin)
    string public baseUrl = "https://sandbox-nft.ru/gonft/api"; 

    //Randomizer nonce
    uint256 internal nonce = 0;

    //Actual tokens store
    uint256[MAX_TOKENS] internal indices;

    //Token price
    uint256 public tokenPrice = 0.5 ether;

    //Minting enabled or disabled by admin
    bool public mintEnabled = true;

    //Contract creation
    constructor()
        ERC721("Green Ocean", "GONFT") 
    {}

    ///
    /// Internal functions
    ///

    //Returns metadata base url
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    //Get random index
    function randomIndex() internal returns (uint256) {
        uint256 totalSize = MAX_TOKENS - numTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    _msgSender(),
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

    //Mint one token internal
    function _internalMint(address to) internal returns (uint256) {
        require(numTokens < MAX_TOKENS, "Token limit");

        //Get random token
        uint256 id = randomIndex();

        //Change internal token amount
        numTokens++;

        //Mint token
        _mint(to, id);
        return id;
    }

    function _doMint(uint8 _amount, address _to) internal returns (uint256) {
        uint256 result = 0;
        for (uint8 i = 0; i < _amount; i++) {
            result += tokenPrice;
            _internalMint(_to);
        }
        return result;
    }

    ///
    /// Public functions
    ///

    //Mint selected amount of tokens from the collection
    function mint(address _to, uint8 _amount) public payable {
        require(mintEnabled, "Minting disabled");
        require(_to != address(0), "Cannot mint to empty");
        require(_amount <= 20, "Maximum 20 tokens per mint");
        require(numTokens < MAX_TOKENS, "Token limit");
        
        uint256 totalPrice = _doMint(_amount, _to);
        uint256 balance = msg.value.sub(totalPrice);

        // Return not used balance
        payable(msg.sender).transfer(balance);
        
    }
    
    //Mint selected amount of tokens to a given address by owner (airdrop)
    function airdrop(address _to, uint8 _amount) public onlyOwner {
        require(mintEnabled, "Minting disabled");
        require(_amount <= 20, "Maximum 20 tokens per airdrop");
        require(_to != address(0), "Cannot drop to empty address");
        
        _doMint(_amount, _to);
    }
    
    //Mint selected amount of tokens to a given addresses by owner (airdrop)
    function airdropMany(address[] memory _to, uint8 _amount) public onlyOwner {
        require((_amount * _to.length) <= 20, "Maximum 20 tokens per airdrop");
        for (uint256 i = 0; i < _to.length; i++) {
            require(_to[i] != address(0), "Cannot drop to empty address");
            _doMint(_amount, _to[i]);
        }
    }

    //Burns multiple tokens at once
    function burnMany(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }
    
    ///
    /// Admin functions
    ///

    // Claim ether
    function claimOwner(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }


    //Update base url
    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    //Enable or disable Minting
    function setMintingStatus(bool _status) public onlyOwner {
        mintEnabled = _status;
    }

    //Allow owner to change token sale price
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }
 
    ///
    /// Fallback function
    ///

    //Fallback to mint
    fallback() external payable {
        revert();
    }

    //Fallback to mint
    receive() external payable {
        revert();
    }

    ///
    /// Overrides
    ///

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

}