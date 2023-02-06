// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./interfaces/IMintpassVault.sol";

/**
 * @title Module handling Gooodfellas mintpass mintable NFTs.
 */
abstract contract MintpassMintable is Ownable {

    IERC721Enumerable public immutable mintpass;

    mapping(uint256 => bool) public mintpassUsed;
    uint256 public mintpassesUsed;
    IMintpassVault public vault; 
    uint256 private _mintpassesTotalFrozen;


    constructor(address _mintpass) {
        require(_mintpass != address(0), "Invalid mintpass");
        mintpass = IERC721Enumerable(_mintpass);
    }

    function initiateMintUnclaimedToVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Invalid vault");
        require(address(vault) == address(0), "Already initiated");
        _mintpassesTotalFrozen = mintpass.totalSupply();
        vault = IMintpassVault(_vault);
    }


    /**
     * @notice Finalize the mint by minting the unclaimed mintpass mints to the given `_vault` where they can be claimed later.
     * @dev onlyOwner
     */
    function mintUnclaimedToVault(uint256 _maxAmount) external onlyOwner {
        require(address(vault) != address(0), "Not initiated yet");

        uint256 amount = _mintpassMintsOpen();
        if (amount > _maxAmount) amount = _maxAmount;
        _mintTo(address(vault), amount);
    }


    /**
     * @notice Mint free NFT using mintpasses with `_tokenIds`.
     */
    function useMintpasses(uint256[] calldata _tokenIds) external {
        address user = msg.sender;
        uint256 amount = _tokenIds.length;
        for (uint256 i = 0; i < amount; ++i) {
            require(mintpass.ownerOf(_tokenIds[i]) == user, "Not owner of mintpass");
            require(!mintpassUsed[_tokenIds[i]], "Mintpass already used");
            require(_mintpassesTotalFrozen == 0 || _tokenIds[i] <= _mintpassesTotalFrozen, "Mintpass minted after freeze");
            mintpassUsed[_tokenIds[i]] = true;
        }
        mintpassesUsed += amount;

        if (address(vault) == address(0)) {
            _mintTo(user, amount);
        } else {
            vault.claimWithMintpass(user, amount);
        }
    }

    /**
     * @dev Amount of NFTs to keep reserved for mintpass users
     */
    function _mintpassMintsOpen() internal view returns (uint256) {
        return mintpassesUnused() - (address(vault) == address(0) ? 0 : vault.mintableBalance()); 
    }

    /** 
     * @notice Number of free mints left 
     */
    function mintpassesUnused() public view returns (uint256) {
        return validMintpasses() - mintpassesUsed;
    }

    /** 
     * @notice Number of total valid mintpasses
     */
    function validMintpasses() public view returns (uint256) {
        return _mintpassesTotalFrozen != 0 ? _mintpassesTotalFrozen : mintpass.totalSupply();
    }

    /**
     * @notice Returns all mintpass tokenIds owned by `_owner` and their used states.
     * @param _owner: owner
     */
    function mintpassesOfOwner(address _owner) external view returns (uint256[] memory, bool[] memory) {
        uint256 tokenCount = mintpass.balanceOf(_owner);

        uint256[] memory _tokenIds = new uint256[](tokenCount);
        bool[] memory _mintpassUsed = new bool[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            _tokenIds[index] = mintpass.tokenOfOwnerByIndex(_owner, index);
            _mintpassUsed[index] = mintpassUsed[_tokenIds[index]];
        }
        return (_tokenIds, _mintpassUsed);
    }

    /**
     * @notice Returns a list of mintpass IDs and their used state of mintpasses owned by `user` given a `cursor` and `size` of its token list
     * @param user: address
     * @param cursor: cursor
     * @param size: size
     */
    function mintpassesOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, bool[] memory, uint256) {
        uint256 length = size;
        if (length > mintpass.balanceOf(user) - cursor) {
            length = mintpass.balanceOf(user) - cursor;
        }

        uint256[] memory _tokenIds = new uint256[](length);
        bool[] memory _mintpassUsed = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenIds[i] = mintpass.tokenOfOwnerByIndex(user, cursor + i);
            _mintpassUsed[i] = mintpassUsed[_tokenIds[i]];
        }

        return (_tokenIds, _mintpassUsed, cursor + length);
    }

    /**
     * @notice Returns a list of all mintpass IDs and their used state given a `cursor` and `size` of its token list
     * @param cursor: cursor
     * @param size: size
     */
    function mintpassesUsedBySize(
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, bool[] memory, uint256) {
        uint256 length = size;
        if (length > mintpass.totalSupply() - cursor) {
            length = mintpass.totalSupply() - cursor;
        }

        uint256[] memory _tokenIds = new uint256[](length);
        bool[] memory _mintpassUsed = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenIds[i] = mintpass.tokenByIndex(cursor + i);
            _mintpassUsed[_tokenIds[i]] = mintpassUsed[_tokenIds[i]];
        }

        return (_tokenIds, _mintpassUsed, cursor + length);
    }

    function _hasMintpass(address _user) internal view returns (bool) {
        return mintpass.balanceOf(_user) > 0;
    }

    function _mintTo(address _to, uint256 _amount) internal virtual;
}