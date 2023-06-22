// SPDX-License-Identifier: MIT
// TBA Contract
// Creator: NFT Guys nftguys.biz

//
//  ________  __    __  ________        __       __
// /        |/  |  /  |/        |      /  \     /  |
// $$$$$$$$/ $$ |  $$ |$$$$$$$$/       $$  \   /$$ |  ______   _______    ______    ______    ______    ______    _______
//    $$ |   $$ |__$$ |$$ |__          $$$  \ /$$$ | /      \ /       \  /      \  /      \  /      \  /      \  /       |
//    $$ |   $$    $$ |$$    |         $$$$  /$$$$ | $$$$$$  |$$$$$$$  | $$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$$/
//    $$ |   $$$$$$$$ |$$$$$/          $$ $$ $$/$$ | /    $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$    $$ |$$ |  $$/ $$      \
//    $$ |   $$ |  $$ |$$ |_____       $$ |$$$/ $$ |/$$$$$$$ |$$ |  $$ |/$$$$$$$ |$$ \__$$ |$$$$$$$$/ $$ |       $$$$$$  |
//    $$ |   $$ |  $$ |$$       |      $$ | $/  $$ |$$    $$ |$$ |  $$ |$$    $$ |$$    $$ |$$       |$$ |      /     $$/
//    $$/    $$/   $$/ $$$$$$$$/       $$/      $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$ | $$$$$$$/ $$/       $$$$$$$/
//                                                                                /  \__$$ |
//                                                                                $$    $$/
//                                                                                 $$$$$$/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/IERC4906.sol";


// 6551 Interfaces
interface IERC6551Registry {
    event AccountCreated(
        address account,
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    );

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed,
        bytes calldata initData
    ) external returns (address);

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address);
}

contract ManagersTBA is Ownable, ERC721A, ERC2981, IERC4906, DefaultOperatorFilterer {
    // ----------------------------- State variables ------------------------------

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_USER = 5;
    uint256 public PRICE_PER_TOKEN = 0.015 ether;
    bool public revealed = false;
    string public notRevealedUri = "https://ipfs.io/ipfs/QmW3mpjh2waM6YQws1dNuf4Zd8GCgx1MbFwtq28hyhGth9";
    string public _baseTokenURI = "";

    IERC6551Registry public ERC6551Registry;
    address public ERC6551AccountImplementation;

    // ----------------------------- CONSTRUCTOR ------------------------------

    constructor(address _ERC6551Registry, address _ERC6551AccountImplementation) ERC721A("The Managers", "MAN") {
        _setDefaultRoyalty(0xcF94ba8779848141D685d44452c975C2DdC04945, 500);

        ERC6551Registry = IERC6551Registry(_ERC6551Registry);
        ERC6551AccountImplementation = _ERC6551AccountImplementation;
    }

    ////////////////////////////////////////
    //              SETTERS               //
    ////////////////////////////////////////

    function mint(uint256 quantity, address destination) external payable {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max Supply Hit");
        // we dont check destination but owner that is minting which is msg.sender
        require((quantity + ERC721A.balanceOf(msg.sender)) <= MAX_PER_USER, "Max per user Hit");
        require(msg.value >= quantity * PRICE_PER_TOKEN, "Insufficient Funds Sent");
        uint256 currentMinted = _totalMinted();

        _mint(destination, quantity);

        // Check that the TBA creation was success
        require(tokenBoundCreation(quantity, currentMinted), "TBA creation failed");
    }

    function tokenBoundCreation(uint256 quantity, uint256 currentMinted) internal returns (bool) {
        for (uint256 i = 1; i <= quantity; i++) {
            ERC6551Registry.createAccount(
                ERC6551AccountImplementation,
                block.chainid,
                address(this),
                currentMinted + i,
                0,
                abi.encodeWithSignature("initialize()", msg.sender)
            );
        }

        return true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
        _baseTokenURI = baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    // Blacklist operators that dont support royalties

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setTokenRoyalty(address royaltieReceiver, uint96 bips) external onlyOwner {
        _setDefaultRoyalty(royaltieReceiver, bips);
    }

    function setPricePerToken(uint256 _pricePerToken) public onlyOwner {
        PRICE_PER_TOKEN = _pricePerToken;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Interfaces support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////
    //              GETTERS               //
    ////////////////////////////////////////

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function showTBA(uint256 _tokenId) external view returns (address) {
        return ERC6551Registry.account(ERC6551AccountImplementation, block.chainid, address(this), _tokenId, 0);
    }
}