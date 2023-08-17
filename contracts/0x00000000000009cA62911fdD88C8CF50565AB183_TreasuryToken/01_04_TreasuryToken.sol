// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "solady/src/tokens/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ITokenMetadata} from "./interfaces/ITokenMetadata.sol";

interface IERC721 {
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256) external view returns (address);
}

contract TreasuryToken is ERC721, Ownable {
    error NotStaked();
    error NotOwner();
    error Soulbound();

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    IERC721 public immutable FOUNDERS_PASS;

    ITokenMetadata public metadataContract;

    uint256 private tokenIdIndex = 0;
    mapping(uint256 => uint256) private stakedTokenMap;

    constructor() {
        FOUNDERS_PASS = IERC721(0xdf9669A65c5845E472ad3Ca83d07605a9d7701b7);
        _initializeOwner(0x6544fa99fa7b6301cE366bc56C39397B7016Ca1C);
    }

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "Frensville Treasury Token";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "FTTKN";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view override returns (string memory) {
        return metadataContract.tokenURI(id);
    }

    function stake(uint256[5] calldata tokenIds) public {
        uint256 tokenIdToMint = ++tokenIdIndex;
        uint96 packedTokenIds;
        for (uint256 i; i < 5;) {
            uint256 tokenId = tokenIds[i];
            stakedTokenMap[tokenId] = tokenIdToMint;
            FOUNDERS_PASS.transferFrom(msg.sender, address(this), tokenId);
            unchecked {
                // founders pass has supply of 800 and we are going to assume that the supply is never
                // going to exceed 65535, so it it safe to pack these token ids in 16 bits
                packedTokenIds += uint96(tokenId << (16 * i));
                ++i;
            }
        }

        _mint(msg.sender, tokenIdToMint);
        _setExtraData(tokenIdToMint, packedTokenIds);
    }

    function unstake(uint256 stakedTokenId) public {
        if (ownerOf(stakedTokenId) != msg.sender) {
            revert NotOwner();
        }

        uint96 tokenData = _getExtraData(stakedTokenId);
        uint256[] memory tokenIds = unpackTokenIds(tokenData);
        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            delete stakedTokenMap[tokenId];
            FOUNDERS_PASS.transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                ++i;
            }
        }

        _burn(stakedTokenId);
        _setExtraData(stakedTokenId, 0);

        emit MetadataUpdate(stakedTokenId);
    }

    function transferFrom(address, address, uint256) public payable override {
        revert Soulbound();
    }

    function approve(address, uint256) public payable override {
        revert Soulbound();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert Soulbound();
    }

    /// @notice gets the staking token id associated with a founders pass
    /// @param tokenId the founders pass to check
    /// @return staked token id or reverts if not staked
    function getStakedTokenId(uint256 tokenId) public view returns (uint256) {
        uint256 token = stakedTokenMap[tokenId];
        if (token == 0) {
            revert NotStaked();
        }
        return token;
    }

    /// @notice gets the owner of the specified founders pass, regardless of staking status
    /// @dev this method will not revert if the token is not staked and instead passes through
    /// to the underlying founders pass contract ownership
    /// @param tokenId token to check ownership of
    /// @return owner of the specified token
    function foundersPassOwnerOf(uint256 tokenId) public view returns (address) {
        uint256 token = stakedTokenMap[tokenId];
        if (token == 0) {
            return FOUNDERS_PASS.ownerOf(tokenId);
        }

        return ownerOf(token);
    }

    /// @notice Gets the founders pass IDs staked with a specific treasury token
    /// @param tokenId treasury token to get staked founders passes
    /// @return tokenIds staked with the specified treasury token id
    function stakedIdsForToken(uint256 tokenId) public view returns (uint256[] memory) {
        uint96 tokenData = _getExtraData(tokenId);

        return unpackTokenIds(tokenData);
    }

    function unpackTokenIds(uint96 data) private pure returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](5);

        tokenIds[0] = data & type(uint16).max;
        tokenIds[1] = data >> 16 & type(uint16).max;
        tokenIds[2] = data >> 32 & type(uint16).max;
        tokenIds[3] = data >> 48 & type(uint16).max;
        tokenIds[4] = data >> 64 & type(uint16).max;

        return tokenIds;
    }

    function setMetadataContract(address metadata) external onlyOwner {
        metadataContract = ITokenMetadata(metadata);
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function metadataChanged() external {
        if (msg.sender != address(metadataContract)) {
            revert Unauthorized();
        }

        emit BatchMetadataUpdate(1, type(uint256).max);
    }
}