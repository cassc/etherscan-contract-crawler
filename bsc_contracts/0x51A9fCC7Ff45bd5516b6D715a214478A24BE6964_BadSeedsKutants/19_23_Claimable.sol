// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "../interfaces/IClaimableVault.sol";

/**
 * @title Module handling claiming of mintable NFTs.
 */
abstract contract Claimable is Ownable {

    IERC721Enumerable public immutable pass;

    uint256 public passesUsed;
    IClaimableVault public vault; 
    uint256 private _passesTotalFrozen;


    constructor(address _pass) {
        require(_pass != address(0), "Invalid pass address");
        pass = IERC721Enumerable(_pass);
    }

    /**
     * @notice Initialte minting unclaimed NFTs to vault to be randomly claimed later.
     * @dev onlyOwner  
     */
    function initiateMintUnclaimedToVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Invalid vault");
        require(address(vault) == address(0), "Already initiated");
        _passesTotalFrozen = pass.totalSupply();
        vault = IClaimableVault(_vault);
    }


    /**
     * @notice Finalize the mint by minting the unclaimed pass mints to the given vault where they can be claimed later.
     * @dev onlyOwner
     */
    function mintUnclaimedToVault(uint256 _maxAmount) external onlyOwner {
        require(address(vault) != address(0), "Not initiated yet");

        uint256 amount = _passMintsOpen();
        if (amount > _maxAmount) amount = _maxAmount;
        _mintTo(address(vault), amount);
    }


    /**
     * @notice Mint free NFT using passes with `_tokenIds`.
     */
    function _claim(address user, uint256[] memory _tokenIds) internal {
        require(tx.origin == user, "Only self");
        uint256 amount = _tokenIds.length;
        for (uint256 i = 0; i < amount; ++i) {
            require(pass.ownerOf(_tokenIds[i]) == user, "Not owner of pass");
            require(!_getPassUsed(_tokenIds[i]), "Pass already used");
            require(_passesTotalFrozen == 0 || _tokenIds[i] <= _passesTotalFrozen, "Pass minted after freeze");
            _setPassUsed(_tokenIds[i]);
        }
        passesUsed += amount;

        if (address(vault) == address(0)) {
            _mintTo(user, amount);
        } else {
            vault.claim(user, amount);
        }
    }

    /**
     * @dev Amount of NFTs to keep reserved for pass users
     */
    function _passMintsOpen() internal view returns (uint256) {
        return passesUnused() - (address(vault) == address(0) ? 0 : vault.claimableBalance()); 
    }

    /** 
     * @notice Number of free mints left 
     */
    function passesUnused() public view returns (uint256) {
        return validPasses() - passesUsed;
    }

    /** 
     * @notice Number of total valid passes
     */
    function validPasses() public view returns (uint256) {
        return _passesTotalFrozen != 0 ? _passesTotalFrozen : pass.totalSupply();
    }

    /**
     * @notice Returns all pass tokenIds owned by `_owner` and their used states.
     * @param _owner: owner
     */
    function passesOfOwner(address _owner) external view returns (uint256[] memory, bool[] memory) {
        uint256 tokenCount = pass.balanceOf(_owner);

        uint256[] memory _tokenIds = new uint256[](tokenCount);
        bool[] memory _passUsed = new bool[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            _tokenIds[index] = pass.tokenOfOwnerByIndex(_owner, index);
            _passUsed[index] = _getPassUsed(_tokenIds[index]);
        }
        return (_tokenIds, _passUsed);
    }

    /**
     * @notice Returns a list of pass IDs and their used state of passes owned by `user` given a `cursor` and `size` of its token list
     * @param user: address
     * @param cursor: cursor
     * @param size: size
     */
    function passesOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, bool[] memory, uint256) {
        uint256 length = size;
        if (length > pass.balanceOf(user) - cursor) {
            length = pass.balanceOf(user) - cursor;
        }

        uint256[] memory _tokenIds = new uint256[](length);
        bool[] memory _passUsed = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenIds[i] = pass.tokenOfOwnerByIndex(user, cursor + i);
            _passUsed[i] = _getPassUsed(_tokenIds[i]);
        }

        return (_tokenIds, _passUsed, cursor + length);
    }

    /**
     * @notice Returns `_amount` pass tokenIds owned by `_owner`, which are not used yet.
     * @param _owner: owner
     */
    function unusedPassesOfOwner(address _owner, uint256 _amount) public view returns (uint256[] memory) {
        uint256 tokenCount = pass.balanceOf(_owner);
        require(_amount <= tokenCount, "Not enough passes");

        uint256[] memory _tokenIds = new uint256[](_amount);
        uint256 i;
        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 tokenId = pass.tokenOfOwnerByIndex(_owner, index);
            if (!_getPassUsed(tokenId)) {
                _tokenIds[i++] = tokenId;
                if (i == _amount) return _tokenIds;
            }
        }
        revert("Not enought unused passes");
    }

    /**
     * @notice Returns a list of all pass IDs and their used state given a `cursor` and `size` of its token list
     * @param cursor: cursor
     * @param size: size
     */
    function passesUsedBySize(
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, bool[] memory, uint256) {
        uint256 length = size;
        if (length > pass.totalSupply() - cursor) {
            length = pass.totalSupply() - cursor;
        }

        uint256[] memory _tokenIds = new uint256[](length);
        bool[] memory _passUsed = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokenIds[i] = pass.tokenByIndex(cursor + i);
            _passUsed[_tokenIds[i]] = _getPassUsed(_tokenIds[i]);
        }

        return (_tokenIds, _passUsed, cursor + length);
    }

    function _hasPass(address _user) internal view returns (bool) {
        return pass.balanceOf(_user) > 0;
    }

    function _mintTo(address _to, uint256 _amount) internal virtual;
    function _setPassUsed(uint256 _tokenId) internal virtual;
    function _getPassUsed(uint256 _tokenId) internal virtual view returns (bool);
}