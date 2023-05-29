// SPDX-License-Identifier: MIT

//                                .:=+**#####*++-:.   .-=+**####**+=-:                                 
//                             .=*#################*+##################*-.                             
//                           .+#####*=-:....::-=*#######+=-:....::-+######+.                           
//                          :#####=.            =####*-              .+#####-                          
//                         .#####:             -####*                  .+###*                          
//                         =####=              *####:                    :-:                           
//                         +####:              #####                                                   
//                         =####=              *####:                                                  
//                         .#####.             -####+                                                  
//                          -#####.             +####=                                                 
//                           -#####-             =####*.                                               
//                          .-*#####=           :=######:                                              
//                       :=##########*.      -+##########+                                             
//                     -*####*=-.:*####=.  =#####*=:.=#####-                                           
//                   .*####=.      -#####=####*-      .+#####:                                         
//                  :####*.         .+#######=          :*####+.                -=-                    
//                 .####*             :*#####:            -#####+.             *###+                   
//                 +####.               :*####*-           *######+:          :####=                   
//                 ####+                  :*#####-        -#########*:        *####                    
//                .####+                    -*#####=     .####+ =#####*:     =####-                    
//                 #####                      -*#####=. .####*    -#####*-  :####+                     
//                 +####-                       :+#####+#####.      -*#####+####+                      
//                 .#####-                        .=#######*.         :+#######=                       
//                  .#####+                         =#######*:         .+#######=.                     
//                   .+#####-                    :=#####*#####*-.    -*#####*#####*-                   
//                     :*#####*=:.          .:=+######+.  -*#####+=*######=  .=######+.                
//                       :=#########*****###############****##########*=:       :+#####=               
//                          :=+###############*=-=*###############+=:              -*#*.               
//                               .::-----::.         .:------:..                                       

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Cheek is ERC721A, Pausable, Ownable
{
    using Strings for uint256;

    struct AddressWithAmount
    {
        address addr;
        uint16 amount;
    }

    bool public saleActive;

    uint256 constant public MAX_SUPPLY = 3888;
    uint256 constant public PRICE = 0.08 ether;
    uint256 constant public MAX_PUBLIC_MINT = 5;
    uint256 constant public MAX_RAFFLE_MINT = 1;

    uint256 public ticketMintStartTimestamp;
    uint256 public raffleMintStartTimestamp;
    uint256 public publicMintStartTimestamp;

    uint256 public ticketMintStopTimestamp;
    uint256 public raffleMintStopTimestamp;

    uint256 public startingIndex;

    bytes32 public merkleRootCheekList;
    bytes32 public merkleRootRaffleList;

    string constant public PROVENANCE = 'c2c11792b67c5ac04372e37c3589f7109ac7ec6c23ad131abad9b14a0369569f';
    string public baseURI = 'ipfs://bafybeihytjnsu4qycggcybnhnes3tqbqwg2lw5sltlh6jlznhjqhcg5vpq/';

    mapping (address => bool) public whitelistMinted;
    mapping (address => bool) public rafflelistMinted;
    mapping (address => uint16) public maxTicketMint;
    mapping (address => uint16) public ticketMintAmount;
    mapping (address => uint16) public publicMintAmount;

    constructor() ERC721A("Cheek", "CHEEK")
    {
    }

    //    OWNER

    function pause() external onlyOwner 
    {
        _pause();
    }

    function unpause() external onlyOwner 
    {
        _unpause();
    }

    function withdraw() external onlyOwner 
    {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseUri(string calldata value) external onlyOwner
    {
        baseURI = value;
    }

    function setCheeksListMerkleRoot(bytes32 value) external onlyOwner
    {
        merkleRootCheekList = value;
    }

    function setRaffleListMerkleRoot(bytes32 value) external onlyOwner
    {
        merkleRootRaffleList = value;
    }

    function setMintsLeft(AddressWithAmount[] calldata values) external onlyOwner
    {
        for(uint i = 0; i < values.length; i++)
        {
            maxTicketMint[values[i].addr] = values[i].amount;
        }
    }

    function forceMint(uint16 numberOfTokens) external onlyOwner
    {
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Mint would exceed max supply of Cheeks");
        
        _safeMint(msg.sender, numberOfTokens);
        
        if (totalSupply() == MAX_SUPPLY)
        {
            startingIndex = block.number;
        }
    }

    function setSaleState(bool value) external onlyOwner
    {
        saleActive = value;
    }

    function setSaleTimes(
        uint256 newTicketMintStartTimestamp, 
        uint256 newTicketMintStopTimestamp,
        uint256 newRaffleMintStartTimestamp,
        uint256 newRaffleMintStopTimestamp,
        uint256 newPublicMintStartTimestamp) external onlyOwner
    {
        ticketMintStartTimestamp = newTicketMintStartTimestamp;
        raffleMintStartTimestamp = newRaffleMintStartTimestamp;
        publicMintStartTimestamp = newPublicMintStartTimestamp;

        ticketMintStopTimestamp = newTicketMintStopTimestamp;
        raffleMintStopTimestamp = newRaffleMintStopTimestamp;

        saleActive = true;
    }

    //    PUBLIC

    function mint(uint16 numberOfTokens, bytes32[] calldata proof) external payable
    {
        require(saleActive, "Sale is not active");
        require(numberOfTokens > 0, "numberOfTokens needs to be greater than 0");
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of Cheeks");
        require((PRICE * numberOfTokens) <= msg.value, "Ether value sent is not correct");

        uint8 mintStatus = getMintStatus();

        if (mintStatus == 5)
        {
            _publicMint(msg.sender, numberOfTokens);
        }
        else if (mintStatus == 3)
        {
            _raffleMint(msg.sender, numberOfTokens, proof);
        }
        else if (mintStatus == 1)
        {
            _ticketMint(msg.sender, numberOfTokens, proof);
        }

        if (totalSupply() == MAX_SUPPLY)
        {
            startingIndex = block.number;
        }
    }

    // 0 - not started, 1 - ticket mint, 2 - ticket mint end, 3 - raffle mint, 4 - raffle mint end, 5 - public mint
    function getMintStatus() public view returns (uint8)
    {
        uint256 timeNow = block.timestamp;

        if (timeNow >= publicMintStartTimestamp)
        {
            return 5;
        }
        
        if (timeNow >= raffleMintStartTimestamp)
        {
            if (timeNow < raffleMintStopTimestamp)
            {
                return 3;
            }

            return 4;
        }
        
        if (timeNow >= ticketMintStartTimestamp)
        { 
            if (timeNow < ticketMintStopTimestamp)
            {
                return 1;
            }

            return 2;
        }

        return 0;
    }

    function isWhitelisted(address addr, bytes32[] memory proof) public view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRootCheekList, _getLeaf(addr));
    }

    function isRaffleWinner(address addr, bytes32[] memory proof) public view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRootRaffleList, _getLeaf(addr));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) 
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 tokenIndex = (tokenId + startingIndex) % MAX_SUPPLY;

        string memory base = _baseURI();
        return bytes(base).length != 0 ? string(abi.encodePacked(base, tokenIndex.toString())) : '';
    }

    //   INTERNAL

    function _ticketMint(address addr, uint16 numberOfTokens, bytes32[] calldata proof) private
    {
        uint16 maxMintCount = maxTicketMint[addr] - ticketMintAmount[addr];
        bool clMint = !whitelistMinted[addr] && isWhitelisted(addr, proof);
        if (clMint)
        {
            maxMintCount++;
        }

        require(numberOfTokens <= maxMintCount, "Can only mint MAX tokens at a time");

        _safeMint(addr, numberOfTokens);

        if (clMint)
        {
            numberOfTokens--;
            whitelistMinted[addr] = true;
        }

        ticketMintAmount[addr] += numberOfTokens;
    }

    function _raffleMint(address addr, uint16 numberOfTokens, bytes32[] calldata proof) private    
    {
        require(numberOfTokens == MAX_RAFFLE_MINT, "Can only mint MAX tokens at a time");
        require(!rafflelistMinted[addr] && isRaffleWinner(addr, proof), "Already minted or not eligible");
        _safeMint(addr, numberOfTokens);
        rafflelistMinted[addr] = true;
    }

    function _publicMint(address addr, uint16 numberOfTokens) private
    {
        require(publicMintAmount[addr] + numberOfTokens <= MAX_PUBLIC_MINT, "Can only mint MAX tokens at a time");
        _safeMint(addr, numberOfTokens);
        publicMintAmount[addr] += numberOfTokens;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return baseURI;
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint quantity) internal whenNotPaused override
    {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function _getLeaf(address addr) pure private returns (bytes32)
    {
        return keccak256(abi.encode(addr));
    }
}