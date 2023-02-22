// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BaseBank721.sol";
import "./W4907Factory.sol";

contract Bank721 is BaseBank721, W4907Factory {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address admin_,
        address w4907Impl_
    ) public initializer {
        _initOwnable(owner_, admin_);
        _initW4907(w4907Impl_);
    }

    function tryStakeNFT721(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId,
        address from
    ) public virtual override onlyMarket {
        if (staked[oNFT][oNFTId] == address(0)) {
            staked[oNFT][oNFTId] = from;
            if (tokenType == TokenType.ERC721) {
                address wNFT = oNFT_w4907[oNFT];
                require(wNFT != address(0), "wNFT is not deployed yet");
                IWrapNFT(wNFT).stake(oNFTId, from, address(this));
            } else if (tokenType == TokenType.ERC4907) {
                IERC721(oNFT).transferFrom(from, address(this), oNFTId);
            } else {
                revert("invalid token type");
            }
        }
    }

    function redeemNFT721(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId
    ) public virtual override nonReentrant {
        bytes32 key = keccak256(abi.encode(oNFT, oNFTId, type(uint64).max));
        require(
            msg.sender == durations[key].owner || msg.sender == market,
            "only owner or market"
        );
        require(durations[key].start < block.timestamp, "cannot redeem now");
        if (tokenType == TokenType.ERC721) {
            address w4907 = oNFT_w4907[oNFT];
            require(w4907 != address(0), "w4907 is Zero Address");
            IWrapNFT(w4907).redeem(oNFTId, staked[oNFT][oNFTId]);
        } else if (tokenType == TokenType.ERC4907) {
            IERC721(oNFT).transferFrom(
                address(this),
                staked[oNFT][oNFTId],
                oNFTId
            );
        } else {
            revert("invalid token type");
        }
        delete staked[oNFT][oNFTId];
        delete durations[key];
        emit RedeemNFT721(oNFT, oNFTId);
    }

    function _setUser(
        NFT calldata nft,
        address user,
        uint64 expiry
    ) internal virtual override {
        if (expiry > type(uint64).max) expiry = type(uint64).max;
        if (nft.tokenType == TokenType.ERC721) {
            address w4907 = oNFT_w4907[nft.token];
            require(w4907 != address(0), "wNFT is not deployed yet");
            IERC4907(w4907).setUser(nft.tokenId, user, expiry);
        } else if (nft.tokenType == TokenType.ERC4907) {
            IERC4907(nft.token).setUser(nft.tokenId, user, expiry);
        } else {
            revert("invalid token type");
        }
    }

    function userInfoOf(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId
    ) public view virtual override returns (address user, uint256 userExpires) {
        if (tokenType == TokenType.ERC721) {
            address w4907 = oNFT_w4907[oNFT];
            require(w4907 != address(0), "wNFT is not deployed yet");
            user = IERC4907(w4907).userOf(oNFTId);
            userExpires = IERC4907(w4907).userExpires(oNFTId);
        } else if (tokenType == TokenType.ERC4907) {
            user = IERC4907(oNFT).userOf(oNFTId);
            userExpires = IERC4907(oNFT).userExpires(oNFTId);
        } else {
            revert("invalid token type");
        }
    }
}