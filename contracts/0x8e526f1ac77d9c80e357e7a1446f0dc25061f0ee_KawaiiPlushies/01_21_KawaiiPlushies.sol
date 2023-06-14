// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KawaiiPlushies is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private kpClaimed;

    /* Constants */
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant KP_MACHINE_SUPPLY = 2222;
    uint256 public constant SUPPLY = 5555;
    uint96 public constant ROYALTY_BPS = 500;
    address private constant ROYALTY_ADDRESS = address(0xa41AA743a1823d11e69EB53d507605dF39EaDab8); 
    uint256 public constant PRICE = 40000000000000000;  // 0.044

    /* Variables */
    bool public isSaleActive = false;
    bool public isKPMachineActive = false;
    bool public isPublicSaleActive = false;
    bytes32 public merkleRoot;
    uint256 public machineSupplyMinted = 0;
    uint256 public supplyMinted = 0;
    IERC721Enumerable kpMachines;
    string public baseTokenURI;
    string public suffixURI = ".json";
    bool public isRevealed = false;
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
         if (!isKPMachineActive) {
            revert SaleNotActive();
        }

        uint16 count = 0;
        uint256 next = _nextTokenId();

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

            count = count + 2;
            next = next + 2;
        }

        machineSupplyMinted = machineSupplyMinted + count;
        _mint(msg.sender, count);
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint8 quantity) payable external  {
        if (!isSaleActive) {
            revert SaleNotActive();
        }

        if (quantity > 2) {
            revert IncorrectAmountForMint();
        }

        if (_getAux(msg.sender) == 1) {
            revert MachineAlreadyClaimed();
        }

        if (_totalMinted() + quantity > MAX_SUPPLY || supplyMinted + quantity > SUPPLY) {
            revert MaxSupplyReached();
        }

        if (!isWhitelisted(msg.sender, merkleProof)) {
            revert IncorrectProof();
        }

        if (msg.value != PRICE * quantity) {
            revert IncorrectAmountForMint();
        }

        _setAux(msg.sender, 1);
        supplyMinted = supplyMinted + quantity;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint8 quantity) payable external {
        if (!isPublicSaleActive) {
            revert SaleNotActive();
        }

        if (quantity > 2) {
            revert IncorrectAmountForMint();
        }

        if (_numberMinted(msg.sender) + quantity > 2) {
            revert MaxMintPerWalletReached();
        }

        if (_totalMinted() + quantity > MAX_SUPPLY || supplyMinted + quantity > SUPPLY) {
            revert MaxSupplyReached();
        }

        if (msg.value != PRICE * quantity) {
            revert IncorrectAmountForMint();
        }
        
        supplyMinted = supplyMinted + quantity;
        _mint(msg.sender, quantity);
    }

    function setSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setKPMachineActive(bool _active) public onlyOwner {
        isKPMachineActive = _active;
    }

    function setPublicSale(bool _active) public onlyOwner {
        isPublicSaleActive = _active;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        isRevealed = _revealed;
    }

    function setUnrevealedTokenURI(string calldata _unrevealedURI) external onlyOwner {
        unrevealedTokenURI = _unrevealedURI;
    }

    function isWhitelisted(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function whitelistClaimed(address addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        return isWhitelisted(addr, _merkleProof) && _getAux(addr) == 1;
    }

    function machineClaimed(uint256 machineId) external view returns (bool) {
        return kpClaimed.get(machineId);
    }

    function numberOfMintsForAddress(address addr) external view returns (uint256) {
        return _numberMinted(addr);
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

    function mintRemaining(address addr, uint256 quantity) external onlyOwner {
        if (isKPMachineActive || isPublicSaleActive || isSaleActive) {
            revert SaleStillActive();
        }
        _mint(addr, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if (isRevealed){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), suffixURI))
                : "";
        } else {
            return unrevealedTokenURI;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    /* Operator Filter */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
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