// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@chiru-labs/erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/contracts/utils/Address.sol";
import "@openzeppelin/contracts/contracts/utils/math/SafeCast.sol";
import "@opensea/operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IDoradoLogic.sol";
import "./interfaces/IDorado.sol";

string constant UNRECOGNIZABLE_HASH_ERROR = "Unrecognizable Hash";
string constant WALLET_LIMIT_EXCEEDED = "Wallet Limit Exceeded";
string constant WALLET_STAGE_LIMIT_EXCEEDED = "Wallet Stage Limit Exceeded";
string constant STAGE_EXCEEDED = "Stage exceeded";
string constant STAGE_LIMIT_EXCEEDED = "Stage Limit Exceeded";
string constant STAGE_OUT_TOTAL = "Stage Quantity Exceeded";
string constant CANNOT_USE_ZERO = "Cannot use 0 address";
string constant OWNER_ERROR = "Ownable: caller is not the owner";
string constant ETH_NOT_ENOUGH = "Sent ETH not enough";
string constant TOKEN_QUANTITY_EXCEEDED = "Token's quantity exceeded";

// DefaultOperatorFiltererUpgradeable check https://etherscan.io/address/0x000000000000AAeB6D7670E522A718067333cd4E#code
contract Dorado721A is ERC721A, ERC165, ERC2981, DefaultOperatorFiltererUpgradeable, IDoradoLogic {
    uint256 private constant _MINT_BITS_TOTAL = 200;
    uint256 private constant _MINT_BITS_LENGTH = 20;
    uint256 private constant _MINT_BITS = 0xFFFFF; // stage max mint = 20 bits = 0xFFFFF = 1048575.

    // don't change name. It's used as xxx.owner()
    address public owner; // Owner is specified by DoradoKit.sol's call initialize.
    address private _pendingOwner; // use for owner step.

    modifier onlyOwner() {
        require(msg.sender == owner, OWNER_ERROR);
        _;
    }

    modifier onlyOwnerOrPlatform() {
        require((msg.sender == owner) || (msg.sender == viewWithdraw()), OWNER_ERROR);
        _;
    }

    string private _name; // override ERC721A's private name.
    string private _symbol; // override ERC721A's private symbol.

    string public baseURI; // real resource uri.
    string public revealURI; // reveal resource uri.
    string public contractURI; // (https://docs.opensea.io/docs/contract-level-metadata)

    uint256 public maxTokens;
    uint256 private _airdropCount;

    mapping(bytes32 => bool) private _usedHashes; // signature filter.
    mapping(address => uint256) private addressStageMint;

    address private _doradoKit; // Dorado Kit.
    address private _treasury; // Collection's treasury.

    bool public burnable;
    bool public lockURI;

    modifier onlyUser() {
        require(!Address.isContract(msg.sender), "Don't support contract");
        _;
    }

    modifier saleIsOpen(MintData memory ms, bytes calldata signature) {
        // hard check
        {
            require(ms.stage > 0 && ms.stage <= 10, STAGE_EXCEEDED);
            require(block.number <= ms.nonce + 20, "Time limit has passed");
            require(ms.quantity <= 20, TOKEN_QUANTITY_EXCEEDED);
            require(msg.value >= ms.price * ms.quantity, ETH_NOT_ENOUGH);

            bytes32 messageHash = hashTransaction(address(this), msg.sender, ms);
            address signerAddress = viewSigner();
            require(ECDSA.recover(messageHash, signature) == signerAddress, UNRECOGNIZABLE_HASH_ERROR);
            // reject reused signature.
            require(!_usedHashes[messageHash], "Reused Hash");
            _usedHashes[messageHash] = true;
        }
        _;
    }

    // =============================================================
    //                        EVENTS
    // =============================================================
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event TokenURIChanged(string oldURI, string newURI, uint8 typeid);
    event BalanceChanged(uint256 feeAmount, uint256 transferAmount);
    event Mint(address to, uint8 stage, uint256 startTokenId, uint256 quantity, uint256 price);
    event TreasuryChanged(address indexed newTreasuryAddress);

    constructor() payable ERC721A("", "") {
        _name = "Dorado721A";
        _symbol = "Dorado";
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint64 maxTokens_,
        bool burnable_,
        uint96 feeNumerator_,
        address treasury_,
        string[] calldata uris
    ) external initializer {
        address creator = tx.origin;
        _doradoKit = msg.sender;
        owner = creator;
        _name = name_;
        _symbol = symbol_;
        maxTokens = maxTokens_;
        burnable = burnable_;
        if (treasury_ != address(0)) {
            _treasury = treasury_;
        }
        baseURI = uris[0];
        revealURI = uris[1];
        contractURI = uris[2];

        _setDefaultRoyalty(creator, feeNumerator_);
        __DefaultOperatorFilterer_init();
        // start token id must be 0.
        // otherwise should init _currentIndex
        // _currentIndex = _startTokenId();
    }

    // =============================================================
    //                        Wallet
    // =============================================================
    receive() external payable {}

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), CANNOT_USE_ZERO);
        _treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    function viewSigner() public view returns (address returnSigner) {
        returnSigner = IDorado(_doradoKit).viewSigner();
    }

    function viewWithdraw() public view returns (address returnWithdraw) {
        returnWithdraw = IDorado(_doradoKit).viewWithdraw();
    }

    function getFeeRate() public view returns (uint96 feeRate) {
        feeRate = IDorado(_doradoKit).getFeeRateOf(address(this));
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uri = baseURI;
        // if baseURI is empty uri, use reveal uri.
        if (bytes(uri).length == 0) {
            return revealURI;
        }
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }

    // =============================================================
    //                        ERC2981
    // =============================================================
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // =============================================================
    //                        IERC165
    // =============================================================
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC165, ERC2981) returns (bool) {
        return (ERC721A).supportsInterface(interfaceId) || (ERC2981).supportsInterface(interfaceId);
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================
    function airdrop(address[] calldata address_, uint64 quantity) external onlyOwner {
        require(
            totalMinted() + address_.length * quantity <= maxTokens,
            "This exceeds the maximum number of NFTs on sale!"
        );

        uint256 beginTokenId = nextTokenId();
        for (uint256 i = 0; i < address_.length; ) {
            address to = address_[i];
            _safeMint(to, uint256(quantity));
            emit Mint(to, 0, beginTokenId, quantity, 0);
            unchecked {
                beginTokenId = beginTokenId + quantity;
                ++i;
            }
        }

        unchecked {
            _airdropCount += address_.length * quantity;
        }
    }

    function mint(MintData memory ms, bytes calldata signature) external payable saleIsOpen(ms, signature) onlyUser {
        uint256 beginTokenId = nextTokenId();
        uint256 alreadyMinted = beginTokenId - startTokenId();
        uint256 stageIdx = ms.stage - 1;

        uint256 availableCount = ms.quantity;
        {
            // if has airdrop , stageLimit must contains airdrop nums;
            // for example, airdrop 10 tokens, owner set stage limit 20
            // now, beginTokenId = 10 (0..9 has been minted), stageLimit = 30
            uint256 stageLimit = _airdropCount + ms.stageLimit;
            require(stageLimit > alreadyMinted, STAGE_LIMIT_EXCEEDED);
            require(stageLimit <= maxTokens, STAGE_OUT_TOTAL);

            uint256 mintValue = addressStageMint[msg.sender];
            uint256 alreadyMintedByWallet = (mintValue >> _MINT_BITS_TOTAL) & _MINT_BITS;
            if (ms.walletMaxLimit > 0) {
                // remaining count = (wallet's max count) - minted
                require(ms.walletMaxLimit > alreadyMintedByWallet, WALLET_LIMIT_EXCEEDED);
                if (alreadyMintedByWallet + availableCount > ms.walletMaxLimit) {
                    unchecked {
                        availableCount = ms.walletMaxLimit - alreadyMintedByWallet;
                    }
                }
            }

            uint256 minterStageAlreadyMinted = (mintValue >> (stageIdx * _MINT_BITS_LENGTH)) & _MINT_BITS;

            if (ms.walletStageLimit > 0) {
                require(ms.walletStageLimit > minterStageAlreadyMinted, WALLET_STAGE_LIMIT_EXCEEDED);
                if (minterStageAlreadyMinted + availableCount > ms.walletStageLimit) {
                    unchecked {
                        availableCount = ms.walletStageLimit - minterStageAlreadyMinted;
                    }
                }
            }

            if (alreadyMinted + availableCount > stageLimit) {
                unchecked {
                    availableCount = stageLimit - alreadyMinted;
                }
            }

            minterStageAlreadyMinted = minterStageAlreadyMinted + availableCount;
            alreadyMintedByWallet = alreadyMintedByWallet + availableCount;

            uint256 newValue = (alreadyMintedByWallet << _MINT_BITS_TOTAL) |
                (minterStageAlreadyMinted << (stageIdx * _MINT_BITS_LENGTH));
            uint256 mask = (_MINT_BITS << _MINT_BITS_TOTAL) | (_MINT_BITS << (stageIdx * _MINT_BITS_LENGTH));
            addressStageMint[msg.sender] = ((~mask) & mintValue) | newValue;
        }

        _mint(msg.sender, availableCount);

        unchecked {
            uint256 reimbursement = (ms.quantity - availableCount) * ms.price;
            if (0 < reimbursement && reimbursement < msg.value) {
                (bool sent, ) = msg.sender.call{value: reimbursement}("");
                require(sent, "Failed to send Ether");
            }
        }

        // Mint(address to, uint8 stage, uint256 startTokenId, uint256 quantity, uint256 price)
        emit Mint(msg.sender, ms.stage, beginTokenId, availableCount, ms.price);
    }

    function getStageMintedCount(address minter, uint8 stage) external view returns (uint256) {
        require(stage > 0 && stage <= 10, STAGE_EXCEEDED);
        return ((addressStageMint[minter] >> ((stage - 1) * _MINT_BITS_LENGTH)) & _MINT_BITS);
    }

    function burn(uint256 tokenId) external {
        require(burnable, "The collection doesn't permit burned.");
        require(msg.sender == ownerOf(tokenId), OWNER_ERROR);
        _burn(tokenId);
    }

    function hashTransaction(address address_, address sender, MintData memory ms) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        address_,
                        sender,
                        ms.walletMaxLimit,
                        ms.stage,
                        ms.stageLimit,
                        ms.walletStageLimit,
                        ms.quantity,
                        ms.price,
                        ms.nonce
                    )
                )
            )
        );
        return hash;
    }

    // =============================================================
    //                          OWNERSHIP
    // =============================================================
    function transferOwnership(address newOwner) external onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function acceptOwnership() external {
        address sender = msg.sender;
        require(pendingOwner() == sender, OWNER_ERROR);

        delete _pendingOwner;

        address oldOwner = owner;
        owner = sender;
        emit OwnershipTransferred(oldOwner, sender);
    }

    // =============================================================
    //                           WITHDRAW
    // =============================================================
    function withdraw() external payable onlyOwnerOrPlatform {
        address feeTreasury = viewWithdraw();
        require(feeTreasury != address(0), CANNOT_USE_ZERO);

        uint96 feeRate = getFeeRate();

        uint256 feeAmount = (address(this).balance * feeRate) / 10000;
        (bool success, ) = payable(feeTreasury).call{value: feeAmount}("");
        require(success, "withdraw may have reverted");

        uint256 transferAmount = address(this).balance;
        address treasury = _treasury == address(0) ? owner : _treasury;
        payable(treasury).transfer(transferAmount);

        emit BalanceChanged(feeAmount, transferAmount);
    }

    // =============================================================
    //                       VARIABLES EDIT
    // =============================================================
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        if (!lockURI) {
            emit TokenURIChanged(baseURI, baseURI_, 0);
            baseURI = baseURI_;
        }
    }

    function setRevealURI(string calldata revealURI_) external onlyOwner {
        if (!lockURI) {
            emit TokenURIChanged(revealURI, revealURI_, 1);
            revealURI = revealURI_;
        }
    }

    function setContractURI(string calldata contractURI_) external onlyOwner {
        if (!lockURI) {
            contractURI = contractURI_;
        }
    }

    // =============================================================
    //                           OTHERS
    // =============================================================
    function lockURIForever() external onlyOwner {
        lockURI = true;
    }

    // =============================================================
    //                     Proxy Public Methods.
    // =============================================================
    function numberMinted(address owner_) public view returns (uint256) {
        return _numberMinted(owner_);
    }

    function numberBurned(address owner_) public view returns (uint256) {
        return _numberBurned(owner_);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function startTokenId() public view returns (uint256) {
        return _startTokenId();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    // =============================================================
    //                     Override Methods For OpenSea Operator.
    // =============================================================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}