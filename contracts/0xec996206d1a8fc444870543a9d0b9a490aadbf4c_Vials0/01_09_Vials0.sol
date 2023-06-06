// contracts/Vials0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./Incubator.sol";

struct MintParams {
    uint256 diamondQuantity;
    uint256 goldQuantity;
    uint256 silverQuantity;
    uint256 bronzeQuantity;
    uint256 regularQuantity;
    uint256 publicQuantity;
    uint256 freeQuantity;
    uint256 claimQuantity;
    // tier
    uint256 tier;
    bytes32[] tierProof;
    // code
    string code;
    bytes32[] codeProof;
    // free
    uint256 free;
    bytes32[] freeProof;
    // claim
    uint256 claim;
    bytes32[] claimProof;
}

contract Vials0 is ERC721AQueryable, Ownable {
    uint256 private constant MAX_SUPPLY = 8001;
    uint256 private constant SUPPLY = 7001;
    uint256 private constant RESERVED_SUPPLY = 1001;

    uint256 private constant DIAMOND_TIER_SUPPLY = 226;
    uint256 private constant GOLD_TIER_SUPPLY = 501;
    uint256 private constant SILVER_TIER_SUPPLY = 1001;
    uint256 private constant BRONZE_TIER_SUPPLY = 1501;

    uint256 private constant GOLD_TIER = 4;
    uint256 private constant SILVER_TIER = 3;
    uint256 private constant BRONZE_TIER = 2;
    uint256 private constant REGULAR_TIER = 1;
    uint256 private constant PUBLIC_TIER = 0;

    string private tokenUri;

    uint256 private price = 0.07 ether;

    uint256 private walletLimit = 6;

    address private incubatorAddress;

    bytes32 private tierRoot;
    bytes32 private codeRoot;
    bytes32 private freeRoot;
    bytes32 private claimRoot;

    bool private saleActive = false;

    uint256 diamond;
    uint256 gold;
    uint256 silver;
    uint256 bronze;
    uint256 claimed;

    mapping(address => uint256) private walletToClaimed;
    mapping(address => uint256) private walletToFree;

    constructor(string memory _tokenUri)
        ERC721A("The Digital Pets Company", "VIAL0")
    {
        tokenUri = _tokenUri;
    }

    function devClaim() external onlyOwner {
        uint256 quantity = RESERVED_SUPPLY - 1 - claimed;
        require(_totalMinted() + quantity < MAX_SUPPLY);
        claimed += quantity;
        _safeMint(msg.sender, quantity);
    }

    function devMint(address[] calldata _to, uint256[] calldata _quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            require(
                _totalMinted() - claimed + _quantity[i] < SUPPLY,
                "Purchase would exceed unreserved supply."
            );
            _safeMint(_to[i], _quantity[i]);
        }
    }

    function setWalletLimit(uint256 _walletLimit) external onlyOwner {
        walletLimit = _walletLimit + 1;
    }

    function getWalletLimit() external view returns (uint256) {
        return walletLimit - 1;
    }

    function setSaleActive(bool _saleActive) external onlyOwner {
        saleActive = _saleActive;
    }

    function getSaleActive() external view returns (bool) {
        return saleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function setTierRoot(bytes32 _tierRoot) external onlyOwner {
        tierRoot = _tierRoot;
    }

    function setCodeRoot(bytes32 _codeRoot) external onlyOwner {
        codeRoot = _codeRoot;
    }

    function setFreeRoot(bytes32 _freeRoot) external onlyOwner {
        freeRoot = _freeRoot;
    }

    function setClaimRoot(bytes32 _claimRoot) external onlyOwner {
        claimRoot = _claimRoot;
    }

    function mint(MintParams calldata _params) external payable {
        require(saleActive, "Sale is not active.");

        uint256 tier = PUBLIC_TIER;
        uint256 quantity = 0;
        uint256 cost = 0;

        if (_params.tierProof.length > 0) {
            // check if wallet should be granted higher tier
            require(
                verifyProof(
                    _params.tierProof,
                    tierRoot,
                    createAddressIntLeaf(msg.sender, _params.tier)
                ),
                "Tier verification failed."
            );
            tier = _params.tier;
        } else if (_params.codeProof.length > 0) {
            // if valid code is provided apply silver tier discount
            require(
                verifyProof(
                    _params.codeProof,
                    codeRoot,
                    createStringLeaf(_params.code)
                ),
                "Code verification failed."
            );
            tier = REGULAR_TIER;
        }

        // diamond
        if (_params.diamondQuantity > 0) {
            require(tier > GOLD_TIER, "Insufficient tier (diamond).");
            diamond += _params.diamondQuantity;
            require(
                diamond < DIAMOND_TIER_SUPPLY,
                "Purchase would exceed diamond tier supply."
            );
            cost += _params.diamondQuantity * 0.042 ether;
            quantity += _params.diamondQuantity;
        }

        // gold
        if (_params.goldQuantity > 0) {
            require(tier > SILVER_TIER, "Insufficient tier (gold).");
            gold += _params.goldQuantity;
            require(
                gold < GOLD_TIER_SUPPLY,
                "Purchase would exceed gold tier supply."
            );
            cost += _params.goldQuantity * 0.049 ether;
            quantity += _params.goldQuantity;
        }

        // silver
        if (_params.silverQuantity > 0) {
            require(tier > BRONZE_TIER, "Insufficient tier (silver).");
            silver += _params.silverQuantity;
            require(
                silver < SILVER_TIER_SUPPLY,
                "Purchase would exceed silver tier supply."
            );
            cost += _params.silverQuantity * 0.053 ether;
            quantity += _params.silverQuantity;
        }

        // bronze
        if (_params.bronzeQuantity > 0) {
            require(tier > REGULAR_TIER, "Insufficient tier (bronze).");
            bronze += _params.bronzeQuantity;
            require(
                bronze < BRONZE_TIER_SUPPLY,
                "Purchase would exceed bronze tier supply."
            );
            cost += _params.bronzeQuantity * 0.056 ether;
            quantity += _params.bronzeQuantity;
        }

        // regular
        if (_params.regularQuantity > 0) {
            require(tier > PUBLIC_TIER, "Insufficient tier (regular).");
            cost += _params.regularQuantity * 0.06 ether;
            quantity += _params.regularQuantity;
        }

        // free
        if (_params.freeQuantity > 0) {
            require(
                verifyProof(
                    _params.freeProof,
                    freeRoot,
                    createAddressIntLeaf(msg.sender, _params.free)
                ),
                "Free limit verification failed."
            );
            walletToFree[msg.sender] += _params.freeQuantity;
            require(
                walletToFree[msg.sender] <= _params.free,
                "Purchase would exceed free limit."
            );
            quantity += _params.freeQuantity;
        }

        // public
        if (_params.publicQuantity > 0) {
            cost += _params.publicQuantity * price;
            quantity += _params.publicQuantity;
        }

        // verify wallet limit
        require(
            _numberMinted(msg.sender) - walletToClaimed[msg.sender] + quantity <
                walletLimit,
            "Purchase would exceed wallet limit."
        );

        // verify unreserved supply
        require(
            _totalMinted() - claimed + quantity < SUPPLY,
            "Purchase would exceed unreserved supply."
        );

        // verify funds
        require(msg.value == cost, "Insufficient funds.");

        if (_params.claimQuantity > 0) {
            // mint + claim
            require(
                verifyProof(
                    _params.claimProof,
                    claimRoot,
                    createAddressIntLeaf(msg.sender, _params.claim)
                ),
                "Claim limit verification failed."
            );
            claimed += _params.claimQuantity;
            require(
                claimed < RESERVED_SUPPLY,
                "Purchase would exceed reserved supply."
            );
            walletToClaimed[msg.sender] += _params.claimQuantity;
            require(
                walletToClaimed[msg.sender] <= _params.claim,
                "Purchase would exceed claim limit."
            );
            _safeMint(msg.sender, quantity + _params.claimQuantity);
        } else {
            // just mint
            _safeMint(msg.sender, quantity);
        }
    }

    function setIncubatorAddress(address _incubatorAddress) external onlyOwner {
        incubatorAddress = _incubatorAddress;
    }

    function getIncubatorAddress() external view returns (address) {
        return incubatorAddress;
    }

    function incubate(uint256 _vialId) external {
        require(incubatorAddress != address(0), "Incubation is not active.");
        _burn(_vialId, true);
        Incubator incubator = Incubator(incubatorAddress);
        incubator.incubate(_vialId, msg.sender);
    }

    function setTokenUri(string calldata _tokenUri) external onlyOwner {
        tokenUri = _tokenUri;
    }

    function getTokenUri() external view returns (string memory) {
        return tokenUri;
    }

    function getStats()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (diamond, gold, silver, bronze, claimed, _totalMinted());
    }

    function getWalletStats(address _address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            walletToClaimed[_address],
            walletToFree[_address],
            _numberMinted(_address)
        );
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function createStringLeaf(string calldata _value)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_value));
    }

    function createAddressIntLeaf(address _address, uint256 _value)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address, _value));
    }

    function verifyProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    /** OVERRIDES */
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}