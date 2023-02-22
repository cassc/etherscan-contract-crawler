// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./IWrapNFT.sol";
import "./IWrapNFTUpgradeable.sol";
import "../ERC4907Upgradeable.sol";

contract WrappedInERC4907Upgradeable is
    ERC4907Upgradeable,
    IWrapNFT,
    IWrapNFTUpgradeable
{
    address private _originalAddress;
    address public operator;

    modifier onlyOperator {
        require(msg.sender == operator,"only operator");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address originalAddress_,
        address operator_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        require(
            IERC165(originalAddress_).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not IERC721"
        );
        _originalAddress = originalAddress_;
        operator = operator_;
    }

    function originalAddress() public view returns (address) {
        return _originalAddress;
    }

    function stake(
        uint256 tokenId,
        address from,
        address holder
    ) onlyOperator public returns (uint256) {
        IERC721(_originalAddress).safeTransferFrom(
            from,
            address(this),
            tokenId
        );
        _mint(holder, tokenId);
        emit Stake(_originalAddress, tokenId, from, holder);
        return tokenId;
    }

    function redeem(uint256 tokenId, address to) onlyOperator public {
        IERC721(_originalAddress).safeTransferFrom(address(this), to, tokenId);
        _burn(tokenId);
        emit Redeem(_originalAddress, tokenId, to);
    }

    function onlyApprovedOrOwner(
        address spender,
        address nftAddress,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = IERC721(nftAddress).ownerOf(tokenId);
        return (spender == owner ||
            IERC721(nftAddress).getApproved(tokenId) == spender ||
            IERC721(nftAddress).isApprovedForAll(owner, spender));
    }

    function originalOwnerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner)
    {
        owner = IERC721(_originalAddress).ownerOf(tokenId);
        if (owner == address(this)) {
            owner = ownerOf(tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return IERC721Metadata(_originalAddress).tokenURI(tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure virtual override returns (bytes4) {
        bytes4 received = 0x150b7a02;
        return received;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IWrapNFT).interfaceId ||
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}