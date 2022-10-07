// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RICHPEOPLECLUB is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    uint256 public TOTAL_RICHPEOPLE = 3069;
    uint256 public richRoyalty = 8;

    uint256 public teamMintCap = 323;

    uint256 public constant MINT_LIMIT = 5;
    uint256 public constant MINT_PRICE = .09 ether;

    bool public pooronsCanMint = false;
    bool public richlistCanMint = false;

    bytes32 public richlist_merkleRoot;

    address public team_saleWallet;

    address public team_royaltyWallet;

    constructor(address _team_saleWallet, address _team_royaltyWallet)
        ERC721A("RICH PEOPLE CLUB", "RPC")
    {
        team_saleWallet = _team_saleWallet;
        team_royaltyWallet = _team_royaltyWallet;
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _totalMinted();
    }

    function isPresale() public view returns (bool) {
        return richlistCanMint;
    }

    function isPublicSale() public view returns (bool) {
        return pooronsCanMint;
    }

    function setPublicSaleWallet(address _teamSaleWallet) public onlyOwner {
        team_saleWallet = _teamSaleWallet;
    }

    function setRoyaltyWallet(address _teamRoyaltyWallet) public onlyOwner {
        team_royaltyWallet = _teamRoyaltyWallet;
    }

    function setRichListRoot(bytes32 _merkleRoot) public onlyOwner {
        richlist_merkleRoot = _merkleRoot;
    }

    function allowThePooronsToMint(bool _pubsale) public onlyOwner {
        pooronsCanMint = _pubsale;
    }

    function setRichListActive(bool _richlist) public onlyOwner {
        richlistCanMint = _richlist;
    }

    function richlistMint(uint256 quantity, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        require(
            MerkleProof.verify(
                proof,
                richlist_merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not on the whitelist"
        );
        require(richlistCanMint, "RICHLIST IS NOT ALLOWED TO MINT YET");
        require(
            quantity <= MINT_LIMIT - _numberMinted(msg.sender),
            "You got to rich. You can't mint anymore"
        );
        require(
            msg.value >= MINT_PRICE * quantity,
            "poorons can't afford this"
        );

        require(
            _totalMinted() + quantity <= TOTAL_RICHPEOPLE,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function pooronMint(uint256 quantity) public payable nonReentrant {
        require(pooronsCanMint, "The poorons are not allowed to mint yet");
        require(msg.value >= MINT_PRICE * quantity, "fucking poor ass pooron");
        require(
            _totalMinted() + quantity <= TOTAL_RICHPEOPLE,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function teamMint(address to, uint256 quantity) public onlyOwner {
        require(
            _totalMinted() + quantity <= TOTAL_RICHPEOPLE,
            "can not mint this many"
        );
        require(quantity < teamMintCap, "can not mint this many");
        teamMintCap -= quantity;
        _safeMint(to, quantity);
    }

    function setRoyalty(uint256 _royaltyAmount) public onlyOwner {
        require(_royaltyAmount <= 10, "Royalty cannot be more than 10%");
        richRoyalty = _royaltyAmount;
    }

    function cutSupply(uint256 _newAmount) public onlyOwner {
        require(_newAmount < TOTAL_RICHPEOPLE, "Cannot increase supply");
        require(
            _newAmount > _totalMinted(),
            "Cannot cut supply below current supply"
        );
        TOTAL_RICHPEOPLE = _newAmount;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(team_saleWallet).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        _tokenId;
        uint256 royaltyAmount = (_salePrice / 100) * richRoyalty;
        return (team_royaltyWallet, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}