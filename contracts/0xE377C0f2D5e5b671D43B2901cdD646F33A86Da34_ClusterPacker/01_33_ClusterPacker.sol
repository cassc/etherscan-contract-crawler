// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC9981155Extension.sol";
import "./ERC998ERC20Extension.sol";
import "../utils/KeysMapping.sol";
import "../interfaces/IPackBuilder.sol";
import "../interfaces/IClusterPacker.sol";
import "../interfaces/IDispatcher.sol";
import "../interfaces/IAllowedNFTs.sol";
import "../interfaces/IAllowedERC20s.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ClusterPacker is IPackBuilder, ERC9981155Extension, ERC998ERC20Extension {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    IDispatcher public immutable hub;

    event NewBundle(uint256 bundleId, address indexed sender, address indexed receiver);

    constructor(
        address _dispatcher,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        hub = IDispatcher(_dispatcher);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC9981155Extension, ERC998ERC20Extension)
        returns (bool)
    {
        return
            _interfaceId == type(IERC721Receiver).interfaceId ||
            _interfaceId == type(IClusterPacker).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function allowedAsset(address _asset) public view returns (bool) {
        IAllowedNFTs allowedNFTs = IAllowedNFTs(hub.getContract(KeysMapping.PERMITTED_NFTS));
        return allowedNFTs.getNFTPermit(_asset) > 0;
    }

    function allowedErc20Asset(address _erc20Contract) public view returns (bool) {
        IAllowedERC20s allowedERC20s = IAllowedERC20s(hub.getContract(KeysMapping.PERMITTED_BUNDLE_ERC20S));
        return allowedERC20s.isERC20Permitted(_erc20Contract);
    }

    function createBundle(
        BundleElements memory _bundleElements,
        address _sender,
        address _receiver
    ) external override returns (uint256) {
        uint256 bundleId = _safeMint(_receiver);
        require(
            _bundleElements.erc721s.length > 0 ||
                _bundleElements.erc20s.length > 0 ||
                _bundleElements.erc1155s.length > 0,
            "bundle is empty"
        );
        for (uint256 i = 0; i < _bundleElements.erc721s.length; i++) {
            if (_bundleElements.erc721s[i].safeTransferable) {
                IERC721(_bundleElements.erc721s[i].tokenContract).safeTransferFrom(
                    _sender,
                    address(this),
                    _bundleElements.erc721s[i].id,
                    abi.encodePacked(bundleId)
                );
            } else {
                _getChild(_sender, bundleId, _bundleElements.erc721s[i].tokenContract, _bundleElements.erc721s[i].id);
            }
        }

        for (uint256 i = 0; i < _bundleElements.erc20s.length; i++) {
            _getERC20(_sender, bundleId, _bundleElements.erc20s[i].tokenContract, _bundleElements.erc20s[i].amount);
        }

        for (uint256 i = 0; i < _bundleElements.erc1155s.length; i++) {
            IERC1155(_bundleElements.erc1155s[i].tokenContract).safeBatchTransferFrom(
                _sender,
                address(this),
                _bundleElements.erc1155s[i].ids,
                _bundleElements.erc1155s[i].amounts,
                abi.encodePacked(bundleId)
            );
        }

        emit NewBundle(bundleId, _sender, _receiver);
        return bundleId;
    }

    function unpackBundle(uint256 _tokenId, address _receiver) external override nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "caller is not owner");
        _validateReceiver(_receiver);

        while (childContracts[_tokenId].length() > 0) {
            address childContract = childContracts[_tokenId].at(0);

            while (childTokens[_tokenId][childContract].length() > 0) {
                uint256 childId = childTokens[_tokenId][childContract].at(0);

                uint256 balance = balances[_tokenId][childContract][childId];

                if (balance > 0) {
                    _remove1155Child(_tokenId, childContract, childId, balance);
                    IERC1155(childContract).safeTransferFrom(address(this), _receiver, childId, balance, "");
                    emit Transfer1155Child(_tokenId, _receiver, childContract, childId, balance);
                } else {
                    _removeChild(_tokenId, childContract, childId);

                    try IERC721(childContract).safeTransferFrom(address(this), _receiver, childId) {
                        // solhint-disable-previous-line no-empty-blocks
                    } catch {
                        _oldNFTsTransfer(_receiver, childContract, childId);
                    }
                    emit TransferChild(_tokenId, _receiver, childContract, childId);
                }
            }
        }

        while (erc20ChildContracts[_tokenId].length() > 0) {
            address erc20Contract = erc20ChildContracts[_tokenId].at(0);
            uint256 balance = erc20Balances[_tokenId][erc20Contract];

            _removeERC20(_tokenId, erc20Contract, balance);
            IERC20(erc20Contract).safeTransfer(_receiver, balance);
            emit TransferERC20(_tokenId, _receiver, erc20Contract, balance);
        }
    }

    function _receiveChild(
        address _from,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) internal virtual override {
        require(allowedAsset(_childContract), "erc721 not permitted");
        super._receiveChild(_from, _tokenId, _childContract, _childTokenId);
    }

    function _receive1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId,
        uint256 _amount
    ) internal virtual override {
        require(allowedAsset(_childContract), "erc1155 not permitted");
        super._receive1155Child(_tokenId, _childContract, _childTokenId, _amount);
    }

    function _receiveErc20Child(
        address _from,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) internal virtual override {
        require(allowedErc20Asset(_erc20Contract), "erc20 not permitted");
        super._receiveErc20Child(_from, _tokenId, _erc20Contract, _value);
    }
}