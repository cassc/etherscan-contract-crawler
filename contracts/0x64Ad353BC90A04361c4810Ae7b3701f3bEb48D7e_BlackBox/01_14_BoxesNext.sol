// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error MismatchedInputs();
error BoxOpeningIsClosed();
error CannotOpenUnownedBox();
error RENGAFactoryNotOpenYet();
error AddressIsNull();
error TransferFailed();
error PublicSaleClosed();
error NoContractMints();
error MaxMintExceeded();
error AlreadyMintedAddress();
error InvalidSignature();
error NotEnoughEth();
error OnlyOwnerCanDrop();

abstract contract RengaFactory {
    function openBox(address to, uint256 boxId) public virtual returns (uint256);
}

contract BlackBox is ERC721AQueryable, ReentrancyGuard, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_BOX_DROP = 7_500;
    uint256 public constant MAX_BOXES = 10_000;
    
    address private rengaContract;
    bool public canOpenBox;

    address public airdropOwner = 0x68cBE370A1b35f3f185172c063BBbabF836d7Ecc;
    address public sigSigner = 0x68cBE370A1b35f3f185172c063BBbabF836d7Ecc;

    bool public raffleMintOpen;
    bool public waitlistMintOpen;
    uint256 public publicMintPrice;

    string private _baseTokenURI;

    constructor() ERC721A("Black Box", "BOX") {}    
    
    function openBox(uint256 boxId) public nonReentrant() returns (uint256) {
        if (!canOpenBox) {
            if (msg.sender != owner()) revert BoxOpeningIsClosed();
        }

        address to = ownerOf(boxId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotOpenUnownedBox();
        }

        RengaFactory factory = RengaFactory(rengaContract);

        _burn(boxId, true);

        uint256 rengaTokenId = factory.openBox(to, boxId);
        return rengaTokenId;
    }

    // ======== Airdrops ========

    function seasonsGreetings(address[] calldata receivers, uint256[] calldata amounts) external {
        if (receivers.length != amounts.length || receivers.length == 0) revert MismatchedInputs();
        if (msg.sender != airdropOwner) revert OnlyOwnerCanDrop();

        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ======== Public Sale ========

    function findBox(bytes calldata sig) external payable {
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + 1 > MAX_BOXES) revert MaxMintExceeded();
        if (_getAux(msg.sender) == 1) revert AlreadyMintedAddress();

        bytes memory data;

        // once waitlist mint opens, only check waitlist signatures
        if (waitlistMintOpen) {
            data = abi.encodePacked(msg.sender, uint256(1));
        } else if (raffleMintOpen) {
            data = abi.encodePacked(msg.sender, uint256(0));
        } else {
            revert PublicSaleClosed();
        }

        address signedAddr = keccak256(data)
            .toEthSignedMessageHash()
            .recover(sig);

        if (sigSigner != signedAddr) revert InvalidSignature();
        
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
        _refundOverPayment(publicMintPrice);
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert NotEnoughEth();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function alreadyMinted(address addr) external view returns (bool) {
        return _getAux(addr) == 1;
    }

    // ======== Info ========

    function boxesOpened(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalBoxesOpened() external view returns (uint256) {
        return _totalBurned();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // ======== Royalty ========

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ======== Admin ========

    function toggleCanOpenBox() external onlyOwner {
        if (rengaContract == address(0)) revert RENGAFactoryNotOpenYet();
        canOpenBox = !canOpenBox;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setRengaContract(address contractAddress) external onlyOwner {
        rengaContract = contractAddress;
    }

    function setSigSigner(address signer) external onlyOwner {
        if (signer == address(0)) revert AddressIsNull();
        sigSigner = signer;
    }

    function setAirdropOwner(address addr) external onlyOwner {
        if (addr == address(0)) revert AddressIsNull();
        airdropOwner = addr;
    }

    function toggleRaffleMint() external onlyOwner {
        raffleMintOpen = !raffleMintOpen;
    }

    function toggleWaitlistMint() external onlyOwner {
        waitlistMintOpen = !waitlistMintOpen;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}