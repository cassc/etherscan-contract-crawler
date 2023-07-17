// SPDX-License-Identifier: MIT

/*                                                         
        @                                                             @@.       
        @@@                                                        %@@@@.       
        @@@@@                        (@                         /@@@@@@@.       
        @@@@@@@                    *@@@@@                    ,@@@@@@@@@@.       
        @@@@@@@@@#                @@@@@@@@@                @@@@@@@@@@@@@.       
        @@@@@@@@@@@@            @@@@@@@@@@@@@           @@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/          (@@@@.       
           (#########(      @@@@@@@@@@@@@@@@@@@@@@@      ,########.             
       ###################(    @@@@@@@@@@@@@@@@@    ####################        
    (################,  #####,   @@@@@@@@@@@@@   ,############   ##########     
    ,################,  #######.  *@@@@@@@@@@   ##############   ############   
      (##############,  #########   @@@@@@@@  .###############   ###########    
         ############*..#########   /@@@@@@@&    #############...########       
             ###############*     @@@@@@@@@@@@@%     ################           
        @@@@                 ,@@@@@@@@@@@@@@@@@@@@@&                  @@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     %@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@   ###   @@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@   #######   @@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@                ,@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DarenMonster is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    string private _baseURIextended;

    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public constant MAX_OG_COUNT = 25;
    uint256 public constant MAX_WL1_COUNT = 50;
    uint256 public constant MAX_WL2_COUNT = 788;
    uint256 public constant MAX_SALE_COUNT = 112;

    uint256 public constant OG_LIMIT = 2;
    uint256 public constant WL1_LIMIT = 1;
    uint256 public constant WL2_LIMIT = 1;

    mapping(address => uint256) private ogMinted;
    mapping(address => uint256) private wl1Minted;
    mapping(address => uint256) private wl2Minted;

    Counters.Counter private _ogCount;
    Counters.Counter private _wl1Count;
    Counters.Counter private _wl2Count;
    Counters.Counter private _saleCount;

    bytes32 private ogRoot;
    bytes32 private wl1Root;
    bytes32 private wl2Root;

    bool private _ogSaleActive;
    bool private _wl1SaleActive;
    bool private _wl2SaleActive;
    bool private _saleActive;

    uint256 private _mintPrice;

    constructor(
        bytes32 _ogRoot,
        bytes32 _wl1Root,
        bytes32 _wl2oot
    ) ERC721("Daren Monster", "DM") {
        ogRoot = _ogRoot;
        wl1Root = _wl1Root;
        wl2Root = _wl2oot;

        _ogSaleActive = false;
        _wl1SaleActive = false;
        _wl2SaleActive = false;
        _saleActive = false;

        _mintPrice = 0.5 ether;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function verifyOG(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, amount)))
        );
        require(MerkleProof.verify(proof, ogRoot, leaf), "Invalid proof");
    }

    function verifyWL1(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, amount)))
        );
        require(MerkleProof.verify(proof, wl1Root, leaf), "Invalid proof");
    }

    function verifyWL2(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, amount)))
        );
        require(MerkleProof.verify(proof, wl2Root, leaf), "Invalid proof");
    }

    // Mint functions
    function mintOG(bytes32[] memory proof) public {
        require(_ogSaleActive, "OG sale is not active");
        require(
            ogMinted[msg.sender] + OG_LIMIT <= OG_LIMIT,
            "Purchase would exceed OG limit"
        );
        require(
            _ogCount.current() < MAX_OG_COUNT,
            "Purchase would exceed max OG supply"
        );
        uint256 ts = totalSupply();
        require(
            ts + OG_LIMIT <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        verifyOG(proof, msg.sender, OG_LIMIT);
        for (uint256 i = 0; i < OG_LIMIT; i++) {
            _safeMint(msg.sender, ts + i + 1);
            ogMinted[msg.sender] += 1;
        }
        _ogCount.increment();
    }

    function mintWL1(bytes32[] memory proof) public {
        require(_wl1SaleActive, "WL1 sale is not active");
        require(
            wl1Minted[msg.sender] + WL1_LIMIT <= WL1_LIMIT,
            "Purchase would exceed WL1 limit"
        );
        require(
            _wl1Count.current() < MAX_WL1_COUNT,
            "Purchase would exceed max WL1 supply"
        );
        uint256 ts = totalSupply();
        require(
            ts + WL1_LIMIT <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        verifyWL1(proof, msg.sender, WL1_LIMIT);
        _safeMint(msg.sender, ts + 1);
        wl1Minted[msg.sender] += 1;
        _wl1Count.increment();
    }

    function mintWL2(bytes32[] memory proof) public {
        require(_wl2SaleActive, "WL2 sale is not active");
        require(
            wl2Minted[msg.sender] + WL2_LIMIT <= WL2_LIMIT,
            "Purchase would exceed WL2 limit"
        );
        require(
            _wl2Count.current() < MAX_WL2_COUNT,
            "Purchase would exceed max WL2 supply"
        );
        uint256 ts = totalSupply();
        require(
            ts + WL2_LIMIT <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        verifyWL2(proof, msg.sender, WL2_LIMIT);
        _safeMint(msg.sender, ts + 1);
        wl2Minted[msg.sender] += 1;
        _wl2Count.increment();
    }

    function mint() public payable {
        require(_saleActive, "Sale is not active");
        require(
            _saleCount.current() < MAX_SALE_COUNT,
            "Purchase would exceed max sale supply"
        );
        require(msg.value >= _mintPrice, "Insufficient funds to mint");
        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max supply");
        _safeMint(msg.sender, ts + 1);
        _saleCount.increment();
    }

    function reserve(uint32 num) public onlyOwner {
        require(num <= 10, "Purchase limit of 10");
        uint256 ts = totalSupply();
        require(ts + num <= MAX_SUPPLY, "Purchase would exceed max supply");
        for (uint32 i = 0; i < num; i++) {
            _safeMint(msg.sender, ts + i + 1);
        }
    }

    // Set functions
    function setOGRoot(bytes32 root) public onlyOwner {
        ogRoot = root;
    }

    function setWL1Root(bytes32 root) public onlyOwner {
        wl1Root = root;
    }

    function setWL2Root(bytes32 root) public onlyOwner {
        wl2Root = root;
    }

    // Set sales
    function setOGSaleStatus(bool active) public onlyOwner {
        _ogSaleActive = active;
    }

    function setWL1SaleStatus(bool active) public onlyOwner {
        _wl1SaleActive = active;
    }

    function setWL2SaleStatus(bool active) public onlyOwner {
        _wl2SaleActive = active;
    }

    function setSaleStatus(bool active) public onlyOwner {
        _saleActive = active;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}