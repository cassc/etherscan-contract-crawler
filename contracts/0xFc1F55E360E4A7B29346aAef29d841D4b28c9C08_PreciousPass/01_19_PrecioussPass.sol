// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RandomNumberConsumer.sol";
import "./PriceConsumer.sol";
import "erc721a/contracts/ERC721A.sol";

contract PreciousPass is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter,
    RandomNumberConsumer,
    PriceConsumerV3
{
    uint256 public constant COST = 0.066 ether;
    uint256 public constant WHITELIST_COST = 0.045 ether;
    uint256 public constant MAX_SUPPLY = 3499;
    uint256 public constant INITIAL_MINT = 150;
    string private diamondURI;
    string private goldURI;
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension;
    bool public revealed;
    bool private paymentClaimed;
    bytes32 private merkleRoot;
    uint256[] private diamondSpots;
    address[] private team;
    uint256[] private _teamShares = [95, 25 / uint256(10), 25 / uint256(10)];
    Status public currentStatus;
    mapping(address => bool) private whitelistClaimed;
    mapping(uint256 => bool) public _diamondSpots;

    enum Status {
        CLOSED,
        WHITELIST,
        MINT
    }

    constructor(
        string memory _name, //
        string memory _symbol, //
        string memory _initBaseURI, //
        string memory _baseExtension,
        string memory _initNotRevealedUri, //
        string memory _initDiamondPassUri, //
        string memory _initGoldPassUri,//
        address[] memory _team,
        bytes32 _merkleRoot //
    ) ERC721A(_name, _symbol) PaymentSplitter(_team, _teamShares) {
        baseURI = _initBaseURI;
        baseExtension = _baseExtension;
        notRevealedUri = _initNotRevealedUri;
        diamondURI = _initDiamondPassUri;
        goldURI = _initGoldPassUri;
        _mint(_team[0], INITIAL_MINT);
        transferOwnership(_team[0]);
        team = _team;
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Avoid people to send funds directly to contract
     **/
    receive() external payable override {
        revert("Only if you mint");
    }
    
    ///=======================================
    ///  TOKEN URI
    ///=======================================

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Allows to get the complete URI of a specific NFT by his ID
     *
     * @param _tokenId The id of the NFT
     *
     * @return The token URI of the NFT which has _tokenId Id
     **/
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();

        if (revealed == false) {  //while reveal is false every token has the unrevealed URI
            return string(abi.encodePacked(currentBaseURI, notRevealedUri, baseExtension));
        }

        string memory tierIs;
        _diamondSpots[_tokenId] ? tierIs = diamondURI : tierIs = goldURI;

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tierIs, baseExtension))
                : "";
    }

    /// =======================
    ///   Minting
    /// =======================

    /**
     * @notice Allows to mint NFTs after whitelist mint is over
     *
     * @param _quantity The ammount of NFTs the user wants to mint
     **/
    function mint(uint256 _quantity) external payable nonReentrant {
        require(currentStatus == Status.MINT, "not in normal mint");
        require(
            _quantity <= 4 && MAX_SUPPLY >= totalSupply() + _quantity,
            "Max mint quantity reached"
        );
        require(msg.value == (_quantity * COST), "not enough ether");
        _mint(msg.sender, _quantity);
    }

    /// @notice Allows owner to mint NFTs for airdops, only after whitelist is over
    /// @param _quantity quantity of NFTs to mint for airdrop
    function airdropMint(uint256 _quantity) external onlyOwner {
        require(
            MAX_SUPPLY >= totalSupply() + _quantity,
            "Max mint quantity reached"
        );
        require(currentStatus == Status.MINT, "whitelist not over");
        _mint(owner(), _quantity);
    }

    /**
     * @notice Allows to mint one or two NFT if whitelisted
     * @param _quantity The quantity of NFT the user is minting
     * @param _merkleProof The Merkle Proof to verify if an user is whitelisted
     **/
    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        require(currentStatus == Status.WHITELIST, "not in presale");
        require(!whitelistClaimed[msg.sender], "already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "invalid proof"
        );
        require(msg.value == _quantity * WHITELIST_COST, "not enough ether");
        require(
            _quantity <= 2 && MAX_SUPPLY >= totalSupply() + _quantity,
            "Max mint quantity reached"
        );

        whitelistClaimed[msg.sender] = true;
        _mint(msg.sender, _quantity);
    }

    ///=======================================
    ///    SETTERS
    ///=======================================

    /**
     * @notice Change the base URI
     *
     * @param _newBaseURI The new base URI
     **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Allows to change the base extension of the metadatas files
     *
     * @param _baseExtension the new extension of the metadatas files
     **/
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    /**
     * @notice Edit the Merkle Root
     *
     * @param _newMerkleRoot The new Merkle Root
     **/
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /// ======================================
    ///    ONLY OWNER
    /// ======================================

    /**
     * @notice Allows to open whitelist mint phase
     **/
    function openWhitelist() external onlyOwner {
        require(currentStatus == Status.CLOSED, "only after whitelist phase");
        currentStatus = Status.WHITELIST;
    }

    /**
     * @notice Allows to open public mint phase
     **/
    function closeWhitelist() external onlyOwner {
        require(currentStatus == Status.WHITELIST, "only after whitelist over");
        currentStatus = Status.MINT;
    }

    /**
    * @notice return all the token Ids of the diamond tokens
     */
    function getDiamondSpots() external view onlyOwner returns(uint256[] memory){
        return diamondSpots;
    }


    ///================================
    ///  REVEAL
    ///================================

    /**
     * @notice Allows to set the revealed variable to true, to reveal NFTs' real URI
     *  and randomly selects the 49 Diamond passes through an external call to chainLink
     **/
    function reveal() external onlyOwner {
        require(revealed == false, "already revealed");
        revealDiamondSpots();
        revealed = true;
    }

    /**
    * @notice creates an array of 49 numbers from the chainlink oracle random number
     */
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /**
    * @notice randomly selects the diamond spots from a chainlink oracle call;
     */
    function revealDiamondSpots() internal {
        getRandomNumber();
        uint256 rn = randomResult;
        uint256[] memory array = expand(rn, 48);

        _diamondSpots[0] = true;   //Token Zero is a diamond 
        diamondSpots.push(0);

        for (uint256 i = 0; i < array.length; i++) {
            uint256 rnE = 150 + (array[i] % 3350);
            while (_diamondSpots[rnE] == true) rnE = (rnE * array[i - 1]) % 3350;
            _diamondSpots[rnE] = true;
            diamondSpots.push(rnE);
        }
    }

    ///===========================
    ///    WITHDRAW
    ///===========================

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * @param account the account that will receive its share
     */
    function release(address payable account) public virtual override {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        require(paymentClaimed, "not releasable yet");
        uint256 _payment = releasable(account);

        require(_payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += _payment;
        _totalReleased += _payment;

        Address.sendValue(account, _payment);
        emit PaymentReleased(account, _payment);
    }

    /// @notice dev payment, claim 1 time
    function payment() external nonReentrant {
        require(
            msg.sender == team[1] || msg.sender == team[2],
            "not a team member"
        );
        require(!paymentClaimed, "already claimed");
        int _price = getLatestPriceETHUSD();
        require(address(this).balance >= (8100 * 10 ** 8 / uint(_price)), "not enough balance");

        payable(team[1]).transfer(4050 * 10 ** 8 / uint(_price));
        payable(team[2]).transfer(4050 * 10 ** 8 / uint(_price));
        paymentClaimed = true;
    }
}