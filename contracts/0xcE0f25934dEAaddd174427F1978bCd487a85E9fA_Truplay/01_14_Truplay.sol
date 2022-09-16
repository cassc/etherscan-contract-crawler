pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Truplay is ERC721, Ownable, Pausable {
    /**
        E#0: Sale is not active
        E#1: Sale has ended
        E#2: Token's minting limit achieved
        E#3: tokenId outside of the reserve
        E#4: Withdrawal unsuccessful
        E#5: You are not on whitelist
        E#6: You already minted your tokens with whitelist
    */
    event SaleState(bool isSaleActive);
    event MintSuccessful(uint256 tokenId);
    event NewNFTLimit(uint8 NFTlimit);
    event ReserveMintSuccessful(uint256 tokenId);
    event WhitelistMintSuccessful(uint256 tokenId);
    event WithdrawalSuccessful(uint256 balance);
    event NewBaseURI(string baseURI);

    using Counters for Counters.Counter;
    string public baseURI;
    uint256 public constant MAX_TOTAL_SUPPLY = 7000;
    uint256 public constant MAX_PUBLIC_SUPPLY = 6650; //350 NFTs reserved for the Truplay team
    bool public isSaleActive = false;
    uint8 public NFTlimitPerUser = 1;

    Counters.Counter private _tokenIdCounter;
    uint256 private _reserveTokenIdCounter = MAX_PUBLIC_SUPPLY; //separate counter used only for reserve tokens

    bytes32 private whitelistMerkleRoot;
    mapping(address => uint8) private claimedUsersTokens;

    constructor(string memory _baseUri) ERC721("Truplay", "TRU") {
        baseURI = _baseUri;
    }

    modifier checkIsSaleIsActive() {
        require(isSaleActive, "E#0");
        _;
    }

    modifier checkTokenCounter() {
        require(_tokenIdCounter.current() < MAX_PUBLIC_SUPPLY, "E#1");
        _;
    }

    function safeMint()
        public
        whenNotPaused
        checkIsSaleIsActive
        checkTokenCounter
    {
        require(claimedUsersTokens[msg.sender] < NFTlimitPerUser, "E#2");
        claimedUsersTokens[msg.sender]++;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        emit MintSuccessful(tokenId);
    }

    function safeReserveMint() public onlyOwner {
        require(
            _reserveTokenIdCounter >= MAX_PUBLIC_SUPPLY &&
                _reserveTokenIdCounter < MAX_TOTAL_SUPPLY,
            "E#3"
        );
        _reserveTokenIdCounter++;
        _safeMint(msg.sender, _reserveTokenIdCounter);
        emit ReserveMintSuccessful(_reserveTokenIdCounter);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "E#4");
        emit WithdrawalSuccessful(balance);
    }

    function setNFTLimit(uint8 _NFTlimit) public onlyOwner {
        NFTlimitPerUser = _NFTlimit;
        emit NewNFTLimit(NFTlimitPerUser);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit NewBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
        emit SaleState(isSaleActive);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function safeWhitelistMint(bytes32[] memory merkleProof)
        public
        whenNotPaused
        checkTokenCounter
    {
        require(
            MerkleProof.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "E#5"
        );
        require(claimedUsersTokens[msg.sender] < NFTlimitPerUser, "E#6");

        claimedUsersTokens[msg.sender]++;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        emit WhitelistMintSuccessful(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintedNftAmount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
}