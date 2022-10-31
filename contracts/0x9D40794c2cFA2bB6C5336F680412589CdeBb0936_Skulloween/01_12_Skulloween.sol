// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▓▓▓▓▓▓▓▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░▒▓▓▒▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒░░░░░░░░░░░░░░░░░░░░░░
░░▒▓▓▓▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▓▒░░░░░░░░░░░░░░░░░░░░░
░▓▓▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓░░░░░░░░░░░░░░░░░░░░░
▓▓▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓░░░░░░░░░░░░░░░░░░░░░
▓▓▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓░░░░░░░░░░░░░░░░░░░░░
▓▓▓▓▓▓▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒░░░░░░░░░░░░░░░░░░░░░
▓▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓░░░░░░░░░░░░░░░░░░░░░
▒▓▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓███▓▓▒░░░░░░░░░░░░░░░░░░░
░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▓▓█████████▓▓▒▒▒▒▒▓██████▓▓░░░░░░░░░░░░░░░░░░░
░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▓██████████████▒▒▒▒▒▓██████▓▓░░░░░░░░░░░░░░░░░░░
░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▒▓███████████████▓▒▒▒▒▓██████▓▒░░░░░░░░░░░░░░░░░░░
░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▓███████████████▒▒▓▓▒▒▓████▓▓▒░░░░░░░░░░░░░░░░░░░
░░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒▒▓▓█████████████▓▒▓▓▓▓▓▒▓███▓▓░░░░░░░░░░░░░░░░░░░░
░░░▒▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓███████▓▓▓▓▓▓███▓▓▒▒▓▓▓▒▓▒░░░░░░░░░░░░░░░░░░░
░░░░▓▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▒▓▓▒▓███▓▓▓▒▒▓▒▒▓▒░░░░░░░░░░░░░░░░░░░
░░░░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▓█▓▓▓▓▓▒▒▓▒▓▓░░░░░░░░░░░░░░░░░░░░
░░░░░░▓▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒█▓▒░░░░░░░░░░░░░░░░░░░░░
░░░░░░░▒▓▓▒▒▒▓▒▒▓▓▓▒▒▒▓██▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░▒▒▒▒▓▓▒▒▒▒▓▓▓▓████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░▓▒▒▒▒▒▒▓▒▓███▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒░░░░░░░░░░░░░░░░░▓░░░░░
░░░░░░░░░░░░░░░░▓▒▒▒▒▒▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░▓▓▒░░░▒
░░░░░░░░░░░░░░░░░▓▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓███▓▓▓▓▓▓▒▒▒░░░░░░░░░░░▒▓▒░░░▒▓▓░░▓▓
░░░░░░░░░░░░░░░░░▒▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▒▒▓▓▓▓▓▓▓░░░░░░░░▓▒░░▓▓▒░░▓▓▓▓▓▓░
░░░░░░░░░░░░░▒▒▒▓▒▒▒▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▒░░░░░░░░▓▓▒░▓▓▓░▓▒▓▓▓▓░░
░░░░░░░▒▒▒▓▓▒▓▒▒▓▓▒▓▓▓████▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░░░░▒▓▓░▓▓▓▓▓▒▓▓▒░░░
░░░░▒▓▓▓▒▒▒▒▒▓▒▓▓▓▒▒▓▒▓▓▓▓██▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░▓▓▒▓▒▓▓▒▒░░░░░░
░░░░▓▓▒▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░▒▓▓▓▓▓▒░░░░░░░░░
░░░▒▓▒▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▓▓▓▓▓▓▓░░░░░░░░▓▓▓▒▓▓▓░░░░░░░░░░
░░░▓▒▒▓▒▒▒▓▓▒▒▓▓▒▒▓▓▓▓▓▓▓▓▒▒▒▒▒▒▓▓▓▓▓▒▓▓▓▒▒▒▓░░░░░░░▒▓▒▓▒▒▓░░░░░░░░░░░
░░░▓▓▒▒▓▓▓▓▓▒▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▓▓▓▒▒▓▓▒▓▓▓▒▒▓▒░░░░░░▒▒▒▓▒▓░░░░░░░░░░░░
░░▒▓▓▒▒▓▓▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒▒▒▓▓▓▓▓▓▓▒▓▒░▓▓▒▓░░░░░░▓▒▓▒▓░░░░░░░░░░░░░
░░▓▓▓▒▓░▓▒▓▓▓▒▒▒▓▒▒▓▒▓▓▓▓▓▓▓▒▒▓▓▓▒▒▓▓▓▓▓▓░▓▓▓▓▒░░░░░▓▓▓▓▒░░░░░░░░░░░░░
░░▓▒▒▒▓▒▓▓▒▓▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▓▒▓▓▓▓▒▓▓▓▒▓▒▓▓▒▓░░░░▓▒▓▒▓░░░░░░░░░░░░░░
░▓▒▒▒▓░▓▒▓▓▒▓▓▒▓▓▓▓▓▓▓▓▓▓▒▒▒▓▒▓▒▓▒░░▒▓▓▒▒▓░▒▓▓▓▒░░▒▓▓▓▓░░░░░░░░░░░░░░░
░▓▒▒▒▒░▓▒▒▓▓▒▒▓▓▒░▒▓▓▓▓▓▓▓▓▓▒▒▓▓▒▓▒▒▒▓▒▒▓▒░░▒▓▒▓░░▓▒▓▒▓░░░░░░░░░░░░░░░
*/
contract Skulloween is ERC721A, Ownable, ReentrancyGuard {
    enum MintPhase {
        NONE,
        PAUSED,
        MINTING,
        SOLD_OUT
    }

    uint8 public constant MAX_PER_WALLET = 6;
    uint16 public constant COLLECTION_SIZE = 1000;
    uint64 public constant MINT_PRICE = .02 ether;

    string private baseURI;
    MintPhase public mintPhase = MintPhase.NONE;

    constructor() ERC721A("Skulloween", "SKULL") {}

    function mint(uint8 _quantity) external payable nonReentrant {
        if (mintPhase != MintPhase.MINTING) {
            revert IncorrectMintPhase();
        }
        if (msg.value != MINT_PRICE * _quantity) {
            revert IncorrectPayment();
        }
        if (totalSupply() + _quantity > COLLECTION_SIZE) {
            revert InsufficientSupply();
        }
        if (balanceOf(msg.sender) + _quantity > MAX_PER_WALLET) {
            revert ExceedsMaxAllocation();
        }

        _safeMint(msg.sender, _quantity);
    }

    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function getMintPhase() public view returns (MintPhase) {
        return mintPhase;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function devMint(uint256 _quantity) external onlyOwner {
        if (mintPhase != MintPhase.NONE) {
            revert IncorrectMintPhase();
        }
        if (totalSupply() + _quantity > COLLECTION_SIZE) {
            revert InsufficientSupply();
        }

        _safeMint(owner(), _quantity);
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    fallback() external payable {
        revert NotImplemented();
    }

    receive() external payable {
        revert NotImplemented();
    }
}

/**
 * Incorrect mint phase for action
 */
error IncorrectMintPhase();

/**
 * Incorrect payment amount
 */
error IncorrectPayment();

/**
 * Insufficient supply for action
 */
error InsufficientSupply();

/**
 * Exceeds max allocation
 */
error ExceedsMaxAllocation();

/**
 * Withdraw failed
 */
error WithdrawFailed();

/**
 * Function not implemented
 */
error NotImplemented();