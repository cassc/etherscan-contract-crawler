//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721a.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/** 
                                                              _____
 ______   _____ ______   _____            _____          _____\    \  _____    _____     
|\     \ |     |\     \  \    \      _____\    \_       /    / |    ||\    \   \    \    
\ \     \|     | \    |  |    |     /     /|     |     /    /  /___/| \\    \   |    |   
 \ \           |  |   |  |    |    /     / /____/|    |    |__ |___|/  \\    \  |    |   
  \ \____      |  |    \_/   /|   |     | |_____|/    |       \         \|    \ |    |   
   \|___/     /|  |\         \|   |     | |_________  |     __/ __       |     \|    |   
       /     / |  | \         \__ |\     \|\        \ |\    \  /  \     /     /\      \  
      /_____/  /   \ \_____/\    \| \_____\|    |\__/|| \____\/    |   /_____/ /______/| 
      |     | /     \ |    |/___/|| |     /____/| | ||| |    |____/|  |      | |     | | 
      |_____|/       \|____|   | | \|_____|     |\|_|/ \|____|   | |  |______|/|_____|/  
                           |___|/         |____/             |___|/                      

*/

contract Yugen is ERC721A, Ownable, PaymentSplitter, VRFConsumerBase {

    using Strings for uint256;

    //Chainlink values
    uint constant fee = 2 ether;
    bytes32 constant keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

    //Minting values
    uint public maxSupply = 8888;
    uint public constant price = 0.07 ether;
    uint public constant whitelistPrice = 0.06 ether;
    uint public constant mintPassPrice = 0.04 ether;

    bytes32 public merkleRoot;

    mapping(address => uint) public FreeMinted;
    mapping(address => uint) public MintPassUsed;

    bool public isPublicMint;

    //Reveal values
    string public baseURI = "ipfs://bafybeify6pvt2oh4wf2pgce5cdtaupob7wlwzj5b2pdkz2ddl4jcnpymtq/";

    string public upgradeUri;

    mapping(uint => bool) tokenUpgraded;

    struct RevealData {
        uint range;
        uint randomness;
        string uri;
    }

    RevealData[] public revealData;

    mapping(address => bool) acceptedAddresses;

    mapping(uint => string) customUri;

    uint public reckoning;

    uint public constant reckoningDelay = 1 days;

    uint teamAllocation;

    constructor(address[] memory payees, uint256[] memory shares, address _vrfCoordinator, address _link) 
    ERC721A("Yugen", "YUGEN")
    PaymentSplitter(payees, shares)
    VRFConsumerBase(_vrfCoordinator, _link) {

    }

    modifier onlyAcceptedAddress() {

        require(acceptedAddresses[msg.sender], "Not an accepted address");
        _;

    }


    /**
    
            ___________          ____________  _____    _____    ________    ________   
           /           \        /            \|\    \   \    \  /        \  /        \  
          /    _   _    \      |\___/\  \\___/|\\    \   |    ||\         \/         /| 
         /    //   \\    \      \|____\  \___|/ \\    \  |    || \            /\____/ | 
        /    //     \\    \           |  |       \|    \ |    ||  \______/\   \     | | 
       /     \\_____//     \     __  /   / __     |     \|    | \ |      | \   \____|/  
      /       \ ___ /       \   /  \/   /_/  |   /     /\      \ \|______|  \   \       
     /________/|   |\________\ |____________/|  /_____/ /______/|         \  \___\      
    |        | |   | |        ||           | / |      | |     | |          \ |   |      
    |________|/     \|________||___________|/  |______|/|_____|/            \|___|      
                                                                                
    
    */

    /**
    * @dev Minting once open to the public, limit to 20 per transaction
    */
    function publicMint(uint quantity) external payable {

        require(isPublicMint, "Minting isn't public");

        require(msg.value == quantity * price, "Invalid value sent");
            
        _internalMint(quantity);

    }

    /**
    * @dev Allows minting the the wallet is on any of the whitelists, requires a proof
    */
    function whitelistMint(bytes32[][] calldata _proofs, uint[] memory _quantities, uint[] memory _types, uint[] memory _maxAmounts) external payable {

        uint _price;
        uint totalToMint;

        for (uint i = 0; i < _proofs.length; i++) {

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _types[i], _maxAmounts[i]));

            require(MerkleProof.verify(_proofs[i], merkleRoot, leaf), "Invalid Proof");

            uint amountOfTypeMinted;

            if(_types[i] == 0) {

                _price += (whitelistPrice * _quantities[i]);

            
            } else if(_types[i] == 1) {

                _price += (mintPassPrice * _quantities[i]);

                amountOfTypeMinted = MintPassUsed[msg.sender] + _quantities[i];

                MintPassUsed[msg.sender] += _quantities[i];


            } else {    

                amountOfTypeMinted = FreeMinted[msg.sender] + _quantities[i];

                FreeMinted[msg.sender] += _quantities[i];

            }

            require(amountOfTypeMinted <= _maxAmounts[i], "Minting too many");

            totalToMint += _quantities[i];
            
        }

        require(totalToMint > 0, "Nothing to mint");

        require(msg.value == _price, "Invalid value sent");

        _internalMint(totalToMint);
       
    }

    /**
    * @dev internal mint function
    */
    function _internalMint(uint quantity) internal {

        require(_totalMinted() + quantity <= maxSupply, "Attempting to mint over max supply");
        
        _safeMint(msg.sender, quantity);

    }

    /**
    * @dev Accepted Address can upgrade a citizen if they have met the appropriate conditions
    */
    function upgradeToken(uint tokenId, address owner) external onlyAcceptedAddress {

        require(ownerOf(tokenId) == owner, "Not owner");

        require(isApprovedForAll(owner, msg.sender), "Owner has to approve this");

        tokenUpgraded[tokenId] = true;

    }

    /**
    * @dev Accepted Address can assassinate citizens once the reckoning has started
    */
    function assassinate(uint tokenId) external onlyAcceptedAddress {
        require(reckoning > 0, "Reckoning hasn't started");
        require(block.timestamp > reckoning + reckoningDelay, "Season hasn't started");

        _burn(tokenId);
    }

    /**
    * @dev Allows for a citizen to ascend, if the criteria has been met
    */
    function customize(uint tokenId, string memory uri) external onlyAcceptedAddress {
        require(reckoning > 0, "Reckoning hasn't started");
        require(block.timestamp > reckoning + reckoningDelay, "Season hasn't started");

        customUri[tokenId] = uri;
    }

    /**                                      _____                            
   _______    ______   ____________     _____\    \    _______     _______    
   \      |  |      | /            \   /    / |    |  /      /|   |\      \   
    |     /  /     /||\___/\  \\___/| /    /  /___/| /      / |   | \      \  
    |\    \  \    |/  \|____\  \___|/|    |__ |___|/|      /  |___|  \      | 
    \ \    \ |    |         |  |     |       \      |      |  |   |  |      | 
     \|     \|    |    __  /   / __  |     __/ __   |       \ \   / /       | 
      |\         /|   /  \/   /_/  | |\    \  /  \  |      |\\/   \//|      | 
      | \_______/ |  |____________/| | \____\/    | |\_____\|\_____/|/_____/| 
       \ |     | /   |           | / | |    |____/| | |     | |   | |     | | 
        \|_____|/    |___________|/   \|____|   | |  \|_____|\|___|/|_____|/  
                                            |___|/                   

    */   

    /**
        @dev Returns the uri for a given token, each tokens metadata uri is offset by a chainlink verifiable random number
    */
    function getUri(uint tokenId) public view returns(string memory) {
            
        RevealData[] memory data = revealData;

        uint count = data.length;
        RevealData memory tokenData;
        uint lastRange = 0;
       
        for(uint i = 0; i < count;) {

            if(tokenId < data[i].range) {

                tokenData = data[i];
                break;

            }

            lastRange = data[i].range;

            unchecked {
                
                ++i; 
            }

        }

        if(tokenData.randomness == 0) {

            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        uint metadataId = lastRange + ((tokenId + tokenData.randomness) % (tokenData.range - lastRange));

        string memory uri;

        if(tokenUpgraded[tokenId]) {

            uri = upgradeUri;

        } else {
            uri = tokenData.uri;
        }

        return string(abi.encodePacked(uri, metadataId.toString()));

    }

    /**
    * @dev See {IERC721Metadata-tokenURI}. 
    *  Returns the metadata uri based on the tokens key type
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        require(_exists(tokenId), "Token doesn't exist");

        if(bytes(customUri[tokenId]).length > 0) {
            return customUri[tokenId];
        }

        return getUri(tokenId);
    }


    /**                                                                                                                                                      
            _____         __     __           _____          ____________  _____    _____   _____              ____________  _____    _____     ______   _______   
       _____\    \_      /  \   /  \        /      |_       /            \|\    \   \    \ |\    \            /            \|\    \   \    \   |\     \  \      \  
      /     /|     |    /   /| |\   \      /         \     |\___/\  \\___/|\\    \   |    | \\    \          |\___/\  \\___/|\\    \   |    |   \\     \  |     /| 
     /     / /____/|   /   //   \\   \    |     /\    \     \|____\  \___|/ \\    \  |    |  \\    \          \|____\  \___|/ \\    \  |    |    \|     |/     //  
    |     | |____|/   /    \_____/    \   |    |  |    \          |  |       \|    \ |    |   \|    | ______        |  |       \|    \ |    |     |     |_____//   
    |     |  _____   /    /\_____/\    \  |     \/      \    __  /   / __     |     \|    |    |    |/      \  __  /   / __     |     \|    |     |     |\     \   
    |\     \|\    \ /    //\_____/\\    \ |\      /\     \  /  \/   /_/  |   /     /\      \   /            | /  \/   /_/  |   /     /\      \   /     /|\|     |  
    | \_____\|    |/____/ |       | \____\| \_____\ \_____\|____________/|  /_____/ /______/| /_____/\_____/||____________/|  /_____/ /______/| /_____/ |/_____/|  
    | |     /____/||    | |       | |    || |     | |     ||           | / |      | |     | ||      | |    |||           | / |      | |     | ||     | / |    | |  
     \|_____|    |||____|/         \|____| \|_____|\|_____||___________|/  |______|/|_____|/ |______|/|____|/|___________|/  |______|/|_____|/ |_____|/  |____|/   
            |____|/                                                                                                                                                
    
    
    */

    /**
     * @dev Callback function used by Chainlink VRF Coordinator
    * sets the randomness used to determine the metadata id
    */
    function fulfillRandomness(bytes32, uint256 _randomness) internal override {

        revealData[revealData.length - 1].randomness = _randomness;

    }

    /**
                                                                       _____                    
           ____        _______     _______   _____    _____       _____\    \ ___________       
       ____\_  \__    /      /|   |\      \ |\    \   \    \     /    / |    |\          \      
      /     /     \  /      / |   | \      \ \\    \   |    |   /    /  /___/| \    /\    \     
     /     /\      ||      /  |___|  \      | \\    \  |    |  |    |__ |___|/  |   \_\    |    
    |     |  |     ||      |  |   |  |      |  \|    \ |    |  |       \        |      ___/     
    |     |  |     ||       \ \   / /       |   |     \|    |  |     __/ __     |      \  ____  
    |     | /     /||      |\\/   \//|      |  /     /\      \ |\    \  /  \   /     /\ \/    \ 
    |\     \_____/ ||\_____\|\_____/|/_____/| /_____/ /______/|| \____\/    | /_____/ |\______| 
    | \_____\   | / | |     | |   | |     | ||      | |     | || |    |____/| |     | | |     | 
     \ |    |___|/   \|_____|\|___|/|_____|/ |______|/|_____|/  \|____|   | | |_____|/ \|_____| 
      \|____|                                                         |___|/                    
   
    */
    

    /**
    * @dev Set merkle tree roots
    */
    function setRoot(bytes32 _root) external onlyOwner {

        merkleRoot = _root;

    }

    /**
    * @dev Open minting to the public
    */
    function setPublicMint(bool _value) external onlyOwner {

        isPublicMint = _value;

    }

    /**
    * @dev Set the base unrevealed uri, the upgrade uri, and or the revealed uri
    */
    function setURI(string calldata _uri, string calldata _upgradeUri, string[] calldata _revealedUri) external onlyOwner {

        baseURI = _uri;
        upgradeUri = _upgradeUri;

        require(_revealedUri.length == revealData.length, "Invalid data");

        for(uint i = 0; i < _revealedUri.length; i++) {

            revealData[i].uri = _revealedUri[i];

        }

    }

    /**
    * @dev Lowers the max supply
    */
    function lowerMaxSupply(uint _newSupply) external onlyOwner {

        require(_newSupply < maxSupply, "maxSupply needs to be lower than current max");
        maxSupply = _newSupply;

    }

    /**
    * @dev Reveals all nfts up to a range, and requests a random number to offset the ids to make the reveal as fair as possible
    */
    function reveal(uint range, string calldata uri) external onlyOwner {

        RevealData[] memory data = revealData;

        if(data.length > 0) {

            require(range > data[data.length - 1].range, "Range needs to be greator than last");
            require(data[data.length - 1].randomness > 0, "randomness needs to be set");
            
        }

        revealData.push(RevealData(range, 0, uri));

        requestRandomness(keyHash, fee);

    }

    /**
    * @dev overrides payment splitter release function to require caller to be reciever
    */
    function release(address payable account) public override  {

        require(account == msg.sender, "reciever must be caller");
        super.release(account);

    }

    /**
    * @dev Set trusted contracts that can expand the functionality of this collection
    */
    function setAcceptedAddress(address _addr, bool _value) external onlyOwner {

        acceptedAddresses[_addr] = _value;

    }

    /**
    * @dev ?
    */
    function startTheReckoning() external onlyOwner {
        require(reckoning == 0, "Reckoning already started");
        reckoning = block.timestamp;
    }

    /**
    * @dev Mint for team and for later giveaways
    */
    function teamMint(uint _amount) external onlyOwner {

        require(teamAllocation + _amount <= 200, "Minting too many");

        _safeMint(msg.sender, _amount);

        teamAllocation += _amount;

    }

}