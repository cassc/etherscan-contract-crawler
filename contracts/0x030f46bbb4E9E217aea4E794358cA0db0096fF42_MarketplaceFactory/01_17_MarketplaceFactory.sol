// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IMarketplace {
    function initialize(
        string memory domain,
        address factory,
        address owner,
        address signer,
        address guarantor,
        address arbitrator
    ) external;

    function upgradeTo(address newImplementation) external;
}

contract MarketplaceFactory is Ownable, Initializable, UUPSUpgradeable {
    using ECDSA for bytes32;

    address public marketplaceImpl;
    address public signer;
    address public arbitrator;

    address[] public marketplaces;
    mapping(address => uint256) public marketplaceIndex;
    mapping(string => address) public domainToMarket;
    mapping(address => address[]) public guarantorToMarket;

    event NewMarketplace(
        string domain,
        address marketplace,
        address guarantor,
        address arbitrator
    );

    function getMarketplace(
        string memory _domain
    ) external view returns (address) {
        return domainToMarket[_domain];
    }

    function getMarketplacesByGuarantor(
        address _guarantor
    ) external view returns (address[] memory) {
        return guarantorToMarket[_guarantor];
    }

    function initialize(
        address _marketplaceImpl,
        address _signer,
        address _arbitrator
    ) public initializer {
        _transferOwnership(_msgSender());
        marketplaceImpl = _marketplaceImpl;
        signer = _signer;
        arbitrator = _arbitrator;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    function upgradeMarketplace(
        address _newMarketplaceImpl
    ) external onlyOwner {
        marketplaceImpl = _newMarketplaceImpl;
        for (uint256 i = 0; i < marketplaces.length; i++) {
            IMarketplace(marketplaces[i]).upgradeTo(_newMarketplaceImpl);
        }
    }

    /**
     * @dev Create a new marketplace.
     * @param _domain The domain name of the marketplace.
     * @return The address of the created marketplace.
     */
    function newMarketplace(
        string memory _domain,
        bytes memory _signature
    ) external returns (address) {
        require(
            domainToMarket[_domain] == address(0),
            "MarketplaceFactory: domain exists"
        );
        require(
            _verify(_domain, msg.sender, _signature),
            "MarketplaceFactory: invalid signature"
        );
        bytes memory deployCode = abi.encodeCall(
            IMarketplace.initialize,
            (_domain, address(this), owner(), signer, msg.sender, arbitrator)
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(
            marketplaceImpl,
            deployCode
        );
        address marketplace = address(marketplaceProxy);
        marketplaces.push(marketplace);
        marketplaceIndex[marketplace] = marketplaces.length - 1;
        domainToMarket[_domain] = marketplace;

        guarantorToMarket[msg.sender].push(marketplace);

        emit NewMarketplace(_domain, marketplace, msg.sender, arbitrator);

        return marketplace;
    }

    function _verify(
        string memory _domain,
        address _guarantor,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(_domain, _guarantor));
        return message.toEthSignedMessageHash().recover(_signature) == signer;
    }
}