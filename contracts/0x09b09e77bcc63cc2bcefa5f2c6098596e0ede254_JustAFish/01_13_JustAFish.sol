// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "../lib/ERC721F/ERC721F.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

 /**
 * @title JustAFish contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @simonbuidl.eth
 * 
 */

contract JustAFish is ERC721F {
    using Strings for uint256;
    
    uint256 public tokenPrice = 0.0033 ether; 
    uint256 public constant MAX_TOKENS= 6969;
    
    uint public constant MAX_PRESALE_PURCHASE = 2; // set 1 to high to avoid some gas
    uint public MAX_PUBLIC_PURCHASE = 4; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;

    bytes32 public merkleRoot;

    mapping(address => bool) public isClaimed;
    mapping(address => uint256) private amount;
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("JustAFish", "FISH") {
        setBaseTokenURI("ipfs://QmWVP43QSdmSMU4w81qNcm8RuDs88BG9dc9VjZTX1YkXCt/");
        updateMerkleRoot(0xd7407a85a778580cd724f52f9a44b92937a4eb7116d344402abbdacce6861ed1);
        _safeMint(0xD37B441828Af470746b06E5500a6fbd6b92ffeAb, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function adminMint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }
    }
    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }


    function changeMaxPublicMint(uint256 newAmount) external onlyOwner {
        require(newAmount >= 0);
        MAX_PUBLIC_PURCHASE = newAmount;
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0);
        tokenPrice = newPrice;
        emit priceChange(msg.sender, newPrice);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
 
     function updateMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

      function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * Mint your tokens here. merge these methods
     */
    function preMint(uint256 numberOfTokens, bytes32[] memory merkleProof) external payable {
            require(preSaleIsActive, "Presale is not active");
            uint256 supply = totalSupply();

            //Check whitelist
            bytes32 node = keccak256(abi.encodePacked(uint256(1), msg.sender));
            require(verify(merkleProof, merkleRoot, node), 'Sender is not on the whitelist');

            //Check min and max numberOfTokens
            require(numberOfTokens > 0, "Total number of mints cannot be 0");
            require(numberOfTokens <= 2, "Total number of mints cannot exceed 3");
            require(amount[msg.sender]+numberOfTokens <= MAX_PRESALE_PURCHASE, "You can only mint 2 during presale");
            require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");

            //Check msg.value depending if free mint has been claimed.
            !isClaimed[msg.sender] 
                 ? require(tokenPrice * (numberOfTokens - 1) <= msg.value, "Ether value sent is not correct")
                 : require(tokenPrice * (numberOfTokens) <= msg.value, "Ether value sent is not correct");
            
            //Change state
            amount[msg.sender] += numberOfTokens;
            for(uint256 i; i < (numberOfTokens); i++){
                _safeMint( msg.sender, supply + i );
            }
            isClaimed[msg.sender] = true;
    }
    function mint(uint256 numberOfTokens) external payable {
            require(saleIsActive,"Sale NOT active yet");

            //Check min and max numberOfTokens
            uint256 supply = totalSupply();
            require(numberOfTokens > 0, "Total number of mints cannot be 0");
            require(numberOfTokens <= 4, "Total number of mints cannot exceed 4");
            require(amount[msg.sender] + numberOfTokens <= MAX_PUBLIC_PURCHASE,"You can only mint 4 in total");
            require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");

            //Check msg.value
            amount[msg.sender] == 0
                 ? require(tokenPrice * (numberOfTokens - 1) <= msg.value, "Ether value sent is not correct")
                 : require(tokenPrice * (numberOfTokens) <= msg.value, "Ether value sent is not correct");


            //Change state
            amount[msg.sender] += numberOfTokens;
            for(uint256 i; i < (numberOfTokens); i++){
                _safeMint( msg.sender, supply + i );
            }
            isClaimed[msg.sender] = true;
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(0xD37B441828Af470746b06E5500a6fbd6b92ffeAb, (balance * 25) / 100);
        _withdraw(0x5409CfdF149d8BA163a58B25901C050d4DF8A122, (balance * 40) / 100);
        _withdraw(0x012e944B7181F4c4E8b18a60CEE33c47b3EaF37c, (balance * 35) / 100);
    }
}