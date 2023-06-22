// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



//    ____  _______    ______  __  ______   ____  ____     ____  __________         
//    / __ \/ ____/ |  / / __ \/ / /_  __/  / __ \/ __ \   / __ \/  _/ ____/         
//   / /_/ / __/  | | / / / / / /   / /    / / / / /_/ /  / / / // // __/            
//  / _, _/ /___  | |/ / /_/ / /___/ /    / /_/ / _, _/  / /_/ // // /___            
// /_/ |_/_____/__|___/\____/_____/_/_____\____/_/_|_|  /_____/___/_____/ ____  _____
// | |     / / ____/  /   |  / __ \/ ____/  / //_/ __ \/ __ )/ __ \/ /   / __ \/ ___/
// | | /| / / __/    / /| | / /_/ / __/    / ,< / / / / __  / / / / /   / / / /\__ \ 
// | |/ |/ / /___   / ___ |/ _, _/ /___   / /| / /_/ / /_/ / /_/ / /___/ /_/ /___/ / 
// |__/|__/_____/  /_/  |_/_/ |_/_____/  /_/ |_\____/_____/\____/_____/_____//____/            ¯                                                                                                                                                                                                            `'´              `'*'´¯                   '                                         '                              '                             ¯ `'*'´ ¯     '                 '                               '`*^·–·^*'´'           ‘



contract Kobolds is ERC721A,Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public MAX_SUPPLY = 6999;
    bool public curOpenState = false;

    // for public
    uint256 public constant publicCost = 0.01 ether;
    uint256 public constant maxPerWallet = 5;

    // for free 
    uint256 public freeMinted = 0;
    uint256 public constant MAX_FREE_SUPPLY = 1000;
    uint256 public constant maxFreePerWallet = 1;
    
    bool public manualOpenFreeMint = false;

    mapping (address => bool) private ogMinted;

    // for dev
    //using ECDSA for bytes32;
    bytes32 public _ogRoot;
    uint256 public constant maxWLmint = 10;
    bool private isInitMint = false;

    constructor() ERC721A("Kobolds","KBT",maxWLmint,MAX_SUPPLY) {
    }

    // public function  
    function setWLRoot(bytes32 newMerkleRoot) external onlyOwner{
        _ogRoot = newMerkleRoot;
    }

    function numberMinted(address account) public view returns(uint256) {
        return _numberMinted(account);
    }

    function initMint() external onlyOwner {
        require(isInitMint == false,"already inited!");
        _safeMint(msg.sender,1); 
        isInitMint = true;  
    }

    function OGMint(bytes32[] memory proof) 
            external 
            payable 
            isValidMerkleProof(proof,_ogRoot) {
        require(curOpenState,"not open yet!");
        require(ogMinted[msg.sender] == false, "");
        _safeMint(msg.sender,maxWLmint);
        ogMinted[msg.sender] = true;
    }

    function Mint(uint256 quantity) external payable mintCompliance(quantity) {
        require(curOpenState,"not open yet!");
        require(msg.sender == tx.origin, "must be real kobolds!!");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        uint256 minted = numberMinted(msg.sender);
        require(minted + quantity <= maxPerWallet, "max 5 per wallet");


        uint256 price;
        if (minted > 0) {
            price = publicCost * quantity;
        } else if (freeMinted < MAX_FREE_SUPPLY) {
            price = (quantity - 1) * quantity;
            freeMinted = freeMinted + 1;
        }

        if (manualOpenFreeMint == true) {
            price = 0;
        }
        
        require(msg.value >= price,"Ether value sent is not correct");
 
        _safeMint(msg.sender, quantity);
        refundIfOver(price);
    }

    function changeCurOpenState(bool state) onlyOwner external {
        curOpenState = state;
    }

    function changeManualOpenFreeMint(bool state) onlyOwner external {
        manualOpenFreeMint = state;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    } 

    function canOGMint(bytes32[] calldata merkleProof) view external returns (bool res){
        require(_ogRoot != "", "root not set");
        if (MerkleProof.verify(merkleProof,_ogRoot,keccak256(abi.encodePacked(msg.sender))) && ogMinted[msg.sender] == false)
        {
            return true;
        }
        return false;
    }

    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function sacrifice() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "sacrifice failed.");
    }

    // modifier 
    modifier mintCompliance(uint256 quantity) {
        require(totalSupply() + quantity <= MAX_SUPPLY,"not enough limit!");
        _;
    } 
    modifier isValidMerkleProof(bytes32[] memory merkleProof, bytes32 root) {
        require(root != "", "OG mint not set");
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
}