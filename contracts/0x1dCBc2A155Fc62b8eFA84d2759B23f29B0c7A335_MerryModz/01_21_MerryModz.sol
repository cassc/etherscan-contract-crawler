// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITFKFreeMintable.sol";
import "./Royalty.sol";

contract MerryModz is
    Ownable,
    ERC721Enumerable,
    ReentrancyGuard,
    ITFKFreeMintable,
    Royalty
{
    // Structs
    struct FKUsage {
        bool freeMint;
        bool presale;
    }

    // Utils
    using ECDSA for bytes32;
    using Strings for uint256;

    // ERC721 params
    string private baseURI = "https://api.merrymodz.io/";
    uint32 private tokenCount;

    // ECDSA
    address private signerAddress;
    mapping(string => bool) private isNonceUsed;

    // Token Timings
    mapping(uint256 => uint256) private _tokenMintedAt;
    mapping(uint256 => uint256) private _tokenLastTransferredAt;

    // Allowances
    mapping(uint256 => FKUsage) public fkUsage;

    // Withdrawal
    address public withdrawalAddress =
        0xdAD835097E934A3B7D0b8528Cc6a29D58BA1D308;

    // Magic Moment
    address public magicContractAddress;
    mapping(uint256 => uint256) private _magic;

    // Collection params
    uint32 public constant TOTAL_SUPPLY = 10000;
    uint32 public constant MINT_LIMIT = 15;

    // Price params
    uint256 public constant PRICE = 0.07 ether;

    // Provably randomness
    bytes32 public firstProvenanceHash; // The hash from the ordered list of NFTs
    uint256 public randomSeed; // Random seed used to shuffle the first ordered list of NFTs
    bytes32 public finalProvenanceHash; // The hash from the shuffled list of NFTs

    // Sale state variables
    bool public preSaleStarted = false;
    bool public isPresaleActive = false;
    bool public saleStarted = false;
    bool public isSaleActive = false;
    bool public saleHasEnded = false;

    // Event declaration
    event SetBaseURI(string baseURI);
    event SetProvenance(bytes32 provenance);
    event MagicContractAddress(address approved);
    event PresaleBegins();
    event SaleBegins();
    event SaleEnds();
    event Minted(uint256 indexed fromId, uint256 indexed toId);

    // Constructor
    constructor(
        address _signerAddresss,
        address _itfk,
        address _itfkPeer
    )
        ERC721("Merry Modz", "MM")
        ITFKFreeMintable(_itfk, _itfkPeer)
        Royalty(address(this), 500) // This contract receives 5.00% from 2nd market sales
    {
        signerAddress = _signerAddresss;
    }

    receive() external payable {}

    // Signature verfification
    modifier onlySignedTx(
        uint32 _amount,
        string memory _nonce,
        bytes memory _signature
    ) {
        require(!isNonceUsed[_nonce], "Nonce already used");
        require(
            keccak256(abi.encodePacked(msg.sender, _amount, _nonce))
                .toEthSignedMessageHash()
                .recover(_signature) == signerAddress,
            "Signature does not correspond"
        );

        // Save the used nonce
        isNonceUsed[_nonce] = true;
        _;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    // Private mint function
    function _mintPrivate(address _to, uint256 _amount) private {
        for (uint256 i; i < _amount; i++) {
            tokenCount++;
            _safeMint(_to, tokenCount);

            // Store the token minting timestamp
            _tokenMintedAt[tokenCount] = block.timestamp;
        }
    }

    // Public Mint
    function mint(
        uint8 _amount,
        string memory _nonce,
        bytes memory _signature
    ) external payable onlySignedTx(_amount, _nonce, _signature) nonReentrant {
        require(isSaleActive, "Sale not active");
        require(_amount <= (TOTAL_SUPPLY - tokenCount), "Not enough supply");
        require(_amount > 0, "You must mint at least 1");
        require(
            _amount <= MINT_LIMIT,
            "Cannot mint more than MINT_LIMIT per transaction"
        );
        require(
            (balanceOf(msg.sender) + _amount) <= MINT_LIMIT,
            "Any one wallet cannot hold more than MINT_LIMIT"
        );

        require(
            msg.value >= PRICE * _amount,
            "Insufficient eth to process the order"
        );

        if (msg.value > PRICE * _amount) {
            payable(msg.sender).transfer(msg.value - (PRICE * _amount)); // Refund if sent more than required
        }

        uint256 fromId = tokenCount + 1;
        uint256 toId = tokenCount + _amount;

        _mintPrivate(msg.sender, _amount);

        emit Minted(fromId, toId);
    }

    // Founder's Key Minting
    function _fkFreeMint(uint256[] memory _fkTokenIds) private {
        for (uint256 i; i < _fkTokenIds.length; i++) {
            require(
                !fkUsage[_fkTokenIds[i]].freeMint,
                "1 free mint on this collection per Founder's Key"
            );

            require(
                itfkPeer.getFreeMintsRemaining(_fkTokenIds[i]) > 0,
                "No free mints available"
            );

            fkUsage[_fkTokenIds[i]].presale = true;
            fkUsage[_fkTokenIds[i]].freeMint = true;
            itfkPeer.updateFreeMintAllocation(_fkTokenIds[i]);
        }

        uint256 fromId = tokenCount + 1;
        uint256 toId = tokenCount + _fkTokenIds.length;

        _mintPrivate(msg.sender, _fkTokenIds.length);

        emit Minted(fromId, toId);
    }

    function _fkPaidMint(uint256[] memory _fkPresaleTokenIds, uint32 _amount)
        private
    {
        require(
            msg.value >= PRICE * _amount,
            "Insufficient eth to process the order"
        );

        for (uint256 i; i < _fkPresaleTokenIds.length; i++) {
            fkUsage[_fkPresaleTokenIds[i]].presale = true;
        }

        uint256 fromId = tokenCount + 1;
        uint256 toId = tokenCount + _amount;

        _mintPrivate(msg.sender, _amount);

        emit Minted(fromId, toId);
    }

    function fkMint(
        uint256[] memory _fkPresaleTokenIds,
        uint256[] memory _fkFreeMintTokenIds,
        uint32 _amount,
        string memory _nonce,
        bytes memory _signature
    )
        external
        payable
        override
        onlySignedTx(_amount, _nonce, _signature)
        nonReentrant
    {
        require(isPresaleActive || isSaleActive, "No sale active");

        uint256[] memory eligibleFKs = itfkPeer.getFoundersKeysByTierIds(
            msg.sender,
            3 // 3 = 011 = Heroic & Legendary
        );
        require(
            arrayContains(eligibleFKs, _fkFreeMintTokenIds) &&
                arrayContains(eligibleFKs, _fkPresaleTokenIds),
            "Not owner of Heroic or Legendary Founder's Key"
        );

        if (isPresaleActive) {
            require(
                arrayContains(_fkPresaleTokenIds, _fkFreeMintTokenIds),
                "Free minting tokens must be presale tokens"
            );
            require(
                _amount == _fkPresaleTokenIds.length,
                "1 mint per Founder's Key during presale"
            );
            for (uint256 i; i < _fkPresaleTokenIds.length; i++) {
                require(
                    !fkUsage[_fkPresaleTokenIds[i]].presale,
                    "Founder's Key already used during presale"
                );
            }
        } else {
            require(_amount > 0, "You must mint at least 1");
        }

        require(_amount <= (TOTAL_SUPPLY - tokenCount), "Not enough supply");

        require(
            (balanceOf(msg.sender) + _amount) <= MINT_LIMIT ||
                (balanceOf(msg.sender) + _amount) <= eligibleFKs.length,
            "Any one wallet cannot hold more than MINT_LIMIT"
        );

        require(
            _amount >= _fkFreeMintTokenIds.length,
            "You must attempt to mint at least the amount of free mints being used"
        );

        uint32 purchaseAmount = uint32(_amount - _fkFreeMintTokenIds.length);

        if (msg.value > PRICE * purchaseAmount) {
            payable(msg.sender).transfer(msg.value - (PRICE * purchaseAmount)); // Refund if sent more than required
        }

        if (_fkFreeMintTokenIds.length > 0) {
            _fkFreeMint(_fkFreeMintTokenIds);
        }

        if (purchaseAmount > 0) {
            _fkPaidMint(_fkPresaleTokenIds, purchaseAmount);
        }
    }

    // Giveaway function
    function giveaway(address[] memory _toArray, uint32 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "Must mint at least 1");
        require(
            _toArray.length * _amount <= 100,
            "Limited to 100 giveaways per transaction"
        );
        require(
            _toArray.length * _amount <= (TOTAL_SUPPLY - tokenCount),
            "Exceeds token supply"
        );

        uint256 fromId = tokenCount + 1;
        uint256 toId = tokenCount + (_toArray.length * _amount);

        for (uint256 i; i < _toArray.length; i++) {
            _mintPrivate(_toArray[i], _amount);
        }

        emit Minted(fromId, toId);
    }

    // Provably Random
    // Set the first provenance hash and extract a seed to shuffle the list
    // Shuffle the list
    // Set the final provenance hash
    function setFirstProvenanceHash(bytes32 _provenanceHash)
        external
        onlyOwner
        returns (uint256)
    {
        // Once firstProvenanceHash is set it is impossible to change it or the randomSeed
        require(firstProvenanceHash == 0, "First Provenance hash already set");
        firstProvenanceHash = _provenanceHash;
        randomSeed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
        return randomSeed;
    }

    function setFinalProvenanceHash(bytes32 _provenanceHash)
        external
        onlyOwner
    {
        // Once finalProvenanceHash is set it is impossible to change it
        require(finalProvenanceHash == 0, "Final Provenance hash already set");
        finalProvenanceHash = _provenanceHash;
        emit SetProvenance(_provenanceHash);
    }

    // Setting presale state
    function startPresale() external onlyOwner {
        require(!saleHasEnded, "Sale has ended");
        require(!preSaleStarted, "Presale has already been started");
        preSaleStarted = true;
        isPresaleActive = true;
        emit PresaleBegins();
    }

    function pausePresale(bool _state) external onlyOwner {
        require(!saleHasEnded, "Sale has ended");
        require(preSaleStarted, "Presale must be started");
        require(
            !saleStarted,
            "Cannot change presale state when sale has started"
        );
        isPresaleActive = !_state;
    }

    // Setting sale state
    function startSale() external onlyOwner {
        require(!saleHasEnded, "Sale has ended");
        require(!saleStarted, "Sale has already been started");
        require(preSaleStarted, "Presale must be started before sale");
        saleStarted = true;
        isSaleActive = true;
        isPresaleActive = false;
        emit SaleBegins();
    }

    function pauseSale(bool _state) external onlyOwner {
        require(!saleHasEnded, "Sale has ended");
        require(preSaleStarted && saleStarted, "Sale must be started");
        isSaleActive = !_state;
    }

    function endSale() external onlyOwner {
        require(!saleHasEnded, "Sale has ended");
        isSaleActive = false;
        isPresaleActive = false;
        saleHasEnded = true;
        emit SaleEnds();
    }

    // Contract & token metadata
    function setBaseURI(string memory _uri) public onlyOwner {
        require(
            bytes(_uri)[bytes(_uri).length - 1] == bytes1("/"),
            "Must set trailing slash"
        );
        baseURI = _uri;
        emit SetBaseURI(_uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, "token/", tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    // Withdrawal
    function withdrawAll() external onlyOwner {
        require(
            withdrawalAddress != address(0),
            "Set a valid withdrawal address"
        );
        require(address(this).balance != 0, "Balance is zero");
        require(payable(withdrawalAddress).send(address(this).balance));
    }

    function setWithdrawalAddress(address _withdrawalAddress)
        external
        onlyOwner
    {
        require(
            _withdrawalAddress != address(0),
            "Set a valid withdrawal address"
        );
        withdrawalAddress = _withdrawalAddress;
    }

    // Approved to burn
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) ||
                msg.sender == magicContractAddress,
            "Caller is not owner nor approved"
        );

        _tokenMintedAt[tokenId] = 0;
        _tokenLastTransferredAt[tokenId] = 0;

        _burn(tokenId);
    }

    function setMagicContractAddress(address _approvedAddress)
        external
        onlyOwner
    {
        magicContractAddress = _approvedAddress;
        emit MagicContractAddress(_approvedAddress);
    }

    // Token Timings
    function tokenMintedAt(uint256 _tokenId)
        external
        view
        returns (uint256 timestamp)
    {
        require(_exists(_tokenId), "Minted time query for nonexistent token");
        return _tokenMintedAt[_tokenId];
    }

    function tokenLastTransferredAt(uint256 _tokenId)
        external
        view
        returns (uint256 timestamp)
    {
        require(_exists(_tokenId), "Transfer time query for nonexistent token");
        return _tokenLastTransferredAt[_tokenId];
    }

    // Magic Moment
    function setMagicId(uint256 _tokenId, uint256 _magicId) external {
        require(msg.sender == magicContractAddress, "Caller is not approved");
        require(_exists(_tokenId), "Magic operation for nonexistent token");
        _magic[_tokenId] = _magicId;
    }

    function getMagicId(uint256 _tokenId)
        external
        view
        returns (uint256 magicId)
    {
        require(_exists(_tokenId), "Magic query for nonexistent token");
        return _magic[_tokenId];
    }

    // Extra Operations
    function arrayContains(uint256[] memory array, uint256[] memory contains)
        private
        pure
        returns (bool)
    {
        if (array.length < contains.length) return false;

        uint32 containedCount;

        for (uint32 i; i < array.length; i++) {
            for (uint32 j; j < contains.length; j++) {
                if (array[i] == contains[j]) {
                    containedCount++;
                }
            }
        }

        if (containedCount != contains.length) return false;

        return true;
    }

    // Storing the last token transfer timestamp
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        _tokenLastTransferredAt[_tokenId] = block.timestamp;

        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    // Compulsory overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ITFKFreeMintable, Royalty)
        returns (bool)
    {
        return
            interfaceId == type(IITFKFreeMintable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}