// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/********************
 * @author: Techoshi.eth *
        <(^_^)>
 ********************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract ShadedApesNFT is Ownable, ERC721, ERC721URIStorage, PaymentSplitter {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    struct user {
        address userAddress;
        uint8 entries;
        bool isExist;
    }
    // mapping(address => user) public giveAwayAllowance;
    // mapping(address => uint256) public giveAwayMints;
    // uint16 public remainingReserved;

    Counters.Counter private _tokenSupply;
    Counters.Counter private _freeSupply;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public publicMintMaxLimit = 50;
    uint256 public whitelistMintMaxLimit = 50;
    uint256 public tokenPrice = 0.025 ether;
    uint256 public whitelistTokenPrice = 0.0 ether;
    uint256 public maxWhitelistPassMints = 1000;

    bool public publicMintIsOpen = false;
    bool public bogoMintIsOpen = false;
    bool public privateMintIsOpen = false;
    bool public revealed = false;

    string _baseTokenURI;
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    address private _ContractVault = 0x0000000000000000000000000000000000000000;
    address private _ClaimsPassSigner = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) whitelistedAddresses;

    string public Author = "techoshi.eth";
    string public ProjectTeam = "nftpumps";

    struct WhitelistClaimPass {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function _isVerifiedWhitelistClaimPass(
        bytes32 digest,
        WhitelistClaimPass memory whitelistClaimPass
    ) internal view returns (bool) {
        address signer = ecrecover(
            digest,
            whitelistClaimPass.v,
            whitelistClaimPass.r,
            whitelistClaimPass.s
        );

        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _ClaimsPassSigner;
    }

    modifier isWhitelisted(uint8 amount, WhitelistClaimPass memory whitelistClaimPass) {
        bytes32 digest = keccak256(
            abi.encode(amount, msg.sender)
        );

        require(
            _isVerifiedWhitelistClaimPass(digest, whitelistClaimPass),
            "Invalid Pass"
        ); // 4
        _;
    }

    constructor(
        string memory contractName,
        string memory contractSymbol,
        address _vault,
        address _signer,
        string memory __baseTokenURI,
        string memory _hiddenMetadataUri,
        address[] memory _payees, uint256[] memory _shares
    ) ERC721(contractName, contractSymbol)  PaymentSplitter(_payees, _shares) payable {
        _ContractVault = _vault;
        _ClaimsPassSigner = _signer;
        _tokenSupply.increment();
        _tokenSupply.increment();
        _safeMint(msg.sender, 1);
        _baseTokenURI = __baseTokenURI;
        hiddenMetadataUri = _hiddenMetadataUri;
        
    }
    
    function withdraw() external onlyOwner {
        payable(_ContractVault).transfer(address(this).balance);
    }

    function whitelistClaimMint(
        uint8 quantity, //Whitelist,
        uint8 claimable,
        WhitelistClaimPass memory whitelistClaimPass
    ) external payable isWhitelisted(claimable, whitelistClaimPass) {
        require(
            whitelistTokenPrice * quantity <= msg.value,
            "Not enough ether sent"
        );

        uint256 supply = _tokenSupply.current();        

        require(privateMintIsOpen == true, "Claim Mint Closed");
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");
        require(quantity <= claimable, "Mint quantity can't be greater than claimable");
        require(quantity > 0, "Mint quantity must be greater than zero");
        require(quantity <= whitelistMintMaxLimit, "Mint quantity too large");
        require(
            _freeSupply.current() + quantity <= maxWhitelistPassMints,
            "Not enough free mints remaining"
        );

        // giveAwayMints[msg.sender] += quantity;        

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            _freeSupply.increment();
            _safeMint(msg.sender, supply + i);
        }

    }

    function openMint(uint256 quantity) external payable {
        require(tokenPrice * quantity <= msg.value, "Not enough ether sent");
        uint256 supply = _tokenSupply.current();
        require(publicMintIsOpen == true, "Public Mint Closed");
        require(quantity <= publicMintMaxLimit, "Mint amount too large");
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function bogoMint(uint256 quantity) external payable {
        
        require(tokenPrice * quantity <= msg.value, "Not enough ether sent");
        require(quantity <= publicMintMaxLimit, "Mint amount too large");
        quantity = quantity * 2;        
        uint256 supply = _tokenSupply.current();
        require(bogoMintIsOpen == true, "Bogo Mint Closed");        
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, supply + i);
        }
    }

    function teamMint(address to, uint256 amount) external onlyOwner {
        uint256 supply = _tokenSupply.current();
        require((supply-1) + amount <= MAX_TOKENS, "Not enough tokens remaining");
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function setParams(
        uint256 newPrice,
        uint256 newWhitelistTokenPrice,
        uint256 setOpenMintLimit,
        uint256 setWhistlistPassMintLimit,
        bool setPublicMintState,
        bool setPrivateMintState,
        bool setBogoMintState
    ) external onlyOwner {
        whitelistTokenPrice = newWhitelistTokenPrice;
        tokenPrice = newPrice;
        publicMintMaxLimit = setOpenMintLimit;
        whitelistMintMaxLimit = setWhistlistPassMintLimit;
        publicMintIsOpen = setPublicMintState;
        privateMintIsOpen = setPrivateMintState;
        bogoMintIsOpen = setBogoMintState;
    }

    function setTransactionMintLimit(uint256 newMintLimit) external onlyOwner {
        publicMintMaxLimit = newMintLimit;
    }

    function setWhitelistTransactionMintLimit(uint256 newprivateMintLimit)
        external
        onlyOwner
    {
        whitelistMintMaxLimit = newprivateMintLimit;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setFreeMints(uint256 amount) external onlyOwner {
        require(amount <= MAX_TOKENS, "Free mint amount too large");
        maxWhitelistPassMints = amount;
    }

    function toggleBogoMint() external onlyOwner {
        bogoMintIsOpen = !bogoMintIsOpen;
    }

    function togglePublicMint() external onlyOwner {
        publicMintIsOpen = !publicMintIsOpen;
    }

    function togglePresaleMint() external onlyOwner {
        privateMintIsOpen = !privateMintIsOpen;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current() - 1;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        _ContractVault = newVault;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    //receive() external payable {}

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        _ClaimsPassSigner = newSigner;
    }


}