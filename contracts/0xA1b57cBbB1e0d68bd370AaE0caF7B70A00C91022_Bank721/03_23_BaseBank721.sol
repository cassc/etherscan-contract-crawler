// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Bank.sol";
import "./IBank721.sol";
import "./W4907Factory.sol";

abstract contract BaseBank721 is Bank, IBank721, IERC721Receiver {
    //      nft                 nftId      from
    mapping(address => mapping(uint256 => address)) public staked;
    mapping(bytes32 => Duration) public durations;

    function tryStakeNFT721(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId,
        address from
    ) public virtual onlyMarket {}

    function redeemNFT721(TokenType tokenType, address oNFT, uint256 oNFTId) public virtual {}

    function setUser(
        NFT calldata nft,
        address lender,
        address renter,
        uint64 expiry,
        uint64 durationId
    ) external virtual onlyMarket {
        _updateDuration(nft, durationId, lender, expiry + 1);
        _setUser(nft, renter, expiry);
    }

    function claimUser(NFT calldata nft, uint64 durationId) external virtual {
        require(durationId > block.timestamp, "invalid durationId");
        bytes32 key = _getDurationKey(nft, durationId);
        require(durations[key].start > 0, "non-existed duration");
        require(durations[key].start < block.timestamp, "invalid duration start");
        require(durations[key].owner == msg.sender, "invalid duration owner ");
        _setUser(nft, msg.sender, durationId);
    }

    function _setUser(NFT calldata nft, address user, uint64 expiry) internal virtual {}

    function userInfoOf(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId
    ) public view virtual returns (address user, uint256 userExpires) {}

    function _getDurationKey(NFT calldata nft, uint64 durationId) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(nft.token, nft.tokenId, durationId));
    }

    function _updateDuration(
        NFT calldata nft,
        uint64 durationId,
        address lender,
        uint64 start
    ) internal returns (bytes32 key) {
        require(durationId > block.timestamp, "invalid durationId");
        key = _getDurationKey(nft, durationId);
        if (durations[key].start == 0) {
            if (durationId == type(uint64).max) {
                tryStakeNFT721(nft.tokenType, nft.token, nft.tokenId, lender);
            } else {
                (address user, uint256 userExpires) = userInfoOf(nft.tokenType, nft.token, nft.tokenId);
                require(userExpires == durationId, "invalid durationId");
                require(user == lender, "invalid order lender");
            }
            durations[key].owner = lender;
        } else {
            require(durations[key].owner == lender, "invalid order lender");
            require(durations[key].start <= block.timestamp, "invalid duration start");
        }
        require(start > durations[key].start);
        durations[key].start = SafeCast.toUint40(start);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBank721).interfaceId;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual returns (bytes4) {
        bytes4 received = 0x150b7a02;
        return received;
    }
}