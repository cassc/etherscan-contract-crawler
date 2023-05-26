// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 * @title The Paradox Metaverse
 * @notice Implements The Paradox Metaverse collection contract.
 */
contract TheParadoxMetaverse is Ownable, ERC721A, VRFConsumerBase {
    using Strings for uint256;

    uint256 public tokenPrice;
    uint256 public chainlinkFee;
    uint256 private _seed;
    uint256 public maxSupply;
    uint256 public immutable MAX_PER_TRANSACTION_PRESALE_1;
    uint256 public immutable MAX_PER_TRANSACTION_PRESALE_2;
    uint256 public immutable MAX_PER_TRANSACTION;
    bytes32 public merkleRoot1;
    bytes32 public merkleRoot2;
    bytes32 public chainlinkHash;
    string public baseURI;
    string public notRevealedURI;
    bool public paused;
    bool public presale;
    bool public revealed;
    bool public freezedMetadata;

    constructor(
        string memory _initbaseURI,
        string memory _initNotRevealedURI,
        address _LINK_TOKEN,
        address _LINK_VRF_COORDINATOR_ADDRESS,
        bytes32 _chainlinkHash,
        uint256 _chainlinkFee,
        uint256 _tokenPrice,
        uint256 _maxSupply
    )
        ERC721A("The Paradox Metaverse", "PARA")
        VRFConsumerBase(_LINK_VRF_COORDINATOR_ADDRESS, _LINK_TOKEN)
    {
        baseURI = _initbaseURI;
        notRevealedURI = _initNotRevealedURI;
        chainlinkHash = _chainlinkHash;
        chainlinkFee = _chainlinkFee;
        tokenPrice = _tokenPrice;
        MAX_PER_TRANSACTION = 15;
        MAX_PER_TRANSACTION_PRESALE_1 = 5;
        MAX_PER_TRANSACTION_PRESALE_2 = 15;
        maxSupply = _maxSupply;
        paused = true;
        presale = true;
    }

    modifier correctValue(uint256 _mintAmount) {
        require(
            msg.value == tokenPrice * _mintAmount,
            "Incorrect ether amount"
        );
        _;
    }

    modifier checkAmount(uint256 _amount) {
        require(_amount > 0, "Mint at least one token");
        require(
            _totalMinted() + _amount <= maxSupply,
            "Not enough tokens left to mint that many"
        );
        _;
    }

    function presaleMint1(bytes32[] calldata _merkleProof, uint256 _mintAmount)
        external
        payable
        correctValue(_mintAmount)
    {
        require(_mintAmount <= MAX_PER_TRANSACTION_PRESALE_1, "Max 5 Allowed.");
        presaleMint(merkleRoot1, _merkleProof, _mintAmount);
    }

    function presaleMint2(bytes32[] calldata _merkleProof, uint256 _mintAmount)
        external
        payable
        correctValue(_mintAmount)
    {
        require(
            _mintAmount <= MAX_PER_TRANSACTION_PRESALE_2,
            "Max 15 Allowed."
        );
        presaleMint(merkleRoot2, _merkleProof, _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        correctValue(_mintAmount)
    {
        require(!presale, "Presale is active");
        require(_mintAmount <= MAX_PER_TRANSACTION, "Max 15 Allowed.");
        _mint(_mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenID does not exist");

        if (!revealed || _seed == 0) {
            return notRevealedURI;
        }

        string memory tokenURI_ = metadataOf(tokenId);
        string memory base_ = _baseURI();

        return string(abi.encodePacked(base_, tokenURI_, ".json"));
    }

    function metadataOf(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        uint256[] memory randomIds = new uint256[](maxSupply);
        for (uint256 i = 1; i <= maxSupply; i++) {
            randomIds[i - 1] = i;
        }

        for (uint256 i = 0; i < maxSupply - 1; i++) {
            uint256 j = i +
                (uint256(keccak256(abi.encode(_seed, i))) % (maxSupply - i));
            (randomIds[i], randomIds[j]) = (randomIds[j], randomIds[i]);
        }

        return randomIds[_tokenId].toString();
    }

    function isWhitelisted(
        bytes32 _merkleRoot,
        address _user,
        bytes32[] calldata _merkleProof
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    /// ============ INTERNAL ============

    function presaleMint(
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof,
        uint256 _mintAmount
    ) internal {
        require(presale, "Presale is not active");
        require(
            isWhitelisted(_merkleRoot, msg.sender, _merkleProof),
            "Sorry, no access unless you're whitelisted"
        );

        _mint(_mintAmount);
    }

    function _mint(uint256 _mintAmount) internal checkAmount(_mintAmount) {
        require(!paused, "Please wait until unpaused");
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //Callback function used by Chainlink VRF Coordinator.
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(_seed == 0, "Seed already generated");
        _seed = (randomness % maxSupply) + 1;
    }

    /// ============ ONLY OWNER ============

    ///@notice This function requests a random number from Chainlink Oracle. Is important to notice that the random number needs to be set at right before the time of reveal.
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(_seed == 0, "Seed already generated");
        require(
            LINK.balanceOf(address(this)) >= chainlinkFee,
            "Link balance is not enough"
        );
        return requestRandomness(chainlinkHash, chainlinkFee);
    }

    function setChainlinkConfig(uint256 _chainlinkFee, bytes32 _chainlinkHash)
        external
        onlyOwner
    {
        chainlinkFee = _chainlinkFee;
        chainlinkHash = _chainlinkHash;
    }

    function airdropUser(uint256 _mintAmount, address _user)
        external
        checkAmount(_mintAmount)
        onlyOwner
    {
        _safeMint(_user, _mintAmount);
    }

    ///@notice This function mint one token for each address of the given list.
    function airdropList(address[] memory _users)
        external
        onlyOwner
        checkAmount(_users.length)
    {
        for (uint256 i; i < _users.length; i++) {
            _safeMint(_users[i], 1);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!freezedMetadata, "Metadata is frozen");
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }

    ///@notice This function reveals the URI indefinitely and should be called only after the getRandomNumber() function.
    function revealURI() external onlyOwner {
        revealed = true;
        paused = true; // Minting is paused
    }

    function freezeMetadata() external onlyOwner {
        freezedMetadata = true;
    }

    function setPresale(bool _presale) external onlyOwner {
        presale = _presale;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _valueInWei) external onlyOwner {
        tokenPrice = _valueInWei;
    }

    function setWhitelists(bytes32 _merkleRoot1, bytes32 _merkleRoot2)
        external
        onlyOwner
    {
        merkleRoot1 = _merkleRoot1;
        merkleRoot2 = _merkleRoot2;
    }

    function setWhitelist1(bytes32 _merkleRoot1) external onlyOwner {
        merkleRoot1 = _merkleRoot1;
    }

    function setWhitelist2(bytes32 _merkleRoot2) external onlyOwner {
        merkleRoot2 = _merkleRoot2;
    }
}