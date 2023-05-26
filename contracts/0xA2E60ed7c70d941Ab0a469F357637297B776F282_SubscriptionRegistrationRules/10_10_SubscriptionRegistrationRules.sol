// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRegister.sol";
import "./IManager.sol";
import "./IMetadata.sol";
import "lib/EnsPrimaryContractNamer/src/PrimaryEns.sol";
import "ens-contracts/registry/ENS.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/utils/Strings.sol";

struct SubscriptionDetails {
    uint256[] prices;
    uint256[] daylengths;
}

interface IENSToken {
    function nameExpires(uint256 id) external view returns (uint256);

    function reclaim(uint256 id, address addr) external;

    function setResolver(address _resolverAddress) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract SubscriptionRegistrationRules is
    IMetadata,
    IRegister,
    PrimaryEns,
    IERC721Receiver
{
    IManager public immutable domainManager;
    uint256 public constant COMMISSION = 2;

    mapping(uint256 => SubscriptionDetails) internal mintPrices;
    mapping(uint256 => uint256) public maxTokens;
    mapping(bytes32 => uint256) public expires;
    mapping(address => uint256) public renewalsBalance;
    mapping(uint256 => string) public descriptions;
    mapping(uint256 => uint256) public mintCount;

    address private tokenOwner;

    bytes4 constant ERC721_SELECTOR = this.onERC721Received.selector;

    event UpdateSubscriptionDetails(
        uint256 indexed _tokenId,
        SubscriptionDetails _details
    );
    event UpdateMaxMint(uint256 indexed _tokenId, uint256 _maxMint);
    event UpdateDescription(uint256 indexed _tokenId, string _description);
    event RenewDomain(
        bytes32 indexed _subdomain,
        address _owner,
        uint256 _expires
    );

    using Strings for uint256;

    IManager public Manager;
    ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IENSToken public constant ensToken =
        IENSToken(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    string public constant DefaultImage =
        "ipfs://QmYWSU93qnqDvAwHGEpJbEEghGa7w7RbsYo9mYYroQnr1D";

    constructor(address _esf) {
        domainManager = IManager(_esf);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public returns (bytes4) {
        domainManager.transferFrom(address(this), tokenOwner, _tokenId);
        return ERC721_SELECTOR;
    }

    function canRegister(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) public view returns (bool) {
        require(_addr == address(this), "incorrect minting address");
        return true;
    }

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs,
        address _mintTo
    ) external payable {
        //only do price and whitelist checks for none owner addresses
        require(_proofs.length == 1, "expiry in proof");

        uint256 duration = uint256(_proofs[0]);
        uint256 currentMint = mintCount[_id];
        if (msg.sender != domainManager.TokenOwnerMap(_id)) {
            require(
                domainManager.DefaultMintPrice(_id) != 0,
                "not for primary sale"
            );

            require(
                currentMint < maxTokens[_id],
                "max mint reached for this token"
            );

            require(
                msg.value >= mintPrice(_id, _label, msg.sender, _proofs),
                "incorrect price"
            );
        }

        unchecked {
            mintCount[_id] = currentMint + 1;
        }

        tokenOwner = _mintTo;
        domainManager.registerSubdomain{value: msg.value}(_id, _label, _proofs);
        delete tokenOwner;

        bytes32 subdomain = subdomainHash(_id, _label);
        uint256 newExpires = getExpiry(subdomain, duration);
        expires[subdomain] = newExpires;

        emit RenewDomain(subdomain, _mintTo, newExpires);
    }

    function ownerBulkMint(
        uint256 _tokenId,
        address[] calldata _addr,
        string[] calldata _labels,
        uint256[] calldata _durations
    ) public payable isTokenOwner(_tokenId) {
        require(
            _addr.length == _labels.length,
            "arrays need to be same length"
        );

        bytes32[] memory duration = new bytes32[](1);

        uint256 count = _addr.length;

        for (uint256 i; i < count; ) {
            require(_addr[i] != address(0), "cannot mint to zero address");
            tokenOwner = _addr[i];
            duration[0] = bytes32(_durations[i]);

            domainManager.registerSubdomain{value: msg.value}(
                _tokenId,
                _labels[i],
                duration
            );
            {
                bytes32 subdomain = subdomainHash(_tokenId, _labels[i]);
                uint256 expiry = block.timestamp + _durations[i];
                expires[subdomain] = expiry;

                emit RenewDomain(subdomain, _addr[i], expiry);
            }
            unchecked {
                ++i;
            }
        }

        unchecked {
            mintCount[_tokenId] += count;
        }

        delete tokenOwner;
    }

    function updateSubscriptionDetails(
        uint256 _tokenId,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
    }

    function updateMaxMint(
        uint256 _tokenId,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        maxTokens[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintAndSubscription(
        uint256 _tokenId,
        uint256 _maxMint,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
        maxTokens[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintDescriptionAndSubscription(
        uint256 _tokenId,
        uint256 _maxMint,
        string calldata _description,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
        maxTokens[_tokenId] = _maxMint;
        descriptions[_tokenId] = _description;

        emit UpdateMaxMint(_tokenId, _maxMint);
        emit UpdateDescription(_tokenId, _description);
    }

    function updateDescriptionA(
        uint256 _tokenId,
        string calldata _description
    ) public isTokenOwner(_tokenId) {
        descriptions[_tokenId] = _description;
        emit UpdateDescription(_tokenId, _description);
    }

    function renewDomain(
        uint256 _tokenId,
        string calldata _label,
        bytes32[] calldata _duration
    ) public payable {
        bytes32 node = subdomainHash(_tokenId, _label);
        require(expires[node] > 0, "domain not registered");
        require(_duration.length == 1, "duration must be 1");
        require(_duration[0] > 0, "duration must be greater than 0");

        // token owner can extend any of their subdomain tokens for free

        address owner = domainManager.TokenOwnerMap(_tokenId);
        if (owner == msg.sender) {
            expires[node] = (block.timestamp + uint256(_duration[0]) * 1 days);

        } else {

            uint256 price = mintPrice(_tokenId, _label, msg.sender, _duration);

            require(msg.value >= price, "incorrect price");
            uint256 currentExpiry;
            if (expires[node] < block.timestamp) {
                currentExpiry = block.timestamp;
            } else {
                currentExpiry = expires[node];
            }

            expires[node] = currentExpiry + (uint256(_duration[0]) * 1 days);

            uint256 commission = msg.value / 50;

            renewalsBalance[owner] = renewalsBalance[owner] + msg.value - commission;
            payable(address(domainManager)).call{value: commission}("");

        }


        emit RenewDomain(node, msg.sender, expires[node]);
    }

    function withdrawRenewals() public {
        uint256 balance = renewalsBalance[msg.sender];
        require(balance > 0, "no balance");

        renewalsBalance[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) public view returns (uint256) {
        require(
            _proofs.length > 0,
            "require registration length in first value of proofs"
        );

        if (_addr == domainManager.TokenOwnerMap(_tokenId)) {
            return 0;
        } else {
            uint256 registrationLength = uint256(_proofs[0]);
            SubscriptionDetails memory dets = mintPrices[_tokenId];

            uint256 previousPrice;
            require(
                registrationLength >= dets.daylengths[0] &&
                    registrationLength <= 365,
                "registration length too short"
            );
            for (uint256 i; i < dets.prices.length; ) {
                if (registrationLength < dets.daylengths[i]) {
                    return previousPrice * registrationLength;
                }

                previousPrice = dets.prices[i];

                unchecked {
                    ++i;
                }
            }
            return previousPrice * registrationLength;
        }
    }

    function getExpiry(
        bytes32 subdomain,
        uint256 _duration
    ) public view returns (uint256) {
        uint256 currentExpiry = expires[subdomain];

        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp;
        }

        return currentExpiry + (_duration * 1 days);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory label = domainManager.IdToLabelMap(tokenId);

        uint256 ownerId = domainManager.IdToOwnerId(tokenId);
        string memory parentName = domainManager.IdToDomain(ownerId);
        string memory ensName = string(
            abi.encodePacked(label, ".", parentName, ".eth")
        );
        string memory locked = (ensToken.ownerOf(ownerId) ==
            address(domainManager)) && (domainManager.TokenLocked(ownerId))
            ? "True"
            : "False";
        string memory image = domainManager.IdImageMap(ownerId);

        bytes32 hashed = domainManager.IdToHashMap(tokenId);

        string memory active;

        {
            address resolver = ens.resolver(hashed);
            active = resolver == address(domainManager) ? "True" : "False";
        }

        uint256 expiry = ensToken.nameExpires(ownerId);

        uint256 subExpires = expires[subdomainHash(ownerId, label)];

        string memory subActive = subExpires > block.timestamp
            ? "True"
            : "False";

        string memory description = descriptions[tokenId];

        bytes memory data = abi.encodePacked(
            'data:application/json;utf8,{"name": "',
            ensName,
            '","description": "Transferable ',
            parentName,
            ".eth sub-domain. ",
            description,
            '","image":"',
            (bytes(image).length == 0 ? DefaultImage : image),
            '","attributes":[{"trait_type" : "parent name", "value" : "',
            parentName
        );

        return
            string(
                abi.encodePacked(
                    data,
                    '.eth"},{"trait_type" : "parent locked", "value" : "',
                    locked,
                    '"},{"trait_type" : "ens active", "value" : "',
                    active,
                    '"},{"trait_type" : "subscription active", "value" : "',
                    active,
                    '" },{"trait_type" : "subscription expiry", "display_type": "date","value": "',
                    subExpires.toString(),
                    '" },{"trait_type" : "parent expiry", "display_type": "date","value": ',
                    expiry.toString(),
                    "}]}"
                )
            );
    }

    function subdomainHash(
        uint256 _parent,
        string memory _label
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_parent, keccak256(bytes(_label))));
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(
            domainManager.TokenOwnerMap(_tokenId) == msg.sender,
            "not authorised"
        );
        _;
    }
}