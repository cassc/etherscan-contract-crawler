// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Vault is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721HolderUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant PAYER_ROLE = keccak256("PAYER_ROLE");
    bytes32 public constant PAYEE_ROLE = keccak256("PAYEE_ROLE");

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    function _transferErc20(
        IERC20Upgradeable erc20,
        address payee,
        uint256 amount
    ) internal {
        _checkRole(PAYEE_ROLE, payee);
        erc20.safeTransfer(payee, amount);
    }

    function transferErc20(
        IERC20Upgradeable token,
        address payee,
        uint256 amount
    ) external onlyRole(PAYER_ROLE) {
        _transferErc20(token, payee, amount);
    }

    function batchTransferErc20(
        IERC20Upgradeable[] calldata tokens,
        address[] calldata payees,
        uint256[] calldata amounts
    ) external onlyRole(PAYER_ROLE) {
        require(
            tokens.length == payees.length,
            "Vault::batchTransferErc20: tokens/payees length mismatch"
        );
        require(
            payees.length == amounts.length,
            "Vault::batchTransferErc20: payees/amounts length mismatch"
        );
        require(
            payees.length > 0,
            "Vault::batchTransferErc20: payees length must be gt zero"
        );

        for (uint256 index = 0; index < payees.length; index++) {
            _transferErc20(tokens[index], payees[index], amounts[index]);
        }
    }

    function _transferErc721(
        IERC721Upgradeable erc721,
        address payee,
        uint256 tokenId
    ) internal {
        _checkRole(PAYEE_ROLE, payee);
        erc721.safeTransferFrom(address(this), payee, tokenId);
    }

    function transferErc721(
        IERC721Upgradeable token,
        address payee,
        uint256 tokenId
    ) external onlyRole(PAYER_ROLE) {
        _transferErc721(token, payee, tokenId);
    }

    function batchTransferErc721(
        IERC721Upgradeable[] calldata tokens,
        address[] calldata payees,
        uint256[] calldata tokenIds
    ) external onlyRole(PAYER_ROLE) {
        require(
            tokens.length == payees.length,
            "Vault::batchTransferErc721: tokens/payees length mismatch"
        );
        require(
            payees.length == tokenIds.length,
            "Vault::batchTransferErc721: payees/tokenIds length mismatch"
        );
        require(
            payees.length > 0,
            "Vault::batchTransferErc721: payees length must be gt zero"
        );

        for (uint256 index = 0; index < payees.length; index++) {
            _transferErc721(tokens[index], payees[index], tokenIds[index]);
        }
    }

    function _transferEther(address payee, uint256 amount) internal {
        _checkRole(PAYEE_ROLE, payee);
        AddressUpgradeable.sendValue(payable(payee), amount);
    }

    function transferEther(address payee, uint256 amount)
        external
        onlyRole(PAYER_ROLE)
    {
        _transferEther(payee, amount);
    }

    function batchTransferEther(
        address[] calldata payees,
        uint256[] calldata amounts
    ) external onlyRole(PAYER_ROLE) {
        require(
            payees.length == amounts.length,
            "Vault::batchTransferEther: payees/amounts length mismatch"
        );
        require(
            payees.length > 0,
            "Vault::batchTransferEther: payees length must be gt zero"
        );

        for (uint256 index = 0; index < payees.length; index++) {
            _transferEther(payees[index], amounts[index]);
        }
    }
}