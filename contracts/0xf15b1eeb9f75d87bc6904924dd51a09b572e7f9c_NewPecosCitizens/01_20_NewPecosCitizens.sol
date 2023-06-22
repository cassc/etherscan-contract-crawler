// SPDX-License-Identifier: MIT
// Modified by datboi1337 to make compliant with Opensea Operator Filter Registry

pragma solidity >=0.8.13 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract NewPecosCitizens is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981
{
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public Erc20Price = 15000000000000000000000000; // num of tokens * decimal point system num

    uint256 public maxSupply;
    uint256 public wlSupply = 7000;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    mapping(address => uint256) public mintCount;
    uint256 public maxLimitPerWallet = 9969;

    uint96 internal royaltyFraction = 420; // 100 = 1% , 1000 = 10%
    address internal royaltiesReciever = 0xb32F4f0Cd907b0692d9caD8cB89De0Def2E0ac80;

    // erc20 contract address
    IERC20 erc20Contract = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        setRoyaltyInfo(royaltiesReciever, royaltyFraction);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
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

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    // ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        require(
            totalSupply() + _mintAmount <= wlSupply,
            "wl supply exceeded!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    )
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(
            mintCount[msg.sender] + _mintAmount <= maxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );

        mintCount[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function erc20mint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(
            mintCount[msg.sender] + _mintAmount <= maxLimitPerWallet,
            "Max mint per wallet exceeded!"
        );

        // transfer erc20 from minter to the contract
        uint256 amountToSend = Erc20Price * _mintAmount;
        require(
            erc20Contract.allowance(msg.sender, address(this)) >= amountToSend,
            "Allowance not met"
        );
        erc20Contract.transferFrom(msg.sender, address(this), amountToSend);

        mintCount[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Various checks ~~~~~~~~~~~~~~~~~~~~
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return uriPrefix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
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
                        uriSuffix
                    )
                )
                : "";
    }

    // ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
        maxLimitPerWallet = _maxLimitPerWallet;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
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

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setErc20Price(uint256 _Erc20Price) public onlyOwner {
        Erc20Price = _Erc20Price;
    }

    function seterc20AddressAddress(IERC20 _address) public onlyOwner {
        erc20Contract = _address;
    }

    function setmaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setwlSupply(uint256 _supply) public onlyOwner {
        wlSupply = _supply;
    }

    function setRoyaltyTokens(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _royaltyFeesInBips);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }


    // ~~~~~~~~~~~~~~~~~~~~ Opensea Operator Filter Registry Functions ~~~~~~~~~~~~~~~~~~~~
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
    function withdraw() public onlyOwner nonReentrant {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function withdrawUSDC() public onlyOwner nonReentrant {
        uint balance = erc20Contract.balanceOf(address(this));
        erc20Contract.transfer(msg.sender, balance);
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

}