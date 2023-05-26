//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/utils/MerkleProof.sol";

contract GenesisTiimy is ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /**
     *@dev mint phases
     *@param PREMINT before wl phase
     *@param WHITELIST whitelist phase
     *@param PUBLIC public minting phase
     *@param CLOSED end of sale phase
     */
    enum MintPhase {
        PREMINT,
        WHITELIST,
        PUBLIC,
        CLOSED
    }

    string public baseURI;
    string public contractURI;

    mapping(address => bool) freeMints;
    uint256 freeMinted = 0;
    uint256 whitelistMinted = 0;
    mapping(address => uint256) public amountNFTsPerWalletWhitelistSale;
    mapping(address => uint256) public amountNFTsPerWalletPublicSale;

    uint256 private constant MAX_SUPPLY = 2000;
    // WL + Freemint = 1500
    uint256 private constant MAX_WHITELIST = 984;
    uint256 private constant MAX_FREE_GUARANTEED = 516;
    uint256 private constant PREMINT = 200;

    uint256 public constant SALE_PRICE = 0.08 ether;
    uint256 public constant WHITELIST_SALE_PRICE = 0.065 ether;
    uint256 public constant MAX_MINTS_PER_WALLET = 4;
    uint256 public constant MAX_WHITELIST_MINTS_PER_WALLET = 4;
    bool public preminted = false;

    ///@dev current phase
    MintPhase public currentPhase;

    ///@dev merkel root
    bytes32 public whitelistMerkleRoot;
    bytes32 public freeMerkleRoot;

    ///@dev Mint event
    event Minted(address minter, uint256 id);

    /**
     * @dev constructor
     * @param _name name
     * @param _symbol symbol
     * @param _baseURI base URI for token.
     */
    constructor(
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    )
        ERC721(_name, _symbol)
    {
        baseURI = _baseURI;
        ///royalty fee = 7.5 %
        setRoyaltyInfo(owner(), 750);
        contractURI = _contractURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function preMint() external payable onlyOwner {
        require(currentPhase == MintPhase.PREMINT, "Pre minting sale is not activated");
        require(preminted == false, "Pre mint already done");
        address sender = _msgSender();
        for (uint256 i = 0; i < PREMINT; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(sender, id);
            emit Minted(sender, id);
        }
        preminted = true;
    }

    function freeMint(bytes32[] calldata _proof) external payable nonReentrant callerIsUser {
        address sender = _msgSender();
        require(currentPhase == MintPhase.WHITELIST, "Whitelist sale is not activated");
        require(hasFreeMint(msg.sender, _proof), "No free mint");
        require(!freeMints[sender], "Only 1 NFT per wallet can be freely minted");
        require(freeMinted < MAX_FREE_GUARANTEED, "Max free mint supply exceeded");
        require(totalSupply() < MAX_SUPPLY, "Max supply exceeded");

        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(sender, id);
        emit Minted(sender, id);
        freeMints[sender] = true;
        freeMinted += 1;
    }

    function whitelistMint(bytes32[] calldata _proof, uint256 amount) external payable nonReentrant callerIsUser {
        uint price = WHITELIST_SALE_PRICE;
        require(price != 0, "Price is 0");

        address sender = _msgSender();
        require(currentPhase == MintPhase.WHITELIST, "Whitelist sale is not activated");
        require(isWhitelisted(msg.sender, _proof), "Not whitelisted");
        require((whitelistMinted + amount) <= MAX_WHITELIST, "Max whitelist supply exceeded");
        require(amountNFTsPerWalletWhitelistSale[sender] + amount <= MAX_WHITELIST_MINTS_PER_WALLET, "Max NFTs minted reached for whitelist sale");
        require(msg.value >= (price * amount), "Not enough funds");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(sender, id);
            emit Minted(sender, id);
        }
        whitelistMinted += amount;
        amountNFTsPerWalletWhitelistSale[sender] += amount;
    }

    /**
     * @dev mint card token to contract
     * @param amount amount to be minted
     */
    function mint(uint256 amount) external payable nonReentrant callerIsUser {
        uint price = SALE_PRICE;
        require(price != 0, "Price is 0");

        address sender = _msgSender();
        require(currentPhase == MintPhase.PUBLIC, "Public sale is not activated");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amountNFTsPerWalletPublicSale[sender] + amount <= MAX_MINTS_PER_WALLET, "Max NFTs minted reached for public sale");
        require(msg.value >= (price * amount), "Not enough funds");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _safeMint(sender, id);
            emit Minted(sender, id);
        }
        amountNFTsPerWalletPublicSale[sender] += amount;
    }

    /**
     * @dev withdraw current balance: only owner can call
     * @param recipient address of recipient
     */
    function withdraw(address payable recipient) external onlyOwner nonReentrant {
        require(recipient != address(0), "Invalid recipient address");

        uint256 currentBalance = getBalance();

        (bool success, ) = recipient.call{ value: currentBalance }("");
        require(success, "Failed to send ethers");
    }

    /**
     * @dev set current mint phase
     * @param newPhase one of mint phases
     */
    function setPhase(MintPhase newPhase) external onlyOwner {
        currentPhase = newPhase;
    }

    ///@dev get current balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function numberFreeMinted(address _address) public view returns (uint) {
        return freeMints[_address] ? 1 : 0;
    }

    function numberWhitelistedMinted(address _address) public view returns (uint) {
        return amountNFTsPerWalletWhitelistSale[_address];
    }

    function numberPublicMinted(address _address) public view returns (uint) {
        return amountNFTsPerWalletPublicSale[_address];
    }

    /**
    * @dev function "renounceOwnership()" prevents ownership renounce
    */
    function renounceOwnership() public override onlyOwner {
    }

    //Whitelist & free mint
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setFreeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMerkleRoot = _merkleRoot;
    }

    function isWhitelisted(address _account, bytes32[] calldata _proof) public view returns(bool) {
        return _verify(leaf(_account), _proof, whitelistMerkleRoot);
    }

    function hasFreeMint(address _account, bytes32[] calldata _proof) public view returns(bool) {
        return _verify(leaf(_account), _proof, freeMerkleRoot);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof, bytes32 _root) internal pure returns(bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    //Royalties
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        require(_receiver != address(0), "Invalid receiver address");
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}