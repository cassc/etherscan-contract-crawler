// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
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

contract AmericanApeComics is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    string private baseURI;
    uint256 public comicMintId = 0;

    bool public mintIsActive  = false;
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
        mapping(address => uint256) claimed;
    }

    constructor() ERC721A("American Ape Comic Series", "APESER") {}

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
        bytes32 _merkleRoot
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
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(comicExists(_comicId), "");

        comics[_comicId].tokenPricePublic = _tokenPricePublic;
        comics[_comicId].tokenPricePresale = _tokenPricePresale;
        comics[_comicId].maxPerTxnPublic = _maxPerTxnPublic;
        comics[_comicId].endTokenId = _endTokenId;
        comics[_comicId].startBurnableTokenId = _startBurnableTokenId;
        comics[_comicId].endBurnableTokenId = _endBurnableTokenId;
        comics[_comicId].merkleRoot = _merkleRoot;
    }


    //  PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /*
    *  @notice public mint function
    */
    function mintComic(uint256 _qty) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");
        require(_qty <= comics[comicMintId].maxPerTxnPublic, "You went over max tokens per transaction");
        require(totalSupply() + _qty <= comics[comicMintId].endTokenId + 1, "Not enough tokens left to mint that many");
        require(comics[comicMintId].tokenPricePublic * _qty <= msg.value, "You sent the incorrect amount of ETH");

        _safeMint(msg.sender, _qty);
    }


    // BURN TO MINT FUNCTION
 
    function flipBurnToMintState() external onlyOwner {
        mintIsActiveBurn = !mintIsActiveBurn;
    }

    /*
    *  @notice  burn token id to mint
    */
    function burnMint(uint256 _burnTokenId) external nonReentrant {
        require(tx.origin == msg.sender);
        require(mintIsActiveBurn, "Mint is not active");
        require(totalSupply() + 1 <= comics[comicMintId].endTokenId+1, "Not enough tokens left to mint that many");

        require(msg.sender == ownerOf(_burnTokenId), "You do not own the token");
        require(_burnTokenId >= comics[comicMintId].startBurnableTokenId && _burnTokenId <= comics[comicMintId].endBurnableTokenId, "Invalid burnable token id");
        _burn(_burnTokenId);

        _safeMint(msg.sender, 1);
    }

    //  PRESALE MERKLE MINT

    /*
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata _merkleProof, uint256 _qty) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _qty));
        return MerkleProof.verify(_merkleProof, comics[comicMintId].merkleRoot, leaf);
    }

    /*
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /*
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory _walletList, uint256 _qty) external onlyOwner {
	    for (uint i; i < _walletList.length; i++) {
		    comics[comicMintId].claimed[_walletList[i]] = _qty;
	    }
    }

    /*
     * @notice check if address minted
     */
    function checkAddressOnPresaleMerkleWalletList(address _wallet) public view returns (uint256) {
	    return comics[comicMintId].claimed[_wallet];
    }

    /*
     * @notice Presale wallet list mint 
     */
    function mintPresaleMerkle(uint256 _qty, uint256 _maxQty, bytes32[] calldata _merkleProof) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");
        require(
	        comics[comicMintId].tokenPricePublic * _qty <= msg.value,
            "You sent the incorrect amount of ETH"
        );
        require(
            comics[comicMintId].claimed[msg.sender] + _qty <= _maxQty, 
            "Claim: Not allowed to claim given amount"
        );
        require(
            totalSupply() + _qty <= comics[comicMintId].endTokenId+1, 
            "Not enough tokens left to mint that many"
        );

        bytes32 node = keccak256(abi.encodePacked(msg.sender, _maxQty));
        require(
            MerkleProof.verify(_merkleProof, comics[comicMintId].merkleRoot, node),
            "You have a bad Merkle Proof."
        );
        comics[comicMintId].claimed[msg.sender] += _qty;

        _safeMint(msg.sender, _qty);
    }

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
            require(msg.sender == ownerOf(_tokenIds[i]), "You do not own the token");
            _burn(_tokenIds[i]);
        }
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /*
    *  @notice reserve mint n numbers of tokens
    */
    function mintReserveTokens(uint256 _qty) public onlyOwner {
        require(
            totalSupply() + _qty <= comics[comicMintId].endTokenId + 1, 
            "Not enough tokens left to mint that many"
        );
        _safeMint(msg.sender, _qty);
    }

    /*
    *  @notice mint a token id to a wallet
    */
    function mintTokenToWallet(address _toWallet, uint256 _qty) public onlyOwner {
        require(
            totalSupply() + _qty <= comics[comicMintId].endTokenId + 1, 
            "Not enough tokens left to mint that many"
        );
         _safeMint(_toWallet, _qty);
    }

    /*
    *  @notice get base URI of tokens
    */
   	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(baseURI, _tokenId.toString()));
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
    * @notice check if wallet claimed for all potions
    */
    function checkClaimed(address _wallet) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = comics[i].claimed[_wallet];
        }

        return result;
    }

    /*
    *  @notice Set max tokens for each staged mint
    */
    function setComicMintId(uint256 _id) external onlyOwner {
        require(_id >= 0, "Must be greater or equal then zer0");
        comicMintId = _id;
    }

}