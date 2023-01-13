// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./erc721a/ERC721AQueryable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";

//    _____          __                                     .__    .__        
//   /     \   _____/  |______    _____   _________________ |  |__ |__| ____  
//  /  \ /  \_/ __ \   __\__  \  /     \ /  _ \_  __ \____ \|  |  \|  |/ ___\ 
// /    Y    \  ___/|  |  / __ \|  Y Y  (  <_> )  | \/  |_> >   Y  \  \  \___ 
// \____|__  /\___  >__| (____  /__|_|  /\____/|__|  |   __/|___|  /__|\___  >
//         \/     \/          \/      \/             |__|        \/        \/ 
contract MetamorphicGG is
    ERC721AQueryable,
    OperatorFilterer,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    using Address for address;
    using Strings for uint256;
    using MerkleProof for bytes32[];
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                                PUBLIC VARIABLES
    //////////////////////////////////////////////////////////////*/
    string public baseURI;
    string public contractURI;
    bytes32 public root =
        0xc1bb4feb2aa97d46340ab7d89da943b00f5e5dc071645e6e308f811e2c7a6f17;
    bytes32 public root2 =
        0xc1bb4feb2aa97d46340ab7d89da943b00f5e5dc071645e6e308f811e2c7a6f17;
    uint256 public albumSaleStartTime = 1705078101; //will be changed
    uint256 public songSaleStartTime = 1705078101; //will be changed
    uint256 public publicStartTime = 1705078101; //will be changed
    uint256 public destroyPublicStartTime = 1687035600; //Sat Jun 17 2023 21:00:00 GMT+0000
    uint256 public albumPrice = 7 ether;
    uint256 public songPrice = 1 ether;
    uint256 public depositPrice = 3 ether;
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public quorum = 3; //quorum required for settings the public experience destroyed
    uint256 public albumSongCounter = 1; //NFTs starts with 1 for albums
    uint256 public songCounter = 100; //NFTs starts with 100 for songs
    uint256 public destroyPublicVotes = 0; // votes for destroy public start with 0

    bool public destroyPublicIsRestricted = false; // shows if destory public was called
    mapping(address => bool) destroyPublicVoteTracker; // address - voted
    bool public operatorFilteringEnabled;

    address payable public splitsWallet =
        payable(0x41FC27bf77c3f4259C972D15fFeb49fD28C8a096);
    IERC721 public songContract =
        IERC721(0xC075514B004Cd6c46C181184c600117f8E3624c4);
    address public artistWallet = 0x207C5B884765C4fc1074F401A0b31f67aF13F5d9;
    address public backendSigner = 0xABCD747b0E10950506e18c4B898F5F2c658C5583; //the backend signer used to claim the album if you have the songs
    mapping(string => bool) private noncesUsed;

    mapping(address => uint256) public mintedPerWallet;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event DestroyPublic(uint256 when);
    event Deposit(address from, uint256 amountDeposited);

    error Unauthorized();
    modifier notContract() {
        if (_isContract(_msgSender())) revert Unauthorized();
        if (_msgSender() != tx.origin) revert Unauthorized();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                         START Metamorphic by DAILLY
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721A("Metamorphic by DAILLY", "MORPH") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // at 9% (default denominator is 10000).
        _setDefaultRoyalty(0xAADdfe8d736234DE2D25B4405E7EB72858aED2c6, 900);
    }

    //anyone can deposit, however the allowlist is merkle root based and the deposit wallets will be added manually to it
    function deposit(uint256 qty) external payable {
        require(depositPrice * qty == msg.value, "exact amount needed");
        require(qty <= 2, "over max qty");
        emit Deposit(_msgSender(), msg.value);
    }

    /**
	 @dev get an album (need to be in the allow list)
	  */
    /**
	 @dev only whitelisted can get one
	 @param proof - merkle proof
	  */
    function buyAlbum(uint256 tokenID, bytes32[] calldata proof)
        external
        payable
        nonReentrant
        notContract
    {
        require(block.timestamp >= albumSaleStartTime, "not live");
        require(albumPrice == msg.value, "exact amount needed");
        require(totalSupply() + 1 <= MAX_SUPPLY, "out of stock");
        require(isProofValid(_msgSender(), tokenID, proof), "invalid proof");
        require(mintedPerWallet[_msgSender()] < tokenID, "over max limit");

        for (uint256 i = 0; i < 10; i++) {
            songContract.safeTransferFrom(
                artistWallet,
                _msgSender(),
                albumSongCounter
            );
            albumSongCounter += 1;
        }

        mintedPerWallet[_msgSender()] += 1;
        _mint(msg.sender, 1); //mints one album NFT
    }

    /**
	@dev public minting of an album
	  */
    function publicMintAlbum() external payable {
        require(block.timestamp >= publicStartTime, "not live");
        require(albumPrice == msg.value, "exact amount needed");
        require(totalSupply() + 1 <= MAX_SUPPLY, "out of stock");
        for (uint256 i = 0; i < 10; i++) {
            songContract.safeTransferFrom(
                artistWallet,
                _msgSender(),
                albumSongCounter
            );
            albumSongCounter += 1;
        }
        _mint(msg.sender, 1); //mints one album NFT
    }

    /**
	 @dev buying a song (allowlist)
     @param qty - quantity
     @param tokenID - merkle id
	 @param proof - merkle proof
	  */
    function buySong(
        uint256 qty,
        uint256 tokenID,
        bytes32[] calldata proof
    ) external payable nonReentrant notContract {
        require(block.timestamp >= songSaleStartTime, "not live");
        require(songPrice * qty == msg.value, "exact amount needed");
        require(isProofValid2(_msgSender(), tokenID, proof), "invalid proof");
        require(qty <= 10, "qty should be less then 10");

        for (uint256 i = 0; i < qty; i++) {
            songContract.safeTransferFrom(
                artistWallet,
                _msgSender(),
                songCounter
            );
            songCounter -= 1;
        }
    }

    /**
	@dev public mint
	  */
    function publicMintSong(uint256 qty) external payable {
        require(block.timestamp >= publicStartTime, "not live");
        require(songPrice * qty == msg.value, "exact amount needed");
        require(qty <= 10, "qty should be less then 10");

        for (uint256 i = 0; i < qty; i++) {
            songContract.safeTransferFrom(
                artistWallet,
                _msgSender(),
                songCounter
            );
            songCounter -= 1;
        }
    }

    //admin mint reserved
    function adminMintSong(address to) external onlyOwner {
        songContract.safeTransferFrom(artistWallet, to, songCounter);
        songCounter -= 1;
    }

    /**
	 @dev adds one YES vote to destroy public. 	 
     @param ownedTokenID - your token ID 
	  */
    function destroyPublic(uint256 ownedTokenID)
        external
        nonReentrant
        notContract
    {
        require(block.timestamp >= destroyPublicStartTime, "not live");
        require(ownerOf(ownedTokenID) == _msgSender(), "not the owner");

        require(!destroyPublicIsRestricted, "already restricted");

        require(!destroyPublicVoteTracker[_msgSender()], "already voted");

        destroyPublicVoteTracker[_msgSender()] = true;
        destroyPublicVotes = destroyPublicVotes + 1;

        if (destroyPublicVotes >= quorum) {
            destroyPublicIsRestricted = true;
            emit DestroyPublic(block.timestamp);
        }
    }

    //transfering a token decreases the votes of destroy experience
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (destroyPublicVotes > 0) {
            if (destroyPublicVoteTracker[from]) {
                destroyPublicVotes = destroyPublicVotes - 1;
                destroyPublicVoteTracker[from] = false; //transfered address can vote again
            }
        }

        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
	 @dev can claim one album if you have 10 songs
	 @param nonce - unique nonce (eg: hash of the songs ids)
     @param _signature - the signature
	  */
    function claimAlbum(string calldata nonce, bytes memory _signature)
        external
        nonReentrant
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "out of stock");
        require(!noncesUsed[nonce], "nonce used");
        require(
            keccak256(abi.encode(nonce, _msgSender()))
                .toEthSignedMessageHash()
                .recover(_signature) == backendSigner,
            "invalid signature"
        );

        noncesUsed[nonce] = true;
        _mint(_msgSender(), 1); //mints one album NFT
    }

    /**
	@dev tokenURI from ERC721 standard
	*/
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function setImportantURIs(
        string memory newBaseURI,
        string memory newContractURI
    ) external onlyOwner {
        baseURI = newBaseURI;
        contractURI = newContractURI;
    }

    //recover lost erc20. chance of getting them back: very low!
    function reclaimERC20Token(address erc20Token) external onlyOwner {
        IERC20(erc20Token).transfer(
            _msgSender(),
            IERC20(erc20Token).balanceOf(address(this))
        );
    }

    //recover lost nfts. chance of getting them back: very low!
    function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
        IERC721(erc721Token).safeTransferFrom(address(this), _msgSender(), id);
    }

    //change the start time of the sale
    function setStartTimes(
        uint256 newAlbumTime,
        uint256 newSongTime,
        uint256 newPublicSale,
        uint256 newDestroyPublicTime
    ) external onlyOwner {
        albumSaleStartTime = newAlbumTime;
        songSaleStartTime = newSongTime;
        publicStartTime = newPublicSale;
        destroyPublicStartTime = newDestroyPublicTime;
    }

    //sets the whitelist merkle root
    function setMerkleRoot(bytes32 _root, bytes32 _root2) external onlyOwner {
        root = _root;
        root2 = _root2;
    }

    //sets the artist wallet containing the NFTs
    function setArtistWallet(address newWallet) external onlyOwner {
        artistWallet = newWallet;
    }

    //sets the Song NFT Contract
    function setSongContract(address newContract) external onlyOwner {
        songContract = IERC721(newContract);
    }

    //sets the royalty fee and recipient for the collection.
    function setRoyalty(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    //sets the quorum for the destroy public experience
    function setQuorum(uint256 newQuorum) external onlyOwner {
        quorum = newQuorum;
    }

    //owner reserves the right to change the price
    function setPricePerToken(
        uint256 newAlbumPrice,
        uint256 newSongPrice,
        uint256 newDepositPrice
    ) external onlyOwner {
        albumPrice = newAlbumPrice;
        songPrice = newSongPrice;
        depositPrice = newDepositPrice;
    }

    //setSplitsWallet owner can change the 0xsplits wallet
    function setSplitsWallet(address newAddress) external onlyOwner {
        splitsWallet = payable(newAddress);
    }

    //setBackendSigner owner can change the backend signer wallet
    function setBackendSigner(address newAddress) external onlyOwner {
        backendSigner = newAddress;
    }

    //withdraw to 0xsplits
    function withdrawToSplits() external onlyOwner {
        (
            bool sent, /*memory data*/

        ) = splitsWallet.call{value: address(this).balance}("");
        require(sent, "failed to send eth");
    }

    /*///////////////////////////////////////////////////////////////
                             OTHER THINGS
    //////////////////////////////////////////////////////////////*/
    function _isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    //merkle root check
    function isProofValid(
        address to,
        uint256 limit,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to, limit));
        return proof.verify(root, leaf);
    }

    //merkle root check
    function isProofValid2(
        address to,
        uint256 limit,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(to, limit));
        return proof.verify(root2, leaf);
    }

    //overwrites for open sea
    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}