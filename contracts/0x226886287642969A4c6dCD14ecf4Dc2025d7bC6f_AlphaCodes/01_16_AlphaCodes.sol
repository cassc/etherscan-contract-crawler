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
error ExceedsTxnLimit();
error ExceedsAllowlistLimit();
error ExceedsTotalSupply();
error NotOnAllowlist();
error PublicMintInactive();
error AllowlistMintInactive();
error CallerIsContract();
error NoFundsToWithdraw();
error TransferFailed();

contract AlphaCodes is ERC721AQueryable, Ownable, ERC2981, DefaultOperatorFilterer {
    uint256 public constant MAX_BATCH_SIZE = 5;
    uint256 public maxSupply = 1555;
    uint256 public maxPublicMints = 5;
    uint256 public maxAllowlistMints = 2;
    uint256 public allowlistMintPrice = 0.079 ether;
    uint256 public publicMintPrice = 0.079 ether;
    bool public isPublicMintActive = false;
    bool public isAllowlistMintActive = false;
    string public baseTokenURI;
    bytes32 public merkleRoot;
    address[] public minters;
    uint256 public totalMinted;

    event Received(address indexed sender, uint256 amount);

    constructor() ERC721A("AlphaCodes", "ALPHACODES") {}

    /*--------------------------- MINT + AIRDROP ------------------------------*/

    /// @notice Public mint when public sale is active. Minters will receive their token after the airdrop is executed
    function mintPublic(uint256 nMints) external payable {
        if (!isPublicMintActive) revert PublicMintInactive();
        if (nMints > maxPublicMints) revert ExceedsTxnLimit();
        if (msg.value != publicMintPrice * nMints) revert InsufficientAmountSent();
        if (totalMinted + nMints > maxSupply) revert ExceedsTotalSupply();

        uint256 numMinted = _getAux(msg.sender);
        _setAux(msg.sender, uint64(numMinted + nMints));
        totalMinted += nMints;

        minters.push(msg.sender);
        emit Received(msg.sender, msg.value);
    }

    /// @notice Allowlist mint when allowlist sale is active. Minters will receive their token after the airdrop is executed
    /// @dev Uses a Merkle tree to verify if address is on allowlist
    function mintAllowlist(bytes32[] calldata _proof, uint256 nMints) external payable {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        uint256 numMinted = _getAux(msg.sender);

        if (!isAllowlistMintActive) revert AllowlistMintInactive();
        if (!MerkleProof.verify(_proof, merkleRoot, node)) revert NotOnAllowlist();
        if (msg.value != allowlistMintPrice * nMints) revert InsufficientAmountSent();
        if (numMinted + nMints > maxAllowlistMints) revert ExceedsAllowlistLimit();
        if (totalMinted + nMints > maxSupply) revert ExceedsTotalSupply();

        _setAux(msg.sender, uint64(numMinted + nMints));
        totalMinted += nMints;

        minters.push(msg.sender);
        emit Received(msg.sender, msg.value);
    }

    /// @notice Reserved mints for owner
    /// @dev MAX_BATCH_SIZE enforces a fixed batch size when minting large quantities with ERC721A
    function mintReserve(uint256 nMints) external onlyOwner {
        if (totalMinted + nMints > maxSupply) revert ExceedsTotalSupply();
        totalMinted += nMints;

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

    /// @notice Airdrop mint to list of addresses with specified amounts
    function airdropTo(address[] calldata _addresses, uint256[] calldata nMints) external onlyOwner {
        unchecked {
            for (uint256 i; i < _addresses.length; ++i) {
                if (totalSupply() + nMints[i] > maxSupply) revert ExceedsTotalSupply();
                _mint(_addresses[i], nMints[i]);
            }
        }
    }

    /// @notice Airdrop mint to minters
    function airdropMints() external onlyOwner {
        unchecked {
            for (uint256 i; i < minters.length; ++i) {
                _mint(minters[i], _getAux(minters[i]));
                _setAux(minters[i], 0);
            }
        }
    }

    /*--------------------------- ONLY OWNER --------------------------------*/
    /// @notice Allows the owner to set the maximum supply of the collection
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /// @notice Allows the owner to set the maximum public mints per txn
    function setMaxPublicMints(uint256 _maxPublicMints) external onlyOwner {
        maxPublicMints = _maxPublicMints;
    }

    /// @notice Allows the owner to set the maximum allowlist mints per txn
    function setMaxAllowlistMints(uint256 _maxAllowlistMints) external onlyOwner {
        maxAllowlistMints = _maxAllowlistMints;
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

        _withdraw(address(0x768090beEe26D01c47D4FaD128417486cC469dBd), (contractBalance * 8) / 100);
        _withdraw(address(0xfcdf99080A08Cd4b0D2E503793d7d6aeECa7BCc8), (contractBalance * 5) / 100);
        _withdraw(address(0xED1ccA805809292Fb02BAE713E1f06cd632437F8), address(this).balance);
    }

    /*---------------------------- OTHER --------------------------------*/
    /// @notice Override view function to get the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Get the number of mints for an address
    /// @dev Make _getAux external
    function getAux(address _address) external view returns (uint64) {
        return _getAux(_address);
    }

    /// @notice Get array of minters
    function getMinters() external view returns (address[] memory) {
        return minters;
    }

    /// @notice Get array of minters and their mint amounts
    /// @dev Convenience function for front-end
    function getMintersAndAmounts() external view returns (address[] memory, uint64[] memory) {
        uint256 numMinters = minters.length;
        uint64[] memory mintAmounts = new uint64[](numMinters);
        unchecked {
            for (uint256 i; i < numMinters; ++i) {
                mintAmounts[i] = _getAux(minters[i]);
            }
        }
        return (minters, mintAmounts);
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