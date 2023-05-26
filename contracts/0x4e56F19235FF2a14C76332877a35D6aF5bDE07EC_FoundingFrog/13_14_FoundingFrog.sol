// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFoundingFrog.sol";

contract FoundingFrog is IFoundingFrog, ERC721Enumerable, Ownable {
    /// @notice When `true`, `NFTs are allowed to be transfered
    bool public isTransferable;

    /// @notice address of the contract allowed to mint NFTs
    address public minter;

    /// @notice mapping from token ID to image hash
    /// this can be used to ensure that the image pointed by the metadata is valid
    mapping(uint256 => bytes32) public imageHash;

    modifier onlyMinter() {
        require(msg.sender == minter, "not authorized");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable() {}

    /// @notice Mints an NFT to the given account
    function mint(
        address to,
        uint256 tokenId,
        bytes32 _imageHash
    ) external onlyMinter {
        _mint(to, tokenId);
        imageHash[tokenId] = _imageHash;
        emit Minted(to, tokenId, _imageHash);
    }

    /// @notice Set the minter to the given address
    function setMinter(address _minter) external onlyOwner {
        require(minter == address(0), "minter already set");
        minter = _minter;
        emit MinterSet(_minter);
    }

    /// @notice Enable NFT transfers
    function enableTransfers() external onlyOwner {
        require(!isTransferable, "already transferable");
        isTransferable = true;
        emit TransfersEnabled();
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }

    /// @dev NFTs are not transferable by default
    /// Transfers might be enabled later
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from == address(0) || isTransferable, "not transferable");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://founders.gyro.finance/metadata/";
    }
}