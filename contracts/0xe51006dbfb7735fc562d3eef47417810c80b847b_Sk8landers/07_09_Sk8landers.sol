// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Sk8landers is ERC721A, Ownable {

    /// ERRORS ///
    error ContractMint();
    error OutOfSupply();
    error ExceedsTxnLimit();
    error ExceedsWalletLimit();
    error InsufficientFunds();
    
    error MintPaused();
    error MintInactive();
    error InvalidProof();
    error InvalidQuantity();
    error InexistentToken();

    /// @dev For URI concatenation.
    using Strings for uint256;

    string public baseURI = "ipfs://QmP5ejFQBQQnashCMHKXjo2Yr7JKkEoMxKRGxm3sh7YzgL/Hidden.json";
    
    uint32 saleStartTime;

    uint256 public PRICE = 0.0069 ether;
    uint256 public SUPPLY_MAX;
    uint256 public MAX_PER_TXN = 3;

    bool public publicSalePaused;
    bool public revealed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) payable {
        _safeMint(msg.sender, 1);
        SUPPLY_MAX = 444;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (block.timestamp < saleStartTime) revert MintInactive();
        if (_mintAmount > MAX_PER_TXN) revert ExceedsTxnLimit();
        if ((_numberMinted(msg.sender) + _mintAmount) > MAX_PER_TXN) revert ExceedsWalletLimit();
        _;
    }

    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();
        if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();

        _safeMint(msg.sender, _mintAmount);
    }
    
    /// @notice Airdrop to a single wallet.
    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    /// @notice Airdrops to multiple wallets.
    function batchMintForAddress(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        uint32 i;
        unchecked {
            for (i=0; i < addresses.length; ++i) {
                _safeMint(addresses[i], quantities[i]);
            }
        }
    }

    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
    }

    function numberMinted(address userAddress) external view virtual returns (uint256) {
        return _numberMinted(userAddress);
    }

    /// SETTERS ///

    function toggleReveal(bool state) external onlyOwner {
        revealed = state;
    }

    function pausePublicSale(bool _state) external onlyOwner {
        publicSalePaused = _state;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }
    
    function setMaxPerWalletLimit(uint256 _max) external onlyOwner {
        MAX_PER_TXN = _max;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// METADATA URI ///

    function _baseURI()
        internal 
        view 
        virtual
        override returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev Returning concatenated URI with .json as suffix on the tokenID when revealed.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert InexistentToken();

        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

}