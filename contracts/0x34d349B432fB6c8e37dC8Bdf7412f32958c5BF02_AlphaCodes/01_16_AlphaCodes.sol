// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//   ▄████████  ▄█          ▄███████▄    ▄█    █▄       ▄████████       ▄████████  ▄██████▄  ████████▄     ▄████████    ▄████████
//  ███    ███ ███         ███    ███   ███    ███     ███    ███      ███    ███ ███    ███ ███   ▀███   ███    ███   ███    ███
//  ███    ███ ███         ███    ███   ███    ███     ███    ███      ███    █▀  ███    ███ ███    ███   ███    █▀    ███    █▀
//  ███    ███ ███         ███    ███  ▄███▄▄▄▄███▄▄   ███    ███      ███        ███    ███ ███    ███  ▄███▄▄▄       ███
//▀███████████ ███       ▀█████████▀  ▀▀███▀▀▀▀███▀  ▀███████████      ███        ███    ███ ███    ███ ▀▀███▀▀▀     ▀███████████
//  ███    ███ ███         ███          ███    ███     ███    ███      ███    █▄  ███    ███ ███    ███   ███    █▄           ███
//  ███    ███ ███▌    ▄   ███          ███    ███     ███    ███      ███    ███ ███    ███ ███   ▄███   ███    ███    ▄█    ███
//  ███    █▀  █████▄▄██  ▄████▀        ███    █▀      ███    █▀       ████████▀   ▀██████▀  ████████▀    ██████████  ▄████████▀

import {ERC721AQueryable, ERC721A, IERC721A} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InsufficientAmountSent();
error ExceedsTotalSupply();
error NotOnAllowlist();
error PublicMintInactive();
error AllowlistMintInactive();
error NoFundsToWithdraw();
error TransferFailed();

contract AlphaCodes is ERC721AQueryable, Ownable, ERC2981, DefaultOperatorFilterer {
    uint256 public constant MAX_BATCH_SIZE = 5;
    uint256 public maxSupply = 1555;
    uint256 public allowlistMintPrice = 0.049 ether;
    uint256 public publicMintPrice = 0.049 ether;
    bool public isPublicMintActive = false;
    bool public isAllowlistMintActive = false;
    string public baseTokenURI;
    bytes32 public merkleRoot;

    constructor() ERC721A("AlphaCodes", "ALPHACODES") {}

    /*------------------------------MINT  ------------------------------*/
    /// @notice Public mint when public sale is active
    function mintPublic(uint256 nMints) external payable {
        if (!isPublicMintActive) revert PublicMintInactive();
        if (msg.value != publicMintPrice * nMints) revert InsufficientAmountSent();
        if (totalSupply() + nMints > maxSupply) revert ExceedsTotalSupply();

        _mint(msg.sender, nMints);
    }

    /// @notice Allowlist mint when allowlist sale is active
    /// @dev Uses a Merkle tree to verify if address is on allowlist
    function mintAllowlist(bytes32[] calldata _proof, uint256 nMints) external payable {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));

        if (!isAllowlistMintActive) revert AllowlistMintInactive();
        if (!MerkleProof.verify(_proof, merkleRoot, node)) revert NotOnAllowlist();
        if (msg.value != allowlistMintPrice * nMints) revert InsufficientAmountSent();
        if (totalSupply() + nMints > maxSupply) revert ExceedsTotalSupply();

        _mint(msg.sender, nMints);
    }

    /// @notice Reserved mints for owner
    /// @dev MAX_BATCH_SIZE enforces a fixed batch size when minting large quantities with ERC721A
    function mintReserve(uint256 nMints) external onlyOwner {
        if (totalSupply() + nMints > maxSupply) revert ExceedsTotalSupply();

        uint256 remainder = nMints % MAX_BATCH_SIZE;
        unchecked {
            uint256 nBatches = nMints / MAX_BATCH_SIZE;
            for (uint256 i; i < nBatches; ++i) {
                _mint(msg.sender, MAX_BATCH_SIZE);
            }
        }
        if (remainder != 0) {
            _mint(msg.sender, remainder);
        }
    }

    /*--------------------------- ONLY OWNER --------------------------------*/
    /// @notice Allows the owner to set the maximum supply of the collection
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /// @notice Allows the owner to set the public mint price
    function setPublicMintPrice(uint256 _mintPrice) external onlyOwner {
        publicMintPrice = _mintPrice;
    }

    /// @notice Allows the owner to set the allowlist Merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Allows the owner to set the base URI
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Allows the owner to turn the public mint on or off
    function togglePublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    /// @notice Allows the owner to turn the allowlist mint on or off
    function toggleAllowlistMintActive() external onlyOwner {
        isAllowlistMintActive = !isAllowlistMintActive;
    }

    /// @notice Allows the owner to set the default royalty.
    /// @dev feeNumerator is divided by 10000 basis points, eg. feeNumerator = 500 is 5% royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Allows the owner to delete the default royalty
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Allows contract to transfer and amount of funds to an address
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = payable(_address).call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Allows the owner to withdraw and split contract funds
    function withdrawAll() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert NoFundsToWithdraw();
        _withdraw(address(0xB7F9fa83EB9e0A5274a63E036c13C5e29D7Fd387), (contractBalance * 5) / 100);
        _withdraw(address(0xED1ccA805809292Fb02BAE713E1f06cd632437F8), address(this).balance);
    }

    /// @notice Allows the owner to withdraw contract balance
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert NoFundsToWithdraw();
        _withdraw(address(0x768090beEe26D01c47D4FaD128417486cC469dBd), address(this).balance);
    }

    /// @notice Allows the owner to withdraw 10 ETH
    function withdraw10() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert NoFundsToWithdraw();
        _withdraw(address(0x768090beEe26D01c47D4FaD128417486cC469dBd), 10000000000000000000);
    }

    /*---------------------------- OTHER --------------------------------*/
    /// @notice Override view function to get the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Sets first token ID to be 1
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}