// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "erc721a/contracts/ERC721A.sol";
// import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// DefaultOperatorFilterer,

contract NotDeployedHunter is DefaultOperatorFilterer, ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {

    using Strings for uint256;
    using ECDSA for bytes32;

    /// merkleroot
    bytes32 internal root;
    bytes32 internal ogRoot;
    mapping(address => bool) public usedOgList;
    mapping(address => uint256) public _privateListMintAmount;

    /// IERC721Metadata
    uint256 public maxSupply = 10000;
    string public baseURI;
    uint256 privateMintLimit = 10;

    string private _revealUri;
    string public notRevealedUri = "ipfs://QmYUuwLoiRb8woXwJCCsr1gvbr8E21KuxRtmVBmnH1tZz7/hidden.json";

    uint256 _privatePrice = 1000000000000000; // Fix 0.001ETH 
    uint256 _publicPrice = 1000000000000000; // Fix 0.001ETH
    string public baseExtension = ".json";

    ///nft status
    enum MintState {
        Public,
        Private,
        Paused,
        FreeMint
    }
    MintState public mintState = MintState.Paused;


    ///Team Share
    uint256[] private _teamShares = [90,10]; // Fix Co-founder Split share
    address[] private _team = [
            0xADcE9Ba4523CEaaBAFE47df7020D6a84311d6439, // company
            0x41e535272bb9988f91AE90fEb63319A92FAE45CC  // whitelist2
    ];

    bool public revealed = false;


    /// signature
    mapping(bytes => bool) public usedSignature;
    address public publicMintSigner;


    /// modifier
    modifier isValidMerkleProof (bytes32[] calldata _proof) {
        validMerkleProof(_proof);
        _;
    }

    modifier isOgValidMerkleProof (bytes32[] calldata _proof) {
        validOgMerkleProof(_proof);
        _;
    }

    modifier onlyAccounts () {
        _onlyAccounts();
        _;
    }

    function _onlyAccounts () view private {
        require(msg.sender == tx.origin, "Not allowed origin");
    }

    function validMerkleProof(bytes32[] calldata _proof) view private{
        require(MerkleProof.verify(
      _proof,
      root,
      keccak256(abi.encodePacked(msg.sender))
      ) == true, "Not allowed WL");
    }

    function validOgMerkleProof(bytes32[] calldata _proof) view private{
        require(MerkleProof.verify(
      _proof,
      ogRoot,
      keccak256(abi.encodePacked(msg.sender))
      ) == true, "Not allowed OG");
    }


    constructor (string memory uri, bytes32 wlMerkleroot,bytes32 ogMerkleroot,address _signer) 
        ERC721A("Space","SPACE") PaymentSplitter(_team, _teamShares) ReentrancyGuard()
        {
            root = wlMerkleroot;
            ogRoot = ogMerkleroot;
            setBaseURI(notRevealedUri);
            _revealUri = uri;
            publicMintSigner = _signer;

        }

    
    /// ERC721 Metadata
    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
       return baseURI;
    }

    function reveal() public onlyOwner {
        require(!revealed, "ALREADY REVEALED");
        revealed = true;
        baseURI = _revealUri;
    }


    function setFMMerkleRoot(bytes32 merkleroot) onlyOwner public {
        ogRoot = merkleroot;
    }

    function setWLMerkleRoot(bytes32 merkleroot) onlyOwner public {
        root = merkleroot;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    } 

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"Token is not exist");
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        // uint256 randomTokenId = (tokenId + tokenOffset) z% totalSupply();
        // return bytes(baseURI).length != 0 ? string(abi.encodePacked(currentBaseURI,randomTokenId.toString())) : '';
        return
            bytes(currentBaseURI).length > 0 ? 
                string(abi.encodePacked(
                        currentBaseURI,tokenId.toString(),baseExtension
                    )
                )
                :
                "";
    } 

    /// Function of mint State
    function mintPause() public onlyOwner {
        mintState = MintState.Paused; 
    }

    function mintPrivate() public onlyOwner {
        mintState = MintState.Private;
    }

    function mintPublic() public onlyOwner {
        mintState = MintState.Public;
    }

    function mintFree() public onlyOwner {
        mintState = MintState.FreeMint;
    }
 
    /// minting
    function freeMint(bytes32[] calldata _proof ) 
        external payable onlyAccounts isOgValidMerkleProof(_proof)
        {
            require(mintState == MintState.FreeMint, "Private Sale is closed");
            require(!usedOgList[msg.sender],"You alerady minted.");
            usedOgList[msg.sender] = true;
            _safeMint(msg.sender, 1);
        }

    function privateMint(uint _amount, bytes32[] calldata _proof ) 
        external payable onlyAccounts isValidMerkleProof(_proof)
        {   
            require(mintState == MintState.Private, "Private Sale is closed");
            require(_amount < privateMintLimit + 1, "You can't mint so many token.");
            require(_privateListMintAmount[msg.sender] +_amount < privateMintLimit + 1, "amount exceeded limit.");
            require(totalSupply() + _amount < maxSupply +1, "SHTC's max supply exceeded");
            require(_privatePrice * _amount <= msg.value,"Not enough ethers sent");
            _privateListMintAmount[msg.sender] += _amount;
            _safeMint(msg.sender, _amount);
        }

    function publicMint(uint256 _amount, uint _nonce, bytes memory _signature) 
        external payable onlyAccounts 
        {  
            require(mintState == MintState.Public, "Public Sale is closed");
            require(totalSupply() + _amount < maxSupply +1, "SHTC's max supply exceeded");
            require(_publicPrice * _amount <= msg.value,"Not enough ethers sent");
            verifySignature(_nonce, _signature);
            _safeMint(msg.sender, _amount);
        }


    /// signature
    function verifySignature(uint256 _nonce, bytes memory _signature) internal {
        bytes32 hashedSignature = keccak256(abi.encodePacked(msg.sender, _nonce)).toEthSignedMessageHash();
        require(!usedSignature[_signature],"Used signature");
        require(hashedSignature.recover(_signature) == publicMintSigner, "invalid access");
        usedSignature[_signature] = true;
    }


    ///  opensea function
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}