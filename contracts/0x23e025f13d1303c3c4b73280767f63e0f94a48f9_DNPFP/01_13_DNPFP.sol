//SPDX-License-Identifier: MIT
//IN BILLIONAIRE WE TRUST

/*
                                                                                                                   
DDDDDDDDDDDDD        NNNNNNNN        NNNNNNNN     PPPPPPPPPPPPPPPPP   FFFFFFFFFFFFFFFFFFFFFFPPPPPPPPPPPPPPPPP      SSSSSSSSSSSSSSS 
D::::::::::::DDD     N:::::::N       N::::::N     P::::::::::::::::P  F::::::::::::::::::::FP::::::::::::::::P   SS:::::::::::::::S
D:::::::::::::::DD   N::::::::N      N::::::N     P::::::PPPPPP:::::P F::::::::::::::::::::FP::::::PPPPPP:::::P S:::::SSSSSS::::::S
DDD:::::DDDDD:::::D  N:::::::::N     N::::::N     PP:::::P     P:::::PFF::::::FFFFFFFFF::::FPP:::::P     P:::::PS:::::S     SSSSSSS
  D:::::D    D:::::D N::::::::::N    N::::::N       P::::P     P:::::P  F:::::F       FFFFFF  P::::P     P:::::PS:::::S            
  D:::::D     D:::::DN:::::::::::N   N::::::N       P::::P     P:::::P  F:::::F               P::::P     P:::::PS:::::S            
  D:::::D     D:::::DN:::::::N::::N  N::::::N       P::::PPPPPP:::::P   F::::::FFFFFFFFFF     P::::PPPPPP:::::P  S::::SSSS         
  D:::::D     D:::::DN::::::N N::::N N::::::N       P:::::::::::::PP    F:::::::::::::::F     P:::::::::::::PP    SS::::::SSSSS    
  D:::::D     D:::::DN::::::N  N::::N:::::::N       P::::PPPPPPPPP      F:::::::::::::::F     P::::PPPPPPPPP        SSS::::::::SS  
  D:::::D     D:::::DN::::::N   N:::::::::::N       P::::P              F::::::FFFFFFFFFF     P::::P                   SSSSSS::::S 
  D:::::D     D:::::DN::::::N    N::::::::::N       P::::P              F:::::F               P::::P                        S:::::S
  D:::::D    D:::::D N::::::N     N:::::::::N       P::::P              F:::::F               P::::P                        S:::::S
DDD:::::DDDDD:::::D  N::::::N      N::::::::N     PP::::::PP          FF:::::::FF           PP::::::PP          SSSSSSS     S:::::S
D:::::::::::::::DD   N::::::N       N:::::::N     P::::::::P          F::::::::FF           P::::::::P          S::::::SSSSSS:::::S
D::::::::::::DDD     N::::::N        N::::::N     P::::::::P          F::::::::FF           P::::::::P          S:::::::::::::::SS 
DDDDDDDDDDDDD        NNNNNNNN         NNNNNNN     PPPPPPPPPP          FFFFFFFFFFF           PPPPPPPPPP           SSSSSSSSSSSSSSS  

*/

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DNPFP is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant WHITELIST_PRICE = 0.0099 ether;
    uint256 public constant PUBLIC_PRICE = 0.0099 ether;

    uint256 public constant MAX_QUANTITY = 2;

    address public constant THE_MONKEY_WALLET = 0x1f97c140b9D67BdFFf5F4a55923ebC1442D67A13;

    mapping(address => uint256) public whitelistedMint;
    mapping(address => uint256) public publicMint;

    bool public mintTime = false;
    bool public publicMintTime = false;

    string private baseTokenUri = "https://chocolate-charming-kite-7.mypinata.cloud/ipfs/QmP52Fh8vYLXbCCX1NiMfydmhV9wPGnLrc8dkNZNKU42AD/";

    bytes32 public whitelistMerkleRoot = 0x34583c40e5f0f57f95539170f0277526a95b30f488ac9211d298d88401f2990b;

    constructor() ERC721A("DN PFP", "DN") {

        _safeMint(THE_MONKEY_WALLET, 50);

    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable {

        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(mintTime, "It is not time to mint");
        require(whitelistedMint[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
        require(msg.value >= WHITELIST_PRICE, "Not enough Ether");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Merkle Proof");

            whitelistedMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function mint(uint256 _quantity) external payable {

        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Out Of Stock!");
        require(publicMintTime, "It is not time to mint");
        require(publicMint[msg.sender] + _quantity <= MAX_QUANTITY, "Already Minted!");
        require(msg.value >= PUBLIC_PRICE * _quantity, "Not enough Ether");

            
            publicMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenURI(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function flipState() public onlyOwner {

        mintTime = !mintTime;
    }

    function flipStatePublic() public onlyOwner {

        publicMintTime = !publicMintTime;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {

        whitelistMerkleRoot = _merkleRoot;

    }

    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }

}