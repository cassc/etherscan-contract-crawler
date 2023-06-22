// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NFT is ERC721Enumerable, IERC2981, Ownable {
    using Strings for uint256;

    // Royalty vars
    address public royaltyRecipient =
        0x339Ff26CF5E9332b59A6E37C2453c4B335b839d1; // koolkidz.eth
    uint256 public royaltyPercentage = 750; // starting at 7.5% royalty
    uint256 public SCALE = 10000;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.08 ether;
    uint256 public reservedSupply = 250;
    uint256 public reservedMinted;
    uint256 public maxSupply = 5000;
    uint256 public maxMintAmountPresale = 2;
    uint256 public maxMintAmountPublic = 10;
    bool public presaleMintingEnabled = false;
    bool public publicMintingEnabled = false;
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri;

    bytes32 public whitelistMerkleRoot;

    // keep track of how many each address has claimed
    mapping(address => uint256) public mintedAmount;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintPublic(uint256 _mintAmount) public payable onlyHumans {
        uint256 supply = totalSupply();
        require(publicMintingEnabled, "Public minting is not enabled");
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Cannot mint 0");
        require(
            supply + _mintAmount <= maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            mintedAmount[msg.sender] + _mintAmount <= maxMintAmountPublic,
            "Mints exceed 10 per address"
        );

        require(msg.value >= cost * _mintAmount, "Not enough ETH");

        mintedAmount[msg.sender] += _mintAmount;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintPresale(bytes32[] calldata merkleProof, uint256 _mintAmount)
        public
        payable
        onlyHumans
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        uint256 supply = totalSupply();
        require(presaleMintingEnabled, "Presale minting is not enabled");
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Cannot mint 0");
        require(
            supply + _mintAmount <= maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            mintedAmount[msg.sender] + _mintAmount <= maxMintAmountPresale,
            "Mints exceed 2 per address"
        );

        require(msg.value >= cost * _mintAmount, "Not enough ETH");

        mintedAmount[msg.sender] += _mintAmount;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintReserved(uint256 _mintAmount) public {
        require(
            msg.sender == owner() || msg.sender == royaltyRecipient,
            "Only owners can mint reserved"
        );
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Cannot mint 0");
        require(
            reservedMinted + _mintAmount <= reservedSupply,
            "Cannot mint more than reserved supply"
        );

        uint256 startingID = reservedMinted;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, startingID + i);
            reservedMinted++;
        }
    }

    function isWhitelistedInMerkleProof(
        address _account,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                _merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(_account))
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        if (revealed == false) {
            return
                bytes(notRevealedUri).length > 0
                    ? string(
                        abi.encodePacked(
                            notRevealedUri,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function reveal() public onlyOwner {
        revealed = true;
    }

    // NOTE: before enabling, make sure all reserved NFTs minted
    function setPresaleMintingEnabled(bool _enabled) external onlyOwner {
        presaleMintingEnabled = _enabled;
    }

    // NOTE: before enabling, make sure all reserved NFTs minted
    function setPublicMintingEnabled(bool _enabled) external onlyOwner {
        publicMintingEnabled = _enabled;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setRoyalty(uint256 _newRoyaltyPercentage) public onlyOwner {
        require(_newRoyaltyPercentage <= SCALE, "Royalty percentage too high");
        royaltyPercentage = _newRoyaltyPercentage;
    }

    function setRoyaltyRecipient(address _newRoyaltyRecipient)
        public
        onlyOwner
    {
        royaltyRecipient = _newRoyaltyRecipient;
    }

    function setMaxMintAmountPublic(uint256 _newMax) public onlyOwner {
        maxMintAmountPublic = _newMax;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    // ============ ROYALTIES ============

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: Royalty query for nonexistent token"
        );

        receiver = royaltyRecipient;
        royaltyAmount = (salePrice * royaltyPercentage) / SCALE;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ============ MODIFIERS ============

    /**
     * @dev Only allows EOA accounts to call function
     */
    modifier onlyHumans() {
        require(tx.origin == msg.sender, "Only humans allowed");
        _;
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
}