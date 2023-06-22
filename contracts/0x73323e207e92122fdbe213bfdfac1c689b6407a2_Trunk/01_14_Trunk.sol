// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "closedsea/src/OperatorFilterer.sol";

error MismatchedInputs();
error TrunkOpeningIsClosed();
error CannotOpenUnownedTrunk();
error ROTNFactoryNotOpenYet();
error AddressIsNull();
error TransferFailed();
error PublicSaleNotOpen();
error NoContractMints();
error MaxMintExceeded();
error NotEnoughEth();
error OnlyOwnerCanDrop();
error PresaleLimitExceeded();
error PresaleNotOpen();
error NotOnPresaleList();

abstract contract ROTNFactory {
    function openTrunk(address to, uint256 trunkId) public virtual returns (uint256);
}

contract Trunk is ERC721AQueryable, ERC2981, OperatorFilterer, ReentrancyGuard, Ownable {

    uint256 public constant SUPPLY = 6666;
    address public airdropOwner = 0xC298d05155e36Ee91090478A66485eE0395FFca5;
    
    address private rotnContract;
    bool public trunksOpenable;

    bool public preSaleOpen;
    bool public publicSaleOpen;
    uint256 public price;

    bytes32 public merkleRoot;

    string private _baseTokenURI;

    bool public operatorFilteringEnabled = true;

    constructor(
        string memory initialBaseURI,
        address payable royaltiesReceiver
    ) ERC721A("ROTN Trunk", "TRUNK") {
        _baseTokenURI = initialBaseURI;
        setRoyaltyInfo(royaltiesReceiver, 500);
        _registerForOperatorFiltering();
    }    
    
    function openTrunk(uint256 trunkId) public nonReentrant() returns (uint256) {
        if (!trunksOpenable) {
            if (msg.sender != owner()) revert TrunkOpeningIsClosed();
        }

        address to = ownerOf(trunkId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotOpenUnownedTrunk();
        }

        ROTNFactory factory = ROTNFactory(rotnContract);

        _burn(trunkId, true);

        uint256 rotnTokenId = factory.openTrunk(to, trunkId);
        return rotnTokenId;
    }

    // ======== Airdrops ========
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external {
        if (receivers.length != amounts.length || receivers.length == 0) revert MismatchedInputs();
        if (msg.sender != airdropOwner) revert OnlyOwnerCanDrop();

        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }


    // ======== Pre-sale ========

    function preSaleMint(uint64 quantity, bytes32[] memory proof) external payable {
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + quantity > SUPPLY) revert MaxMintExceeded();

        uint64 numAddressPresaleMints = _getAux(msg.sender);
        if (numAddressPresaleMints + quantity > 3) revert PresaleLimitExceeded();

        if (!preSaleOpen) revert PresaleNotOpen();
        if (MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            _mint(msg.sender, quantity);
            _refundOverPayment(quantity);
            _setAux(msg.sender, numAddressPresaleMints + quantity);
        } else {
            revert NotOnPresaleList();
        }
    }

    // ======== Public Sale ========

    function publicMint(uint64 quantity) external payable {
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + quantity > SUPPLY) revert MaxMintExceeded();

        if (!publicSaleOpen) revert PublicSaleNotOpen();
        
        _mint(msg.sender, quantity);
        _refundOverPayment(quantity);
    }

    function _refundOverPayment(uint256 quantity) internal {
        if (msg.value < quantity * price) revert NotEnoughEth();
        if (msg.value > quantity * price) {
            payable(msg.sender).transfer(msg.value - (quantity * price));
        }
    }

    // ======== Info ========

    function trunksOpenedByAddress(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalTrunksOpened() external view returns (uint256) {
        return _totalBurned();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

     // ======== OperatorFilterer ========

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    // ======== IERC2981 ========

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // ======== Admin ========

    function toggleTrunksOpenable() external onlyOwner {
        if (rotnContract == address(0)) revert ROTNFactoryNotOpenYet();
        trunksOpenable = !trunksOpenable;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setROTNContract(address contractAddress) external onlyOwner {
        rotnContract = contractAddress;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setAirdropOwner(address addr) external onlyOwner {
        if (addr == address(0)) revert AddressIsNull();
        airdropOwner = addr;
    }

    function togglePreSale() external onlyOwner {
        preSaleOpen = !preSaleOpen;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}