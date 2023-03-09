// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ENS.sol";
import "./IAddressResolver.sol";
import "./IAddrResolver.sol";
import "./ITextResolver.sol";
import "./INameResolver.sol";
import "./INameWrapper.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract CatEnsMapperUpgradeable is
    IAddressResolver,
    IAddrResolver,
    ITextResolver,
    INameResolver,
    ERC165Upgradeable,
    OwnableUpgradeable
{
    using Strings for uint256;

    ENS private ens;
    IERC1155 public nft;
    bytes32 public domainHash;

    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(string => bool) public blacklistedReservedWords;

    string public domainLabel;

    mapping(bytes32 => address) public hashToClaimer;
    mapping(address => bytes32) public claimerToHash;
    mapping(address => uint256) public claimerToExpireDate;
    mapping(bytes32 => string) public hashToDomainMap;

    uint256 public expirationPeriod;

    bool public publicClaimOpen;

    event RegisterSubdomain(address claimer, string label, uint256 expiresAt);
    event SubdomainProlonged(address claimer, uint256 expiresAt);
    event SubdomainReset(address claimer);
    event ViolationReset(address claimer);

    function initialize() public initializer {
        __ERC165_init();
        __Ownable_init();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAddressResolver).interfaceId ||
            interfaceId == type(IAddrResolver).interfaceId ||
            interfaceId == type(ITextResolver).interfaceId ||
            interfaceId == type(INameResolver).interfaceId ||
            interfaceId == 0xbc1c58d1 || //contentHash
            super.supportsInterface(interfaceId);
    }

    function text(bytes32 node, string calldata key)
        external
        view
        override
        returns (string memory)
    {
        address claimer = hashToClaimer[node];
        require(
            claimer != address(0) &&
                claimerToExpireDate[claimer] >= block.timestamp,
            "Address doesn't exist"
        );

        if (keccak256(abi.encodePacked(key)) == keccak256("url")) {
            return "https://guttercatgang.com";
        } else {
            return texts[node][key];
        }
    }

    function addr(bytes32 node)
        external
        view
        override
        returns (address payable)
    {
        address claimer = hashToClaimer[node];
        require(claimer != address(0), "Address doesn't exist");

        if (claimerToExpireDate[claimer] >= block.timestamp) {
            return payable(claimer);
        } else {
            return payable(address(0));
        }
    }

    function addr(bytes32 node, uint256 coinType)
        external
        view
        override
        returns (bytes memory)
    {
        address claimer = hashToClaimer[node];
        require(claimer != address(0), "Address doesn't exist");

        if (coinType == 60 && claimerToExpireDate[claimer] >= block.timestamp) {
            return abi.encodePacked(address(claimer));
        }

        return abi.encodePacked(address(0x0));
    }

    function name(bytes32 node) public view override returns (string memory) {
        return
            (hashToClaimer[node] == address(0))
                ? ""
                : string(
                    abi.encodePacked(
                        hashToDomainMap[node],
                        ".",
                        domainLabel,
                        ".eth"
                    )
                );
    }

    function domainMap(string calldata label) public view returns (bytes32) {
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(
            abi.encodePacked(domainHash, encoded_label)
        );

        address claimer = hashToClaimer[big_hash];
        return
            (claimer != address(0) &&
                claimerToExpireDate[claimer] >= block.timestamp)
                ? big_hash
                : bytes32(0x0);
    }

    function getAddressDomain(address claimer)
        private
        view
        returns (string memory uri)
    {
        require(
            claimerToHash[claimer] != 0x0 &&
                claimerToExpireDate[claimer] >= block.timestamp,
            "Address does not have an ENS"
        );

        uri = string(
            abi.encodePacked(
                hashToDomainMap[claimerToHash[claimer]],
                ".",
                domainLabel,
                ".eth"
            )
        );
    }

    function getAddressesDomains(address[] memory addresses)
        public
        view
        returns (string[] memory)
    {
        string[] memory uris = new string[](addresses.length);
        for (uint256 i; i < addresses.length; i++) {
            uris[i] = getAddressDomain(addresses[i]);
        }
        return uris;
    }

    function getDomainHash() private view returns (bytes32 namehash) {
        namehash = 0x0;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked("eth")))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(domainLabel)))
        );
    }

    function setDomain(
        address tokenOwner,
        string calldata label,
        uint256 token_id
    ) public isClaimAuthorized(tokenOwner, token_id) {
        require(publicClaimOpen || owner() == _msgSender(), "Not authorised");
        require(
            !blacklistedReservedWords[label] || owner() == _msgSender(),
            "Label not allowed"
        );

        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(
            abi.encodePacked(domainHash, encoded_label)
        );

        require(
            claimerToExpireDate[tokenOwner] < block.timestamp,
            "Active ENS by address exists"
        );

        address claimerWithLabel = hashToClaimer[big_hash];
        require(
            claimerWithLabel == address(0) ||
                claimerToExpireDate[claimerWithLabel] < block.timestamp,
            "ENS is already in use"
        );

        // reset expired old claimer of the label if it exists
        if (claimerWithLabel != address(0) && claimerToExpireDate[claimerWithLabel] < block.timestamp) {
            _reset(claimerWithLabel);
        }

        // reset old expired label of the claimer if it exists
        if (claimerToExpireDate[tokenOwner] < block.timestamp && claimerToExpireDate[tokenOwner] > 0) {
            _reset(tokenOwner);
        }

        // if record doesn't exist, if record exists but reset, if record exists but expired
        require(
            !ens.recordExists(big_hash) ||
                (ens.recordExists(big_hash) &&
                    hashToClaimer[big_hash] == address(0)) ||
                (ens.recordExists(big_hash) &&
                    claimerToExpireDate[claimerWithLabel] < block.timestamp) ||
                _msgSender() == owner(),
            "sub-domain already exists"
        );

        ens.setSubnodeRecord(
            domainHash,
            encoded_label,
            owner(),
            address(this),
            0
        );

        hashToClaimer[big_hash] = tokenOwner;
        claimerToHash[tokenOwner] = big_hash;
        hashToDomainMap[big_hash] = label;
        claimerToExpireDate[tokenOwner] = block.timestamp + expirationPeriod;

        emit RegisterSubdomain(
            tokenOwner,
            label,
            block.timestamp + expirationPeriod
        );
        emit AddrChanged(big_hash, tokenOwner);
        emit AddressChanged(big_hash, 60, abi.encodePacked(tokenOwner));
    }

    function prolongENS(address claimer, uint256 tokenId) external {
        require(
            _msgSender() == owner() ||
                (_msgSender() == claimer &&
                    claimerToHash[claimer] != 0x0 &&
                    claimerToExpireDate[claimer] >= block.timestamp &&
                    nft.balanceOf(claimer, tokenId) > 0),
            "Not authorized"
        );
        claimerToExpireDate[claimer] = block.timestamp + expirationPeriod;

        emit SubdomainProlonged(claimer, block.timestamp + expirationPeriod);
    }

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external onlyOwner {
        texts[node][key] = value;
        emit TextChanged(node, key, key, value);
    }

    function resetHash(address claimer) external {
        require(
            _msgSender() == owner() ||
                (_msgSender() == claimer &&
                    claimerToHash[claimer] != 0x0 &&
                    claimerToExpireDate[claimer] >= block.timestamp),
            "Not authorized"
        );

        _reset(claimer);

        emit SubdomainReset(claimer);
    }

    function violationReset(address claimer) external onlyOwner {
        _reset(claimer);

        emit ViolationReset(claimer);
        emit SubdomainReset(claimer);
    }

    function _reset(address claimer) internal {
        bytes32 domain = claimerToHash[claimer];
        require(ens.recordExists(domain), "Sub-domain does not exist");

        hashToDomainMap[domain] = "";
        hashToClaimer[domain] = address(0);
        claimerToHash[claimer] = 0x0;
        claimerToExpireDate[claimer] = 0;

        emit AddrChanged(domain, address(0));
        emit AddressChanged(domain, 60, abi.encodePacked(address(0)));
    }

    function setDomainLabel(string calldata label) external onlyOwner {
        domainLabel = label;
        domainHash = getDomainHash();
    }

    function setNftAddress(address addy) external onlyOwner {
        nft = IERC1155(addy);
    }

    function setEnsAddress(address addy) external onlyOwner {
        ens = ENS(addy);
    }

    function togglePublicClaim() external onlyOwner {
        publicClaimOpen = !publicClaimOpen;
    }

    function updateBlacklistedReservedWords(
        string[] calldata words,
        bool blacklisted
    ) external onlyOwner {
        for (uint256 i = 0; i < words.length; i++) {
            blacklistedReservedWords[words[i]] = blacklisted;
        }
    }

    function updateExpirationPeriod(uint256 _expirationPeriod)
        external
        onlyOwner
    {
        expirationPeriod = _expirationPeriod;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_msgSender(), balance);
    }

    modifier isClaimAuthorized(address tokenOwner, uint256 tokenId) {
        require(
            owner() == _msgSender() ||
                (tokenOwner == _msgSender() &&
                    nft.balanceOf(_msgSender(), tokenId) > 0),
            "Not authorised"
        );
        _;
    }
}