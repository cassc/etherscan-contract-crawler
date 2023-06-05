// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// ,--------.,------.,------.  ,------.,--.   ,--.
// '--.  .--'|  .---'|  .-.  \ |  .-.  \\  `.'  /
//    |  |   |  `--, |  |  \  :|  |  \  :'.    /
//    |  |   |  `---.|  '--'  /|  '--'  /  |  |
//    `--'   `------'`-------' `-------'   `--'
// ,-----. ,------.  ,---.  ,------.
// |  |) /_|  .---' /  O  \ |  .--. '
// |  .-.  \  `--, |  .-.  ||  '--'.'
// |  '--' /  `---.|  | |  ||  |\  \
// `------'`------'`--' `--'`--' '--'
//  ,---.   ,-----.   ,--. ,--.  ,---.  ,------.
// '   .-' '  .-.  '  |  | |  | /  O  \ |  .-.  \
// `.  `-. |  | |  |  |  | |  ||  .-.  ||  |  \  :
// .-'    |'  '-'  '-.'  '-'  '|  | |  ||  '--'  /
// `-----'  `-----'--' `-----' `--' `--'`-------'

// @nftchef

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721SeqEnumerable.sol";

import "./rewardToken.sol";
//----------------------------------------------------------------------------
// OpenSea proxy
//----------------------------------------------------------------------------
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// ERC20 $TOYS Token Interface

interface IRewardToken {
    function spend(address _from, uint256 _amount) external;

    function getTotalClaimable(address _address) external;

    function updateReward(
        address _from,
        address _to,
        uint256 _qty
    ) external;
}

//----------------------------------------------------------------------------
// Teddy Bear Squad
//----------------------------------------------------------------------------

contract Main is
    ERC721SeqEnumerable,
    ContextMixin,
    NativeMetaTransaction,
    Ownable,
    Pausable,
    ReentrancyGuard,
    VRFConsumerBase
{
    using Strings for uint256;
    using ECDSA for bytes32;

    uint128 public PUBLIC_SUPPLY = 9851;
    uint128 public MAX_SUPPLY = 10001;
    uint128 public PUBLIC_MINT_LIMIT = 7;
    uint128 public PRESALE_MINT_LIMIT = 4;
    uint128 public PUBLIC_PRICE = 0.12 ether;
    uint128 public PRESALE_PRICE = 0.08 ether;

    // Start 2022/01/24 14:00:00 UTC
    uint256 public presaleStartTime = 1643032800;
    uint256 public publicStartInterval = 1 days;

    // @dev enforce a per-address lifetime limit based on the mintBalances mapping
    bool public publicWalletLimit = true;
    bool public isRevealed = false;

    string public PROVENANCE_HASH; // keccak256

    mapping(address => uint256) public mintBalances;

    uint256 public tokenOffset;
    string internal baseTokenURI;
    address[] internal payees;
    address internal _SIGNER;

    IRewardToken public RewardToys;

    // opensea proxy
    address private immutable _proxyRegistryAddress;
    address private _treasury = 0x8fBc1fB5fd267aFefF5cc4e69b3ca6D41567dc01;
    // LINK
    uint256 internal LINK_FEE;
    bytes32 internal LINK_KEY_HASH;

    constructor(
        string memory _initialURI,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _linkToken,
        uint256 _linkFee,
        address proxyRegistryAddress
    )
        payable
        ERC721Sequencial("Teddy Bear Squad", "TBS")
        Pausable()
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        _pause();
        baseTokenURI = _initialURI;

        LINK_KEY_HASH = _keyHash;
        LINK_FEE = _linkFee;
        _proxyRegistryAddress = proxyRegistryAddress;
        _initializeEIP712("TeddyBearSquad");
    }

    function purchase(uint256 _quantity)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            block.timestamp >= presaleStartTime + publicStartInterval,
            "Presale only."
        );
        require(
            _quantity <= PUBLIC_MINT_LIMIT,
            "Quantity exceeds PUBLIC_MINT_LIMIT"
        );
        require(_quantity * PUBLIC_PRICE <= msg.value, "Not enough minerals");
        if (publicWalletLimit) {
            require(
                _quantity + mintBalances[msg.sender] <= PUBLIC_MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }

        _mint(_quantity);
    }

    function presalePurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable nonReentrant whenNotPaused {
        require(block.timestamp >= presaleStartTime, "Presale has not started");
        require(
            checkHash(_hash, _signature, _SIGNER),
            "Address is not on Presale List"
        );
        /// @dev Presale always enforces a per-wallet limit
        require(
            _quantity + mintBalances[msg.sender] <= PRESALE_MINT_LIMIT,
            "Quantity exceeds per-wallet limit"
        );
        require(_quantity * PRESALE_PRICE <= msg.value, "Not enough minerals");

        _mint(_quantity);
    }

    function _mint(uint256 _quantity) internal {
        require(
            _quantity + _owners.length <= PUBLIC_SUPPLY,
            "Purchase exceeds available supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender);
        }
        RewardToys.updateReward(address(0), msg.sender, _quantity);
        mintBalances[msg.sender] += _quantity;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function senderMessageHash() internal view returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), msg.sender))
            )
        );
        return message;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts
     *  to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function checkHash(
        bytes32 _hash,
        bytes memory signature,
        address _account
    ) internal view returns (bool) {
        bytes32 senderHash = senderMessageHash();
        if (senderHash != _hash) {
            return false;
        }
        return _hash.recover(signature) == _account;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        RewardToys.updateReward(_from, _to, 1);
        ERC721Sequencial.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        RewardToys.updateReward(_from, _to, 1);
        ERC721Sequencial.safeTransferFrom(_from, _to, _tokenId);
    }

    function currentPrice() external view returns (uint256) {
        return
            block.timestamp <= (presaleStartTime + publicStartInterval)
                ? PRESALE_PRICE
                : PUBLIC_PRICE;
    }

    // ｡☆✼★━━━━━━━━ ( ˘▽˘)っ♨  only owner ━━━━━━━━━━━━━★✼☆｡

    function setSigner(address _address) external onlyOwner {
        _SIGNER = _address;
    }

    function setRewardTokenAddress(address _rAddress) external onlyOwner {
        RewardToys = IRewardToken(_rAddress);
    }

    /// @dev gift a single token to each address passed in through calldata
    /// @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + _owners.length <= MAX_SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i]);
            RewardToys.updateReward(address(0), _recipients[i], 1);
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setWalletLimit(bool _state) external onlyOwner {
        publicWalletLimit = _state;
    }

    function setTokenOffset() public onlyOwner {
        require(tokenOffset == 0, "Offset is already set");

        requestRandomness(LINK_KEY_HASH, LINK_FEE);
    }

    // @dev chainlink callback function for requestRandomness
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        tokenOffset = randomness % MAX_SUPPLY;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setReveal(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    // @dev: blockchain is forever, you never know, you might need these...
    function setPresalePrice(uint128 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    function setPublicPrice(uint128 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _limit;
    }

    function setPublicSuppy(uint128 _limit) external onlyOwner {
        PUBLIC_SUPPLY = _limit;
    }

    function setPresaleStartTime(uint256 _time) external onlyOwner {
        presaleStartTime = _time;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = _treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to vault.");
    }
}