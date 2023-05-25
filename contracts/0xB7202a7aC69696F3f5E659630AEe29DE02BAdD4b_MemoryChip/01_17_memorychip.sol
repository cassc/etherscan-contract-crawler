//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// =============================================================
//                           ROCKSTARS
// =============================================================

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "solmate/src/utils/MerkleProofLib.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "solmate/src/utils/LibString.sol";
import "solmate/src/auth/Owned.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// =============================================================
//
//   ▄████  ██▓  ▄████  ▄▄▄       ▄████▄   ██▓▄▄▄█████▓▓██   ██▓
//  ██▒ ▀█▒▓██▒ ██▒ ▀█▒▒████▄    ▒██▀ ▀█  ▓██▒▓  ██▒ ▓▒ ▒██  ██▒
// ▒██░▄▄▄░▒██▒▒██░▄▄▄░▒██  ▀█▄  ▒▓█    ▄ ▒██▒▒ ▓██░ ▒░  ▒██ ██░
// ░▓█  ██▓░██░░▓█  ██▓░██▄▄▄▄██ ▒▓▓▄ ▄██▒░██░░ ▓██▓ ░   ░ ▐██▓░
// ░▒▓███▀▒░██░░▒▓███▀▒ ▓█   ▓██▒▒ ▓███▀ ░░██░  ▒██▒ ░   ░ ██▒▓░
//  ░▒   ▒ ░▓   ░▒   ▒  ▒▒   ▓▒█░░ ░▒ ▒  ░░▓    ▒ ░░      ██▒▒▒ 
//   ░   ░  ▒ ░  ░   ░   ▒   ▒▒ ░  ░  ▒    ▒ ░    ░     ▓██ ░▒░ 
// ░ ░   ░  ▒ ░░ ░   ░   ░   ▒   ░         ▒ ░  ░       ▒ ▒ ░░  
//       ░  ░        ░       ░  ░░ ░       ░            ░ ░     
//                              ░                      ░ ░     
//
// Yo! Welcome to Giga City, a place that's seen it all. This
// city was once vibrant, but it fell victim to corporate greed
// and government's insatiable need for control. Misguided policies
// and a relentless pursuit of wealth centralization sparked social
// unrest, changing the city forever. Now, Giga City stands as a
// testament to what can happen when the balance is lost.
//
// ... mfer. Listen. I really appreciate you checking out the project.
// Not sure how you got here, or if GC is released already or not. But
// I have been working on GC almost every night for the past year. I've
// poured every last drip of blood and sweat into this thing so I hope
// it fucking shows. No matter if you own this GC or not, no matter
// if you just flip it and move on or hold. Thank you for checking it out.
// But watch out ...
//
// I'll do everything that I to get you on this ship with me!

// =============================================================
//                          ASSOCIATES
// =============================================================

abstract contract GigaCityContract {
    function implant(address to) external virtual;
}

abstract contract FilthyPeasantsContract {
    function ownerOf(uint tokenId) external virtual view returns(address);
}

// =============================================================
//                            ERRORS
// =============================================================

error TransferFailed();
error NoCashForMint();
error SupplyExceeded();
error NoFilthyMintYet();
error CantMintFilthy();
error NoCorpoMintYet();
error CantMintCorpo();
error NoBotMintYet();
error YouCantImplantNow();
error AddressQuantityExceeded();
error PeasantAlreadyMinted();
error ChipDoesNotExist();
error CallerIsNotUser();

// =============================================================
//                             RPILL
// =============================================================

contract MemoryChip is
    DefaultOperatorFilterer,
    ERC721AQueryable,
    ERC2981,
    Owned,
    ReentrancyGuard {

    // What is the supply cap?
    uint256 private _supplyCap;

    // How many NFTs we want ppl to mint?
    uint256 private _maxMintPerAddress;

    // Same price for everyone.
    uint256 private _mintPrice;

    // Filthy fucking peasants first.
    bool public peasantMint;

    // How many peasants have minted?
    uint256 private _peasantsMintCounter;

    // Where the peasants at?
    address private _peasantContract;

    // Mapping all the peasants that have minted.
    mapping(uint256 => bool) private _peasantsMinted;

    // Corpos second
    bool public corpoMint;

    // Corpo merkle root
    bytes32 private _corpoRoot;

    // If it gets to it public last
    bool private botMint;

    // Where are our assets hosted?
    string private _baseTokenURI;
    
    // Once/if we will transition to IPFS this will come in handy
    string private _uriSuffix = '';

    // Let's get on with it
    bool public canImplant;

    // Where is GC at?
    address private _gigaCityContract;

    // =============================================================
    //                            CONSTRUCTOR
    // =============================================================

    constructor(address peasantContract_, uint256 supplyCap_, uint256 maxMintPerAddress_) ERC721A("Memory Chip", "MC") Owned(msg.sender) {
        _peasantContract = peasantContract_;
        _supplyCap = supplyCap_;
        _maxMintPerAddress = maxMintPerAddress_;

        // At 5.55% Let's encourage implanting our chips 
        _setDefaultRoyalty(_msgSenderERC721A(), 555);
    }

    // =============================================================
    //                        MAKING THE DEAL
    // =============================================================

    function implant(uint256 cardId_) external nonReentrant() {
        // If implanting is closed, you can't make a deal brother.
        if (!canImplant) revert YouCantImplantNow();
        // If you are not owner you can't make a deal.
        // We don't need to check the ownership here.
        // _burn will revert if you are not the owner.
        // if (_msgSenderERC721A() != ownerOf(cardId_)) revert NotYourMemoryChip();
        // Burn this token.
        _burn(cardId_, true);
        // We will be using other contract.
        GigaCityContract factory = GigaCityContract(_gigaCityContract);
        // And finally mint a new one.
        factory.implant(_msgSenderERC721A());
    }

    // =============================================================
    //                          MINT HELPERS
    // =============================================================

    function _isWithinSupply(uint256 quantity_) private view {
        // Are we exceeding our supply cap?
        if (_supplyCap < _totalMinted() - _peasantsMintCounter + quantity_) revert SupplyExceeded();
    }

    function _isWithinWalletLimit(uint256 quantity_) private view {
        // Did the user already exceed the allowed limit?
        if (_numberMinted(_msgSenderERC721A()) + quantity_ > _maxMintPerAddress) revert AddressQuantityExceeded();
    }

    function _hasEnoughCash(uint256 quantity_) private view {
        // Are you sending enough cash for mint?
        if (msg.value < _mintPrice * quantity_) revert NoCashForMint();
    }

    function _callerIsUser() private view {
        if (tx.origin != _msgSenderERC721A()) revert CallerIsNotUser();
    }

    // =============================================================
    //                             TREASURY
    // =============================================================

    // How am I going to mint the treasury?
    function mintTreasury(address address_, uint256 quantity_) external onlyOwner {
        // Are we exceeding a supply cap?
        _isWithinSupply(quantity_);
        // We mint for free
        _mint(address_, quantity_);
    }

    // =============================================================
    //                           MINT FILTHY
    // =============================================================

    // How are peasants going to mint? Mfers mint filthy!
    function mintFilthy(uint256 peasantId_) external {
        // Only users can mint
        _callerIsUser();
        // Is filthy mint on?
        if (!peasantMint) revert NoFilthyMintYet();
        // Are we exceeding a supply cap?
        // I don't think we need to check. There is only 333 peasants
        // and the supply cannot be changed. In fact checking the total
        // supply would make the code unnecessarily complicated since
        // peasants need reserved capacity to mint.
        // _isWithinSupply(_quantity);
        // Are you filthy?
        if (FilthyPeasantsContract(_peasantContract).ownerOf(peasantId_) != _msgSenderERC721A()) revert CantMintFilthy();
        // Has the peasant been redeemed?
        if (_peasantsMinted[peasantId_] == true) revert PeasantAlreadyMinted();
        // If not, it is redeemed now
        _peasantsMinted[peasantId_] = true;
        // We need to know how many filthys have minted
        _peasantsMintCounter += 1;
        // And we finally mint.
        _mint(_msgSenderERC721A(), 2);
    }

    // =============================================================
    //                         MINT PRIVILEGED
    // =============================================================

    // How is waitlist going to mint?
    function mintCorpo(bytes32[] calldata proof_, uint256 quantity_) external payable {
        // Only users can mint
        _callerIsUser();
        // Is privileged mint on?
        if (!corpoMint) revert NoCorpoMintYet();
        // Are we exceeding a supply cap?
        _isWithinSupply(quantity_);
        // Is the address overallocating?
        _isWithinWalletLimit(quantity_);
        // Are you actualy privileged?
        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        if (!MerkleProofLib.verify(proof_, _corpoRoot, leaf)) revert CantMintCorpo();
        // Do you have enough cash?
        _hasEnoughCash(quantity_);
        // We continue minting. 
        _mint(_msgSenderERC721A(), quantity_);
    }

    // =============================================================
    //                         MINT PUBLIC
    // =============================================================

    function mintBot(uint256 quantity_) external payable {
        // Only users can mint
        _callerIsUser();
        // Is the public mint on?
        if (!botMint) revert NoBotMintYet();
        // Are we exceeding a supply cap?
        _isWithinSupply(quantity_);
        // Is the address overallocating?
        _isWithinWalletLimit(quantity_);
        // Do you have enough cash?
        _hasEnoughCash(quantity_);
        // If you are good, you are good.
        _mint(_msgSenderERC721A(), quantity_);
    }

    // =============================================================
    //                              INFO
    // =============================================================

    function chipsImplanted(address addr_) external view returns (uint256) {
        return _numberBurned(addr_);
    }

    function totalChipsImplanted() external view returns (uint256) {
        return _totalBurned();
    }

    function peasantMinted(uint256 peasantId_) external view returns (bool) {
        return _peasantsMinted[peasantId_] == true;
    }

    function totalPeasantsMinted() external view returns (uint256) {
        return _peasantsMintCounter;
    }

    // =============================================================
    //                              METADATA
    // =============================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId_)) revert ChipDoesNotExist();

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, LibString.toString(tokenId_), _uriSuffix))
            : '';
    }

    // =============================================================
    //                              ADMIN
    // =============================================================

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setURISuffix(string calldata uriSuffix_) external onlyOwner {
        _uriSuffix = uriSuffix_;
    }

    function setGigaCityContract(address contractAddress_) external onlyOwner {
        _gigaCityContract = contractAddress_;
    }

    function setCorpoRoot(bytes32 newRoot_) external onlyOwner {
        _corpoRoot = newRoot_;
    }

    function setMaxMintPerAddress(uint256 maxMintPerAddress_) external onlyOwner {
        _maxMintPerAddress = maxMintPerAddress_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        _mintPrice = mintPrice_;
    }

    function toggleCorpoMint() public onlyOwner {
        corpoMint = !corpoMint;
    }

    function togglePeasantMint() public onlyOwner {
        peasantMint = !peasantMint;
    }

    function toggleBotMint() external onlyOwner {
        botMint = !botMint;
    }

    function openBusiness() external onlyOwner {
        canImplant = !canImplant;
    }

    // =============================================================
    //                           WITHDRAW
    // =============================================================

    function withdraw() external onlyOwner nonReentrant() {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    // =============================================================
    //                  ALLOWED OPERATORS OVERRIDES
    // =============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable 
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //                           INTERFACE
    // =============================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}