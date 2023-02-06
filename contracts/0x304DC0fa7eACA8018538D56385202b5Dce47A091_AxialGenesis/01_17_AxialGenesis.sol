// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?!~~~~~~7JYPBBGPPGGGG5J!~~~~~~!!!7?YYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJ???PGGPPPPGBBGY?!!~~!!!~~~~!?JYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJYPGPJ5PGGPPPB###BGPY5GBGPYJJY5Y?!~~~7JYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?JYGBPYGB555G#####B5JYYP#BGGPPYY5J7!!~~~~!7?JYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYJJJ???7??JY55GBBBBGBGPPPGGPG##G5YYG####BG5G#BGGGP5J7!~~~!77???JJJJYYYYYYYYY
YYYYYYYYYYYYYYYYYYYJ??7!~~~^~~~!!!~^:^!?Y55YY55PPGGPPGB##BBB#####G5PB####P5GBP5?7!~~~~~~~!!77JYYYYYY
YYYYYYYYYYYYYYYYYJ?^:^:::::::!P##BBP?^^~?Y7~^^!7?JY5PGGGGG555G#BPJJJG##BB5J5BB#BGPYJ!~~!~~~!?JYYYYYY
YYYYYYYYYYYYYYYYYJ7:::::.::^?G#####&BY5PY^.^^^:::^~!?JYPGGGGPGB#BGPBBPYPPJJPBPPBBBGY!!!~!7JYYYYYYYYY
YYYYYYYYYYYYYYYYJ?^^:::::^7P#######BG#BY^.^~?P5J7~:::^!?JYPGGGGGB##GGPB##GYYBBPPBBB?~!!~7YYYYYYYYYYY
YYYYYYYYYYYYYYYYJ!:^...:7P########BJ?55^.:~?B###BPY?!:::~7?JYPGGGBG5B####BBB###GGGP?~!!~7JYYYYYYYYYY
YYYYYYYYYYYYYYYY?:^:.^?P##########Y7Y5~.^~Y#####&&##G5?7~^!???YGGGBGGB###YP#BGB#PP7!!!!!~!7JYYYYYYYY
YYYYYYYYYYYYYYYJ!!!?YB#######&###57JJJ~~!P###BBBB######BGY?????5GGGBGGGBGJJGPJJGBPPP5J7!~~~~!7JYYYYY
YYYYYYYYYYYYYYJ7YG####BBBGGGP5YJ?7??7JG5YPPPPPPPPPPPPGGBB#BP???JGGGGGGGPP5PG#PJPB?GGY7!!777??JYYYYYY
YYYYYYYYYYYYYYYJ7????JYYJ??JJJJJJJY5J7?YPGPPPPPPPPPPPPPPPPG5??JPGGGGGGGGPG####B#G5G?~~~!?JYYYYYYYYYY
YYYYYYYYYYYYYYYYYJ?7?5GGP5555P55555555YJ??Y5PPPPPPPPPPPPPP5J?JBGGGGGGGGGGPG#GPB5YBGJ7!!~~!7?JYYYYYYY
YYYYYYYYYYYYYYYYJ?!!J5GPPPPP55555555555P5YJ???Y5PPPPPPPPPPBBPB#GGGBGGGGGGGPGYJ5J5GG5?!!~~~~!?YYYYYYY
YYYYYYYYYYYYYYJ?!~7YYYP5PPPGG5J???????JJY5555YJ?JY55PPPP5#&#B##BGGGBBGBBGGGPPYY?777!~~~!7?JYYYYYYYYY
YYYYYYYYYYYYYYJ7!7YJJJYYPP555PGJ7777777777?JYY555YJJJJJ?JPG#B#BGGGGBBBGBBGBGGGJ!~~~~!~!JYYYYYYYYYYYY
YYYYYYYYYYYYYYYJ7?JJYJJYP#BBP55Y77777777777?????JY555YJ??5B#B#GGGGGGBGGGBBGGBP!~!7!~~~~?YYYYYYYYYYYY
YYYYYYYYYYYYYYYYJYYYYYJJ5BGPBG55?7777777?YPPGPP5YJ??JYPY5B&&#BGGGGGGBBGGGBBBGJ~~7YYJ7!~7YYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYJ?Y!^!YPJ?7777777???JYJ??????7?YYP5B&&#BGGGGBGGBBGGBGJ!~~7YYYYYJ?YYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYJ77!:.^7!777777777?YPPP5YY?77?Y5PY?5#&&#BGGGGGBBBBPGJ~~~~7YYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYY?~7?7~:^7J7777777?55YYY5PPPG5Y55Y77YBB#&&BGGBGBBBGGY!~~!?YYYYYYYYYYYYYYYYYYYY
55YYYYYYYYYYYYYYYYYYYYJ7~77??7!7777777777~~~~~??~!?G5GY77?PBGPPPY55GBBBG5?!~~!JYYYYYYYYYYYYYYYYYYYYY
5555YYYYYYYYYYYYYYYYYJJ!!777?Y5Y?77777777^:...~7????YJ77775GJ77?JP55PBG57~~~~?YYYYYYYYYYYYYYYYYYYYYY
55555YYYYYYYYYYYYYYYYJJ7~7777?J?77777777777!~^^^!J??777777J?7JY??JJ?5PP?!~~~?YYYYYYYYYYYYYYYYYYYYYYY
555YYY5Y5YYYYYYYYYYYYYJJ!~777??77777777777777777??7777777777?5Y???!~!~7YJ!7JYYYYYYYYYYYYYYYYYYYYYYYY
555555YYY5555YYYYYYYYYYYY7~7777777777777777777777777777777?7???J?~~~~!?YYYYYYYYYYYYYYYYYYYYYYYYYYYYY
55555555YYYY5Y5YYYYYYYYYYY?!77????777777777777777777777777!^^:~7!!!7JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
55555555555YYYYYYYYYYYYYYYYY?77????77777777777777777?YJJ7?^~^:~!!~7JJJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
555555555555555YYYYYYYYYYYYYYJ?7777777777777777??J5PGPP5?J????7!!~~~!!7YYYYYYYYYYYYYYYYYYYYYYYYYYYYY
5555555555555555YYYYYYYYYYYYYYYJ??7777???JJY5PBB##GP555?7?G###BPY?!!!!~!JYYYYYYYYYYYYYYYYYYYYYYYYYYY
55555555555555555555YYY55YJ??7?JGBGGGGGGB##&&&&#GP55PY?7?Y5GGB#BBPJ!!!!~?YYYYYYYYYYYYYYYYYYYYYYYYYYY
5555555555555555555555555J!7?YP#&&&##BGGPPG##BP5555PY?77?JJJ5PGBBB5J!!!!!777?YYYYYYYYYYYYYYYYYYYYYYY
55555555555555555555555Y?77~P&&&&&#BGPGBG55PP55555PY777777?YGPPBB#B5J77!!~~~~?YYYYYYYYYYYYYYYYYYYYYY
5555555555555555555555Y?75G5G#&&&#BGGBBB#GP5555555Y77?JY5GBBBPGB#####BBPJ!!!!!?YYYYYYYYYYYYYYYYYYYYY
55555555555555555555555Y?YB####&BGPGBB####BGPPPPGGPPGBB####BGPB#########B?~!!!JYYYYYYYYYYYYYYYYYYYYY
555555555555555555555555?7P####P5P########################BPGB###########5!!!!YYYYYYYYYYYYYYYYYYYYYY
5555555555555555555555Y?7Y5G##5YPB#&###################BBGPB##############P!!!7JYYYYYYYYYYYYYYYYYYYY
555555555555555555555Y7755P##PYPP####################BGGGB#################5!!!!7?YYYYYYYYYYYYYYYYYY
55555555555555555555Y775G5B#GJ555B#################GGGB#####################Y7!!!~7Y5YYYYYYYYYYYYYYY
5555555555555555555Y?!Y#G5B#5JP5PB#############&#GPGB########################B57!!!7YYYYYYYYYYYYYYYY
55555555555555555555J?G&#GGBYJ55G#######&&&###BPPGB############################P?!!!!7Y5YYYYYYYYYYYY
55555555555555555555??G&&B5YYJYJ5Y?G########BPPB#########BBGB########&#########BJ7!!!!?Y555YYYYYYYYY
5555555555555555555J7JB&&G5YY?7~!~~G######GPPPPP5YJJ?7?GJ~^^J######&&&##&##&&##5J7!!!!~?555555YYYYYY
55555555555555555Y??5B&&#PYY5YJJJ?YPP55P5JJP7^:::::::!G5^:::J#####&&&##&&######GJ7!!!!!!J55555555Y55
5555555555555555Y?75#&&&B5YYP5YYYYJ777~^::JY^::::::^JBB7::::Y#####&&#&&#########5J?!!!!!7Y5555555555
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AxialGenesis is
    ERC721,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    bytes32 public freeRoot;

    address proxyRegistryAddress;

    uint256 public maxSupply = 555;

    string public baseURI;
    string public notRevealedUri = "ipfs://Qmbth1DdxejM5qwCLrr7mPXmWPV4qdEzPCU2fB3kSmuccn/hidden.json";
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = false;
    bool public freesaleM = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 freeAmountLimit = 2;
    uint256 presaleAmountLimit = 1;
    mapping(address => uint256) public _freeClaimed;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 10000000000000000; // 0.01 ETH
    uint256 _freePrice = 0; // 0 ETH
    uint256 _preSalePrice = 0; // 0 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [100];
    address[] private _team = [
        0x9a32F450219133B5Fab058b7722450B422b9D837 // Deployer Account gets 100% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, bytes32 freeMerkleRoot, address _proxyRegistryAddress)
        ERC721("AxialGenesis", "AXIAL")
        PaymentSplitter(_team, _teamShares)
        ReentrancyGuard()
    {
        root = merkleroot;
        freeRoot = freeMerkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
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

    function setFreeMerkleRoot(bytes32 freeMerkleRoot)
    onlyOwner
    public
    {
        freeRoot = freeMerkleRoot;
    }

    function setMerkleRoot(bytes32 merkleroot)
    onlyOwner
    public
    {
        root = merkleroot;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
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

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function toggleFreeSale() public onlyOwner {
        freesaleM = !freesaleM;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function freeSaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidFreeMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "AxialGenesis: Not allowed");
        require(freesaleM,                       "AxialGenesis: OG Mint is OFF");
        require(!paused,                        "AxialGenesis: Contract is paused");
        require(
            _amount <= freeAmountLimit,      "AxialGenesis: You can not mint so much tokens");
        require(
            _freeClaimed[msg.sender] + _amount <= freeAmountLimit,  "AxialGenesis: Only 2 Free Mints per OG");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "AxialGenesis: max supply exceeded"
        );
        require(
            _freePrice * _amount <= msg.value,
            "AxialGenesis: Not enough ethers sent"
        );

        _freeClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function preSaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "AxialGenesis: Not allowed");
        require(presaleM,                       "AxialGenesis: WL Mint is OFF");
        require(!paused,                        "AxialGenesis: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "AxialGenesis: You can not mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "AxialGenesis: You can not mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "AxialGenesis: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "AxialGenesis: Not enough ethers sent"
        );

        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(publicM, "AxialGenesis: Public Mint is OFF");
        require(!paused, "AxialGenesis: Contract is paused");
        require(_amount > 0, "AxialGenesis: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "AxialGenesis: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "AxialGenesis: Not enough ethers sent"
        );


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
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
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