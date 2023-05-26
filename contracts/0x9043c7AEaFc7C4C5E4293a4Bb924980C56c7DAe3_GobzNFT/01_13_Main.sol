// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//                                 @@@@@@@@@@@@@@@@@                               
//                           @@@@@@@@@@@@@@@@@@@@@@@@@@@@                          
//                       &@@@@@@@@@@@@[email protected]@@@@@@@@@@(                      
//                     @@@@@@@@@/.....................%@@@@@@@@                    
//                   @@@@@@@@............................/@@@@@@@                  
//                 *@@@@@@@................................,@@@@@@                 
//               @@@@@@@@[email protected]@@@@@@               
//          @@@@@@@@@@@@[email protected]@@@@@@@@@@          
//     @@@@@@@@@@@@@@@@@.....%@@@@@................./@@@@@..../@@@@@@@@@@@@@@@     
//  @@@@@@@@@[email protected]@@@@@&[email protected]@@@@@@[email protected]@@@@@[email protected]@@@@@[email protected]@@@@@@@@@ 
//   @@@@@@@@@[email protected]@@@@@@[email protected]@@[email protected]@@.........&@[email protected]@@@@@[email protected]@@@@@@@ 
//       @@@@@@@@@@@@@@@[email protected]@.................,@@@@@@./@@@@@@@@    
//           @@@@@@@@@@@@[email protected]@&[email protected]@@@@@@@@@@@@&       
//              &@@@@@@@@@@[email protected]@@@@@@@@@@@           
//                  /@@@@@@@@[email protected]@@@@@@@@               
//                    @@@@@@@@@[email protected]@@@@@@@                 
//                      @@@@@@@@@@.....................,@@@@@@@@                   
//                         @@@@@@@@@@@@[email protected]@@@@@@@@@@,                    
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                       
//                                @@@@@@@@@@@@@@@@@@@@@@                           
//                                       @@@@@@@@/                                 
                                                                                

/// @creator:     GobzNFT
/// @author:      peker.eth - twitter.com/peker_eth

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract GobzNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    bytes32 public root;
    
    string BASE_URI = "";
    
    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;
    
    uint constant TOTAL_SUPPLY = 5555;
    uint constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;
    uint constant MINT_PRICE = 0.055 ether; 

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 5;
    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;
    
    mapping (address => uint) addressToMintCount;

    address constant FOUNDER = 0x9d479E8998626daBabb8012b2053df58060EE5E3;
    address constant DEVELOPER = 0xA800F34505e8b340cf3Ab8793cB40Bf09042B28F;
    
    constructor(string memory name, string memory symbol, bytes32 root_)
    ERC721(name, symbol)
    {
        _tokenIdCounter.increment();

        root = root_;
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function togglePublicSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function togglePreSale() public 
    onlyOwner 
    {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function presaleMint(address account, uint numberOfTokens, uint256 allowance, string memory key, bytes32[] calldata proof)
    public
    payable
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");

        string memory payload = string(abi.encodePacked(Strings.toString(allowance), ":", key));

        require(_verify(_leaf(msg.sender, payload), proof), "Invalid merkle proof");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= allowance, "Exceeds allowance");

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint numberOfTokens) 
    public 
    payable
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX, "Too many requested");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function getCurrentMintCount(address _account) public view returns (uint) {
        return addressToMintCount[_account];
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER, (balance * 925) / 1000);
        _withdraw(DEVELOPER, (balance * 75) / 1000);
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    function _leaf(address account, string memory payload)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}