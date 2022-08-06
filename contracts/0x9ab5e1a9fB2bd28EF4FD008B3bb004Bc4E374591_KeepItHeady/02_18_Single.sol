// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ZoraV3/ZoraAsks.sol";

contract Single is ERC721Enumerable, IERC2981, ZoraAsks {
    // count of minted tokens
    uint256 public tokenId;
    // mapping of tokenId to hasBeenTransferred
    mapping(uint256 => bool) tokenTransferred;

    using SafeMath for uint256;

    constructor(
        address _zoraAsksV1_1,
        address _zoraTransferHelper,
        address _zoraModuleManager
    )
        ERC721("Keep it Heady", "INF")
        ZoraAsks(_zoraAsksV1_1, _zoraTransferHelper, _zoraModuleManager)
    {}

    /// @notice mints 1 edition locked in this contract.
    function mint() internal {
        // Token Minting
        tokenId++;
        _mint(address(this), tokenId);
    }

    /// @notice Returns music metadata for the single
    /// @param _tokenId the tokenId with music metadata
    /// @return musicMetadata follows Catalog standard here: https://gist.github.com/bretth18/df8358c840fa94946ec212f753e290dd
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "tokenId doesn't exist");
        return
            "ipfs://bafkreiajivasnm6iipnhy454m273gs57r3k6es7uk5nskth4x6qbvsfeam";
    }

    /// @notice Returns music metadata for the single
    /// @return contractMetadata follows Catalog standard here: https://gist.github.com/bretth18/df8358c840fa94946ec212f753e290dd
    function contractURI() public view virtual returns (string memory) {
        return
            "ipfs://bafkreid5v7lpghkssfcndzjyjrhcbejwu6ycdjtwhgsexzdmwmp5wq3kve";
    }

    /// @notice See {IERC721-isApprovedForAll}.
    /// @dev manual approval for Zora Transfer Helper.
    /// @param _owner of music nft
    /// @param _operator operator to approve for
    /// @return isApprovedForAll
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (bool)
    {
        if (_owner == address(this) && (_operator == zoraTransferHelper))
            return true;
        else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

    /// @notice Hook that is called after any transfer of tokens
    /// @dev This includes minting and burning.
    /// @dev manual approval for Zora Transfer Helper.
    /// @param _from sender
    /// @param _to recipient
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        bool hasBeenTransferred = tokenTransferred[_tokenId];
        bool isMint = (_from == address(0));
        if (!isMint && !hasBeenTransferred) {
            tokenTransferred[_tokenId] = true;
            mint();
        }
    }

    /// @notice See {IERC165-royaltyInfo}.
    /// @param _tokenId token id
    /// @param _salePrice sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(!_exists(_tokenId), "ERC721: token already minted");

        uint256 royaltyPayment = _calcRoyaltyPayment(_salePrice);

        return (sellerFundsRecipient, royaltyPayment);
    }

    /// @notice is interface supported
    /// @param interfaceId interface ID
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Internal function calculate proportion of a fee for a given amount.
    /// @param _amount uint256 value to be split
    /// @return payment _amount * fee / 100
    function _calcRoyaltyPayment(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        return _amount.mul(1000).div(100000);
    }
}