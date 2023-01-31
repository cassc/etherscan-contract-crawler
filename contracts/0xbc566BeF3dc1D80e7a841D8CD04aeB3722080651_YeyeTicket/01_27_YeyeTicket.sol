/*..                                                      
                                         .:::    .::^^^^75GGGGBB#BP?77?7~^.    ^7?7~:                                   
                                      .?G#&&&BY:~B&&&&&&@&&@&@@&@@&@@@@@@#B7 7B&@@@@&G!                                 
                                     ^[email protected]@@@&@@@#:Y&&&&&&&##&&&&&&&##&#&&&&B:[email protected]&@&&@&@@@J                                
                                    [email protected]#[email protected]!5&[email protected]&&@&&@&&@&&&@&&@&&&&&@&[email protected]&GJ5##55#&:                               
                                    .BG~.:7:~?^~^[email protected]&@&@@@&&@&@@&@&&@&@@&&@&Y:~!:^^~~:~^7                                
                                  :7^^^^5PJ5#&#B&@&@&&@&&&&@&&&#&@&&&#&&#&&&BYJ5BB5PB#GY!                               
                                .J##BPG#&&@&#PJ77!777JP#&&&&&&&&&&#&&#&&&&#&@&@&&@&@&PY?7:                              
                               :[email protected]@&@&@@@@G!^!YPGBBBGY7^[email protected]&@&&@@&#&&#@@&@&&@@&@&@#7^!JPGBG5?^                          
                              :[email protected]&&@&@&@&!:JB&&&&&&@@@@#Y:[email protected]&&@@@&&@&&@&@@#&@&&@Y.!G&&&&&@@@&P^                        
                            !YP&&&&&&&&#^^G########&&&&@@#~:G##&#&&&&&&@@&&&BG#&5 J#######&&&@@&!                       
                           7P#&&&#&&&&&!.G#B########&&&&&@&^:77^^7PPGGGGGPP5:::7.~########&&&&&@&^                      
                          ^PY#@@#&@&@@B 7#BB###BP5#@&##&&&@5 ^ ^~..^~~~~~~^ .7~  J#B####GP#@&&&&@5                      
                          :~.!YGY5&&@&B ?#BB&&#P~ 7G######&G ^ ?57:^!!!!~~^^?J!. ?#B#&&GJ .YB###&G                      
                       ^JPGGGPJ~: 7&&&@^:##B&@#GJ:?G######&J ^ ^^?~~^^!~^!!!~~Y. ^B##&@B57^YB###&J                      
                     ^P#GY?7JG##G! ?B&@P 7####&##BB######&G.!! [email protected]~ GY JG ~&?.P5. !###&&#BB####&G.                      
                    !B#Y^?YY7.J#&B^.P&&&P.!G###########&#5.~B7 :75.:#? 5G.:5#::7:J.^P##########5.                       
                   :BBG~PGGGG! P#B! Y#&&&B7:7PB#######GY~:JB#! ^::^:~::^^:^:!^^:.PG7:~JPGBBBPJ~^Y:                      
                   ~BBG5GGG5?7 ^55^ JB&@&@@J  :~7777!^:!YGB##7 ^^:::.:^:.:::.::::!JBGJ!~~:::. .7Y7                      
                   :GBBP5P!!YPP?!7: [email protected]@&P!:~7?JJJJ?!^^~JB###7 ^..^^^^7Y5JJ7::JPG5!^B#B5^:7J555J7~.                     
                    7BBG?^!#&&#GGP:.5#@&7.!YPGGPPPGGP5PY^:5##7 ..^::^: ~5PP#B?^YB#B^~#5 !YPPPPPP5PY^                    
                     !PBBPB##BGPJ: !G&@? ?YYYYYYYYYYYY55Y! P#? .:.^~^^: ?5JG&#Y:5#&Y.G^:YYYYYYYYYYYY:                   
                      .~?YYYJ?!^~:^P#&&^.JYYYYYJJJ???JJJY? J#J :.!~^~J: !Y7YG#B7~PGY.P!.????777?JJJY~                   
                        ^!~~^ ~YYJB#&@&? ~7???7!~^^^^^~~~.~GB5 :.B5.7#: ^Y!7YP5J^J5Y.7!:^~^::^^:~~!~.                   
                        :5P#[email protected]@#&@&#J:.^^^:^~7JJ?!~~!YBBBG...PP !&^ :7^^?YJ?^77^^!!!~!~.7B5 :7^                     
                         !PGP#BG&@&&@&#&&G: 7YPGB#####BBBBBBBB? ^~!7!7!:.!^:!JJ!~!.~!^^^^.75PJ:^GJ^                     
                          ~~YBP#&@&&@&&@&&#J^^7YPBB#####BBBGBB#J^:^~~^^..!~.~77~:.!!~7!7~.7~^~J#5                       
                            ^55B&@&&@&&@&@&&#57~^^^~!!!7777~:!P##GYJ??JJ.^!::^^:.!!~J7~Y~.?YG#&G:                       
                             ^YP#&#&@&@&&@&&@&&#BP5YJJ????7777:~JPB##BGY. ~7!~^~7~^YY:~Y:~&@@&G!                        
                              .?GPP&&#&&#&&&&##@&&&&#&######BBPJ!^^~~~~!!^.:~!!~:.^~..^:^[email protected]&#P!                         
                                ^:~G#&&&&@&&#&&&&&##&@&&@&@&&@&##BGPPGBBBBP?!~^^~7????JP&@&5!^                          
                                   ~YG#B&@&&&&@&&@&#&&#&@#&&#&@@@&@&&@&&&@&&@&&&&&@@@@@&&BJ                             
                                    .~JYYB&&&#@&&@&###&&&&&&#[email protected]@@@@@@@&PGY?&@&&&GGB5~                              
                                       :.~JGBPG#&&&#&#&@&&#&&#PJ7^^7?JJPBGJ~:~J#@&&BJ~J!.                               
                                           :!?^?PGBPB#&@&&#&@&&@&#P5YJ!~~!?PBBBBB57: :                                  
                                                .~?7:75GB##BB#&&&#####BBBBGY7!7!^                                       
                                                       :~!7??7!7JYYYYYY?!^.                                             
                                                                   */


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "./WhiteList.sol";
import "./YeyeBase.sol";

contract YeyeTicket is ERC721A, DefaultOperatorFilterer, Pausable, ReentrancyGuard, WhiteList, AccessControl {
    /* =============================================================
    * CONSTANTS
    ============================================================= */

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    /* =============================================================
    * STATES
    ============================================================= */

    string private _baseTokenURI;

    mapping (uint => uint) public price;
    uint public supply;
    uint public batch;
    uint public maxMint;
    uint public closedIn;
    mapping (uint => mapping (address => uint)) public minted;

    address payable immutable public withdrawAddress;

    /* =============================================================
    * MODIFIER
    ============================================================= */

    modifier supplyCheck(uint quantity) {
        require((totalSupply() + quantity) <= supply, "Mint quantity exceeds supply");
        _;
    }

    modifier mintQuotaCheck(uint quantity) {
        uint currentMinted = minted[batch][msg.sender];
        require((quantity + currentMinted) <= maxMint, string(abi.encodePacked("Remaining mint quota: ", Strings.toString(maxMint - currentMinted), " ticket")));
        _;
    }

    
    modifier whenNotClosed {
        require(block.timestamp <= closedIn, "Mint is not started");
        _;
    }

    /* =============================================================
    * CONSTRUCTOR
    ============================================================= */

    constructor(address payable _withdrawAddress) ERC721A("YEYE TICKET", "YEYE") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(FACTORY_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);

        withdrawAddress = _withdrawAddress;

        setSupply(6969);
        setMaxMint(3);
        setPrice(1, 0);
        setPrice(2, 0.009 ether);
        setPrice(3, 0.01 ether);
    }

    /* =============================================================
    * GETTERS
    ============================================================= */    

    function getTimeLeft() public view whenNotClosed returns (uint _timeLeft) {
        _timeLeft = closedIn - block.timestamp;
    }

    function getCurrentSupply() public view returns (uint[2] memory _supply) {
        _supply[0] = totalSupply();
        _supply[1] = supply;
    }

    function claimedTicket(address _account) public view returns (uint _claimed) {
        _claimed = minted[batch][_account];
    }

    /* =============================================================
    * SETTERS
    ============================================================= */

    function startMint(uint hour) public onlyRole(DEFAULT_ADMIN_ROLE) {
        closedIn = block.timestamp + (hour * 1 hours);
    }

    function closeMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        closedIn = 0;
    }

    function setSupply(uint newSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newSupply >= totalSupply(), "New supply must higher than total mint");
        supply = newSupply;
    }

    function setMaxMint(uint newValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMint = newValue;
    }

    function setPrice(uint i, uint newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        price[i] = newPrice;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMerkleRoot(newRoot);
    }

    function openPublicMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRequireWhiteList(false);
    }

    function closePublicMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRequireWhiteList(true);
    }
    
    function nextBatch() public onlyRole(DEFAULT_ADMIN_ROLE) {
        batch += 1;
    }
    
    function prevBatch() public onlyRole(DEFAULT_ADMIN_ROLE) {
        batch -= 1;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(URI_SETTER_ROLE) {
        _baseTokenURI = baseURI;
    }

    /* =============================================================
    * MAIN FUNCTION
    ============================================================= */

    function airdrop(address[] calldata account, uint256[] calldata quantity) external onlyRole(AIRDROP_ROLE) {
        require(account.length == quantity.length, "Address to quantity length mismatch");
        for (uint i = 0; i < account.length; i++) {
            _safeMint(account[i], quantity[i]);
        }
    }

    function mint(bytes32[] calldata proof, uint256 quantity) external payable whenNotPaused whenNotClosed nonReentrant supplyCheck(quantity) mintQuotaCheck(quantity) {
        require(msg.value >= calculatePrice(quantity), "Not enough ETH");
        minted[batch][msg.sender] += quantity;

        if (requireWhiteList) {
            _listedMint(proof, quantity);
        } else {
            _publicMint(quantity);
        }
    }

    function _listedMint(bytes32[] calldata proof, uint256 quantity) internal onlyListed(proof) {
        _safeMint(msg.sender, quantity);
    }

    function _publicMint(uint256 quantity) internal {
        _safeMint(msg.sender, quantity);
    }

    function calculatePrice(uint quantity) public view returns (uint calculated) {
        uint currentMinted = minted[batch][msg.sender];
        for (uint i = 1; i <= (currentMinted + quantity); i++) 
        {
            if (i <= currentMinted) continue;
            calculated += price[i];
        }
    }

    function factoryBurn(uint tokenId, address owner) external onlyRole(FACTORY_ROLE) {
        require(ownerOf(tokenId) == owner, "You do not own this token");
        _burn(tokenId);
    }

    function withdrawAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(withdrawAddress != address(0), "Cannot withdraw to Address Zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "there is nothing to withdraw");
        Address.sendValue(withdrawAddress, balance);
    }
    
    /* =============================================================
    * OPERATOR FILTER
    ============================================================= */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        payable
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    /* =============================================================
    * MISC
    ============================================================= */

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() external virtual whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external virtual whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}