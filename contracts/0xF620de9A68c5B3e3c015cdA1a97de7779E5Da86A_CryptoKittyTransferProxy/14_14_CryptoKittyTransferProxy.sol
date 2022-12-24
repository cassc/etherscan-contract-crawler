// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../interfaces/ITransferProxy.sol";

contract CryptoKittyTransferProxy is ITransferProxy, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => bool) operators;

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to
    ) external override onlyOperator {
        (uint256 value, ) = abi.decode(asset.data, (uint256, uint256));
        require(value == 1, "erc721 value error");
        (address token, uint256 tokenId) = abi.decode(asset.assetType.data, (address, uint256));
        IERC721Upgradeable(token).transferFrom(from, to, tokenId);
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}