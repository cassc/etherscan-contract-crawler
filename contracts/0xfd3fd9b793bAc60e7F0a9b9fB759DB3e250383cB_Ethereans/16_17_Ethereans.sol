// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./mock/IRNG.sol";


/**
 * @title Ethereans ERC721 Smart Contract
 * punks are #1
 */



contract Ethereans is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings  for uint256;

    bytes32 public ETHEREANS_PROVENANCE;
    uint256 public ethereanTokenPrice = 80000000000000000; // 0.08 ETH
    uint256 public earlyAccessPrice   = 72000000000000000; // 0.9 * 0.08 ETH
    uint    public maxEthereansPurchase = 20;
    uint    public constant reservedEthereans = 20;
    uint256 public constant maxEthereans = 11000;
    bool    public mintIsActive = false;
    bool    public earlyIsActive = false;
    bytes32 public rqh;

    string  public loeuf = "https://www.lexico.com/definition/etherean";

    IERC721                   public EtherCards = IERC721(0x97CA7FE0b0288f5EB85F386FeD876618FB9b8Ab8);
    IRNG                      public iRnd       = IRNG(0x72170F577F3B221b3478E09ccD5323445a8460d7);
    address                   public presigner  = 0x74F5966b7fb22271E53c9C22BE4aBdbeb24Db364;
    mapping(address => uint)  public cardsTaken; // ether cards holders who have claimed
    uint256                   public earlyMinted;
    uint256                   public ECAllocation;
    uint256                   public CommunityAllocation;
    uint256                          rand;

    uint256                   public constant earlyAllocation = 2000;


    constructor( address _presigner) ERC721("Ethereans", "ETHRS") {
        presigner = _presigner;
        _setBaseURI("ipfs://QmPr59FJjW25ZbWfo7uggKeFaiVxy2EcG8EiiRusk6BVHC/");
    }

    // TEST FUNCTIONS
    function setRng(IRNG rnd) external onlyOwner {
        iRnd = rnd;
    }
    function setEC(IERC721 ec) external onlyOwner {
        EtherCards = ec;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

   function reserveEthereans() public onlyOwner {
        uint mintIndex = super.totalSupply();
        uint i;
        for (i = 0; i < reservedEthereans; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipEarlyState() public onlyOwner {
        earlyIsActive = !earlyIsActive;
    }


    function setTokenPrice(uint256 tokenPrice) public onlyOwner {
        ethereanTokenPrice = tokenPrice;
    }

    function setMaxPurchase(uint256 maxPurchase) public onlyOwner {
        require(maxPurchase > 0, "Max purchase amount has to be greater than 1.");
        maxEthereansPurchase = maxPurchase;
    }

    function getHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    // base URI must end with a '/'
    function setBaseURI(string memory _baseURI) public onlyOwner {
        require(getHash(_baseURI)== ETHEREANS_PROVENANCE, "Invalid BaseURI");
        bytes memory ba = bytes(_baseURI);
        require(ba[ba.length -1] == '/',"BaseURI must end with a '/'");
        _setBaseURI(_baseURI);
        rqh = iRnd.requestRandomNumberWithCallback();
    }

    function setProvenanceHash(bytes32 provenanceHash) public onlyOwner {
        require((ETHEREANS_PROVENANCE == bytes32(0)),"Hash already set");
        ETHEREANS_PROVENANCE = provenanceHash;
    }

    function mintEthereans(uint numberOfTokens) public payable {
        require((ETHEREANS_PROVENANCE != bytes32(0)),"Hash not set");
        require(mintIsActive, "Mint is not active.");
        require(numberOfTokens <= maxEthereansPurchase, "You went over max Ethereans per transaction.");
        uint mintIndex = super.totalSupply();
        require(mintIndex.add(numberOfTokens) <= maxEthereans, "Not enough remaining Ethereans to mint.");
        require(ethereanTokenPrice.mul(numberOfTokens) <= msg.value, "You sent the incorrect amount of ETH.");
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, mintIndex+i);
        }
    }

    function mintEarly(uint n) internal  {
        
        require(earlyIsActive,"Early Access is not active");
        require(cardsTaken[msg.sender]+n < 3,"You have a MAXX of two Ethereans. Even then it is risky");
        require(msg.value >= n * earlyAccessPrice,"Insufficent payment made");
        uint mintIndex = super.totalSupply();
        require(mintIndex < maxEthereans, "No remaining Ethereans available");
        cardsTaken[msg.sender] += n;
        _safeMint(msg.sender, mintIndex);
        if (n == 2) {
            _safeMint(msg.sender, mintIndex + 1);
        }
    }


    function earlyAccessByCard(uint n) public payable {
        require(n == 1 || n == 2, "One or Two none else will do");
        require(EtherCards.balanceOf(msg.sender) > 0, "You are not an EC holder");
        require(ECAllocation + n <= earlyAllocation,"Ether Cards Quota already reached");
        ECAllocation += n;
        mintEarly(n);
    }

    function earlyAccessBySignature(uint n, bytes memory signature) public payable {
        require(n == 1 || n == 2, "One or Two none else will do");
        require(verify(msg.sender,signature) ,"Unauthorised");
        require(CommunityAllocation + n  <= earlyAllocation,"Community Quota already reached");
        CommunityAllocation += n;
        mintEarly(n);
    }

    function verify(
        address signer,
        bytes memory signature
    ) internal  view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        bytes32 hash = keccak256(abi.encode(signer));
        require (signature.length == 65,"Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8   sigV;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }
        
        bytes32 data =  keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(
                data,
                sigV,
                sigR,
                sigS
            );
            
        return
            presigner == recovered;
    }

    function process(uint256 _rand, bytes32) external {
        require(msg.sender == address(iRnd),"Unauthorised RNG");
        rand = _rand;
    }


    // --- recovery of tokens sent to this address

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    function randomisedOffset(uint tokenId, uint _rand) public view returns (uint256) {
        if (tokenId < reservedEthereans) {
            return tokenId;
        }
        uint normal_tokenId = tokenId - reservedEthereans;
        uint normal_supply = totalSupply() - reservedEthereans;
        uint new_normal = (normal_tokenId + _rand) % normal_supply;

        return new_normal + reservedEthereans;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint _tokenId = randomisedOffset(tokenId,rand);
        return string(abi.encodePacked(baseURI(), _tokenId.toString()));
    }

}