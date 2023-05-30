// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
 *              _____            ___ _____        _____  __   _____  ___    __
 *   /\/\ /\_/\/__   \/\  /\    /   \\_   \/\   /\\_   \/ _\  \_   \/___\/\ \ \
 *  /    \\_ _/  / /\/ /_/ /   / /\ / / /\/\ \ / / / /\/\ \    / /\//  //  \/ /
 * / /\/\ \/ \  / / / __  /   / /_//\/ /_   \ V /\/ /_  _\ \/\/ /_/ \_// /\  /
 * \/    \/\_/  \/  \/ /_/   /___,'\____/    \_/\____/  \__/\____/\___/\_\ \/
 *
 *     _                        _                      _
 *    / \   _ __ ___   ___ _ __(_) ___ __ _ _ __      / \   _ __   ___
 *   / _ \ | '_ ` _ \ / _ \ '__| |/ __/ _` | '_ \    / _ \ | '_ \ / _ \
 *  / ___ \| | | | | |  __/ |  | | (_| (_| | | | |  / ___ \| |_) |  __/
 * /_/   \_\_| |_| |_|\___|_|  |_|\___\__,_|_| |_| /_/   \_\ .__/ \___|
 *
 *
 *  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
 *  | * * * * * * * * *  :::::::::::::::::::::::::|
 *  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
 *  | * * * * * * * * *  :::::::::::::::::::::::::|
 *  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
 *  | * * * * * * * * *  ::::::::::::::::::::;::::|
 *  |* * * * * * * * * * OOOOOOOOOOOOOOOOOOOOOOOOO|
 *  |:::::::::::::::::::::::::::::::::::::::::::::|
 *  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
 *  |:::::::::::::::::::::::::::::::::::::::::::::|
 *  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
 *  |:::::::::::::::::::::::::::::::::::::::::::::|
 *  |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
 */

/**
 * @title Myth Division American Ape Comics ERC-721 Smart Contract
 */

contract AmericanApeComics is
    ERC721A,
    ERC721AQueryable,
    ERC2981,
    EIP712,
    Ownable,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    bytes32 constant TICKET_TYPE_HASH =
        keccak256("Ticket(address minter,uint256 comicId,uint256 qty)");

    string private baseURI;
    uint256 public comicMintId = 0;

    bool public mintIsActive = false;
    bool public mintIsActivePresale = false;
    bool public mintIsActiveBurn = false;

    mapping(uint256 => Comic) public comics;

    struct Comic {
        uint256 tokenPricePublic;
        uint256 tokenPricePresale;
        uint256 maxPerTxnPublic;
        uint256 endTokenId;
        uint256 startBurnableTokenId;
        uint256 endBurnableTokenId;
        bytes32 merkleRoot;
        address ticketSigner;
        bytes32 freeClaimMerkleRoot;
        mapping(address => uint256) claimed;
        mapping(address => uint256) freeClaimed;
    }

    constructor()
        ERC721A("American Ape Comic Series", "APESER")
        EIP712("AmericanApeComics", "1.0")
    {}

    /*
     *  @dev Calculate remaining mints for a comic via comic._endTokenId - totalMinted()
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // SALE SETUP

    /*
     * @notice create a new comic
     */
    function addComic(
        uint256 _tokenPricePublic,
        uint256 _tokenPricePresale,
        uint256 _maxPerTxnPublic,
        uint256 _endTokenId,
        uint256 _startBurnableTokenId,
        uint256 _endBurnableTokenId,
        bytes32 _merkleRoot,
        address _ticketSigner,
        bytes32 _freeClaimMerkleRoot
    ) external onlyOwner {
        require(_endTokenId > 0, "end token greater than zero");
        Comic storage p = comics[counter.current()];
        p.tokenPricePublic = _tokenPricePublic;
        p.tokenPricePresale = _tokenPricePresale;
        p.maxPerTxnPublic = _maxPerTxnPublic;
        p.endTokenId = _endTokenId;
        p.startBurnableTokenId = _startBurnableTokenId;
        p.endBurnableTokenId = _endBurnableTokenId;
        p.merkleRoot = _merkleRoot;
        p.ticketSigner = _ticketSigner;
        p.freeClaimMerkleRoot = _freeClaimMerkleRoot;
        counter.increment();
    }

    /*
     * @notice edit an existing comic
     */
    function editComic(
        uint256 _comicId,
        uint256 _tokenPricePublic,
        uint256 _tokenPricePresale,
        uint256 _maxPerTxnPublic,
        uint256 _endTokenId,
        uint256 _startBurnableTokenId,
        uint256 _endBurnableTokenId,
        bytes32 _merkleRoot,
        address _ticketSigner,
        bytes32 _freeClaimMerkleRoot
    ) external onlyOwner {
        require(comicExists(_comicId), "");

        comics[_comicId].tokenPricePublic = _tokenPricePublic;
        comics[_comicId].tokenPricePresale = _tokenPricePresale;
        comics[_comicId].maxPerTxnPublic = _maxPerTxnPublic;
        comics[_comicId].endTokenId = _endTokenId;
        comics[_comicId].startBurnableTokenId = _startBurnableTokenId;
        comics[_comicId].endBurnableTokenId = _endBurnableTokenId;
        comics[_comicId].merkleRoot = _merkleRoot;
        comics[_comicId].ticketSigner = _ticketSigner;
        comics[_comicId].freeClaimMerkleRoot = _freeClaimMerkleRoot;
    }

    /*
     * @notice edit an existing comics merkle root
     */
    function setComicMerkleRoot(uint256 _comicId, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        require(comicExists(_comicId), "");

        comics[_comicId].merkleRoot = _merkleRoot;
    }

    /*
     * @notice edit an existing comics ticket signer
     */
    function setComicTicketSigner(uint256 _comicId, address _ticketSigner)
        external
        onlyOwner
    {
        require(comicExists(_comicId), "");

        comics[_comicId].ticketSigner = _ticketSigner;
    }

    /*
     * @notice edit an existing comic with a merkle root for free claims
     */
    function setComicFreeClaimMerkleRoot(uint256 _comicId, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        require(comicExists(_comicId), "");

        comics[_comicId].freeClaimMerkleRoot = _merkleRoot;
    }

    /*
     *  @notice Set the comic id to mint
     */
    function setComicMintId(uint256 _id) external onlyOwner {
        require(_id >= 0, "Must be greater or equal than zero");
        comicMintId = _id;
    }

    //  PUBLIC MINT

    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /*
     *  @notice public mint function
     */
    function mintComic(uint256 _qty) external payable nonReentrant {
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");

        Comic storage comic = comics[comicMintId];

        // common sale checks
        require(
            _qty <= comic.maxPerTxnPublic,
            "You went over max tokens per transaction"
        );
        require(
            _nextTokenId() + _qty <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );
        require(
            comic.tokenPricePublic * _qty == msg.value,
            "You sent the incorrect amount of ETH"
        );

        _safeMint(msg.sender, _qty);
    }

    // TEAM/OWNER MINT

    /*
     *  @notice reserve mint n numbers of tokens
     */
    function mintReserveTokens(uint256 _qty) public onlyOwner {
        require(
            _nextTokenId() + _qty <= comics[comicMintId].endTokenId + 1,
            "Not enough tokens left to mint that many"
        );
        _safeMint(msg.sender, _qty);
    }

    /*
     *  @notice mint a token id to a wallet
     */
    function mintTokenToWallet(address _toWallet, uint256 _qty)
        public
        onlyOwner
    {
        require(
            _nextTokenId() + _qty <= comics[comicMintId].endTokenId + 1,
            "Not enough tokens left to mint that many"
        );
        _safeMint(_toWallet, _qty);
    }

    //  PRESALE MINT

    /*
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /*
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata _merkleProof, uint256 _qty)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _qty));
        return
            MerkleProof.verify(
                _merkleProof,
                comics[comicMintId].merkleRoot,
                leaf
            );
    }

    /*
     * @notice reset a list of addresses to be able to presale mint again.
     */
    function initPresaleMerkleWalletList(
        address[] memory _walletList,
        uint256 _qty
    ) external onlyOwner {
        for (uint i; i < _walletList.length; i++) {
            comics[comicMintId].claimed[_walletList[i]] = _qty;
        }
    }

    /*
     * @notice Check how many tokens a wallet claimed for the current presale
     */
    function claimedPresaleAmount(address _wallet)
        public
        view
        returns (uint256)
    {
        return comics[comicMintId].claimed[_wallet];
    }

    /*
     * @notice Check how many tokens a wallet claimed for a presale
     */
    function claimedPresaleAmountForComic(address _wallet, uint256 _comicId)
        external
        view
        returns (uint256)
    {
        require(comicExists(_comicId), "Comic does not exist");
        return comics[_comicId].claimed[_wallet];
    }

    /*
     * @notice Presale wallet list mint via merkle proof
     */
    function mintPresaleMerkle(
        uint256 _qty,
        uint256 _maxQty,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(tx.origin == msg.sender);

        Comic storage comic = comics[comicMintId];
        require(
            mintIsActivePresale && comic.merkleRoot != 0,
            "Presale mint via allowlist is not active"
        );
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _maxQty));
        require(
            MerkleProof.verify(_merkleProof, comic.merkleRoot, node),
            "Invalid Merkle Proof"
        );

        // common sale checks
        require(
            comic.tokenPricePresale * _qty == msg.value,
            "You sent the incorrect amount of ETH"
        );
        require(
            comic.claimed[msg.sender] + _qty <= _maxQty,
            "Claim: Not allowed to claim given amount"
        );
        require(
            _nextTokenId() + _qty <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );

        comic.claimed[msg.sender] += _qty;

        _safeMint(msg.sender, _qty);
    }

    /*
     * @notice Presale wallet list mint via signature ("ticket")
     */
    function mintPresaleTicket(
        uint256 _qty,
        uint256 _maxQty,
        bytes calldata _ticket
    ) external payable nonReentrant {
        require(tx.origin == msg.sender);

        Comic storage comic = comics[comicMintId];
        require(
            mintIsActivePresale && comic.ticketSigner != address(0),
            "Presale mint via ticket is not active"
        );
        bytes32 claimDigest = _hashTypedDataV4(
            keccak256(
                abi.encode(TICKET_TYPE_HASH, msg.sender, comicMintId, _maxQty)
            )
        );
        address recoveredSigner = ECDSA.recover(claimDigest, _ticket);
        require(recoveredSigner == comic.ticketSigner, "Invalid Ticket");

        // common sale checks
        require(
            comic.tokenPricePresale * _qty == msg.value,
            "You sent the incorrect amount of ETH"
        );
        require(
            comic.claimed[msg.sender] + _qty <= _maxQty,
            "Claim: Not allowed to claim given amount"
        );
        require(
            _nextTokenId() + _qty <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );

        comic.claimed[msg.sender] += _qty;

        _safeMint(msg.sender, _qty);
    }

    // FREE CLAIMS DURING PRESALE

    /*
     * @notice view function to check if a merkleProof is valid before sending free mint function
     */
    function isOnFreeClaimMerkle(bytes32[] calldata _merkleProof, uint256 _qty)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _qty));
        return
            MerkleProof.verify(
                _merkleProof,
                comics[comicMintId].freeClaimMerkleRoot,
                leaf
            );
    }

    /*
     * @notice reset a list of addresses to be able to free mint again.
     */
    function initFreeClaimMerkleWalletList(
        address[] memory _walletList,
        uint256 _qty
    ) external onlyOwner {
        for (uint i; i < _walletList.length; i++) {
            comics[comicMintId].freeClaimed[_walletList[i]] = _qty;
        }
    }

    /*
     * @notice Check how many free tokens a wallet claimed for the current presale
     */
    function claimedFreeAmount(address _wallet) public view returns (uint256) {
        return comics[comicMintId].freeClaimed[_wallet];
    }

    /*
     * @notice Check how many free tokens a wallet claimed for a presale
     */
    function claimedFreeAmountForComic(address _wallet, uint256 _comicId)
        external
        view
        returns (uint256)
    {
        require(comicExists(_comicId), "Comic does not exist");
        return comics[_comicId].freeClaimed[_wallet];
    }

    /*
     * @notice Presale free claim wallet list mint via merkle proof
     */
    function mintFreeClaimMerkle(
        uint256 _qty,
        uint256 _maxQty,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(tx.origin == msg.sender);

        Comic storage comic = comics[comicMintId];
        require(
            mintIsActivePresale && comic.freeClaimMerkleRoot != 0,
            "Presale mint via free claim is not active"
        );
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _maxQty));
        require(
            MerkleProof.verify(_merkleProof, comic.freeClaimMerkleRoot, node),
            "Invalid Merkle Proof"
        );

        // common sale checks
        require(
            comic.freeClaimed[msg.sender] + _qty <= _maxQty,
            "Claim: Not allowed to claim given amount"
        );
        require(
            _nextTokenId() + _qty <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );

        comic.freeClaimed[msg.sender] += _qty;

        _safeMint(msg.sender, _qty);
    }

    // BURN MINT

    function flipBurnToMintState() external onlyOwner {
        mintIsActiveBurn = !mintIsActiveBurn;
    }

    /*
     *  @notice  burn tokens to mint
     */
    function burnMint(uint256 _burnTokenId) external nonReentrant {
        require(tx.origin == msg.sender);
        require(mintIsActiveBurn, "Mint via burn is not active");

        Comic storage comic = comics[comicMintId];

        require(
            _nextTokenId() + 1 <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );

        require(
            msg.sender == ownerOf(_burnTokenId),
            "You do not own the token"
        );
        require(
            _burnTokenId >= comic.startBurnableTokenId &&
                _burnTokenId <= comic.endBurnableTokenId,
            "Invalid burnable token id"
        );
        _burn(_burnTokenId);

        _safeMint(msg.sender, 1);
    }

    /*
     *  @notice  burn multiple tokens to mint
     */
    function burnMintBatch(uint256[] calldata _burnTokenIds)
        external
        nonReentrant
    {
        require(tx.origin == msg.sender);
        require(mintIsActiveBurn, "Mint via burn is not active");

        Comic storage comic = comics[comicMintId];

        require(
            _nextTokenId() + _burnTokenIds.length <= comic.endTokenId + 1,
            "Not enough tokens left to mint that many"
        );

        uint256 amount = _burnTokenIds.length;
        uint256 startBurnId = comic.startBurnableTokenId;
        uint256 endBurnId = comic.endBurnableTokenId;

        for (uint256 i = 0; i < amount; i++) {
            uint256 _burnTokenId = _burnTokenIds[i];
            require(
                msg.sender == ownerOf(_burnTokenId),
                "You do not own the token"
            );
            require(
                _burnTokenId >= startBurnId && _burnTokenId <= endBurnId,
                "Invalid burnable token id"
            );
            _burn(_burnTokenId);
        }

        _safeMint(msg.sender, amount);
    }

    // PERSONAL BURN

    /*
     *  @notice  burn token id
     */
    function burn(uint256 _tokenId) public virtual {
        require(msg.sender == ownerOf(_tokenId), "You do not own the token");
        _burn(_tokenId);
    }

    /*
     *  @notice  burn batch token ids
     */
    function burnBatch(uint256[] memory _tokenIds) external nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(_tokenIds[i]),
                "You do not own the token"
            );
            _burn(_tokenIds[i]);
        }
    }

    // ADMINISTRATIVE FUNCTIONS

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * Sets default token royalties.
     *
     * @param recipient The recipient of the royalties
     * @param value The royalties amount expressed as basis points (100 = 1%)
     */
    function setDefaultRoyalty(address recipient, uint96 value)
        external
        onlyOwner
    {
        require(
            value <= 1_000,
            "Cannot set royalties higher than 1000 bps / 10%"
        );
        _setDefaultRoyalty(recipient, value);
    }

    /*
     *  @notice base URI to construct `tokenURI` in ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     *  @notice set base URI of tokens
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /*
     * @notice indicates weither any comic exists with a given id, or not
     */
    function comicExists(uint256 _tokenId) public view returns (bool) {
        return comics[_tokenId].endTokenId > 0;
    }

    /*
     * @notice Check how many tokens a wallet claimed amongst all presales
     */
    function claimedAmounts(address _wallet)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](counter.current());

        for (uint256 i; i < counter.current(); i++) {
            result[i] = comics[i].claimed[_wallet];
        }

        return result;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}