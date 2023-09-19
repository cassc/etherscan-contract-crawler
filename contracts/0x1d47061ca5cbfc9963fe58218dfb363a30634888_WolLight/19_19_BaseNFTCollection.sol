// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title Base NFT Collection contract
 */
abstract contract BaseNFTCollection is ERC721Royalty, Ownable, IERC721Enumerable {
    using Counters for Counters.Counter;
    
    /**
     * @dev Counter to keep track of the number of minted tokens
     */
    Counters.Counter private _tokenIds;

    /**
     * @notice Price of NFT
     */
    uint public price;

    /**
     * @dev Base URL of the NFTs
     */
    string private _baseUrl;

    /**
     * @notice Total number of tokens
     */
    uint256 public maxTokens;

    /**
     * @dev Initializes the contract by setting a `price`, `baseUrl`, `maxTokens` to the token collection.
     * Also it mints first `firstMintNumber` tokens and sets royalty feeNumerator (ex: 250 for 2.5%)
     */
    constructor(uint price_, string memory baseUrl_, uint maxTokens_, uint firstMintNumber, uint96 feeNumerator) {
        price = price_;
        _baseUrl = baseUrl_;
        maxTokens = maxTokens_;
        _setDefaultRoyalty(msg.sender, feeNumerator);

        for(uint i=0; i < firstMintNumber;){
            _mintOne(msg.sender);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Royalty) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Increments token, mints it and transfers it to `to`.
     *
     * Requirements:
     *
     * - Maximum tokens number not reached
     */
    function _mintOne(address to) internal virtual {
        require(_tokenIds.current() < maxTokens, "Maximum tokens reached");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
    }

    /**
     * @dev Return the tokens' base URL
     */
    function _baseURI() internal view override virtual returns (string memory) {
        return _baseUrl;
    }

    /**
     * @dev Update tokens' base URL
     *
     * Requirements:
     * - Only owner can call
     */
    function setBaseURI(string memory baseUrl_) public virtual onlyOwner {
        _baseUrl = baseUrl_;
    }

    /**
     * @dev Safely mints next token and transfers it to the sender.
     *
     * Requirements:
     *
     * - Correct price is sent
     * - Maximum tokens number not reached
     */
    function mint() public virtual payable {
        require(msg.value == price, "Incorrect price");
        _mintOne(msg.sender);
    }

    /**
     * @dev Return the maximum number of tokens allowed when calling mintMiltiple
     */
    function _maximumPerTransaction() internal pure virtual returns (uint) {
        return 5;
    }

    /**
     * @dev Safely mints multiple tokens and transfers them to the sender.
     *
     * Requirements:
     *
     * - Maximum tokens per transaction not reached
     * - Correct price is sent
     * - Maximum tokens number not reached
     */
    function mintMultiple(uint amount) public virtual payable {
        require(amount <= _maximumPerTransaction(), "Maximum tokens per transaction reached");
        require(msg.value == price * amount, "Incorrect price");
        for(uint i=0; i<amount;){
            _mintOne(msg.sender);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Safely mints an `amount` of tokens and transfers it to `to`.
     *
     * Requirements:
     *
     * - Only owner can call
     * - Maximum tokens number not reached
     */
    function teamMint(uint amount, address to) public virtual onlyOwner {
        for(uint i=0; i<amount;){
            _mintOne(to);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Change price of the token
     *
     * Requirements:
     * - Only owner can call
     */
    function changePrice(uint newPrice) public virtual onlyOwner {
        price = newPrice;
    }

    /**
     * @dev Updates the royalty information for all tokens
     * `feeNumerator` will be divided by 10000. Example: 250 = 2.5%
     *
     * Requirements:
     * - Only owner can call
     */
    function changeRoyalty(address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
    * @dev Send all the ether in the contract 
    * to the owner of the contract
    *
    * Requirements:
    *
    * - Only owner is allowed to call
    * - Balance is not 0
    */
    function withdraw() public virtual onlyOwner  {
        require(address(this).balance > 0, "Balance is empty");
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
    * @dev Disable renounceOwnership function
    */
    function renounceOwnership() public view virtual override onlyOwner {
        revert("Renounce ownership not supported");
    }

    //Enumberable

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "Index out of bounds");
        return index + 1;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "Owner index out of bounds");
        uint256 total = totalSupply();
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (ownerOf(i) == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex++;
            }
        }
        revert("Unable to get token of owner by index");
    }
}