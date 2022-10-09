/*


                                                                                           


                                                                                                                                                             
                                                                                                    bbbbbbbb                                                 
BBBBBBBBBBBBBBBBB                                tttt          BBBBBBBBBBBBBBBBB                    b::::::b                                                 
B::::::::::::::::B                            ttt:::t          B::::::::::::::::B                   b::::::b                                                 
B::::::BBBBBB:::::B                           t:::::t          B::::::BBBBBB:::::B                  b::::::b                                                 
BB:::::B     B:::::B                          t:::::t          BB:::::B     B:::::B                  b:::::b                                                 
  B::::B     B:::::B    eeeeeeeeeeee    ttttttt:::::ttttttt      B::::B     B:::::B  aaaaaaaaaaaaa   b:::::bbbbbbbbb yyyyyyy           yyyyyyy  ssssssssss   
  B::::B     B:::::B  ee::::::::::::ee  t:::::::::::::::::t      B::::B     B:::::B  a::::::::::::a  b::::::::::::::bby:::::y         y:::::y ss::::::::::s  
  B::::BBBBBB:::::B  e::::::eeeee:::::eet:::::::::::::::::t      B::::BBBBBB:::::B   aaaaaaaaa:::::a b::::::::::::::::by:::::y       y:::::yss:::::::::::::s 
  B:::::::::::::BB  e::::::e     e:::::etttttt:::::::tttttt      B:::::::::::::BB             a::::a b:::::bbbbb:::::::by:::::y     y:::::y s::::::ssss:::::s
  B::::BBBBBB:::::B e:::::::eeeee::::::e      t:::::t            B::::BBBBBB:::::B     aaaaaaa:::::a b:::::b    b::::::b y:::::y   y:::::y   s:::::s  ssssss 
  B::::B     B:::::Be:::::::::::::::::e       t:::::t            B::::B     B:::::B  aa::::::::::::a b:::::b     b:::::b  y:::::y y:::::y      s::::::s      
  B::::B     B:::::Be::::::eeeeeeeeeee        t:::::t            B::::B     B:::::B a::::aaaa::::::a b:::::b     b:::::b   y:::::y:::::y          s::::::s   
  B::::B     B:::::Be:::::::e                 t:::::t    tttttt  B::::B     B:::::Ba::::a    a:::::a b:::::b     b:::::b    y:::::::::y     ssssss   s:::::s 
BB:::::BBBBBB::::::Be::::::::e                t::::::tttt:::::tBB:::::BBBBBB::::::Ba::::a    a:::::a b:::::bbbbbb::::::b     y:::::::y      s:::::ssss::::::s
B:::::::::::::::::B  e::::::::eeeeeeee        tt::::::::::::::tB:::::::::::::::::B a:::::aaaa::::::a b::::::::::::::::b       y:::::y       s::::::::::::::s 
B::::::::::::::::B    ee:::::::::::::e          tt:::::::::::ttB::::::::::::::::B   a::::::::::aa:::ab:::::::::::::::b       y:::::y         s:::::::::::ss  
BBBBBBBBBBBBBBBBB       eeeeeeeeeeeeee            ttttttttttt  BBBBBBBBBBBBBBBBB     aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb       y:::::y           sssssssssss    
                                                                                                                           y:::::y                           
                                                                                                                          y:::::y                            
                                                                                                                         y:::::y                             
                                                                                                                        y:::::y                              
                                                                                                                       yyyyyyy                               
                                                                                                                                                             
                                                                                                                                                             


                                                                                                                                                                              

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "erc721a/contracts/ERC721A.sol";


contract OkayBetBabys is ERC721A, Ownable {
    enum SaleStatus{ PAUSED, PRESALE, PUBLIC }

    uint public constant COLLECTION_SIZE = 5000;
    uint public constant FIRSTXFREE = 3;
    uint public constant TOKENS_PER_TRAN_LIMIT = 20;
    uint public constant TOKENS_PER_PERSON_PUB_LIMIT = 200;
    
    
    uint public MINT_PRICE = 0.001 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    
    string private _baseURL = "ipfs://bafybeihmu6mc3mftxbjnzifjabznq65luzgdabfqnskdymdeqzwpyg3cty";
    
    mapping(address => uint) private _mintedCount;
    

    constructor() ERC721A("Okay BetBabys", "Okay BetBabys"){}
    
    
    
    
    
    
    /// @notice Set base metadata URL
    function setBaseURL(string calldata url) external onlyOwner {
        _baseURL = url;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows owner to mint tokens to a specified address
    function airdrop(address to, uint count) external onlyOwner {
        require(_totalMinted() + count <= COLLECTION_SIZE, "Request exceeds collection size");
        _safeMint(to, count);
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) 
            : "";
    }
    
    function calcTotal(uint count) public view returns(uint) {
        require(saleStatus != SaleStatus.PAUSED, "SpaceCatsClub: Sales are off");

        
        require(msg.sender != address(0));
        uint totalMintedCount = _mintedCount[msg.sender];

        if(FIRSTXFREE > totalMintedCount) {
            uint freeLeft = FIRSTXFREE - totalMintedCount;
            if(count > freeLeft) {
                // just pay the difference
                count -= freeLeft;
            }
            else {
                count = 0;
            }
        }

        
        uint price = MINT_PRICE;

        return count * price;
    }
    
    
    
    /// @notice Mints specified amount of tokens
    /// @param count How many tokens to mint
    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "SpaceCatsClub: Sales are off");
        require(_totalMinted() + count <= COLLECTION_SIZE, "SpaceCatsClub: Number of requested tokens will exceed collection size");
        require(count <= TOKENS_PER_TRAN_LIMIT, "SpaceCatsClub: Number of requested tokens exceeds allowance (20)");
        require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "SpaceCatsClub: Number of requested tokens exceeds allowance (200)");
        require(msg.value >= calcTotal(count), "SpaceCatsClub: Ether value sent is not sufficient");
        _mintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }
}