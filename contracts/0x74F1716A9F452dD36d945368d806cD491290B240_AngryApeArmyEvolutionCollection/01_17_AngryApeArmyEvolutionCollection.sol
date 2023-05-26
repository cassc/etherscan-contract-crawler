// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721ABurnable.sol";
import "./Royalty.sol";
import "./IContractURI.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AngryApeArmyEvolutionCollection is ERC721ABurnable, Royalty {
    // Utils
    using ECDSA for bytes32;
    using Strings for uint256;

    // Sale state variables
    enum SaleStates {
        NOT_STARTED,
        FREE_MINT,
        FREE_MINT_PAUSED,
        PRE_SALE,
        PRE_SALE_PAUSED,
        SALE,
        SALE_PAUSED,
        ENDED
    }

    SaleStates private _saleState;

    // OG Ape holders
    IERC721 private _aaaContract;
    mapping(uint256 => uint256) private _aaaDataStore;

    // Whitelist
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistStore;

    // Constants
    uint256 public constant PRE_SALE_PRICE = 0.2 ether;
    uint256 public constant SALE_PRICE = 0.4 ether;
    uint32 public constant MAX_SUPPLY = 10000;
    uint32 public constant MAX_BATCH_MINT = 20;

    // Reserved
    uint32 public reserved = 400;

    // ERC721 Metadata
    string private _baseURI_ = "https://aaa-evolution-api-h5pd2zuvza-uc.a.run.app/";

    // ECDSA
    address private _signer;
    mapping(string => bool) private _isNonceUsed;

    // Events
    event SetBaseURI(string _baseURI_);
    event FreeMintBegins();
    event PreSaleBegins();
    event SaleBegins();
    event SaleEnds();

    address public aaaWithdrawal;
    address public netvrkWithdrawal;

    constructor(
        address signer_,
        address aaaContract_,
        address royaltyReceiver_
    )
        ERC721ABurnable(
            "Angry Ape Army Evolution Collection",
            "AAAEVO",
            MAX_BATCH_MINT
        )
        Royalty(royaltyReceiver_, 750) // 7.50%
    {
        _aaaContract = IERC721(aaaContract_);
        _signer = signer_;

        aaaWithdrawal = 0x6ab71C2025442B694C8585aCe2fc06D877469D30;
        netvrkWithdrawal = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
    }

    receive() external payable {}

    // Signature verfification
    modifier onlySignedTx(
        uint256 quantity_,
        string memory nonce_,
        bytes calldata signature_
    ) {
        require(!_isNonceUsed[nonce_], "Nonce already used");
        require(
            keccak256(abi.encodePacked(msg.sender, quantity_, nonce_))
                .toEthSignedMessageHash()
                .recover(signature_) == _signer,
            "Signature does not correspond"
        );

        _isNonceUsed[nonce_] = true;
        _;
    }

    function setSignerAddress(address signerAddress_) external onlyOwner {
        _signer = signerAddress_;
    }

    // Free Mint
    function freeMint(
        uint256[] calldata freeMintTokens_,
        uint256[] calldata preSaleTokens_,
        string memory nonce_,
        bytes calldata signature_
    )
        external
        payable
        onlySignedTx(
            freeMintTokens_.length + preSaleTokens_.length,
            nonce_,
            signature_
        )
    {
        uint256 quantity_ = freeMintTokens_.length + preSaleTokens_.length;
        require(_saleState == SaleStates.FREE_MINT, "Free mint not active");
        require(quantity_ > 0, "You must mint at least 1");
        require(
            quantity_ <= (MAX_SUPPLY - reserved - totalSupply()),
            "Not enough supply"
        );
        require(
            msg.value >= PRE_SALE_PRICE * preSaleTokens_.length,
            "Insufficient eth to process the order"
        );
        require(
            !usedTokenIds(freeMintTokens_, preSaleTokens_),
            "Token already used"
        );

        for (uint256 i; i < freeMintTokens_.length; i++) {
            require(
                msg.sender == _aaaContract.ownerOf(freeMintTokens_[i]),
                "Token not owned"
            );
        }

        for (uint256 i; i < preSaleTokens_.length; i++) {
            require(
                msg.sender == _aaaContract.ownerOf(preSaleTokens_[i]),
                "Token not owned"
            );
        }

        setUsedTokenIds(freeMintTokens_, preSaleTokens_);

        _safeMint(msg.sender, quantity_);
    }

    // Pre Sale Mint
    function preSaleMint(
        bytes32[] calldata merkleProof_,
        string memory nonce_,
        bytes calldata signature_
    ) external payable onlySignedTx(1, nonce_, signature_) {
        require(_saleState == SaleStates.PRE_SALE, "Pre sale not active");
        require(!whitelistStore[msg.sender], "Whitelist used");
        require(
            1 <= (MAX_SUPPLY - reserved - totalSupply()),
            "Not enough supply"
        );
        require(msg.value >= PRE_SALE_PRICE, "Insufficient eth to process the order");
        require(
            MerkleProof.verify(
                merkleProof_,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Proof failed"
        );

        whitelistStore[msg.sender] = true;

        _safeMint(msg.sender, 1);
    }

    // Sale Mint
    function mint(
        uint8 quantity_,
        string memory nonce_,
        bytes calldata signature_
    ) external payable onlySignedTx(quantity_, nonce_, signature_) {
        require(_saleState == SaleStates.SALE, "Sale not active");
        require(quantity_ > 0, "You must mint at least 1");
        require(
            quantity_ <= (MAX_SUPPLY - reserved - totalSupply()),
            "Not enough supply"
        );
        require(
            quantity_ <= MAX_BATCH_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );
        require(
            (balanceOf(msg.sender) + quantity_) <= MAX_BATCH_MINT,
            "Any one wallet cannot hold more than MAX_BATCH_MINT"
        );
        require(
            msg.value >= SALE_PRICE * quantity_,
            "Insufficient eth to process the order"
        );

        _safeMint(msg.sender, quantity_);
    }

    // Reserved
    function reservedMint(address to_, uint32 quantity_) public onlyOwner {
        require(quantity_ <= reserved, "Not enough reserved supply");
        require(quantity_ > 0, "You must mint at least 1");
        require(
            quantity_ <= MAX_BATCH_MINT,
            "Cannot mint more than MAX_BATCH_MINT per transaction"
        );

        reserved -= quantity_;

        _safeMint(to_, quantity_);
    }

    // Burn
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    // Sale State
    function saleState() public view returns (string memory) {
        if (_saleState == SaleStates.FREE_MINT) return "FREE_MINT";
        if (_saleState == SaleStates.FREE_MINT_PAUSED)
            return "FREE_MINT_PAUSED";
        if (_saleState == SaleStates.PRE_SALE) return "PRE_SALE";
        if (_saleState == SaleStates.PRE_SALE_PAUSED) return "PRE_SALE_PAUSED";
        if (_saleState == SaleStates.SALE) return "SALE";
        if (_saleState == SaleStates.SALE_PAUSED) return "SALE_PAUSED";
        if (_saleState == SaleStates.ENDED) return "ENDED";
        return "NOT_STARTED";
    }

    function startFreeMint() external onlyOwner {
        require(
            _saleState < SaleStates.FREE_MINT,
            "Free mint has already started"
        );
        _saleState = SaleStates.FREE_MINT;
        emit FreeMintBegins();
    }

    function startPreSale() external onlyOwner {
        require(_saleState >= SaleStates.FREE_MINT, "Free mint state required");
        require(
            _saleState < SaleStates.PRE_SALE,
            "Pre-sale has already started"
        );
        _saleState = SaleStates.PRE_SALE;
        emit PreSaleBegins();
    }

    function startSale() external onlyOwner {
        require(_saleState >= SaleStates.PRE_SALE, "Pre-sale state required");
        require(_saleState < SaleStates.SALE, "Sale has already started");
        _saleState = SaleStates.SALE;
        emit SaleBegins();
    }

    function endSale() external onlyOwner {
        require(_saleState >= SaleStates.SALE, "Sale state required");
        require(_saleState < SaleStates.ENDED, "Sale has ended");
        _saleState = SaleStates.ENDED;
        emit SaleEnds();
    }

    // Pauseable
    function pause() public onlyOwner {
        require(
            !(_saleState == SaleStates.NOT_STARTED ||
                _saleState == SaleStates.ENDED),
            "No active sale"
        );

        require(
            !(_saleState == SaleStates.FREE_MINT_PAUSED ||
                _saleState == SaleStates.PRE_SALE_PAUSED ||
                _saleState == SaleStates.SALE_PAUSED),
            "Sale is paused"
        );

        _saleState = SaleStates(uint8(_saleState) + 1);
    }

    function unpause() public onlyOwner {
        require(
            !(_saleState == SaleStates.NOT_STARTED ||
                _saleState == SaleStates.ENDED),
            "No active sale"
        );

        require(
            !(_saleState == SaleStates.FREE_MINT ||
                _saleState == SaleStates.PRE_SALE ||
                _saleState == SaleStates.SALE),
            "Sale is not paused"
        );

        _saleState = SaleStates(uint8(_saleState) - 1);
    }

    // Contract & token metadata
    function setBaseURI(string memory _uri) public onlyOwner {
        require(
            bytes(_uri)[bytes(_uri).length - 1] == bytes1("/"),
            "Must set trailing slash"
        );
        _baseURI_ = _uri;
        emit SetBaseURI(_uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    _baseURI_,
                    "token/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI_, "contract.json"));
    }

    // Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Withdrawal
    function setAaaWithdrawal(address withdrawalAddress_) public onlyOwner {
        require(
            withdrawalAddress_ != address(0),
            "Set a valid withdrawal address"
        );
        aaaWithdrawal = withdrawalAddress_;
    }

    function setNetvrkWithdrawal(address withdrawalAddress_) public onlyOwner {
        require(
            withdrawalAddress_ != address(0),
            "Set a valid withdrawal address"
        );
        netvrkWithdrawal = withdrawalAddress_;
    }

    function withdrawAll() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "Balance is zero");

        uint256 aaaAmount = (totalBalance * 7000) / 10000; // 70.00%
        uint256 netvrkAmount = totalBalance - aaaAmount; // 30.00%

        require(
            payable(aaaWithdrawal).send(aaaAmount),
            "Withdrawal Failed to AAA"
        );

        require(
            payable(netvrkWithdrawal).send(netvrkAmount),
            "Withdrawal Failed to netvrk"
        );
    }

    // Utilities
    function packBool(
        uint256 _packedBools,
        uint256 _boolIndex,
        bool _value
    ) public pure returns (uint256) {
        return
            _value
                ? _packedBools | (uint256(1) << _boolIndex)
                : _packedBools & ~(uint256(1) << _boolIndex);
    }

    function unPackBool(uint256 _packedBools, uint256 _boolIndex)
        internal
        pure
        returns (bool)
    {
        return (_packedBools >> _boolIndex) & uint256(1) == 1 ? true : false;
    }

    function setUsedTokenIds(
        uint256[] calldata freeMints,
        uint256[] calldata preSales
    ) public {
        uint256 cRow;
        uint256 cPackedBools = _aaaDataStore[0];

        for (uint256 i; i < freeMints.length; i++) {
            (uint256 boolRow, uint256 boolColumn) = freeMintPosition(
                freeMints[i]
            );

            if (boolRow != cRow) {
                _aaaDataStore[cRow] = cPackedBools;
                cRow = boolRow;
                cPackedBools = _aaaDataStore[boolRow];
            }

            cPackedBools = packBool(cPackedBools, boolColumn, true);

            if (i + 1 == freeMints.length) {
                _aaaDataStore[cRow] = cPackedBools;
            }
        }

        for (uint256 i; i < preSales.length; i++) {
            (uint256 boolRow, uint256 boolColumn) = preSalePosition(
                preSales[i]
            );

            if (boolRow != cRow) {
                _aaaDataStore[cRow] = cPackedBools;
                cRow = boolRow;
                cPackedBools = _aaaDataStore[boolRow];
            }

            cPackedBools = packBool(cPackedBools, boolColumn, true);

            if (i + 1 == preSales.length) {
                _aaaDataStore[cRow] = cPackedBools;
            }
        }
    }

    function usedTokenIds(
        uint256[] calldata freeMints,
        uint256[] calldata preSales
    ) private view returns (bool) {
        uint256 cRow;
        uint256 cPackedBools = _aaaDataStore[0];
        uint256 unpackedBools;

        for (uint256 i; i < freeMints.length; i++) {
            (uint256 boolRow, uint256 boolColumn) = freeMintPosition(
                freeMints[i]
            );

            if (boolRow != cRow) {
                if (unpackedBools > 0) return true;
                cRow = boolRow;
                cPackedBools = _aaaDataStore[boolRow];
                unpackedBools = 0;
            }

            unpackedBools =
                unpackedBools |
                (cPackedBools & (uint256(1) << boolColumn));

            if (i + 1 == freeMints.length) {
                if (unpackedBools > 0) return true;
            }
        }

        for (uint256 i; i < preSales.length; i++) {
            (uint256 boolRow, uint256 boolColumn) = preSalePosition(
                preSales[i]
            );

            if (boolRow != cRow) {
                if (unpackedBools > 0) return true;
                cRow = boolRow;
                cPackedBools = _aaaDataStore[boolRow];
                unpackedBools = 0;
            }

            unpackedBools =
                unpackedBools |
                (cPackedBools & (uint256(1) << boolColumn));

            if (i + 1 == preSales.length) {
                if (unpackedBools > 0) return true;
            }
        }

        return false;
    }

    function usedTokenId(uint256 tokenId)
        public
        view
        returns (bool freeMintUsed, bool preSaleUsed)
    {
        (uint256 boolRow, uint256 boolColumn) = freeMintPosition(tokenId);
        uint256 packedBools = _aaaDataStore[boolRow];
        freeMintUsed = (packedBools & (uint256(1) << boolColumn)) > 0
            ? true
            : false;
        preSaleUsed = (packedBools & (uint256(1) << (boolColumn + 1))) > 0
            ? true
            : false;
    }

    function freeMintPosition(uint256 tokenId)
        internal
        pure
        returns (uint256 boolRow, uint256 boolColumn)
    {
        boolRow = (tokenId << 1) / 256;
        boolColumn = (tokenId << 1) % 256;
    }

    function preSalePosition(uint256 tokenId)
        internal
        pure
        returns (uint256 boolRow, uint256 boolColumn)
    {
        (boolRow, boolColumn) = freeMintPosition(tokenId);
        boolColumn++;
    }

    // Compulsory overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ABurnable, Royalty)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IContractURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}