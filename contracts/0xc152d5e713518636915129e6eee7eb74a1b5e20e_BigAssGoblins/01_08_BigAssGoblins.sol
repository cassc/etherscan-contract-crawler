// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract BigAssGoblins is ERC721A, Ownable, ReentrancyGuard {

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

    bytes32 public merkleRoot;

    string public baseURI = "ipfs://QmTNMjnX6BBN46APGuaC1nUNaSojuAFA2ybkk8UVvmJK4M/Hidden.json";
    
    uint32 saleStartTime;

    uint256 public PRICE = 0.0059 ether;
    uint256 public SUPPLY_MAX;
    uint256 public SUPPLY_MAX_WHITELIST;
    uint256 public MAX_PER_TXN = 3;
    
    uint256 public teamReserve = 50;
    uint256 public whitelistMints;

    bool public presalePaused;
    bool public publicSalePaused;
    bool public revealed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) payable {
        _safeMint(msg.sender, 1);
        SUPPLY_MAX = 3333;
        SUPPLY_MAX_WHITELIST = 1111;
        saleStartTime = 1662771600; // Saturday, September 10, 2022 01:00:00 AM GMT
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (block.timestamp < saleStartTime) revert MintInactive();
        if (msg.sender != tx.origin) revert ContractMint();
        if ((totalSupply() + _mintAmount) > (SUPPLY_MAX - teamReserve)) revert OutOfSupply();
        if (_mintAmount > MAX_PER_TXN) revert ExceedsTxnLimit();
        if ((_numberMinted(msg.sender) + _mintAmount) > MAX_PER_TXN) revert ExceedsWalletLimit();
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount) 
    {   
        if (_mintAmount < 1) revert InvalidQuantity();
        if (presalePaused) revert MintPaused();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();
        bool inSupply = whitelistMints < SUPPLY_MAX_WHITELIST;
        bool eligibleForFreeMint = _numberMinted(msg.sender) == 0;

        /// @dev Handle edge case.
        if (!inSupply) {
            if (eligibleForFreeMint) {
                if (_mintAmount > 1) {
                    if (msg.value < (PRICE * (_mintAmount - 1))) revert InsufficientFunds();
                    _safeMint(msg.sender, (_mintAmount - 1));
                } else {
                    revert OutOfSupply();
                }
            } else {
                if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();
                _safeMint(msg.sender, _mintAmount);
            }
        } else {
            uint256 quant = eligibleForFreeMint ? (_mintAmount - 1) : _mintAmount;
            if (msg.value < (PRICE * quant)) revert InsufficientFunds();
            _safeMint(msg.sender, _mintAmount);
            if (eligibleForFreeMint) ++whitelistMints;
        }

    }

    function mint(uint256 _mintAmount)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();
        if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();

        _safeMint(msg.sender, _mintAmount);
    }
    
    /// @notice Airdrop to a single wallet.
    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        unchecked { teamReserve -= _mintAmount; }
        _safeMint(_receiver, _mintAmount);
    }

    /// @notice Airdrops to multiple wallets.
    function batchMintForAddress(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        uint32 i;
        unchecked {
            for (i=0; i < addresses.length; ++i) {
                teamReserve -= quantities[i];
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

    function setRevealed() external onlyOwner {
        revealed = true;
    }

    function pausePublicSale(bool _state) external onlyOwner {
        publicSalePaused = _state;
    }

    function pausePresale(bool _state) external onlyOwner {
        presalePaused = _state;
    }

    function setSaleStartTime(uint32 startTime_) external onlyOwner {
        saleStartTime = startTime_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPublicMaxSupply(uint256 _supply) external onlyOwner {
        SUPPLY_MAX = _supply;
    }

    function setWhitelistMaxSupply(uint256 _supply) external onlyOwner {
        SUPPLY_MAX_WHITELIST = _supply;
    }

    function setTeamReserves(uint256 _reserve) external onlyOwner {
        teamReserve = _reserve;
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