/** 
██████╗ ███████╗████████╗██████╗  ██████╗      ██████╗ █████╗ ████████╗███████╗    
██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    
██████╔╝█████╗     ██║   ██████╔╝██║   ██║    ██║     ███████║   ██║   ███████╗    
██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║    ██║     ██╔══██║   ██║   ╚════██║    
██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝    ╚██████╗██║  ██║   ██║   ███████║    
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    
                                                                                 

<<https://github.com/retro-cats/retro-cats-contracts>>

           __..--''``---....___   _..._    __
       _.-'    .-/";  `        ``<._  ``.''_ `. / // /
   _.-' _..--.'_    \                    `( ) ) // //
   (_..-' // (< _     ;_..__               ; `' / ///
 //// // //  `-._,_)' // / ``--...____..-' /// / //
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721URIStorage.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";
import "VRFConsumerBase.sol";

contract RetroCats is Ownable, ERC721URIStorage, VRFConsumerBase, ReentrancyGuard {
    using Strings for uint256;

    // ERC721 Variables
    uint256 public s_tokenCounter;
    string internal s_baseURI;

    // Chainlink VRF Variables
    bytes32 internal s_keyHash;
    uint256 public s_fee;
    mapping(bytes32 => uint256) internal s_requestIdToStartingTokenId;
    mapping(bytes32 => uint256) public s_requestIdToAmount;
    mapping(uint256 => uint256) public s_tokenIdToRandomNumber;
    // Retro Cat Randomness Variables
    address public s_retroCatsMetadata;
    uint256 public s_catFee;
    uint256 public s_maxCatMint;
    uint256 public s_maxCatSupply;

    // Events
    event requestedNewCat(uint256 indexed tokenId, uint256 indexed amount, bytes32 indexed requestId);
    event randomNumberAssigned(uint256 indexed tokenId, uint256 indexed randomNumber);

    /**
     * @notice Deploys the retrocats factory contract
     * @param vrfCoordinator The address of the VRF Coordinator
     * The VRF Coordinator does the due dilligence to ensure
     * the number returned is truly random.
     * @param linkToken The address of the Chainlink token
     * @param keyHash Chainlink VRF job key hash
     * @param fee Chainlink VRF fee (in LINK)
     * @param retroCatsMetadata Address of the metadata contract
     * @param catFee Retro cats fee
     * @param maxCatMint The maximum number of cats that can be minted in 1 tx
     */
    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint256 fee,
        address retroCatsMetadata,
        uint256 catFee,
        uint256 maxCatMint
    ) VRFConsumerBase(vrfCoordinator, linkToken) ERC721("Retro Cats", "RETRO") {
        s_tokenCounter = 0;
        s_keyHash = keyHash;
        s_fee = fee;
        s_retroCatsMetadata = retroCatsMetadata;
        s_baseURI = "https://us-central1-retro-cats.cloudfunctions.net/retro-cats-function?token_id=";
        s_catFee = catFee;
        s_maxCatMint = maxCatMint;
        s_maxCatSupply = 10000; // only 10,000 cats!
    }

    //// MINTING ////

    /**
     * @notice Mints a new random cat
     * We use Chainlink VRF to request a random number.
     * That random number is assigned to a cat as its "dna".
     * This is done in the `fulfillRandomness` function.
     */
    function mint_cats(uint256 amount) public payable nonReentrant {
        require(msg.value >= s_catFee * amount, "Cat fee not paid");
        require(s_maxCatMint >= amount, "Max mints exceeded");
        require(amount > 0, "Amount must be > 0");
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK in contract");
        require(s_tokenCounter < s_maxCatSupply, "Max supply reached");
        uint256 tokenId = s_tokenCounter;
        for(uint256 i = tokenId; i < tokenId + amount; i++){
            _safeMint(msg.sender, i);
        }
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);
        s_requestIdToStartingTokenId[requestId] = tokenId;
        s_requestIdToAmount[requestId] = amount;
        emit requestedNewCat(tokenId, amount, requestId);
        s_tokenCounter = s_tokenCounter + amount;
    }

    /**
     * @dev Use by Chainlink VRF to fulfill randomness requests.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 tokenId = s_requestIdToStartingTokenId[requestId];
        uint256 amount = s_requestIdToAmount[requestId];
        for (uint256 i = tokenId; i < tokenId + amount; i++) {
            // Allows us to get many random numbers from just 1
            s_tokenIdToRandomNumber[i] = uint256(keccak256(abi.encode(randomness, i)));
            emit randomNumberAssigned(i, s_tokenIdToRandomNumber[i]);
        }
    }

    //// OWNER WITHDRAWALS ////

    /**
     * @dev withdraw the ETH earned from the contract.
     */
    function withdraw() public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Withdraw the LINK from the contract.
     */
    function withdrawLink() public onlyOwner nonReentrant {
        LinkTokenInterface linkToken = LinkTokenInterface(LINK);
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

    //// OWNER ADMIN ////

    /**
     * @dev For if a user wants to immortalize their cat in IPFS
     */
    function setTokenURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        _setTokenURI(tokenId, newTokenURI);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        s_baseURI = newBaseURI;
    }

    function setRetroCatMetadata(address retroCatMetadata) public onlyOwner {
        s_retroCatsMetadata = retroCatMetadata;
    }

    function setCatFee(uint256 catfee) public onlyOwner {
        s_catFee = catfee;
    }

    function setKeyHash(bytes32 keyHash) public onlyOwner {
        s_keyHash = keyHash;
    }

    function setFee(uint256 fee) public onlyOwner {
        s_fee = fee;
    }

    function setMaxCatMint(uint256 maxCatMint) public onlyOwner {
        s_maxCatMint = maxCatMint;
    }

    //// VIEW FUNCTIONS ////

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseURI;
    }

    /**
     * @dev TokenURI for the NFTs.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}