// SPDX-License-Identifier: MIT
/*

██████╗ ███████╗ ██████╗ ███████╗███╗   ██╗██╗  ██╗ ██████╗ 
██╔══██╗██╔════╝██╔════╝ ██╔════╝████╗  ██║██║  ██║██╔═══██╗
██║  ██║█████╗  ██║  ███╗█████╗  ██╔██╗ ██║███████║██║   ██║
██║  ██║██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║██╔══██║██║▄▄ ██║
██████╔╝███████╗╚██████╔╝███████╗██║ ╚████║██║  ██║╚██████╔╝
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚══▀▀═╝ 
                                                            

*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DegenHQ is
    ERC721,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    bytes32 public freeRoot;


    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    uint256 public maxSupply = 1000;

    string public baseURI;
    string public notRevealedUri = "ipfs://QmRfX4r9MMXvho6jYCbbrSR7zbcEp1J4BZK6Hzyiag8YKZ/0";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public freesaleM = true;

    uint256 presaleAmountLimit = 5;
    uint256 freeAmountLimit = 25;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _freeClaimed;
    

    uint256 _price = 50000000000000000; // 0.05 ETH
    uint _freePrice = 0;

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [40, 10, 10, 10, 10, 20]; 
    address[] private _team = [
        0x62ce1D739B9Bc6AB5F716A772eA585425d3843b1, // 40% to DegenHQ
        0x4336bcd7D003ccCc0a3b7B981945FF51fF287A19, // 10%
        0x591AEA83f526922e20c5802f57df1bB557ed47AA, // 10%
        0x248B6D850E340ca36Ed4D507c0c6139b54C88c55, // 10%
        0xEdCec06fBeD4dA616193E585F4f57DD33bD4dc7D, // 10%
        0x3E7Cd0E0C86892A064d0E7721E567ffC4D2cD915 // 20%
    ];

    constructor()
        ERC721("DegenHQ", "DEGENALPHA")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {

    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot)
    onlyOwner
    public
    {
        root = merkleroot;
    }

    function setFreeMerkleRoot(bytes32 freeMerkleRoot)
    onlyOwner
    public
    {
        freeRoot = freeMerkleRoot;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

     modifier isValidFreeMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            freeRoot,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function toggleFreeSale() public onlyOwner {
        freesaleM = !freesaleM;
    }



    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "DegenHQ: Not allowed");
        require(presaleM,                       "DegenHQ: Presale is OFF");
        require(!paused,                        "DegenHQ: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "DegenHQ: You can not mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "DegenHQ: You can not mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "DegenHQ: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "DegenHQ: Not enough ethers sent"
        );

        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function freeMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidFreeMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "DegenHQ: Not allowed");
        require(!paused,                        "DegenHQ: Contract is paused");
        require(freesaleM,                       "DegenHQ: Presale is OFF");
        require(
            _amount <= freeAmountLimit,      "DegenHQ: You can not mint so much tokens");
        require(
            _freeClaimed[msg.sender] + _amount <= freeAmountLimit,  "DegenHQ: Only 25 for DegenHQ");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "DegenHQ: max supply exceeded"
        );
        require(
            _freePrice * _amount <= msg.value,
            "DegenHQ: Not enough ethers sent"
        );

        _freeClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(publicM, "DegenHQ: PublicSale is OFF");
        require(!paused, "DegenHQ: Contract is paused");
        require(_amount > 0, "DegenHQ: zero amount");
        require(
            _amount <= presaleAmountLimit,      "DegenHQ: You can not mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "DegenHQ: You can not mint so much tokens");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "DegenHQ: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "DegenHQ: Not enough ethers sent"
        );

        _presaleClaimed[msg.sender] += _amount;


        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
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
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

        function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}