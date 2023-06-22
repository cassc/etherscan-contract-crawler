// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                                       ,*.                                      
//                                $*,,,,,,,,,,,,,*$                               
//                              (,,,,,,,,,,,,,,,,,,,*                             
//                             *,,,,,,,,,,,,,,,,,,,,,*$                           
//                           .*,,,,,,,,,,,,,,,,,,,,,,,*$                          
//                          $**,,,,,$$$(,,,,,*$$$,,,,,*$*                         
//                         $,$$,,,,,,,,,,,,,,,,,,,,,,,*,,,$                       
//                        *,$,,*,,,,,,,,,,,,,,,,,,,,,*/,,,,*                      
//                       *,$,,,,$*,,,,,,,,,,,,,,,,,*$,,,,,,,*                     
//                      $,$,.$/%%#,#*,,,,,,,,,,,**/$%%$*$,.,,*                    
//                     $*$*,,,$###$$***,,,,,,****$$###$,,,,*$,$                   
//                    (**,,,,,$$###$$,,,,,,,,,,,$$%##$,,,,,,,,*$                  
//                  %*,,,,,,,,/$##$$$$,,,,,,,,#$$$$#$$,,,,,,,,,,*$                
//                 *,,,,,,,,,,/$$$$$$$$$$$$$$$$$$$$$$$,,,,,,,,,,,,*               
//               $*,,,,,,,,,,,$$$$$$$$$$$$$$$$$$$$$$$$$,(,,,,,,,,,,,$             
//              $*,,,,,,,,,,$,$$$$$$$$$$$$$$$$$$$$$$$$$,,$,,,,,,,,,,,$            
//             $,,,,,,,,,,,$#$$$$$$$$$$$$$$$$$$$$$$$$$$$$,*,,,,,,,,,,,/           
//            $*,,,,,,,,,,,*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$(/,,,,,,,,,,,,*          
//           $*,,,,,,,,,,,$$%#####$$$$$$$$$$$$$$$$######$$$*,,,,,,,,,,,,*         
//           *,,,,,,,,,,,*%%$$$$$$$$$$$$$$$$$$$$$$$$$$$##%$*,,,,,,,,,,,,*$        
//          **,,,,,,,,,,,$*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/,,,,,,,,,,,,,*$       
//         $*,,,,,,,,,,,*/#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*$*,,,,,,,,,,,,**       
//         **,,,,,,,,,,,***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*/*,,,,,,,,,,,,**%      
//        ***,,,,,,,,,,*$**,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,***,,,,,,,,,,,,***      
//       ****,,,,,,,,,,*$**,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*****,,,,,,,,,,,***      

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract RichRabbits is ERC721A, Ownable {

    string public rabbitsKey = ""; // PLVNDR to add the hash, as well as the seed used to generate the Rich Rabbits

    uint256 public rabbitsPrice = 50000000000000000; // 0.05 ETH

    uint public constant maxRabbitsPurchase = 10;

    uint256 public totalRabbits = 10000; 
    uint256 public public1Rabbits = 4850;
    uint256 public public1Counter = 0;


    bool public saleIsActive = false;
    bool public remainderSaleIsActive = false;

     // Claim Tracking
    mapping(address => uint256) private addressToClaimableRabbits;

    // Withdraw addresses
    address t1 = 0xd5F76A01D4eBe570a9252f1a8459B44FE8F4B5bd; // Artist + Devs
    address t2 = 0xBF6CAd470D415CD0b34774E4b75071797eAdeDB0; // Metaverse Expansion + Operational (Mods etc.)
    
    // Reserve up to 100 Rabbits for mods, marketing etc.
    uint public marketingReserve = 100;

    string private _baseTokenURI;

    constructor() ERC721A("Rich Rabbits", "RichRabbits") { }

    modifier rabbitCapture() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(((_total)/100)*65));
        require(payable(t2).send(((_total)/100)*35));
    }
    
    function reserveRabbits(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= marketingReserve, "Not Possible");
        _safeMint(_to, _reserveAmount);
        marketingReserve = marketingReserve - _reserveAmount;
    }

    function setTheRabbitsPrice(uint256 newPrice) public onlyOwner {
        rabbitsPrice = newPrice;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        rabbitsKey = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipRemainderSale() public onlyOwner {
        remainderSaleIsActive = !remainderSaleIsActive;
    }

    // Utility 
    function remainingRabbitsForClaim(address _address) external view returns (uint) {
    return addressToClaimableRabbits[_address];
    }

    // Moondogs + Moonpups + Free Mints 
    function updateFreeMints(address[] memory _addresses, uint[] memory _rabbitsToClaim) external onlyOwner {
        require(_addresses.length == _rabbitsToClaim.length, "Invalid snapshot data");
        for (uint i = 0; i < _addresses.length; i++) {
            addressToClaimableRabbits[_addresses[i]] = _rabbitsToClaim[i];
        }
    }

    function freeMint(uint rabbitsMint) external {
        require(saleIsActive, "Sale is not active");
        require(rabbitsMint <= addressToClaimableRabbits[msg.sender], "Invalid Rabbits Mint!");
        require(totalSupply() + rabbitsMint <= totalRabbits, "Supply would be exceeded");

                _safeMint(msg.sender, rabbitsMint);
                addressToClaimableRabbits[msg.sender] = addressToClaimableRabbits[msg.sender] - rabbitsMint;

    } 

    function publicMint(uint rabbitsMint) public payable rabbitCapture {
        require(saleIsActive, "Public Sale is not active");
        require(rabbitsMint > 0 && rabbitsMint <= maxRabbitsPurchase, "This is not possible");
        require(public1Counter + rabbitsMint <= public1Rabbits, "Not possible at this moment");
        require(msg.value >= rabbitsPrice * rabbitsMint, "Ether value sent is incorrect");

                _safeMint(msg.sender, rabbitsMint);
                public1Counter = public1Counter + rabbitsMint;

    } 

    function remainderMint(uint rabbitsMint) public payable rabbitCapture {
        require(remainderSaleIsActive, "Remainder Sale is not active");
        require(rabbitsMint > 0 && rabbitsMint <= maxRabbitsPurchase, "This is not possible");
        require(totalSupply() + rabbitsMint <= totalRabbits, "Supply would be exceeded");
        require(msg.value >= rabbitsPrice * rabbitsMint, "Ether value sent is incorrect");

                _safeMint(msg.sender, rabbitsMint);

    } 

}