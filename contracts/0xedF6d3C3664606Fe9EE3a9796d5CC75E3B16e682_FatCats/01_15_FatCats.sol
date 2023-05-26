// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Mint InCreation collection
 * @notice Contract in creation
 */

contract FatCats is ERC721A, VRFConsumerBaseV2, Ownable {
    /**
     *
     *
     **********CHAINLINK DATA*********
     *
     *
     */

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909; 
    bytes32 keyHash =
        0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; 
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    uint256 public s_randomWords;
    uint256 public s_requestId;

    /**
     *
     *
     **********COLLECTION DATA*********
     *
     *
     */

    using Strings for uint256;
    // Merkle root
    bytes32 public merkleRoot;
    // Max supply
    uint256 public maxSupply = 5000;
    // Token price in ether
    uint256 public price = 0.08 ether;
    // Max wallet step 1
    uint256 public maxNftByWallet1 = 2;
    // Max wallet step 2
    uint256 public maxNftByWallet2 = 10;
    // Team wallet
    address payable team;
    // Proxy registery Address
    address public proxyAddress;
    // Shuffle flag
    bool public shuffle = false;
    // paused flag
    bool public paused = true;
    // Step 2 flag
    bool public step_2 = false;
    // Public Step flag
    bool public publicStep = false;
    // Reveal flag
    bool public revealed = false;
    // publicBurn flag
    bool public publicBurnFlag = false;
    // Collection Base URI
    string public baseURI;
    //Collection hidden URI
    string public hideURI;

    /**
     * @dev Ensure the caller is in the whitelist
     */
    modifier isWhitelisted(bytes32[] calldata merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Not in the whitelist"
        );
        _;
    }

    /**
     * @dev Ensure the caller is not a SC
     */
    modifier isAUser() {
        require(tx.origin == msg.sender, "Not a user");
        _;
    }

    constructor(
        string memory _collectionURI,
        string memory _hiddenURI,
        bytes32 _merkleRoot,
        address payable _team,
        uint64 subscriptionId,
        address _proxyAddress
    ) ERC721A("FatCats", "FCD") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        baseURI = _collectionURI;
        hideURI = _hiddenURI;
        merkleRoot = _merkleRoot;
        team = _team;
        proxyAddress = _proxyAddress;
        _safeMint(team, 1);
    }

    receive() external payable {}

    /**
     *
     *
     **********MINT FUNCTIONS*********
     *
     *
     */

    /**
     * @dev mintStep1
     *
     * Requirements:
     *
     * Contract must be unpaused
     * Contract must be in sale step 1
     * The caller must be in the whitelist
     * The caller must request an amount lower or equal to the authorized by wallet
     * The amount of token must be superior to 0
     * The supply must be available
     * The price must be correct
     *
     * @param amountToMint the number of token to mint
     * @param merkleProof for the wallet address
     *
     */
    function mintStep1(uint256 amountToMint, bytes32[] calldata merkleProof)
        external
        payable
        isWhitelisted(merkleProof)
    {
        require(!paused, "Contract paused");
        require(!step_2 && !publicStep, "Wrong step");

        require(
            amountToMint + _numberMinted(msg.sender) <= maxNftByWallet1,
            "Requet too much for a wallet at this stage"
        );
        require(
            amountToMint + totalSupply() <= maxSupply,
            "Request superior max Supply"
        );
        require(msg.value >= price * amountToMint, "Insufficient funds");
        _safeMint(msg.sender, amountToMint);
    }

    /**
     * @dev mintStep2
     *
     * Requirements:
     *
     * Contract must be in sale step 2
     * The caller must be in the whitelist
     * The caller must request an amount lower or equal to the authorized by wallet
     * The amount of token must be superior to 0
     * The supply must be available
     * The price must be correct
     *
     * @param amountToMint the number of token to mint
     * @param merkleProof for the wallet address
     *
     */
    function mintStep2(uint256 amountToMint, bytes32[] calldata merkleProof)
        external
        payable
        isWhitelisted(merkleProof)
    {
        require(!paused, "Contract paused");
        require(step_2 && !publicStep, "Wrong step");
        require(
            amountToMint + _numberMinted(msg.sender) <= maxNftByWallet2,
            "Requet too much for a wallet at this stage"
        );

        require(
            amountToMint + totalSupply() <= maxSupply,
            "Request superior max Supply"
        );
        require(msg.value >= price * amountToMint, "Insufficient funds");

        _safeMint(msg.sender, amountToMint);
    }

    /**
     * @dev publicMint
     *
     * Requirements:
     *
     * Contract must be in public mint step
     * The amount of token must be superior to 0
     * The supply must be available
     * The price must be correct
     *
     * @param amountToMint the number of token to mint
     *
     */
    function publicMint(uint256 amountToMint) external payable isAUser {
        require(!paused, "Contract paused");
        require(publicStep, "Wrong step");

        require(
            amountToMint + totalSupply() <= maxSupply,
            "Request superior to max Supply"
        );
        require(msg.value >= price * amountToMint, "Insufficient funds");
        _safeMint(msg.sender, amountToMint);
    }

    /**
     *
     *
     **********ADMIN OPERATIONS*********
     *
     *
     */

    /**
     * @dev Change the `merkleRoot` of the token for `_newMerkleRoot`
     */
    function updateMerleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    /**
     * @dev Change the contract to step 2`
     */
    function setStep2() external onlyOwner {
        step_2 = true;
    }

    /**
     * @dev Change the contract to public step`
     */
    function setPublicStep() external onlyOwner {
        publicStep = true;
    }

    /**
     * @dev Change the `maxNftByWallet1` of the token for `_newMaxNftByWallet`
     */
    function updateMaxByWallet1(uint256 _newMaxNftByWallet) external onlyOwner {
        maxNftByWallet1 = _newMaxNftByWallet;
    }

    /**
     * @dev Change the `maxByWallet2` of the token for `_newMaxNftByWallet`
     */
    function updateMaxByWallet2(uint256 _newMaxNftByWallet) external onlyOwner {
        maxNftByWallet2 = _newMaxNftByWallet;
    }

    /**
     * @dev Change the `price` of the token for `_newPrice`
     */
    function setNewPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    /**
     * @dev Reveal the final URI
     */
    function revealNFT() external onlyOwner {
        require(shuffle == true, "collection hasn't been shuffled");
        revealed = true;
    }

    /**
     * @dev Pause / Unpause the SC
     */
    function switchPause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Allow public burn
     */
    function openPublicBurn() external onlyOwner {
        publicBurnFlag = !publicBurnFlag;
    }

    /**
     * @dev Decrease the supply
     */
    function updateMaxSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply < maxSupply, "You try to increase the suppply. Decrease only is authorized");
        maxSupply = _newSupply;
    }

    /**
     * @dev Give away attribution
     *
     * Requirements:
     *
     * The caller must be the owner
     * The recipient must be different than 0
     * The amount of token requested must be within the reverse
     * The amount requested must be supperior to 0
     *
     */
    function giveAway(address to, uint256 amountToMint) external onlyOwner {
        require(
            amountToMint + totalSupply() <= maxSupply,
            "Request superior max Supply"
        );

        _safeMint(to, amountToMint);
    }

    /**
     * @dev Team withdraw on the `team` wallet
     */
    function withdraw() external onlyOwner {
        require(address(this).balance != 0, "Nothing to withdraw");
        (bool success, ) = team.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    /**
     * @dev Burn token
     */
    function burn(uint256 tokenId) public virtual onlyOwner {
        _burn(tokenId, true);
    }

    /**
     * @dev Burn token public
     */
    function publicBurn(uint256 tokenId) public virtual {
        require(publicBurnFlag, "public burn unauthorized");
        _burn(tokenId, true);
    }

    /**
     * @dev Set the base URI
     *
     * The style MUST BE as follow : "ipfs://QmdsaXXXXXXXXXXXXXXXXXXXX7epJF/"
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Set the hiddenURI just in case
     *
     */
    function setHidden(string memory _newHiddenUri) public onlyOwner {
        hideURI = _newHiddenUri;
    }

    /**
     *
     *
     **********TOKEN DATA*********
     *
     *
     */

    /**
     * @dev Return an array of token Id owned by `owner`
     */
    function getWallet(address _owner) public view returns (uint256[] memory) {
        uint256 ownerBalance = balanceOf(_owner);
        uint256[] memory ownedIds = new uint256[](ownerBalance);
        uint256 tokenIdCounter = 0;
        uint256 index = 0;

        while (index < ownerBalance && tokenIdCounter <= maxSupply) {
            address tokenOwner = ownerOf(tokenIdCounter);
            if (tokenOwner == _owner) {
                ownedIds[index] = tokenIdCounter;
                index++;
            }
            tokenIdCounter++;
        }
        return ownedIds;
    }

    /**
     * @dev ERC721 standardd
     * @return baseURI value
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the URI of the NFT
     * @notice return the hidden URI then the Revealed JSON when the Revealed param is true
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
            return hideURI;
        }
        string memory URI = _baseURI();
        uint256 randomId = ((s_randomWords + tokenId) % maxSupply) + 1;
        return
            bytes(URI).length > 0
                ? string(abi.encodePacked(URI, randomId.toString(), ".json"))
                : "";
    }

    /**
     *
     *
     **********OS*********
     *
     *
     */

    /**
     * @dev Set the proxyAddress
     */
    function setProxyAddress(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }

    /**
     * @dev Override isApprovedForAll
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     *
     *
     **********RANDOM NUMBERS*********
     *
     *
     */

    function requestRandomWords() external onlyOwner {
        require(shuffle == false, "Shuffle already done");
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        shuffle = true;
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = (randomWords[0] % maxSupply) + 1;
    }
}