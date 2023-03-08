// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT is ERC721Royalty, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // constants
    uint128 public constant MAX_SUPPLY = 333;
    uint256 public constant MINT_PRICE = 0.38 ether;

    // vars
    string public baseURI = "ipfs://QmP6GU1wZ7ANosjnrDUVpRnxB8KjeRKdsPUKH2jFR44jPk/";
    bool public isSaleStarted = false;
    mapping(address => uint256) public mintersMap;

    // Events
    event Mint(address _address, uint256 indexed _id, string _uri);
    event SaleStart(bool _isEnable, uint256 _timestamp);

    constructor() ERC721("THE HANGING RHINO", "RHN") {
        _setDefaultRoyalty(msg.sender, 500); // 5% royalties
        _tokenIdCounter.increment();
    }

    /// @dev Mint a new NFT token
    function mint() public payable returns (uint256) {
        require(isSaleStarted, "sale is not open");
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_SUPPLY, "max supply reached");
        require(msg.value == MINT_PRICE, "amount not valid");
        require(mintersMap[msg.sender] < 20, "max mint for user reached");
        _tokenIdCounter.increment();
        mintersMap[msg.sender]++;
        _safeMint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId, tokenURI(tokenId));
        return tokenId;
    }

    /// @dev Mint a new NFT token and assign it to a specific address (only for contract owner)
    function mintOwner(address addr) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_SUPPLY, "max supply reached");
        _tokenIdCounter.increment();
        _safeMint(addr, tokenId);
        emit Mint(addr, tokenId, tokenURI(tokenId));
        return tokenId;
    }


    /// @dev Mint multiple NFT tokens and assign them to specific addresses (only for contract owner)
    function mintOwnerBatch(address[] memory dests) public onlyOwner {
        require(!isSaleStarted, "sale is not open");
        uint256 i = 0;
        while (i < dests.length) {
            mintOwner(dests[i]);
            i++;
        }
    }

    /// @dev Enable public sale of NFT tokens (only for contract owner)
    function enablePublicSale() public onlyOwner {
        isSaleStarted = true;
        emit SaleStart(true, block.timestamp);
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Sets the baseURI prefix.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json")) : "";
    }


    /**
     * @notice Withdraw payment tokens received
     */
    function withdrawETH() external onlyOwner {
        uint balance = address(this).balance;

        processPaymentTo(address(0), msg.sender, balance);
    }

    function withdraw(address _paymentToken) external onlyOwner {
        uint balance = IERC20(_paymentToken).balanceOf(address(this));

        processPaymentTo(_paymentToken, msg.sender, balance);
    }

    // Refund a bidder if it gets outbidded
    function processPaymentTo(address _token, address _to, uint _amount) internal {
        // BNB
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        }

        // Other tokens
        else {
            IERC20(_token).transfer(_to, _amount);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Royalty, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}