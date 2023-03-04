// SPDX-License-Identifier: MIT
         


pragma solidity ^0.8.16;

import "./IERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrumpyNFTs is ERC721A, Ownable, ReentrancyGuard, ERC721AQueryable, IERC721ABurnable {
    event PermanentURI(string _value, uint256 indexed _id);

    uint256 public constant MAX_SUPPLY = 200;
    

    // Holds the # of remaining tokens available for migration
    uint256 public remainingSupply = 200;

    bool public openPackPaused;
    bool public contractPaused;
    bool public baseURILocked;
    string private _baseTokenURI;
    address private _burnAuthorizedContract;
    address private _admin;
    mapping(address => bool) private _marketplaceBlocklist;

    PackContract private PACK;

    constructor(
        string memory baseTokenURI,
        address admin,
        address packContract)
    ERC721A("GrumpyNFT", "GrumpyNFT") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        openPackPaused = false;
        PACK = PackContract(packContract);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }


    // Starts the migration process of given Grumpy Pack

    function startopenPack(uint256[] memory packIds)
        external
        nonReentrant
        callerIsUser
    {
        require(!openPackPaused && !contractPaused, "Pack opening is paused");


        uint256 i;
        for (i = 0; i < packIds.length;) {
            uint256 packId = packIds[i];
            // check if the msg sender is the owner
            require(PACK.ownerOf(packId) == msg.sender, "You don't own the given Pack");

            // burn pack
            PACK.burn(packId);

            unchecked { i++; }
        }


        // mint GrumpyNFTs
        _safeMint(msg.sender, packIds.length * 6);

    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _burnAuthorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function pauseopenPack(bool paused) external onlyOwnerOrAdmin {
        openPackPaused = paused;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function _beforeTokenTransfers(
        address /* from */,
        address /* to */,
        uint256 /* startTokenId */,
        uint256 /* quantity */
    ) internal virtual override {
        require(!contractPaused, "Contract is paused");
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        baseURILocked = true;
        for (uint256 i = 0; i < _nextTokenId(); i++) {
            if (_exists(i)) {
                emit PermanentURI(tokenURI(i), i);
            }
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Quantity exceeds supply");

        _safeMint(to, quantity);
        
    }
     //  =============   Getters    =============   //

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

 
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setPackContract(address addr) external onlyOwnerOrAdmin {
        PACK = PackContract(addr);
    }

    function setBurnAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _burnAuthorizedContract = authorizedContract;
    }

    //  =============   Getters    =============   //

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "<> contract URI";
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    
    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // ============================================================= //
    //                      Marketplace Controls                     //
    // ============================================================= //

    
    function approve(address to, uint256 tokenId) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[to] == false, "Marketplace is blocked");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) {
        require(_marketplaceBlocklist[operator] == false, "Marketplace is blocked");
        super.setApprovalForAll(operator, approved);
    }

    function blockMarketplace(address addr, bool blocked) public onlyOwnerOrAdmin {
        _marketplaceBlocklist[addr] = blocked;
    }

}

interface PackContract {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}