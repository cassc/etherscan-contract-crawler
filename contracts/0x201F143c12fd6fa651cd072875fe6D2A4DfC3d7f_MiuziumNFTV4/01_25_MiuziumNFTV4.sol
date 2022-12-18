/**
 * 
 * '||\   /||` |''||''| '||   ||` |'''''/ |''||''| '||   ||` '||\   /||` 
    ||\\.//||     ||     ||   ||      //     ||     ||   ||   ||\\.//||  
    ||     ||     ||     ||   ||     //      ||     ||   ||   ||     ||  
    ||     ||     ||     ||   ||    //       ||     ||   ||   ||     ||  
   .||     ||. |..||..|  `|...|'  /.....| |..||..|  `|...|'  .||     ||. 
 *                                                                   
 *                                                                    
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./ICultivation.sol";

enum SaleState {
    Paused,
    VIP,
    Whitelist,
    Public
}

/**
 * @title MiuziumNFT
 */
contract MiuziumNFTV4 is
    ERC721Upgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    mapping(address => bool) private _minters;
    mapping(string => uint256) public _prices;
    mapping(string => bytes32) private _merkleRoots;
    mapping(string => address) public _pieces;
    mapping(uint256 => string) public _idToMetadata;
    mapping(string => uint256) public _metadataToId;
    mapping(address => uint256) public _minterVault;
    mapping(address => uint256) public _bidderVault;
    mapping(string => Auction) public _auctions;
    mapping(string => mapping(uint256 => Offer)) private _offers;
    mapping(string => uint256) private _offersCounter;
    bool public salesActive;
    bool public connectionRevealed;
    bool public stakingEnabled;
    bool public operatorFilteringEnabled;
    string public contractIpfsJson;
    string public contractBaseUri;
    string private unrevealedNft;
    address public vaultAddress;
    uint256 public _baseRoyaltiesPercentage;
    ICultivation public cultivation;
    mapping(address => uint256) public _royaltiesPercentages;

    // Auctions
    struct Offer {
        uint256 offer;
        address from;
        uint40 timestamp;
        bool revoked;
        bool accepted;
    }
    struct Auction {
        uint256 reserve;
        address from;
        uint40 start;
        uint40 end;
        bool ended;
    }

    bool public burnAllowed;
    SaleState public saleState;
    bytes32 public vipRoot;
    bytes32 public whitelistRoot;
    mapping(address => mapping(uint256 => uint256)) public minted;

    event Prepared(address creator, string metadata);
    event Removed(address creator, string metadata);
    event Placed(string metadata, uint256 offer, uint256 value);
    event Accepted(string metadata, uint256 offer, uint256 value);
    event Revoked(string metadata, uint256 offer);

    error SaleNotActive();

    modifier transferrable(uint256 tokenId) {
        require(
            !stakingEnabled || !cultivation.isCultivating(tokenId),
            "Cultivating!"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _ticker,
        string memory _contractIpfs
    ) public initializer {
        __ERC721_init(_name, _ticker);
        contractIpfsJson = _contractIpfs;
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();

        contractBaseUri = "https://api.miuzium.io/nfts/";
        unrevealedNft = "UnrevealedIpfsHash";
        salesActive = false;
        connectionRevealed = false;
        stakingEnabled = false;

        operatorFilteringEnabled = true;
        _baseRoyaltiesPercentage = 5;

        _registerForOperatorFiltering();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return contractBaseUri;
    }

    function contractURI() external view returns (string memory) {
        return contractIpfsJson;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        if (connectionRevealed) {
            string memory _tknId = _idToMetadata[_tokenId];
            return string(abi.encodePacked(contractBaseUri, _tknId));
        } else {
            return unrevealedNft;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function setCultivation(address _cultivation) public onlyOwner {
        cultivation = ICultivation(_cultivation);
    }

    function setVIPRoot(bytes32 _root) public onlyOwner {
        vipRoot = _root;
    }

    function setWLRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function setSaleState(SaleState state) public onlyOwner {
        saleState = state;
    }

    function setBurnAllowed(bool allowed) public onlyOwner {
        burnAllowed = allowed;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function fixStrings(uint256 _what, string memory _newString)
        external
        onlyOwner
    {
        if (_what == 0) {
            contractIpfsJson = _newString;
        } else if (_what == 1) {
            contractBaseUri = _newString;
        } else if (_what == 2) {
            unrevealedNft = _newString;
        }
    }

    function fixBools(
        uint8 _what,
        address _address,
        bool _state
    ) external onlyOwner {
        if (_what == 0) {
            _minters[_address] = _state;
        } else if (_what == 1) {
            salesActive = _state;
        } else if (_what == 2) {
            connectionRevealed = _state;
        }
    }

    function fixVault(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Can't use black hole.");
        vaultAddress = newAddress;
    }

    function fixMerkleRoot(string memory _metadata, bytes32 root)
        external
        onlyOwner
    {
        _merkleRoots[_metadata] = root;
    }

    function isMinter(address _toCheck) public view returns (bool) {
        return _minters[_toCheck];
    }

    /*
        This method will return royalty info
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        require(_tokenId > 0, "Asking royalties for non-existent token");
        string memory metadata = _idToMetadata[_tokenId];
        address creator = _pieces[metadata];
        uint256 percentage = _baseRoyaltiesPercentage;
        address finalReceiver = vaultAddress;
        if (_royaltiesPercentages[creator] > 0) {
            percentage = _royaltiesPercentages[creator];
            finalReceiver = creator;
        }
        uint256 _royalties = (_salePrice * percentage) / 100;
        return (finalReceiver, _royalties);
    }

    /*
        This method will allow owner to fix royalties receiver
    */
    function fixRoyaltiesParams(
        uint256 newRoyaltiesPercentage,
        address creatorAddress
    ) external onlyOwner {
        _royaltiesPercentages[creatorAddress] = newRoyaltiesPercentage;
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(
        bytes32[] calldata _merkleProof,
        address _address,
        string memory _metadata
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted;
        if (saleState == SaleState.VIP) {
            whitelisted = MerkleProofUpgradeable.verify(
                _merkleProof,
                vipRoot,
                leaf
            );
        } else {
            whitelisted = MerkleProofUpgradeable.verify(
                _merkleProof,
                whitelistRoot,
                leaf
            );
        }
        return whitelisted;
    }

    /*
        This method will allow minters to prepare an NFT
     */
    function prepareNFT(string memory _metadata) external {
        require(
            isMinter(_msgSender()) && _pieces[_metadata] == address(0),
            "Not a minter or piece exists"
        );
        _pieces[_metadata] = _msgSender();
        emit Prepared(_msgSender(), _metadata);
    }

    /*
        This method will allow minters to remove an NFT
     */
    function removeNFT(string memory _metadata) external {
        require(
            isMinter(_msgSender()) && _metadataToId[_metadata] == 0,
            "Not a minter or piece minted"
        );
        _pieces[_metadata] = address(0);
        _prices[_metadata] = 0;
        emit Removed(_msgSender(), _metadata);
    }

    function burnNFT(uint256 tokenId) external {
        require(burnAllowed, "burn not allowed");
        _burn(tokenId);
    }

    /*
        This method will allow users to drop nft for free
    */
    function dropNFT(string memory _metadata, address _receiver) external {
        require(
            _pieces[_metadata] == _msgSender() && _metadataToId[_metadata] == 0,
            "not owner"
        );
        _tokenIdCounter.increment();
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _mint(_receiver, nextId);
    }

    /*
        This method will allow minters to prepare an NFT
     */
    function sellNFT(string memory _metadata, uint256 _price) external {
        require(isMinter(_msgSender()), "Only minters");
        require(
            _pieces[_metadata] == _msgSender() && _metadataToId[_metadata] == 0,
            "Not exist, not owner"
        );
        _prices[_metadata] = _price;
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(string memory _metadata, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bool canMint = true;
        if (saleState == SaleState.VIP || saleState == SaleState.Whitelist) {
            canMint = isWhitelisted(_merkleProof, _msgSender(), _metadata);
        }

        if (saleState == SaleState.VIP) {
            require(
                minted[_msgSender()][uint256(saleState)] < 2,
                "max minted on stage"
            );
        } else if (saleState == SaleState.Whitelist) {
            require(
                minted[_msgSender()][uint256(saleState)] == 0,
                "max minted on stage"
            );
        } else if (saleState == SaleState.Public) {
            require(
                minted[_msgSender()][uint256(saleState)] == 0 &&
                    (minted[_msgSender()][uint256(SaleState.VIP)] +
                        minted[_msgSender()][uint256(SaleState.Whitelist)] <
                        3)
            );
        } else {
            revert SaleNotActive();
        }

        require(_prices[_metadata] > 0, "Not selling");
        require(canMint, "Cannot mint");
        require(msg.value == _prices[_metadata], "Price incorrect");
        require(_metadataToId[_metadata] == 0, "Item already minted");
        require(_pieces[_metadata] != address(0), "Item doesn't exists");
        require(_pieces[_metadata] != _msgSender(), "Can't buy from yourself");

        _tokenIdCounter.increment();
        address creator = _pieces[_metadata];
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _minterVault[creator] += msg.value;
        minted[_msgSender()][uint256(saleState)]++;
        _mint(_msgSender(), nextId);
    }

    /*
        This method will allow users to buy the nft through Crossmint.io
    */
    function crossmint(string memory _metadata, address _to) external payable {
        require(
            _msgSender() == 0xdAb1a1854214684acE522439684a145E62505233,
            "Only crossmint"
        );

        require(saleState == SaleState.Public, "Sale not active");
        require(_prices[_metadata] > 0, "Not selling the item");
        require(msg.value == _prices[_metadata], "Price is not correct");
        require(_metadataToId[_metadata] == 0, "Item already minted");
        require(_pieces[_metadata] != address(0), "Item doesn't exists");
        require(_pieces[_metadata] != _msgSender(), "Can't buy from yourself");

        _tokenIdCounter.increment();
        address creator = _pieces[_metadata];
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _minterVault[creator] += msg.value;
        _mint(_to, nextId);
    }

    // Withdraws the earnings earned by the minter.
    function withdrawFromVault() external nonReentrant {
        require(
            isMinter(_msgSender()) && _minterVault[_msgSender()] > 0,
            "zero balance"
        );
        bool success;
        (success, ) = payable(_msgSender()).call{
            value: _minterVault[_msgSender()]
        }("");
        require(success, "failed");
        _minterVault[_msgSender()] = 0;
    }

    // ERC721 function overrides for operator filtering to enable OpenSea creator royalities.

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) transferrable(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) transferrable(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) transferrable(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}