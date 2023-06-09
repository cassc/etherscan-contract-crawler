// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";


//  ██████╗░███████╗██╗░░░██╗██╗░░██╗
//  ██╔══██╗██╔════╝██║░░░██║╚██╗██╔╝
//  ██████╔╝█████╗░░╚██╗░██╔╝░╚███╔╝░
//  ██╔══██╗██╔══╝░░░╚████╔╝░░██╔██╗░
//  ██║░░██║███████╗░░╚██╔╝░░██╔╝╚██╗
//  ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝
/// @author stonkmaster69

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint256 whitelistMintPerWalletMax;
  uint256 whitelistPrice;
}

contract RevX is ERC721A, Ownable, ReentrancyGuard {

    /// ERRORS ///
    error ContractMint();
    error OutOfSupply();
    error ExceedsTxnLimit();
    error ExceedsWalletLimit();
    error InsufficientFunds();
    
    error MintPaused();
    error MintInactive();
    error InvalidProof();

    /// @dev For URI concatenation.
    using Strings for uint256;

    bytes32 public merkleRoot;

    string public baseURI;
    
    uint32 publicSaleStartTime;

    uint256 public PRICE = 0.0444 ether;
    uint256 public SUPPLY_MAX = 2222;
    uint256 public MAX_PER_TXN = 5;

    PresaleConfig public presaleConfig;

    bool public presalePaused;
    bool public publicSalePaused;
    bool public revealed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) payable {
        presaleConfig = PresaleConfig({
            startTime: 1651942800, // MAY 7 2022 5:00:00 PM GMT
            endTime: 1652029200,   // MAY 8 2022 5:00:00 PM GMT
            whitelistMintPerWalletMax: 3,
            whitelistPrice: 0.0333 ether
        });
        publicSaleStartTime = 1652029200; // MAY 8 2022 5:00:00 PM GMT
    }

    modifier mintCompliance(uint256 _mintAmount) {
        if (msg.sender != tx.origin) revert ContractMint();
        if ((totalSupply() + _mintAmount) > SUPPLY_MAX) revert OutOfSupply();
        if (_mintAmount > MAX_PER_TXN) revert ExceedsTxnLimit();
        _;
    }

    function presaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount) 
    {
        PresaleConfig memory config_ = presaleConfig;
        
        if (presalePaused) revert MintPaused();
        if (block.timestamp < config_.startTime || block.timestamp > config_.endTime) revert MintInactive();
        if ((_numberMinted(msg.sender) + _mintAmount) > config_.whitelistMintPerWalletMax) revert ExceedsWalletLimit();
        if (msg.value < (config_.whitelistPrice * _mintAmount)) revert InsufficientFunds();
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();

        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        if (publicSalePaused) revert MintPaused();
        if (block.timestamp < publicSaleStartTime) revert MintInactive();
        if (msg.value < (PRICE * _mintAmount)) revert InsufficientFunds();

        _safeMint(msg.sender, _mintAmount);
    }
    
    /// @notice Airdrop for a single a wallet.
    function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    /// @notice Airdrops to multiple wallets.
    function batchMintForAddress(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
        uint32 i;
        for (i=0; i < addresses.length; ++i) {
            _safeMint(addresses[i], quantities[i]);
        }
    }

    /// @dev RevX tokens begin from 1, Not 0.
    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
    }

    /// SETTERS ///

    function setRevealed() public onlyOwner {
        revealed = true;
    }

    function pausePublicSale(bool _state) public onlyOwner {
        publicSalePaused = _state;
    }

    function pausePresale(bool _state) public onlyOwner {
        presalePaused = _state;
    }

    function setPublicSaleStartTime(uint32 startTime_) public onlyOwner {
        publicSaleStartTime = startTime_;
    }

    function setPresaleStartTime(uint32 startTime_, uint32 endTime_) public onlyOwner {
        presaleConfig.startTime = startTime_;
        presaleConfig.endTime = endTime_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setWhitelistPrice(uint256 _price) public onlyOwner {
        presaleConfig.whitelistPrice = _price;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        SUPPLY_MAX = _supply;
    }

    function withdraw() public onlyOwner {
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
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
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }

}