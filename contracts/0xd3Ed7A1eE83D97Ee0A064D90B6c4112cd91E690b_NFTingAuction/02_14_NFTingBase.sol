// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interface/INFTingConfig.sol";
import "../utilities/NFTingErrors.sol";

contract NFTingBase is
    Context,
    Ownable,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    INFTingConfig config;

    uint256 feesCollected;

    modifier onlyNFT(address _addr) {
        if (
            !_supportsInterface(_addr, INTERFACE_ID_ERC1155) &&
            !_supportsInterface(_addr, INTERFACE_ID_ERC721)
        ) {
            revert InvalidAddressProvided(_addr);
        }

        _;
    }

    modifier isTokenOwnerOrApproved(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _addr
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                IERC1155(_nftAddress).balanceOf(_addr, _tokenId) < _amount &&
                !IERC1155(_nftAddress).isApprovedForAll(_addr, _msgSender())
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                IERC721(_nftAddress).ownerOf(_tokenId) != _addr &&
                IERC721(_nftAddress).getApproved(_tokenId) != _addr
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    modifier isApprovedMarketplace(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                !IERC1155(_nftAddress).isApprovedForAll(_owner, address(this))
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                !IERC721(_nftAddress).isApprovedForAll(_owner, address(this)) &&
                IERC721(_nftAddress).getApproved(_tokenId) != address(this)
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _transfer721And1155(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            revert ZeroAmountTransfer();
        }

        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                ""
            );
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _supportsInterface(address _addr, bytes4 _interface)
        internal
        view
        returns (bool)
    {
        return IERC165(_addr).supportsInterface(_interface);
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        return IERC165(_contract).supportsInterface(INTERFACE_ID_ERC2981);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            type(IERC1155Receiver).interfaceId == _interfaceId ||
            type(IERC721Receiver).interfaceId == _interfaceId;
    }

    function setConfig(address newConfig) external onlyOwner {
        if (newConfig == address(0)) {
            revert ZeroAddress();
        }
        config = INFTingConfig(newConfig);
    }

    function _addBuyFee(uint256 price) internal view returns (uint256) {
        return price += (price * config.buyFee()) / 10000;
    }

    function _payFee(
        address token,
        uint256 tokenId,
        uint256 price
    ) internal returns (uint256 rest) {
        // Cut buy fee
        uint256 listedPrice = (price * 10000) / (10000 + config.buyFee());
        uint256 buyFee = price - listedPrice;

        // If the NFT was created on our marketplace, pay creator fee
        uint256 royaltyFee;
        if (checkRoyalties(token)) {
            (address creator, uint256 royaltyAmount) = IERC2981(token)
                .royaltyInfo(tokenId, listedPrice);
            payable(creator).transfer(royaltyAmount);

            royaltyFee = royaltyAmount;
        }

        // Cut sell fee and creator fee
        uint256 sellFee = (listedPrice * config.sellFee()) / 10000;
        rest = listedPrice - sellFee - royaltyFee;

        if (config.treasury() != address(0)) {
            payable(config.treasury()).transfer(buyFee + sellFee);
        } else {
            feesCollected += (buyFee + sellFee);
        }
    }

    function withdraw() external onlyOwner {
        if (config.treasury() == address(0)) {
            revert ZeroAddress();
        }
        payable(config.treasury()).transfer(feesCollected);
        feesCollected = 0;
    }

    receive() external payable {}
}