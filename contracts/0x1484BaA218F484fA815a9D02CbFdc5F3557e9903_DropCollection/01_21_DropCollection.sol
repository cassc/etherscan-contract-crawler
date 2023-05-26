// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./BaseCollection.sol";

contract DropCollection is BaseCollection {
    event MerkleRootSet(bytes32 indexed merkleRoot);
    event TokenBaseURISet(string indexed tokenBaseURI);

    using SafeMathUpgradeable for uint256;
    using MerkleProofUpgradeable for bytes32[];

    mapping(address => uint256) private _mintCount;
    bytes32 private _merkleRoot;
    string private _tokenBaseURI;

    // Sales Parameters
    uint256 private _maxAmount;
    uint256 private _maxPerMint;
    uint256 private _maxPerWallet;
    uint256 private _price;

    // Auction Parameters
    uint256 private _startPrice;
    uint256 private _endPrice;
    uint256 private _duration;
    uint256 private _startedAt;

    // States
    bool private _presaleActive = false;
    bool private _saleActive = false;
    bool private _auctionActive = false;

    modifier onlyMintable(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "Greater than 0");
        require(
            _mintCount[_msgSender()].add(numberOfTokens) <= _maxPerWallet,
            "Exceeded max: 1"
        );
        require(
            _maxAmount > 0
                ? totalSupply().add(numberOfTokens) <= _maxAmount
                : true,
            "Exceeded max: 2"
        );
        require(numberOfTokens <= _maxPerMint, "Exceeded max: 3");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public override initializer {
        __BaseCollection_init(
            name_,
            symbol_,
            treasury_,
            royalty_,
            royaltyFee_
        );
    }

    function mint(uint256 numberOfTokens)
        public
        payable
        onlyMintable(numberOfTokens)
    {
        require(!_presaleActive, "Not active: 1");
        require(_auctionActive || _saleActive, "Not active: 2");

        _purchaseMint(numberOfTokens, _msgSender());
    }

    function presaleMint(uint256 numberOfTokens, bytes32[] calldata proof)
        public
        payable
        onlyMintable(numberOfTokens)
    {
        require(_presaleActive, "Not active: 3");
        require(_merkleRoot != "", "Not active: 4");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not active"
        );

        _purchaseMint(numberOfTokens, _msgSender());
    }

    function batchAirdrop(
        uint256[] calldata numberOfTokens,
        address[] calldata recipients
    ) external onlyOwner {
        require(numberOfTokens.length == recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(numberOfTokens[i], recipients[i]);
        }
    }

    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        _merkleRoot = newRoot;

        emit MerkleRootSet(newRoot);
    }

    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) public onlyOwner {
        _saleActive = true;
        _presaleActive = presale;

        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _price = newPrice;
    }

    function startAuction(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newStartPrice,
        uint256 newEndPrice,
        uint256 newDuration,
        bool presale
    ) public onlyOwner {
        _auctionActive = true;
        _presaleActive = presale;

        _startedAt = block.timestamp;
        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _endPrice = newEndPrice;
        _startPrice = newStartPrice;
        _duration = newDuration;
    }

    function stopSale() public onlyOwner {
        _saleActive = false;
        _auctionActive = false;
        _presaleActive = false;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;

        emit TokenBaseURISet(newBaseURI);
    }

    function maxAmount() external view returns (uint256) {
        return _maxAmount;
    }

    function maxPerMint() external view returns (uint256) {
        return _maxPerMint;
    }

    function maxPerWallet() external view returns (uint256) {
        return _maxPerWallet;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function presaleActive() external view returns (bool) {
        return _presaleActive;
    }

    function saleActive() external view returns (bool) {
        return _saleActive;
    }

    function auctionActive() external view returns (bool) {
        return _auctionActive;
    }

    function auctionStartedAt() external view returns (uint256) {
        return _startedAt;
    }

    function auctionDuration() external view returns (uint256) {
        return _duration;
    }

    function auctionPrice() public view returns (uint256) {
        if ((block.timestamp - _startedAt) >= _duration) {
            return _endPrice;
        } else {
            return
                ((_duration - (block.timestamp - _startedAt)) *
                    (_startPrice - _endPrice)) /
                _duration +
                _endPrice;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _purchaseMint(uint256 numberOfTokens, address sender) internal {
        uint256 mintPrice = _auctionActive
            ? auctionPrice().mul(numberOfTokens)
            : _price.mul(numberOfTokens);
        require(mintPrice <= msg.value, "Value incorrect");

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
            _mintCount[sender] = _mintCount[sender].add(numberOfTokens);
        }

        _niftyKit.addFees(msg.value);
        _mint(numberOfTokens, sender);
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(sender, mintIndex);
        }
    }
}