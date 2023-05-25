// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "./ERC2981.sol";
import "./ERC721OperatorFilterer.sol";

contract CryptoPirates is ERC721OperatorFilterer, ERC2981, ReentrancyGuard, Ownable {

    uint256 public constant MAX_SUPPLY = 7500;
    
    uint256 public constant PRICE = 0.05 ether;
    
    uint256 public constant PUBLIC_MAX_AMOUNT = 20;
    
    uint96 public constant MAX_ROYALTIES = 333; // 3.33%

    string public baseURI = "ipfs://QmamQCfLUXnJasi1pSy8X9Ru6NeCw3S3xdZSMb7KFjbKGv/";

    bool public isPaused = false;
    bool public presalePaused = false;
    bool public publicPaused = false;

    uint256 public saleStartTime = 1683828900; // Thursday, May 11, 2023 6:15:00 PM

    // mints
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public publicMints;

    // types
    mapping(uint256 => uint256) public types;

    uint256 public constant TYPE_COMMON = 0;
    uint256 public constant TYPE_RARE = 1;
    uint256 public constant TYPE_EPIC = 2;
    uint256 public constant TYPE_LEGENDARY = 3;

    constructor() ERC721OperatorFilterer("CryptoPirates", "OGMF") {
        // set default royalty
        _setDefaultRoyalty(_msgSender(), MAX_ROYALTIES);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev See {Ownable-owner}.
    */
    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Reveal metadata
     */
    function setBaseURI(string calldata __baseURI) external onlyOwner
    {
        baseURI = __baseURI;
    }

     /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
    * @dev Sets the sale pause.
    * @param _publicPaused sale pause
    */
    function setPublicPaused(bool _publicPaused) external onlyOwner {
        publicPaused = _publicPaused;
    }

    /**
    * @dev Sets the presale pause.
    * @param _presalePaused presale pause
    */
    function setPresalePaused(bool _presalePaused) external onlyOwner {
        presalePaused = _presalePaused;
    }

    /**
    * @dev Sets the paused.
    * @param _isPaused paused
    */
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @dev Sets the sale start time.
    * @param _saleStartTime sale start time
    */
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
    * @dev Add to whitelist.
    * @param addresses list of addresses to add to whitelist
    * @param amounts list of amounts to add to whitelist
    */
    function addToWhitelist(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Arrays must be the same length");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = amounts[i];
        }
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        require(feeNumerator <= MAX_ROYALTIES, "Royalties: Too high");
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
    * @dev Sets the types information for the given token ids.
    * @param tokenIds token id
    * @param _type type
    */
    function setType(uint256[] calldata tokenIds, uint256 _type) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            types[tokenIds[i]] = _type;
        }
    }

    /**
    * @dev check if the presale is open
    */
    function isPresaleOpen() public view returns (bool) {
        return !presalePaused;
    }

    /**
    * @dev check if the public sale is open
    */
    function isSaleOpen() public view returns (bool) {
        return !publicPaused && block.timestamp >= saleStartTime;
    }



    /**
    * @dev mint
    * @param amount number of nfts to mint on public
    */
    function mint(uint256 amount) external payable nonReentrant {
        require(!isPaused, "Sale paused");
        if (whitelist[_msgSender()] > 0) {
            // presale user
            require(isPresaleOpen(), "Presale not started");
            amount = whitelist[_msgSender()];
            whitelist[_msgSender()] = 0;
        } else {
            // public user
            require(isSaleOpen(), "Public sale not started");
            // check the amount is not greater than max amount per user
            require(amount + publicMints[_msgSender()] <= PUBLIC_MAX_AMOUNT, "Max amount exceeded");
            // check the amount sent to the contract
            require(msg.value == PRICE * amount, "Wrong payment amount");
            // update the amount minted
            publicMints[_msgSender()] += amount;
        }
        // check the amount is not 0
        require(amount > 0, "Amount must be greater than 0");
        // check the sale not sold out
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out");
        // mint
        _mint(_msgSender(), amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}