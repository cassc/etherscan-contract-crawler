// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721SBurnable.sol";
import "./IERC721S.sol";

interface IMeta {
    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function tokenOfOwnerByIndex(address _owner, uint256 id)
        external
        view
        returns (uint256);
}

/**
 * @title AngryFrogs Contract
 * @dev Extends ERC721S Non-Fungible Token Standard basic implementation
 */
contract AngryFrogs is ERC721SBurnable {
    string public baseTokenURI;
    uint16 public mintedCount;

    uint16 public MAX_SUPPLY;
    uint16 public CLAIM_COUNT;
    uint16 public GIVEAWAY_COUNT;

    uint256 public mintPrice;
    uint16 public maxByMint;

    address private admin;

    address public metaAddress;
    address public stakingAddress;

    bool public publicSale;
    bool public privateSale;
    bool public claimSale;

    mapping(address => bool) public mintedWhiteliste;
    mapping(uint8 => bool) public mintedFromMeta;
    mapping(address => uint8) public mintableFromRaccoon;
    mapping(address => bool) public mintableDiamond;

    string public constant CONTRACT_NAME = "Angryfrogs Contract";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant MINT_TYPEHASH =
        keccak256("Mint(address user,uint256 num)");

    constructor(address _admin) ERC721S("Angry Frogs Famiglia", "AFFs") {
        MAX_SUPPLY = 10000;
        CLAIM_COUNT = 1462;
        GIVEAWAY_COUNT = 150;
        mintPrice = 0.069 ether; // Private: 0.069ETH, Public: 0.08ETH
        maxByMint = 2;

        admin = _admin;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxByMint(uint16 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    function setCount(
        uint16 _max_supply,
        uint16 _claim_count,
        uint16 _giveaway_count
    ) external onlyOwner {
        MAX_SUPPLY = _max_supply;
        CLAIM_COUNT = _claim_count;
        GIVEAWAY_COUNT = _giveaway_count;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSale = status;
    }

    function setPrivateSaleStatus(bool status) external onlyOwner {
        privateSale = status;
    }

    function setClaimSaleStatus(bool status) external onlyOwner {
        claimSale = status;
    }

    function setContractAddress(address _metaAddress, address _stakingAddress)
        external
        onlyOwner
    {
        metaAddress = _metaAddress;
        stakingAddress = _stakingAddress;
    }

    function setRaccoonOwners(address[] memory _owners, uint8[] memory _counts)
        external
        onlyOwner
    {
        require(_owners.length == _counts.length, "Not same count");
        for (uint16 i; i < _owners.length; i++) {
            mintableFromRaccoon[_owners[i]] = _counts[i];
        }
    }

    function setDiamond(address[] memory _owners) external onlyOwner {
        require(_owners.length > 0, "Not zero count");
        for (uint16 i; i < _owners.length; i++) {
            mintableDiamond[_owners[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != stakingAddress)
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721S: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return mintedCount;
    }

    function getTokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 0; tokenId < totalSupply(); tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) {
                        break;
                    }
                }
            }
            return result;
        }
    }

    function mintByUserPrivate(
        uint8 _numberOfTokens,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(privateSale, "Private Sale is not active");
        require(!mintedWhiteliste[msg.sender], "You minted aleady");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            mintedCount + _numberOfTokens <=
                MAX_SUPPLY - CLAIM_COUNT - GIVEAWAY_COUNT,
            "Max Limit To Sale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(MINT_TYPEHASH, msg.sender, _numberOfTokens)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        mintedWhiteliste[msg.sender] = true;
        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(msg.sender, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
    }

    function mintByUser(uint8 _numberOfTokens) external payable {
        require(publicSale, "Public Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            mintedCount + _numberOfTokens <=
                MAX_SUPPLY - CLAIM_COUNT - GIVEAWAY_COUNT,
            "Max Limit To Sale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(mintPrice * _numberOfTokens <= msg.value, "Low Price To Mint");

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(msg.sender, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
    }

    function mintByOwner(uint8 _numberOfTokens, address user)
        external
        onlyOwner
    {
        require(publicSale, "Public Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(
            mintedCount + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Sale"
        );

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(user, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
    }

    function mintByDiamond() external {
        require(publicSale, "Public Sale is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(mintableDiamond[msg.sender], "Not Diamond list");

        mintableDiamond[msg.sender] = false;

        _safeMint(msg.sender, mintedCount);

        mintedCount = mintedCount + 1;
    }

    function getAvailableMeta(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = IMeta(metaAddress).getTokensOfOwner(owner);

        uint256 availableCount;
        for (uint8 i; i < tokenIds.length; i++) {
            if (!mintedFromMeta[uint8(tokenIds[i])]) {
                availableCount++;
            }
        }

        return availableCount;
    }

    function claimByMeta(uint8 count) external {
        require(claimSale, "Claim is not active");
        require(tx.origin == msg.sender, "Only EOA");

        require(
            getAvailableMeta(msg.sender) >= count,
            "Don't have enough Ceramic"
        );

        uint8 j = 0;
        uint8 balance = uint8(IERC721S(metaAddress).balanceOf(_msgSender()));
        for (uint8 i = 0; i < balance; i++) {
            uint8 tokenId = uint8(
                IMeta(metaAddress).tokenOfOwnerByIndex(msg.sender, i)
            );
            if (!mintedFromMeta[tokenId]) {
                mintedFromMeta[tokenId] = true;
                j++;
            }
            if (j == count) {
                break;
            }
        }

        uint8 _numberOfTokens = count * 2;

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(msg.sender, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
    }

    function claimByRaccoon(uint8 count) external {
        require(claimSale, "Claim is not active");
        require(tx.origin == msg.sender, "Only EOA");
        require(mintableFromRaccoon[msg.sender] >= count, "Already Claimed");

        uint8 _numberOfTokens = count * 2;

        mintableFromRaccoon[msg.sender] =
            mintableFromRaccoon[msg.sender] -
            count;

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            _safeMint(msg.sender, mintedCount + i);
        }

        mintedCount = mintedCount + _numberOfTokens;
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(_msgSender()).transfer(totalBalance);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
