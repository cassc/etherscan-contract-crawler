pragma solidity ^0.6.6;
/**
 * @title Uggliz Cryptopians contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


 contract GalacticSecretAgency is ERC721, Ownable {
     using SafeMath for uint256;

     uint256 public STARTING_INDEX;
     uint256 public STARTING_INDEX_BLOCK;
     uint256 public MAX_ALIENS;
     uint256 public constant ALIEN_PRICE = 60000000000000000; //0.06 ETH
     uint256 public REVEAL_TIMESTAMP;
     uint public constant MAX_ALIENT_MINT_TX = 20;
     string public GSA_PROVENANCE = "";
     bool public SALE_IS_ACTIVE = false;
     bool public ALIENS_RESERVED = false;


       constructor(string memory name, string memory symbol, string memory baseURI, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) public {
        _setBaseURI(baseURI);
        MAX_ALIENS = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 9);
    }


    function mintAlien(uint256 numberOfAliensMint) external payable {
        require(SALE_IS_ACTIVE, "Sale must be active to mint Cryptopians");
        require(numberOfAliensMint <= MAX_ALIENT_MINT_TX, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfAliensMint) <= MAX_ALIENS, "Purchase would exceed max supply of Cryptopians");
        require(ALIEN_PRICE.mul(numberOfAliensMint) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfAliensMint; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_ALIENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (STARTING_INDEX_BLOCK == 0 && (totalSupply() == MAX_ALIENS || block.timestamp >= REVEAL_TIMESTAMP)) {
            STARTING_INDEX_BLOCK = block.number;
        } 
    }


    function setStartingIndex() public {
        require(STARTING_INDEX == 0, "Starting index is already set");
        require(STARTING_INDEX_BLOCK != 0, "Starting index block must be set");
        
        STARTING_INDEX = uint(blockhash(STARTING_INDEX_BLOCK)) % MAX_ALIENS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(STARTING_INDEX_BLOCK) > 255) {
            STARTING_INDEX = uint(blockhash(block.number - 1)) % MAX_ALIENS;
        }
        // Prevent default sequence
        if (STARTING_INDEX == 0) {
            STARTING_INDEX = STARTING_INDEX.add(1);
        }
    }
    


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function reserveAliens() public onlyOwner {  
           require(ALIENS_RESERVED == false, "Aliens already reserved");  
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 100; i++) {
            _safeMint(msg.sender, supply + i);
        }
        ALIENS_RESERVED = true;
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GSA_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner returns (bool saleStatus)  {
        SALE_IS_ACTIVE = !SALE_IS_ACTIVE;
        return SALE_IS_ACTIVE;
    }

    function getSaleState() public view returns (bool saleStatus) {
        return SALE_IS_ACTIVE;  
    }


    function emergencySetStartingIndexBlock() public onlyOwner {
        require(STARTING_INDEX == 0, "Starting index is already set");
        STARTING_INDEX_BLOCK = block.number;
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
          _setTokenURI(tokenId, _tokenURI);
    }


    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }
 }