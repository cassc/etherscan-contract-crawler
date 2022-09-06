// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error MismatchedInputs();
error PassOpeningIsClosed();
error CannotOpenUnownedPass();
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
    function openPass(address to, uint256 passId) public virtual returns (uint256);
}

contract TheBlanks is ERC721AQueryable, ReentrancyGuard, ERC2981, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_PASS_DROP = 5555;
    uint256 public constant MAX_PASSES = 5555;
    uint256 public constant maxPerAddress = 2;
    
    address private rengaContract;
    bool public canOpenPass;

    address public airdropOwner = 0x01B80863b5d681Bf0Ef78Ff3Fed14a93b0200031;
    address public sigSigner = 0x01B80863b5d681Bf0Ef78Ff3Fed14a93b0200031;

    bool public raffleMintOpen;
    bool public waitlistMintOpen;
    uint256 public publicMintPrice;

    string private _baseTokenURI;


    mapping(address => uint256) mintCount;

    modifier limitMint {
        require(mintCount[msg.sender] < maxPerAddress);
        mintCount[msg.sender]++;
        _;
    }

    constructor() ERC721A("The Blanks", "BLANKS") {}    
    
    function openPass(uint256 passId) public nonReentrant() returns (uint256) {
        if (!canOpenPass) {
            if (msg.sender != owner()) revert PassOpeningIsClosed();
        }

        address to = ownerOf(passId);

        if (to != msg.sender) {
            if (msg.sender != owner()) revert CannotOpenUnownedPass();
        }

        RengaFactory factory = RengaFactory(rengaContract);

        _burn(passId, true);

        uint256 rengaTokenId = factory.openPass(to, passId);
        return rengaTokenId;
    }

    // ======== Airdrops ========

    function remint(address[] calldata receivers, uint256[] calldata amounts) external {
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

    function findPass() external payable limitMint{
        if (tx.origin != msg.sender) revert NoContractMints();
        if (_totalMinted() + 1 > MAX_PASSES) revert MaxMintExceeded();
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

    function passesOpened(address addr) external view returns (uint256) {
        return _numberBurned(addr);
    }

    function totalPassesOpened() external view returns (uint256) {
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

    function toggleCanOpenPass() external onlyOwner {
        if (rengaContract == address(0)) revert RENGAFactoryNotOpenYet();
        canOpenPass = !canOpenPass;
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