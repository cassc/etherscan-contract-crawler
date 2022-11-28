// SPDX-License-Identifier: MIT
// lostparadigms.xyz
// mikemikemike (https://twitter.com/0xmikemikemike)
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721A, ERC721A, ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./utils/ProvenanceRandHandler.sol";
import "./hotgarbage/DefaultOperatorFilterer.sol";
import "./Errors.sol";

/*

██╗      ██████╗ ███████╗████████╗    ██████╗  █████╗ ██████╗  █████╗ ██████╗ ██╗ ██████╗ ███╗   ███╗███████╗
██║     ██╔═══██╗██╔════╝╚══██╔══╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██╔════╝ ████╗ ████║██╔════╝
██║     ██║   ██║███████╗   ██║       ██████╔╝███████║██████╔╝███████║██║  ██║██║██║  ███╗██╔████╔██║███████╗
██║     ██║   ██║╚════██║   ██║       ██╔═══╝ ██╔══██║██╔══██╗██╔══██║██║  ██║██║██║   ██║██║╚██╔╝██║╚════██║
███████╗╚██████╔╝███████║   ██║       ██║     ██║  ██║██║  ██║██║  ██║██████╔╝██║╚██████╔╝██║ ╚═╝ ██║███████║
╚══════╝ ╚═════╝ ╚══════╝   ╚═╝       ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝

*/
contract LostParadigms is DefaultOperatorFilterer, ProvenanceRandHandler,
    ERC721A("LostParadigms", "LOSTPARADIGMS"),
    ERC721ABurnable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant TOTAL_MAX_SUPPLY = 10001;
    uint256 public constant MAX_PUBLIC_MINT_PER_WALLET = 10;
    uint256 public constant ALLOWLIST_TOKEN_PRICE = .0222 ether;
    uint256 public constant PUBLIC_TOKEN_PRICE = .0333 ether;

    address public signatureVerifier;
    bool public publicMintActive;
    bool public allowListMintActive;
    bool public haltMintState;
    uint256 public freeMintCount;

    struct AllowListMintParams {
        bytes signature;
        address mintToAddress;
        uint256 freeMintAllowance;
        uint256 allowListAllowance;
        uint256 freeMintCount;
        uint256 paidMintCount;
    }

    struct MintCounts {
        uint256 publicMinted;
        uint256 allowlistMinted;
        uint256 freeMinted;
    }

    string private _baseTokenURI;

    constructor() ProvenanceRandHandler(TOTAL_MAX_SUPPLY) 
    {}

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsNotEOA();
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        if(_totalMinted() + _quantity > TOTAL_MAX_SUPPLY) revert PurchaseExceedsMaxSupply();
        
        _;
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizedHash();

        _;
    }

    modifier validateAllowListMintStatus(AllowListMintParams memory p){
        if(!allowListMintActive) revert AllowlistNotActive();
        if(msg.value < ALLOWLIST_TOKEN_PRICE * p.paidMintCount) revert NotEnoughETHSent();
    
        MintCounts memory mintCounts = getAddressMintCounts(p.mintToAddress);

        mintCounts.allowlistMinted += p.paidMintCount;
        if (mintCounts.allowlistMinted > p.allowListAllowance) revert MaxAllocationExceeded();

        mintCounts.freeMinted += p.freeMintCount;
        if (mintCounts.freeMinted > p.freeMintAllowance) revert MaxFreeAllocationExceeded();

        uint64 newAux = uint64(
                                (mintCounts.publicMinted << 26) |  
                                (mintCounts.allowlistMinted << 13) | 
                                mintCounts.freeMinted
                            );
        _setAux(p.mintToAddress, newAux);

        _;
    }

    modifier validatePublicMintStatus(address mintToAddress, uint256 _paidMintCount) {
        if(!publicMintActive) revert PublicMintNotActive();
        if(msg.value < PUBLIC_TOKEN_PRICE * _paidMintCount) revert NotEnoughETHSent();

        MintCounts memory mintCounts = getAddressMintCounts(mintToAddress);

        if(mintCounts.publicMinted + _paidMintCount > MAX_PUBLIC_MINT_PER_WALLET) revert MaxPublicAllocationExceeded();

        mintCounts.publicMinted += _paidMintCount;

        uint64 newAux = uint64(
                                (mintCounts.publicMinted << 26) | 
                                (mintCounts.allowlistMinted << 13) | 
                                mintCounts.freeMinted
                            );
        _setAux(mintToAddress, newAux);

        _;
    }

    function allowListMint(AllowListMintParams memory p)
        external
        payable
        hasValidSignature(p.signature, abi.encodePacked(p.mintToAddress, p.freeMintAllowance, p.allowListAllowance))
        validateAllowListMintStatus(p)
        underMaxSupply(p.freeMintCount + p.paidMintCount)
    {
        _mint(p.mintToAddress, p.paidMintCount + p.freeMintCount);
    }

    function publicMint(bytes memory _signature, address mintToAddress, uint256 _mintCount)
        external
        payable
        callerIsUser
        validatePublicMintStatus(msg.sender, _mintCount)
        underMaxSupply(_mintCount)
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
    {
        _mint(mintToAddress, _mintCount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getAddressMintCounts(address _address) public view returns(MintCounts memory){
        uint64 data = _getAux(_address);

        uint256 publicMinted = uint256(data >> 26);
        uint256 allowlistMinted = uint256((data >> 13) & (2**13 - 1));
        uint256 freeMinted = uint256(data & (2**13 - 1));

        return MintCounts(publicMinted, allowlistMinted, freeMinted);
    }

    // === OWNER FUNCTIONS ====

    function ownerMint(uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        if(haltMintState) revert MintIsHalted();
        _mint(msg.sender, _numberToMint);
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint)
        external
        onlyOwner
        underMaxSupply(_numberToMint)
    {
        if(haltMintState) revert MintIsHalted();
        _mint(_recipient, _numberToMint);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function flipAllowListActive() external onlyOwner {
        if(haltMintState) revert MintIsHalted();
        allowListMintActive = !allowListMintActive;
    }

    function flipPublicMintActive() external onlyOwner {
        if(haltMintState) revert MintIsHalted();
        publicMintActive = !publicMintActive;
    }

    function haltMint() external onlyOwner {
        haltMintState = true;
        allowListMintActive = false;
        publicMintActive = false;
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    /* support for OS operator filter registry */
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        payable 
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        payable 
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721A)
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}