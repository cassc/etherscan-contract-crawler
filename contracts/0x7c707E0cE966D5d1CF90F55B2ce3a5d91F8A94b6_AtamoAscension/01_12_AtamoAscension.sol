// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract AtamoAscension is ERC721A, OperatorFilterer, VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;

    enum MintState {
        Closed,
        Whitelist,
        Public
    }

    struct Prize {
        uint256 id;
        address winnerAddress;
    }

    uint256 public MAX_SUPPLY = 5555;
    
    uint256 public WL_TOKEN_PRICE = 0.02 ether;
    uint256 public PUBLIC_TOKEN_PRICE = 0.02 ether;
    
    uint256 public PUBLIC_MINT_LIMIT = 3;
    uint256 public WHITELIST_MINT_LIMIT = 3;
    
    uint256 public PRIZES_AMOUNT = 5;

    MintState public mintState;
    bytes32 public merkleRoot;

    string public baseURI;

    event requestConfirmationEvent(address sender, uint256 id);

    bytes32 keyHash;
    address vrfCoordinator;

    uint256 public s_requestId;
    uint64 public s_subscriptionId = 558;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 2000000;
    uint32 numWords = 5;

    uint256[] public prizeIds;
    Prize[] public prizes;

    bool public operatorFilteringEnabled;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) 
    VRFConsumerBaseV2(_vrfCoordinator)
    ERC721A("AtamoAscension", "AA") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        
        baseURI = baseURI_;
    }

    // Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    modifier onlyValidProof(bytes32[] calldata proof) {
        bool valid = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        require(valid, "Invalid proof");
        _;
    }

    modifier onlyIfWinnersSelected() {
        require(prizes.length > 0, "Winners must be selected");
        _;
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Mint

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Whitelist;
        else if (newState == 2) mintState = MintState.Public;
        else revert("Mint state does not exist");
    }

    function tokensRemainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Whitelist)
            return WHITELIST_MINT_LIMIT - _numberMinted(who);
        else if (mintState == MintState.Public)
            return PUBLIC_MINT_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    function mintPublic(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Public, "Mint state mismatch");
        require(msg.value >= PUBLIC_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 quantity)
        external
        payable
        onlyExternallyOwnedAccount
        onlyValidProof(proof)
    {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Whitelist, "Mint state mismatch");
        require(msg.value >= WL_TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity));
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");
        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= MAX_SUPPLY, "Batch mint exceeds max supply");

            _mint(recipients[i], quantities[i]);
        }
    }

    // Edit Mint

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setWLPrice(uint256 _newPrice) external onlyOwner {
        WL_TOKEN_PRICE = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        PUBLIC_TOKEN_PRICE = _newPrice;
    }

    function setPublicLimit(uint256 _newLimit) external onlyOwner {
        PUBLIC_MINT_LIMIT = _newLimit;
    }

    function setWLLimit(uint256 _newLimit) external onlyOwner {
        WHITELIST_MINT_LIMIT = _newLimit;
    }

    // VRF

    function addPrizes(uint256[] calldata ids) external onlyOwner {
        require(ids.length == PRIZES_AMOUNT, "Not enough prizes");
        for (uint256 i = 0; i < ids.length; i++) {
            prizeIds.push(ids[i]);
        }
    }

    function selectRandomWinnersForPrizes() external onlyOwner {
        require(prizeIds.length == PRIZES_AMOUNT, "Not enough prizes");
        requestRandom();
    }

    function requestRandom() internal {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        emit requestConfirmationEvent(msg.sender, s_requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 prizeWinnerTokenId = (randomWords[i] % totalSupply()) + 1;
            address prizeWinnerAddress = ownerOf(prizeWinnerTokenId);
            prizes.push(Prize(prizeIds[i], prizeWinnerAddress));
        }
    }

    function sendPrizesToWinner(address collectionAddress) external onlyIfWinnersSelected onlyOwner {
        require(prizes.length == PRIZES_AMOUNT, "Not enough winners");
        for (uint256 i = 0; i < prizes.length; i++) {
            Prize memory prize = prizes[i];
            IERC721 collection = IERC721(collectionAddress);
            uint256 id = prize.id;
            address winner = prize.winnerAddress;
            collection.safeTransferFrom(address(this), winner, id);
        }
    }

    // Withdraw
 
    function withdrawToRecipients() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0xe41Fd011a57fC11d077C1f3b07ADE078CA1e3a13;

        address(owner          ).call{value: balancePercentage * 100}("");
    }
}