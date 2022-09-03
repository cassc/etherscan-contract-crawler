// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../universal/UniversalRegistrar.sol";
import "./RoyaltyPayeeFactory.sol";
import "./RoyaltyPayee.sol";
import "./IRoyaltyPayee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NameStore.sol";

error UnsupportedPayeeInterface(bytes32 node, address recipient);

contract UniversalRoyalties is IERC2981, ERC165, Ownable, Access {
    NameStore public store;
    IRoyaltyFactory public factory;

    uint256 public constant FEE_DENOMINATOR = 10000;

    mapping(uint256 => uint96) public tokenFeeNumerators;
    mapping(bytes32 => uint96) public defaultFeeNumerators;
    mapping(bytes32 => address) public recipients;

    event RoyaltyPayeeChanged(bytes32 indexed node, address indexed old, address indexed payee);
    event DefaultFeeNumeratorChanged(bytes32 indexed node, uint96 old, uint96 newFraction);
    event TokenFeeNumeratorChanged(bytes32  indexed node, uint256 indexed token, uint96 old, uint96 newFraction);

    constructor(UniversalRegistrar _registrar, NameStore _store, IRoyaltyFactory _factory) Access(_registrar) {
        store = _store;
        factory = _factory;
    }

    function setRoyaltyFactory(IRoyaltyFactory _factory) external onlyOwner {
        factory = _factory;
    }

    function initializeRoyalties(bytes32 node, uint96 defaultFeeNumerator) external nodeOperator(node) {
        address payee = factory.create(node);
        emit RoyaltyPayeeChanged(node, recipients[node], payee);
        recipients[node] = payee;

        emit DefaultFeeNumeratorChanged(node, defaultFeeNumerators[node], defaultFeeNumerator);
        defaultFeeNumerators[node] = defaultFeeNumerator;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public override view returns (address, uint256) {
        bytes32 node = store.parentOf(tokenId);
        if (node == bytes32(0) || recipients[node] == address(0)) {
            return (address(0), 0);
        }
        if (tokenFeeNumerators[tokenId] != 0) {
            return (recipients[node], (salePrice * tokenFeeNumerators[tokenId]) / FEE_DENOMINATOR);
        }
        if (defaultFeeNumerators[node] != 0) {
            return (recipients[node], (salePrice * defaultFeeNumerators[node]) / FEE_DENOMINATOR);
        }

        return (address(0), 0);
    }

    function setRoyaltyInfo(bytes32 node, uint96 feeNumerator) external nodeOperator(node)  {
        require(feeNumerator < FEE_DENOMINATOR, "invalid fee numerator");
        emit DefaultFeeNumeratorChanged(node, defaultFeeNumerators[node], feeNumerator);
        defaultFeeNumerators[node] = feeNumerator;
    }

    function setRoyaltyInfoForToken(bytes32 node, uint256 tokenId, uint96 feeNumerator) external nodeOperator(node) {
        require(feeNumerator < FEE_DENOMINATOR, "invalid fee numerator");

        bytes32 parent = store.parentOf(tokenId);
        require(parent == node, "bad token id/node");

        emit TokenFeeNumeratorChanged(node, tokenId, tokenFeeNumerators[tokenId], feeNumerator);
        tokenFeeNumerators[tokenId] = feeNumerator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // helper functions
    function ownerBalance(bytes32 node) external view returns (uint256) {
        require(recipients[node] != address(0));
        try IERC165(recipients[node]).supportsInterface(type(IRoyaltyPayee).interfaceId) returns (bool supported) {
            if (supported) {
                return IRoyaltyPayee(recipients[node]).ownerBalance();
            }
        } catch {}
        revert UnsupportedPayeeInterface(node, recipients[node]);
    }

    function registryBalance(bytes32 node) external view returns (uint256) {
        require(recipients[node] != address(0));
        try IERC165(recipients[node]).supportsInterface(type(IRoyaltyPayee).interfaceId) returns (bool supported) {
            if (supported) {
                return IRoyaltyPayee(recipients[node]).registryBalance();
            }
        } catch {}
        revert UnsupportedPayeeInterface(node, recipients[node]);
    }

    function ownerReleased(bytes32 node) external view returns (uint256) {
        require(recipients[node] != address(0));
        try IERC165(recipients[node]).supportsInterface(type(IRoyaltyPayee).interfaceId) returns (bool supported) {
            if (supported) {
                return IRoyaltyPayee(recipients[node]).ownerReleased();
            }
        } catch {}
        revert UnsupportedPayeeInterface(node, recipients[node]);
    }

    function registryReleased(bytes32 node) external view returns (uint256) {
        require(recipients[node] != address(0));
        try IERC165(recipients[node]).supportsInterface(type(IRoyaltyPayee).interfaceId) returns (bool supported) {
            if (supported) {
                return IRoyaltyPayee(recipients[node]).registryReleased();
            }
        } catch {}
        revert UnsupportedPayeeInterface(node, recipients[node]);
    }
}