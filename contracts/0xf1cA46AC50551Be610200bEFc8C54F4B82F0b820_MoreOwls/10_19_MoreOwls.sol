// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IOwlDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed)
        external
        view
        returns (string memory);
}

contract MoreOwls is
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    OperatorFiltererUpgradeable
{
    mapping(uint256 => uint256) internal seeds;
    mapping(address => uint256)  mintPerWallet;

    IOwlDescriptor public descriptor;

    address DEFAULT_OPERATOR_FILTER;
    string public uriPrefix;
    string public uriSuffix;
    bool public canUpdateSeed;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintPerWallet;

    bool public paused;
    bool public revealed;

    event RoyaltyUpdated(address royaltyAddress, uint96 royaltyAmount);
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    function initialize() public initializer initializerERC721A {
        __ERC721A_init("MoreOwlsWTF", "MOwls");
        __Ownable_init();
        __ReentrancyGuard_init();
        _setDefaultRoyalty(msg.sender, 500);
        DEFAULT_OPERATOR_FILTER = address(
            0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
        );
        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER,
            DEFAULT_OPERATOR_FILTER == address(0) ? false : true
        );
        uriPrefix = "";
        uriSuffix = ".json";
        paused = true;
        descriptor = IOwlDescriptor(0xc11fcaCb7566351Dd4bcd04F4b70d10Ecacfe5A9);
        setCost(0 ether);
        canUpdateSeed = true;
        maxSupply = 10000;
        maxMintPerWallet = 30;
        setMaxMintAmountPerTx(15);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function updateSVGgen(IOwlDescriptor _descriptor) public onlyOwner{
        descriptor = _descriptor;
    }

    function random(uint256 tokenId)
        private
        view
        returns (uint256 pseudoRandomness)
    {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * ((r % 7) + 10) + (((r >> 48) % 20) + 10);
        uint256 faceSeed = 100 *
            (((r >> 96) % 6) + 10) +
            (((r >> 96) % 20) + 10);
        uint256 bodySeed = 100 *
            (((r >> 144) % 7) + 10) +
            (((r >> 144) % 20) + 10);
        uint256 legsSeed = 100 *
            (((r >> 192) % 2) + 10) +
            (((r >> 192) % 20) + 10);
        return
            10000 *
            (10000 * (10000 * headSeed + faceSeed) + bodySeed) +
            legsSeed;
    }

    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        require(canUpdateSeed, "Cannot set the seed");
        seeds[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
    }

    function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(mintPerWallet[msg.sender] + _mintAmount <= maxMintPerWallet, "over max per wallet!");
        mintPerWallet[msg.sender] = mintPerWallet[msg.sender] + _mintAmount;
        for(uint i=totalSupply(); i < (totalSupply() + _mintAmount); ++i) {
              seeds[i+1] = generateSeed(i+1);
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function admin_mint() public onlyOwner {
        uint256 _mintAmount = 10;
        for(uint i=totalSupply(); i < (totalSupply() + _mintAmount); ++i) {
              seeds[i+1] = generateSeed(i+1);
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Owl does not exist.");
        return seeds[tokenId];
    }

    function getMintsPerWallet(address _wallet) public view returns (uint256) {
        return mintPerWallet[_wallet];
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(_tokenId), "Owl does not exist.");
        uint256 seed = seeds[_tokenId];
        return descriptor.tokenURI(_tokenId, seed);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
        emit RoyaltyUpdated(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}