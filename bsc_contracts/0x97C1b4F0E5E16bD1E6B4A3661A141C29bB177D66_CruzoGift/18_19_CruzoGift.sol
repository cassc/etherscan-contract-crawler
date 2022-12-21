//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../transfer-proxy/ITransferProxy.sol";

error ErrInvalidAmount();
error ErrLinkNotFound();
error ErrInvalidSecret();

contract CruzoGift is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Link {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        bytes32 hash;
    }

    event Gift(
        uint256 id,
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    );

    event LinkCreated(
        uint256 id,
        address tokenAddress,
        uint256 tokenId,
        address from,
        uint256 amount,
        bytes32 hash
    );

    event LinkClaimed(uint256 id, address claimer);

    CountersUpgradeable.Counter private giftIds;

    ITransferProxy public transferProxy;

    mapping(uint256 => Link) public links;

    constructor() {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(ITransferProxy _transferProxy) public initializer {
        __Ownable_init();
        transferProxy = _transferProxy;
    }

    function gift(
        address _tokenAddress,
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) external {
        if (_amount == 0) {
            revert ErrInvalidAmount();
        }
        giftIds.increment();
        transferProxy.safeTransferFrom(
            IERC1155Upgradeable(_tokenAddress),
            _msgSender(),
            _to,
            _tokenId,
            _amount,
            ""
        );
        emit Gift(
            giftIds.current(),
            _tokenAddress,
            _tokenId,
            _msgSender(),
            _to,
            _amount
        );
    }

    function createLink(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _hash
    ) external {
        if (_amount == 0) {
            revert ErrInvalidAmount();
        }
        giftIds.increment();
        links[giftIds.current()] = Link({
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: _amount,
            hash: _hash
        });
        transferProxy.safeTransferFrom(
            IERC1155Upgradeable(_tokenAddress),
            _msgSender(),
            address(this),
            _tokenId,
            _amount,
            ""
        );
        emit LinkCreated(
            giftIds.current(),
            _tokenAddress,
            _tokenId,
            _msgSender(),
            _amount,
            _hash
        );
    }

    function claimLink(uint256 _giftId, string calldata _secretKey) external {
        Link memory link = links[_giftId];
        if (link.amount == 0) {
            revert ErrLinkNotFound();
        }
        if (link.hash != keccak256(bytes(_secretKey))) {
            revert ErrInvalidSecret();
        }
        delete links[_giftId];
        transferProxy.safeTransferFrom(
            IERC1155Upgradeable(link.tokenAddress),
            address(this),
            _msgSender(),
            link.tokenId,
            link.amount,
            ""
        );
        emit LinkClaimed(_giftId, _msgSender());
    }
}