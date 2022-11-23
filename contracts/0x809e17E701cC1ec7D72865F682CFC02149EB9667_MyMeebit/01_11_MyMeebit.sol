/// SPDX-License-Identifier: MIT


pragma solidity ^0.8.15;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription) external;

    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    function updateOperator(address registrant, address operator, bool filtered) external;

    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    function subscribe(address registrant, address registrantToSubscribe) external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant) external returns (address[] memory);

    function subscriberAt(address registrant, uint256 index) external returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy) external;

    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    function filteredOperators(address addr) external returns (address[] memory);

    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator() virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MyMeebit is ERC721("MyMeebit", "MyMeebit"), DefaultOperatorFilterer, Ownable {

    uint256 public totalSupply;
    string public baseURI;

    constructor() {
        baseURI = "https://meebits.app/meebit/";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mint() external returns (uint256 tokenId) {
        _mint(msg.sender, ++totalSupply);
        return totalSupply;
    }

    function mint(uint256 count) external returns (uint256 startTokenId) {
        startTokenId = totalSupply + count;
        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, ++totalSupply);
        }
        return startTokenId;
    }

    function mintTo(address to, uint256 count) external returns (uint256 startTokenId) {
        startTokenId = totalSupply + count;
        for (uint256 i = 0; i < count; i++) {
            _mint(to, ++totalSupply);
        }
        return startTokenId;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }
}