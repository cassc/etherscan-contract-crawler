// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "../erc-721/MarketToken.sol";
import "../payment-splitter/MarketPaymentSplitter.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/ICollectionContractInitializer.sol";
import "../interfaces/IPaymentSplitterInitializer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../erc-721/ContextMixin.sol";

/**
 * @dev This contract is for creating proxy to access ERC721Rarible token.
 *
 * The beacon should be initialized before call ERC721RaribleFactoryC2 constructor.
 *
 */
contract ERC721MarketTokenFactory is
    Initializable,
    AccessControlUpgradeable,
    ContextMixin
{
    using Counters for Counters.Counter;
    using Clones for address;
    Counters.Counter private _saltCounter;
    address public erc721Impl;
    address public paymentSplitterImpl;
    address public trustedProxy;

    event CreateMarketTokenProxy(address token, address splitter);

    function __ERC721MarketTokenFactory_init(
        address _erc721Impl,
        address _paymentSplitterImpl,
        address _trustedProxy
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        erc721Impl = _erc721Impl;
        paymentSplitterImpl = _paymentSplitterImpl;
        trustedProxy = _trustedProxy;
    }

    function _updateImpl(
        address _erc721Impl,
        address _paymentSplitterImpl,
        address _trustedProxy
    ) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msgSender()),
            "Caller doesnot have admin role"
        );

        erc721Impl = _erc721Impl;
        paymentSplitterImpl = _paymentSplitterImpl;
        trustedProxy = _trustedProxy;
    }

    function _setupRole() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
    }

    // constructor(
    //     address _erc721Impl,
    //     address _paymentSplitterImpl,
    //     address _trustedProxy
    // ) {
    //     erc721Impl = _erc721Impl;
    //     paymentSplitterImpl = _paymentSplitterImpl;
    //     trustedProxy = _trustedProxy;
    // }

    function _getSalt(address creator, uint256 nonce)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(creator, nonce));
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseURI,
        bool _revealed,
        string memory _notRevealedUri,
        address _contractOwner,
        address[] memory _payees,
        uint256[] memory _shares
    ) external {
        _saltCounter.increment();
        uint256 salt = _saltCounter.current();

        address paymentAddress = paymentSplitterImpl.cloneDeterministic(
            _getSalt(msg.sender, salt)
        );

        IPaymentSplitterInitializer(paymentAddress).initialize(
            _payees,
            _shares
        );
        address collectionAddress = erc721Impl.cloneDeterministic(
            _getSalt(msg.sender, salt)
        );

        ICollectionContractInitializer(collectionAddress).initialize(
            _name,
            _symbol,
            _contractURI,
            _baseURI,
            _revealed,
            _notRevealedUri,
            _contractOwner,
            trustedProxy,
            paymentAddress,
            _payees,
            _shares
        );
        emit CreateMarketTokenProxy(collectionAddress, paymentAddress);
    }
}