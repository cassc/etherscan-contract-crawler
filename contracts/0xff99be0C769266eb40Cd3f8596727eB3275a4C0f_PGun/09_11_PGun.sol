pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./interfaces/ISignerVerification.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


error Not_Verified();

contract PGun is ERC721A, Ownable {

    using Strings for string;

    IERC721 public coreCollection;

    ISignerVerification public signer_verification;

    string public s_baseURI = "https://ipfs.io/ipfs/bafybeifs5m3bh2zqkffcytofabsdr3pmzwo3wr64xsa6oejpm35jcpocey/metadata/";

    address public s_signer;

    mapping (uint256 => NFT) public s_idToNFT;

    mapping(address => uint256) public s_userToNonce;

    uint256 MAX_SUPPLY = 7000;


    struct NFT {
        uint256 id;
        uint256 level;
        uint256 pointsToUpgrade;
    }

    event Upgraded(uint256 tokenId, address owner, uint256 level);
    
    constructor(
        address _coreCollection,
        address _signerVerification
        )
        ERC721A("PGun", "PGun")
        public
    {
        coreCollection = IERC721(_coreCollection);
        s_signer = msg.sender;
        signer_verification = ISignerVerification(_signerVerification);
    }

    function mintNFT(uint256 amount) public {

        require(_totalMinted() + amount <= MAX_SUPPLY, "Max supply is 7000");

        uint256 senderBalanceOfCoreCollection = coreCollection.balanceOf(msg.sender);
        
        uint256 senderBalanceOfGunsCollection = balanceOf(msg.sender);

        require(senderBalanceOfCoreCollection > senderBalanceOfGunsCollection, "You don't have nft from core collection");

        _mint(msg.sender, amount);
    }
    

    function upgradeNFT(uint256 tokenId, uint256 points, bytes memory signature) external {

        require(ownerOf(tokenId) == msg.sender, "Not owner");

        uint256 userNonce = s_userToNonce[msg.sender];

        string memory concatenatedParams = signer_verification.concatParams(points, msg.sender, userNonce);

        bool isVerified = signer_verification.isMessageVerified(s_signer, signature, concatenatedParams);

        if(!isVerified){
            revert Not_Verified();
        }

        NFT memory userNft = s_idToNFT[tokenId];

        uint256 currentLevel = userNft.level == 0 ? 1 : userNft.level;

        uint256 pointsToUpgrade = userNft.level == 0 ? 1000 : userNft.pointsToUpgrade;

        require(points >= pointsToUpgrade, "Insufficient points");

        require(userNft.level < 99, "You archived the highest level");

        userNft.level = currentLevel + 1;

        userNft.pointsToUpgrade = pointsToUpgrade * 2;

        s_userToNonce[msg.sender] = userNonce + 1;

        s_idToNFT[tokenId] = userNft;

        emit Upgraded(userNft.id, msg.sender, userNft.level);
    }


    function setSinger(address _newSigner) external onlyOwner {
        s_signer = _newSigner;
    }

    function setSingerVerification(address _newSignerVerification) external onlyOwner {
        signer_verification = ISignerVerification(_newSignerVerification);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return s_baseURI;
    } 

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        return string(abi.encodePacked(s_baseURI,Strings.toString(tokenId), '.json'));      
  }

    function withdraw() public onlyOwner {
		uint256 value = address(this).balance;
       bool sent = payable(owner()).send(value);
       require(sent, 'Error during withdraw transfer');
	}

    function setBaseURI(string calldata baseURI) external onlyOwner {
       s_baseURI = baseURI;
    }
}