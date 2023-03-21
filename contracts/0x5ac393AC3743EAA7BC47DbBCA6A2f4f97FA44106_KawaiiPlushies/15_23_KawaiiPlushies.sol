// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KawaiiPlushies is ERC721A, ERC721ABurnable, ERC2981, Ownable, DefaultOperatorFilterer {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private kpClaimed;
    BitMaps.BitMap private internalBools;

    /* Constants */
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant KP_MACHINE_SUPPLY = 3333;
    uint256 public constant SUPPLY = 4444;
    uint96 public constant ROYALTY_BPS = 1000;
    address private constant ROYALTY_ADDRESS = address(0xB774aD33B7767F91c679694ffb0faCc06fC1c765); 

    // Use getAux to pack number of mints
    // 0        1         2  
    // KPMints  WL Mints  Public Mints
    uint8 public constant KPMINTS = 32;
    uint8 public constant WLMINTS = 16;
    uint8 public constant PUBLICMINTS = 0;

    // 0 = KP, 1 = WL, 2 = Public, 3 = IsRevealed
    uint8 public constant KP_ACTIVE = 0;
    uint8 public constant WL_ACTIVE = 1;
    uint8 public constant PUBLIC_ACTIVE = 2;
    uint8 public constant IS_REVEALED = 3;

    /* Variables */
    bytes32 public merkleRoot;
    uint128 public machineSupplyMinted = 0;
    uint128 public supplyMinted = 0;
    IERC721Enumerable kpMachines;
    string public baseTokenURI;
    string public suffixURI = ".json";
    string public unrevealedTokenURI = "https://arweave.net/KzSsWQ2MYezD6OlPduF-BWDL1XOVTHE816EAFeQHHq4";

    mapping(uint256 => uint256[]) public kpMachineMinted;

    /* Errors */
    error IncorrectAmountForMint();
    error IncorrectProof();
    error MachineAlreadyClaimed();
    error MaxMintPerWalletReached();
    error MaxSupplyReached();
    error NotOwnerOfMachine(address sender, uint256 tokenId);
    error SaleStillActive();
    error SaleNotActive();
    error SendToAddressZero();
    error TokenDoesNotExist(uint256 id);
    error WithdrawSendFailed();

    constructor(address _kpMachines, bytes32 _merkleRoot) ERC721A("Kawaii Plushies", "KAWAIIPLUSHIES") {
        kpMachines = IERC721Enumerable(_kpMachines);
        _setDefaultRoyalty(ROYALTY_ADDRESS, ROYALTY_BPS);
        merkleRoot = _merkleRoot;
    }

    function kpMachineMint(uint256[] calldata ids) external {
         if (!internalBools.get(KP_ACTIVE)) {
            revert SaleNotActive();
        }

        uint16 count = 0;
        uint256 next = _nextTokenId();
        (uint16 machineMint,,,uint64 aux) = unpackAux(msg.sender);

        for (uint16 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            if (kpMachines.ownerOf(tokenId) != msg.sender) {
                revert NotOwnerOfMachine(msg.sender, tokenId);
            }

            if (kpClaimed.get(tokenId)) {
                revert MachineAlreadyClaimed();
            }

            kpClaimed.set(tokenId);

            kpMachineMinted[tokenId].push(next);
            kpMachineMinted[tokenId].push(next+1);
            kpMachineMinted[tokenId].push(next+2);

            count = count + 3;
            next = next + 3;
        }

        pack(msg.sender, aux, machineMint+count, KPMINTS);
        machineSupplyMinted = machineSupplyMinted + count;
        _mint(msg.sender, count);
    }

    function plushlistMint(bytes32[] calldata merkleProof) payable external  {
        if (!internalBools.get(WL_ACTIVE)) {
            revert SaleNotActive();
        }

        (,uint16 wlMinted,,uint64 aux) = unpackAux(msg.sender);

        if (wlMinted == 1) {
            revert MaxMintPerWalletReached();
        }

        if (_totalMinted() + 1 > MAX_SUPPLY || supplyMinted + 1 > SUPPLY) {
            revert MaxSupplyReached();
        }

        if (!isPlushlisted(msg.sender, merkleProof)) {
            revert IncorrectProof();
        }
        
        pack(msg.sender, aux, wlMinted + 1, WLMINTS);
        supplyMinted = supplyMinted + 1;
        _mint(msg.sender, 1);
    }

    function publicMint() payable external {
        if (!internalBools.get(PUBLIC_ACTIVE)) {
            revert SaleNotActive();
        }

        (,,uint16 publicMinted, uint64 aux) = unpackAux(msg.sender);

        if (publicMinted == 1) {
            revert MaxMintPerWalletReached();
        }

        if (_totalMinted() + 1 > MAX_SUPPLY || supplyMinted + 1 > SUPPLY) {
            revert MaxSupplyReached();
        }
        
        pack(msg.sender, aux, publicMinted + 1, PUBLICMINTS);
        supplyMinted = supplyMinted + 1;
        _mint(msg.sender, 1);
    }

    function isMachineMintActive() external view returns (bool) {
        return internalBools.get(KP_ACTIVE);
    }

    function isPlushlistMintActive() external view returns (bool) {
        return internalBools.get(WL_ACTIVE);
    }

    function isPublicMintActive() external view returns (bool) {
        return internalBools.get(PUBLIC_ACTIVE);
    }

    function setPlushlistSaleActive(bool _isSaleActive) public onlyOwner {
        internalBools.setTo(WL_ACTIVE, _isSaleActive);
    }

    function setKPMachineActive(bool _active) public onlyOwner {
        internalBools.setTo(KP_ACTIVE, _active);
    }

    function setPublicSale(bool _active) public onlyOwner {
        internalBools.setTo(PUBLIC_ACTIVE, _active);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setURISuffix(string calldata _suffix) external onlyOwner {
        suffixURI = _suffix;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        internalBools.setTo(IS_REVEALED, _revealed);
    }

    function setUnrevealedTokenURI(string calldata _unrevealedURI) external onlyOwner {
        unrevealedTokenURI = _unrevealedURI;
    }

    function isPlushlisted(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function isPlushlistClaimed(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        (,uint16 wlMinted,,) = unpackAux(addr);
        return isPlushlisted(addr, _merkleProof) && (wlMinted == 1);
    }

    function machineClaimed(uint256 machineId) external view returns (bool) {
        return kpClaimed.get(machineId);
    }

    function machinesUnclaimedForAddress(address addr) public view returns (uint256) {
        uint256 bal = kpMachines.balanceOf(addr);
        uint256 unclaimed = 0;
        for (uint16 i = 0; i < bal; i++) {
            if (!kpClaimed.get(kpMachines.tokenOfOwnerByIndex(msg.sender, i))) {
                ++unclaimed;
            }
        }

        return unclaimed;
    }

    function machineIDsUnclaimedForAddress(address addr) external view returns (uint256[] memory) {
        uint256 count = machinesUnclaimedForAddress(addr);
        uint256[] memory ids = new uint256[](count);

        uint256 bal = kpMachines.balanceOf(addr);
        uint256 j = 0;

        for (uint16 i = 0; i < bal; i++) {
            uint256 id = kpMachines.tokenOfOwnerByIndex(msg.sender, i);
            if (!kpClaimed.get(id)) {
                ids[j] = id;
            }
        }

        return ids;
    }

    function pack(address addr, uint64 aux, uint16 value, uint16 offset) private {
        _setAux(addr, aux | (uint64(value) << offset));
    }

    function unpackAux(address addr) private view returns(uint16 machineMint, uint16 wlMint, uint16 publicMints, uint64 aux) {
        aux = _getAux(addr);
        machineMint = uint16(aux >> 32);
        wlMint = uint16(aux >> 16);
        publicMints = uint16(aux);
    }

    function getMachinesClaimMinted(address addr) external view returns (uint16 machineClaimMints){
        (machineClaimMints,,,) = unpackAux(addr);
    }

    function getPlushlistMinted(address addr) external view returns (uint16 wlMinted){
        (,wlMinted,,) = unpackAux(addr);
    }

    function getPublicMinted(address addr) external view returns (uint16 publicMinted){
        (,,publicMinted,) = unpackAux(addr);
    }

    function teamMint() external onlyOwner {
        supplyMinted = supplyMinted + 333;
        
        for (uint8 i = 0; i < 9; ++i) {
            _mint(address(0xa41AA743a1823d11e69EB53d507605dF39EaDab8), 37);
        }
    }

    function mintRemaining(address addr, uint128 quantity) external onlyOwner {
        if (internalBools.get(KP_ACTIVE) || internalBools.get(WL_ACTIVE) || internalBools.get(PUBLIC_ACTIVE)) {
            revert SaleStillActive();
        }
        supplyMinted = supplyMinted + quantity;
        _mint(addr, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (internalBools.get(IS_REVEALED)){
            string memory baseURI = baseTokenURI;
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), suffixURI))
                : "";
        } else {
            return unrevealedTokenURI;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public virtual override onlyOwner {
        super.burn(tokenId);
    }

    /* Operator Filter */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
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

    function withdraw(address to) public onlyOwner {
        if (to == address(0)) {
            revert SendToAddressZero();
        }

        uint256 amount = address(this).balance;

        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) {
            revert WithdrawSendFailed();
        }
    }
}