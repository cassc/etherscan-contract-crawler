// SPDX-License-Identifier: MIT
//
//
//                       @@@@@@@@@                                               %@@@@@#                           
//                      @@@/.....%@@@@#                                      &@@@@%**@@@@                          
//                     @@@*..........&@@@@                               %@@@@/.......,@@@                         
//                     @@@..............*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@............%@@#                        
//                    @@@...................* ////*...//////...///#@@@@ [email protected]@@                        
//                    @@@...................,/////*...//////...//////,..................&@@#                       
//                   %@@/...................,/////*...//////...//////,[email protected]@@                       
//                   @@@,...................,/////*...//////...//////[email protected]@@                       
//                   @@@,.....................*/*.....//////....////*....................#@@&                      
//                   @@@,............................./////,.............................,@@@                      
//                  @@@@...[email protected]@@                      
//           @@@@#@@@@.....[email protected]@@@   &@@@@@@           
//           #@@****@@@@@%............................................................../@@@@@ ,,**/@@             
//              @@@******,,, @@@@&*............................................,%@@@@&*,,,,,*****@@#               
//             @@@& @@**********,,,,*%@@@@/............................,%@@@@#,,,,,,,*********@@@                  
//            #@@@//// @@****************,,,,*@@@@%............,@@@@&*,,,,,,***************@@#@@@                  
//            @@@%.......*@&/************************* @@@@@/***************************&@ [email protected]@@@                 
//            @@@,..........*@%//////********************************************////#@ ......%@@@                 
//            @@@#////////////,*@#/////////////////////////*////////////////////// @#/////////@@@&                 
//            &@@@////////////....*@ ///////////////////&@@ ////////////////////@ .///////////@@@                  
//             @@@,................../@ ///////// &@&........./@@#///////////@&[email protected]@@&                  
//              @@@////////............. @  @@&.....................,@@&  @@..........//////@@@@                   
//               @@@#////////[email protected]/*..,..,...../ @..................///////@@@&                    
//                @@@@/////*......................*@**********/@,....................*///@@@@                      
//                  @@@@,............................*@@@%@@@,[email protected]@@@%                       
//                    @@@@@.........................................................%@@@@                          
//                       @@@@@%.................................................*@@@@@%                            
//                          %@@@@@@%.......................................*@@@@@@@                                
//                              @@@@ [email protected]@@@@                                     
//                             @@@@*/*,[email protected]@@                                      
//                            @@@@//////,[email protected]@@%                                     
//                           @@@@//////,[email protected]@@                                     
//                          #@@@[email protected]@@                                     
//                          @@@////*[email protected]@@#                                    
//                          @@@/////*[email protected]@@%                                    
//                         @@@@///*[email protected]@@#                                    
//                      @@@@@*[email protected]@@                                     
//                    @@@@[email protected]@@                                     
//                   @@@#............*        /,....................*    @@@@                                      
//                   @@@...........&@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@&                                       
//                   @@@,............,&@@@@@  @@@&[email protected]@@@@,[email protected]@@@                                              
//                    @@@@[email protected]@@%  %@@@@@@@@@@@@@@@@@@@                                                
//                      @@@@@@@ ........#@@@                                                                       
//                          #@@@@@@@@@@@@@&                                                                        
//
//

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NekoCore is ERC721, Ownable {
    uint256 public constant PRICE_PER_TOKEN = 0.09 ether;
    uint256 public constant PRICE_PER_TOKEN_PRESALE = 0.06 ether;
    uint256 public constant SUPPLY_MAX = 9999;
    uint256 public constant LIMIT_PUBLIC_MINT = 20;
    uint256 public constant LIMIT_PRESALE_MINT = 2;
    uint256 public constant TROPHY_COUNT = 72;
    bytes32 public immutable PROVENANCE; // keccak256 of all metadata in order, 1..9999

    bytes32 public WHITELIST_ROOT; // merkle root
    uint256 public MINTED; // default = 0;
    bool public MINTABLE; // default = false;
    bool public MINTABLE_PRESALE; // default = false;

    mapping(address => uint) private _presale_balance;
    string private _baseTokenURI; // default = "";

    constructor(
        address catKing,
        string memory baseTokenURI,
        bytes32 provenance
        ) ERC721("NekoCore", "NEKOCORE") {
        _baseTokenURI = baseTokenURI;
        PROVENANCE = provenance;
        uint256 _tc = TROPHY_COUNT;
        // mint trophies to be held by the Cat King Tetsurō
        // (to be distributed to tournament winners)
        for(uint256 i = 1; i <= _tc; i++) {
            _mint(catKing, i);
        }
        MINTED = _tc;
    }

    // --- overrides --------------------------------------------------
    // ----------------------------------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- only owner -------------------------------------------------
    // ----------------------------------------------------------------

    function mintReservedTokens(address[] calldata addresses, uint256[] calldata counts) public onlyOwner {
        uint256 _current = MINTED;
        uint256 _tc = TROPHY_COUNT;

        require(addresses.length == counts.length, "Parallel arrays must be of equal length");
        require(_current == _tc, "Dev tokens may only be minted if no other tokens have been minted");

        uint256 _preminted = 0;
        for(uint256 i = 0; i < addresses.length; i++) {
            for(uint256 j = 1; j <= counts[i]; j++) {
                _mint(addresses[i], _tc + _preminted + j);
            }
            _preminted += counts[i];
        }

        MINTED += _preminted;
    }

    function setTokenURI(string calldata uri) public onlyOwner {
        // ipfs://<CID>/token_id
        _baseTokenURI = uri;
    }

    function setMintable(bool allow) public onlyOwner {
        MINTABLE = allow;
    }

    function setMintablePresale(bool allow) public onlyOwner {
        MINTABLE_PRESALE = allow;
    }

    function setWhitelistRoot(bytes32 root) public onlyOwner {
        WHITELIST_ROOT = root;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    // --- public use -------------------------------------------------
    // ----------------------------------------------------------------

    function totalSupply() external view returns (uint256) {
        return MINTED;
    }

    function premintCount(address test) external view returns (uint256) {
        return _presale_balance[test];
    }

    function mint(uint256 count) external payable {
        uint256 _current = MINTED;

        require(MINTABLE, "Contract is not currently mintable");
        require(count <= LIMIT_PUBLIC_MINT, "Exceeded maximum mint count");
        require((_current + count) <= SUPPLY_MAX, "Attempting to mint more tokens than are available");
        require(msg.value >= PRICE_PER_TOKEN * count, "Minting fee not met");

        for(uint256 i = 1; i <= count; i++) {
            _mint(_msgSender(), _current + i);
        }

        // update supply count
        MINTED = _current + count;
    }

    function mintPresale(uint256 count, bytes32[] calldata proof) external payable {
        uint256 _current = MINTED;
        
        require(!MINTABLE, "Contract is live, no longer in presale");
        require(MINTABLE_PRESALE, "Contract is not currently in presale");
        require(MerkleProof.verify(proof, WHITELIST_ROOT, keccak256(abi.encodePacked(_msgSender()))), "Caller did not provide valid whitelist proof");
        require(count <= LIMIT_PRESALE_MINT, "Exceeded maximum mint count for presale");
        require((_presale_balance[_msgSender()] + count) <= LIMIT_PRESALE_MINT, "Caller has already minted the maximum presale amount");
        require((_current + count)                       <= SUPPLY_MAX, "Attempting to mint more tokens than are available");
        require(msg.value >= PRICE_PER_TOKEN_PRESALE * count, "Minting fee not met");

        for(uint256 i = 1; i <= count; i++) {
            _mint(_msgSender(), _current + i);
        }

        // update supply count
        _presale_balance[_msgSender()] += count;
        MINTED = _current + count;
    }
}