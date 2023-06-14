// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************************* /
*   ███████████                   ██████████                                               *
* ░░███░░░░░░█                  ░░███░░░░███                                               *
*  ░███   █ ░   ██████   ███████ ░███   ░░███ ████████   ██████  ████████   █████          *
*  ░███████    ███░░███ ███░░███ ░███    ░███░░███░░███ ███░░███░░███░░███ ███░░           *
*  ░███░░░█   ░███ ░███░███ ░███ ░███    ░███ ░███ ░░░ ░███ ░███ ░███ ░███░░█████          *
*  ░███  ░    ░███ ░███░███ ░███ ░███    ███  ░███     ░███ ░███ ░███ ░███ ░░░░███         *
*  █████      ░░██████ ░░███████ ██████████   █████    ░░██████  ░███████  ██████          *
* ░░░░░        ░░░░░░   ░░░░░███░░░░░░░░░░   ░░░░░      ░░░░░░   ░███░░░  ░░░░░░           *
*                       ███ ░███                                 ░███                      *
*                      ░░██████                                  █████                     *
*                       ░░░░░░                                  ░░░░░                      *
******************************************************************************************** /                                                        *
*/
 
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FogDrop is ERC721AQueryable, Ownable, ReentrancyGuard {
    string public baseTokenURI = "";

    string public uriSuffix = "";

    bytes32 public merkleRoot;

    uint256 public cost;

    uint256 public maxSupply;

    uint256 public maxMintAmountPerTx;

    uint256 public maxMintAmountPreOwner;

    bool public mintPaused = true;
    bool public whitelistMintEnabled = false;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxPreTx,
        uint256 _maxSupply,
        uint256 _maxPreOwner,
        uint256 _cost,
        string memory _baseUri
    ) ERC721A(_name, _symbol) {
        maxMintAmountPerTx = _maxPreTx;
        maxMintAmountPreOwner = _maxPreOwner;
        maxSupply = _maxSupply;
        cost = _cost;
        baseTokenURI = _baseUri;
    }

    /**
     * @dev check the conditions are valid
     */
    modifier _check_mint_compliance(uint256 _mintAmount) {
        require(_msgSender().code.length == 0, "invalid addres");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            ownerMintAmount(_msgSender()) + _mintAmount <=
                maxMintAmountPreOwner,
            "mint amount limited"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    /**
     * @dev check mint balance
     */
    modifier _check_mint_balance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    /**
     * @dev return someone mint amount
     */
    function ownerMintAmount(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev whitelist mint NFTs
     */
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        _check_mint_compliance(_mintAmount)
        _check_mint_balance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(
            numberWhitelistMinted(_msgSender()) == 0,
            "Address already claimed!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        _setAux(_msgSender(), _getAux(_msgSender()) + uint64(_mintAmount));
        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @dev public mint for everyone
     */
    function mint(uint256 _mintAmount)
        public
        payable
        _check_mint_compliance(_mintAmount)
        _check_mint_balance(_mintAmount)
    {
        require(!mintPaused, "The contract is paused!");
        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * @dev The owner mint NFT for the receiver
     */
    function mintTo(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    /**
     * @dev return whitelist mint amount
     */
    function numberWhitelistMinted(address _owner)
        public
        view
        returns (uint256)
    {
        return _getAux(_owner);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev This will set the price of every single NFT.
     */
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    /**
     * @dev This will set How many NFT can be mint in single Tx  .
     */
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /**
     * @dev This will set How many NFT can a wallet to mint  .
     */
    function setMaxMintAmountPreOwner(uint256 _maxMintAmountPreOwner)
        public
        onlyOwner
    {
        maxMintAmountPreOwner = _maxMintAmountPreOwner;
    }

    /**
     * @dev This will set the base token url when revealed .
     */
    function setBaseTokenURI(string memory _baseUrl) public onlyOwner {
        baseTokenURI = _baseUrl;
    }

    /**
     * @dev This will enable or disable publit mint.if false, it should be public .
     */
    function setPaused(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    /**
     * @dev This will set the merkle tree root of the whitelist .
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev This will enable or disaple whitelist mint.
     */
    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    /**
     * @dev This will set uri suffix.
     */
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @dev This will transfer the remaining contract balance to the owner.
     */
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A,IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseurl = _baseURI();
        return
            bytes(baseurl).length != 0
                ? string(
                    abi.encodePacked(baseurl, _toString(tokenId), uriSuffix)
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}