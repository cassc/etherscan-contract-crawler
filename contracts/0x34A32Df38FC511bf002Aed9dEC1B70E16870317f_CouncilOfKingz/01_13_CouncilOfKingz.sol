// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CouncilOfKingz is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Contract controls; defaults to false
    bool public paused;
    bool public presaleEnabled;
    bool public publicSaleEnabled;
    bool public revealed;
    bool public burnEnabled;

    // Sale variables
    uint16 public constant totalTokens = 7777;
    uint16 public maxMintAmount = 5;
    uint16 public maxTokensPerWalletPresale = 5;
    uint16 public maxTokensPerWallet = 25;
    uint256 public costPublicSale = 0.15 ether;
    uint256 public costPresale = 0.13 ether;
    // counter
    uint16 private _totalMintSupply = 0; // start with zero

    // Burn variables
    uint16 public totalBurnTokens = 2500;
    // counter
    uint16 private _totalBurnSupply = 0; // start with zero

    // metadata URIs
    string private _contractURI; // initially set at deploy
    string private _notRevealedURI; // initially set at deploy
    string private _currentBaseURI; // initially set at deploy
    string private _baseExtension = ".json";

    // Presale list
    mapping(address => uint256) public presaleListMintCount;
    bytes32 public merkleRoot;

    // Mapping Minter address to token count for mint controls
    mapping(address => uint16) public addressMints;
    // Mapping Burner address to token count
    mapping(address => uint16) public addressBurns;
    // Mapping token matrix
    mapping(uint16 => uint16) private tokenMatrix;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initContractURI,
        string memory _initBaseURI,
        string memory _initNotRevealedURI
    ) ERC721(_name, _symbol) {
        setContractURI(_initContractURI);
        setCurrentBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedURI);
        _mintNFT(msg.sender, 100);
    }

    /**
     * @dev Returns the total number of tokens in circulation
     */
    function totalSupply() external view returns (uint16) {
        return _totalMintSupply - _totalBurnSupply;
    }

    /**
     * @dev Returns the total number of tokens burned
     */
    function totalBurned() public view returns (uint16) {
        return _totalBurnSupply;
    }

    /**
     * @dev Returns the total number of tokens minted
     */
    function totalMinted() public view returns (uint16) {
        return _totalMintSupply;
    }

    /**
     * @dev Modifier to ensure tokens are avaliable and sale is active
     */
    modifier onlyAllowValidCountAndActiveSale(uint256 _mintAmount) {
        require(!paused, "Sale paused");
        require(totalMinted() + _mintAmount <= totalTokens, "Exceeds supply");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmount,
            "Wrong token count"
        );
        _;
    }

    /**
     * @dev Public mint
     */
    function publicMint(uint16 _mintAmount)
        external
        payable
        onlyAllowValidCountAndActiveSale(_mintAmount)
    {
        require(costPublicSale.mul(_mintAmount) == msg.value, "Wrong amount");
        require(publicSaleEnabled && !presaleEnabled, "Not started");
        require(
            addressMints[_msgSender()] + _mintAmount <= maxTokensPerWallet,
            "Exceeds max"
        );
        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Presale mint
     */
    function presaleMint(bytes32[] calldata _merkleProof, uint16 _mintAmount)
        external
        payable
        onlyAllowValidCountAndActiveSale(_mintAmount)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the list"
        );
        require(costPresale.mul(_mintAmount) == msg.value, "Wrong amount");
        require(!publicSaleEnabled && presaleEnabled, "Presale closed");
        require(
            addressMints[_msgSender()] + _mintAmount <=
                maxTokensPerWalletPresale,
            "Exceeds max"
        );
        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Owner mint function
     */
    function ownerMint(uint16 _mintAmount)
        external
        onlyOwner
        onlyAllowValidCountAndActiveSale(_mintAmount)
    {
        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Internal mint function
     */
    function _mintNFT(address _to, uint16 _mintAmount) private {
        addressMints[_to] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, _getTokenToBeMinted(totalMinted()));
            _totalMintSupply++;
        }
    }

    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId + 1;
    }

    /**
     * @dev Generates a pseudo-random number
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        _msgSender()
                    )
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev Returns list of token ids owned by address
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 k = 0;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_exists(i) && _owner == ownerOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete k;
        return tokenIds;
    }

    /**
     * @dev Returns the URI to the contract metadata
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Internal function to return the base uri for all tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /**
     * @dev Returns the URI to the tokens metadata
     */
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

        if (revealed == false) {
            return _notRevealedURI;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseExtension
                    )
                )
                : "";
    }

    /**
     * @dev Burn tokens in mutiples of 5
     */
    function burn(uint256[] memory _tokenIds) external {
        require(burnEnabled, "Burn disabled");
        require(_tokenIds.length % 5 == 0, "Multiples of 5");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), _tokenIds[i]),
                "ERC721Burnable: caller is not owner nor approved"
            );
        }
        require(
            totalBurned() + _tokenIds.length <= totalBurnTokens,
            "Exceeds burn limit"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
            _totalBurnSupply++;
            addressBurns[_msgSender()] += 1;
        }
    }

    /**
     * Owner functions
     */

    /**
     * @dev Start or pause the sale
     */
    function flipSaleState() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Activate the public sale
     */
    function publicSaleStart() external onlyOwner {
        presaleEnabled = false;
        publicSaleEnabled = true;
    }

    /**
     * @dev Reveal the token metadata
     */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @dev enables the burn mechanism; can only be set once
     */
    function enableBurn() external onlyOwner {
        burnEnabled = true;
    }

    /**
     * @dev Setter for the token cost for public sale
     */
    function setCostPublicSale(uint256 _newCost) external onlyOwner {
        costPublicSale = _newCost;
    }

    /**
     * @dev Setter for the token cost for presale
     */
    function setCostPresale(uint256 _newCostPresale) external onlyOwner {
        costPresale = _newCostPresale;
    }

    /**
     * @dev Setter for the total burnable tokens
     */
    function setTotalBurnTokens(uint16 _newTotalBurnTokens) external onlyOwner {
        totalBurnTokens = _newTotalBurnTokens;
    }

    /**
     * @dev Setter for the Contract URI
     */
    function setContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Setter for the Not Revealed URI
     */
    function setNotRevealedURI(string memory _newNotRevealedURI)
        public
        onlyOwner
    {
        _notRevealedURI = _newNotRevealedURI;
    }

    /**
     * @dev Setter for the Base URI
     */
    function setCurrentBaseURI(string memory _newBaseURI) public onlyOwner {
        _currentBaseURI = _newBaseURI;
    }

    /**
     * @dev Setter for the meta data base extension
     */
    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        _baseExtension = _newBaseExtension;
    }

    function setPresaleListEnabled() external onlyOwner {
        presaleEnabled = true;
    }

    /**
     * @dev Setter for the merkle root
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /**
     * @dev A fallback function in case someone sends ETH to the contract
     */
    fallback() external payable {}

    receive() external payable {}
}