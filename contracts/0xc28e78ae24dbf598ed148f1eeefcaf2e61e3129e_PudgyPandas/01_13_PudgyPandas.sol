// SPDX-License-Identifier: MIT :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//'########::'##::::'##:'########:::'######:::'##:::'##::::'########:::::'###::::'##::: ##:'########:::::'###::::
// ##.... ##: ##:::: ##: ##.... ##:'##... ##::. ##:'##::::: ##.... ##:::'## ##::: ###:: ##: ##.... ##:::'## ##:::
// ##:::: ##: ##:::: ##: ##:::: ##: ##:::..::::. ####:::::: ##:::: ##::'##:. ##:: ####: ##: ##:::: ##::'##:. ##::
// ########:: ##:::: ##: ##:::: ##: ##::'####:::. ##::::::: ########::'##:::. ##: ## ## ##: ##:::: ##:'##:::. ##:
// ##.....::: ##:::: ##: ##:::: ##: ##::: ##::::: ##::::::: ##.....::: #########: ##. ####: ##:::: ##: #########:
// ##:::::::: ##:::: ##: ##:::: ##: ##::: ##::::: ##::::::: ##:::::::: ##.... ##: ##:. ###: ##:::: ##: ##.... ##:
// ##::::::::. #######:: ########::. ######:::::: ##::::::: ##:::::::: ##:::: ##: ##::. ##: ########:: ##:::: ##:
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//:::::::::::::::::::::::::::::::::^^^^:::::::::::::::::::::^~!~::::::::::^^^::::::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::75B###B5~:::::::::::::::^[email protected]:::::::~5B###B57:::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::~G&&#####@B::::^~!?JJYY555PY7^7&#??777!~^[email protected]#####&&B~:::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::[email protected]&@JY555YJ?7!~~^^:....!?7Y&#YJY55#&&&##[email protected]:::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::!#&####&#GY?!^:..................?&B~....:^!JG#&#&#7:::::::::::::::::::::::::::::::
//:::::::::::::::::::::::::::::^[email protected]#57^........................!J5?.........^?#&!::::::::::::::::::::::::::::::::
//:::::::::::::::::::::::::::::^YBJ^.........             ..................  .?#Y:::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::7#5:........                    ..........        :GG^:::::::::::::::::::::::::::::
//:::::::::::::::::::::::::::J&7........        .:^~7??7~:.      ....   :!J555YJ7!BB^::::::::::::::::::::::::::::
//::::::::::::::::::::::::::J&~........     .~J5GB###&&##BGJ~         !5B&#GB#####[email protected]::::::::::::::::::::::::::::
//:::::::::::::::::::::::::[email protected]    ~YB#######PJJPB&###Y.      ?##B7^??PB&#BB#@!:::::::::::::::::::::::::::
//:::::::::::::::::::::::::PB........   .Y####BBB##! ?J7BB####~      P#&~ JP7#&G&BB#@?:::::::::::::::::::::::::::
//::::::::::::::::::::::::~&?........   5##BBBBBB#B  55G&B#&#P.      ~G&Y :YPGG#&BB#@J:::::::::::::::::::::::::::
//::::::::::::::::::::::::J#:........  :##BBBBBBBB#P~:7J5B&G?.  ..:.:^:7PPJ7J5B#####&&7::::::::::::::::::::::::::
//::::::::::::::::::::::::#Y.........   ?B#########&&B5YJ?^    .::^::^::..^~7J5PGBBGP5GP~::::::::::::::::::::::::
//:::::::::::::::::::::::[email protected]~:.........   :7YPGBBBGPY7~:                         ....   ?#7:::::::::::::::::::::::
//:::::::::::::::::::::::?&:!:.........      .:::.            ~JJ7!!77?JPY.   :.       !#@!::::::::::::::::::::::
//:::::::::::::::::::::::[email protected]?~~.........                :!:    [email protected]@@@@@@@G!  ~J?     .^ [email protected]~::::::::::::::::::::::
//:::::::::::::::::::::::~G#G::..........               ~JJ7^:. :[email protected]^~?J7:      ^~?Y&::::::::::::::::::::::::
//:::::::::::::::::::::::::^#Y~7:^^.......                .^!7???77?Y7!!!^:         ^##@5::::::::::::::::::::::::
//::::::::::::::::::::::::::~GGGB!~:........                                       ~#Y^!:::::::::::::::::::::::::
//::::::::::::::::::::::::::::::?55Y?~:......                         :.       .:~JB?::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::::^~?JYYJ?7!~^:.                 .::~!^::^~7?JYYJ?7^:::::::::::::::::::::::::::::
//:::::::::::::::::::::::::::::::::::::^~!7?JJJJJJ??77777777777??JJJJJJJJ?7!~^^::::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::^^^^~~~~!!!!!!!~~^^^:::::::::::::::::::::::::::::::::::::::::::::
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PudgyPandas is ERC721A, Ownable, ReentrancyGuard {

    mapping (address => uint256) public ListWallet;
    bool public mintStatus  = false;
    uint public MintPrice = 3300000000000000; //0.0033 ETH
    string public baseURI;  
    uint public batchThreeFreeMint = 1;
    uint public batchTwoFreeMint = 2;
    uint public batchOneFreeMint = 3;
    uint public maxMintPerTx = 20;  
    uint public maxSupply = 8888;
    uint public publicSupply = 8800;
    uint public devSupply = 88;
    uint public supplyBatchOne = 5555;
    uint public supplyBatchTwo = 6666;
    uint public supplyBatchThree = 7777;

    constructor() ERC721A("Pudgy Pandas", "Pudgy Pandas",maxMintPerTx,maxSupply){}

    function mint(uint256 qty) external payable
    {
        uint freeMint = FreeMintBatch(totalSupply());
        require(mintStatus , "Pudgy Pandas Minting Pause");
        require(qty <= maxMintPerTx, "Pudgy Pandas Max Per Transaction");
        require(totalSupply() + qty <= publicSupply,"Pudgy Pandas Soldout");
        if(ListWallet[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPrice,"Pudgy Pandas Insufficient Funds");
            ListWallet[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPrice,"Pudgy Pandas Insufficient Funds");
            ListWallet[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function FreeMintBatch(uint qty) public view returns (uint256) {
        if(qty < supplyBatchOne)
        {
            return batchOneFreeMint;
        }
        else if (qty < supplyBatchTwo)
        {
            return batchTwoFreeMint;
        }
        else if (qty < supplyBatchThree)
        {
            return batchThreeFreeMint;
        }
        else
        {
            return 0;
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] calldata listedAirdrop ,uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty);
        }
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setPublicMinting() external onlyOwner {
        mintStatus  = !mintStatus ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        MintPrice = price_;
    }

    function setmaxMintPerTx(uint256 maxMintPerTx_) external onlyOwner {
        maxMintPerTx = maxMintPerTx_;
    }

    function setSupplyBatchFreeMintOne(uint256 qty_) external onlyOwner {
        supplyBatchOne = qty_;
    }
    
    function setSupplyBatchFreeMintTwo(uint256 qty_) external onlyOwner {
        supplyBatchTwo = qty_;
    }

    function setSupplyBatchFreeMintThree(uint256 qty_) external onlyOwner {
        supplyBatchThree = qty_;
    }
    
    function setBatchFreeMintOne(uint256 qty_) external onlyOwner {
        batchOneFreeMint = qty_;
    }

    function setBatchFreeMintTwo(uint256 qty_) external onlyOwner {
        batchTwoFreeMint = qty_;
    }

    function setBatchMintThree(uint256 qty_) external onlyOwner {
        batchThreeFreeMint = qty_;
    }

    function setPublicSupply(uint256 maxMint_) external onlyOwner {
        publicSupply = maxMint_;
    }
    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}