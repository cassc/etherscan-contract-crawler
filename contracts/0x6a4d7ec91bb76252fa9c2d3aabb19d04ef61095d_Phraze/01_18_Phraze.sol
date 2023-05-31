//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

//   ,:´'*:^-:´¯'`:·,         ‘          ,:'/¯/`:,       .·/¯/`:,'       .:'/*/'`:,·:~·–:.,                        ,.-:~:-.                                   _ ‘                     ,.-:~:'*:~-.°  
//  '/::::/::::::::::;¯'`*:^:-.,  ‘     /:/_/::::/';    /:/_/::::';     /::/:/:::/:::;::::::/`':.,'                /':::::::::'`,               /:¯:'`:*:^:*:´':¯::/'`;‘              .·´:::::::::::::::;  
// /·´'*^-·´¯'`^·,/::::::::::::'`:,    /:'     '`:/::;  /·´    `·,::';  /·*'`·´¯'`^·-~·:–-'::;:::'`;             /;:-·~·-:;':::',             /:: :: : : : : : :::/::'/             /::;:-·~^*^~-:;:/ ° 
// '`,             ¯'`*^·-:;::::::'\' ‘ ;         ';:';  ;         ';:;  '\                       '`;::'i‘         ,'´          '`:;::`,         ,´¯ '` * ^ * ´' ¯   '`;/    ‘      ,.-/:´     .,       ;/     
//   '`·,                     '`·;:::i'‘ |         'i::i  i         'i:';°   '`;        ,– .,        'i:'/         /                `;::\        '`,                  ,·'   '        /::';      ,'::`:~.-:´;     
//      '|       .,_             \:'/'  ';        ;'::/¯/;        ';:;‘'     i       i':/:::';       ;/'        ,'                   '`,::;         '`*^*'´;       .´         ‘    /;:- ´        `'·–·;:'/' _   
//      'i       'i:::'`·,          i/' ‘ 'i        i':/_/:';        ;:';°     i       i/:·'´       ,:''         i'       ,';´'`;         '\:::', ‘          .´     .'      _   ' ‘  /     ;:'`:.., __,.·'::/:::';  
//      'i       'i::/:,:          /'     ;       i·´   '`·;       ;:/°      '; '    ,:,     ~;'´:::'`:,    ,'        ;' /´:`';         ';:::'i‘       .´      ,'´~:~/:::/`:,  ;'      ';:::::::::::::::/;;::/  
//       ;      ,'.^*'´     _,.·´‘      ';      ;·,  '  ,·;      ;/'        'i      i:/\       `;::::/:'`;' ;        ;/:;::;:';         ',:::;     .´      ,'´::::::/:::/:::'i‘ ¦         '`·-·:;::·-·'´   ';:/‘  
//       ';     ;/ '`*^*'´¯              ';    ';/ '`'*'´  ';    ';/' '‘        ;     ;/   \       '`:/::::/''i        '´        `'         'i::'/   ,'        '*^~·~*'´¯'`·;:/  '\                         /'    
//        \    /                          \   /          '\   '/'            ';   ,'       \         '`;/' ¦       '/`' *^~-·'´\         ';'/'‚  /                        ,'/     `·,                  ,·'  '    
//         '`^'´‘                           '`'´             `''´   '           `'*´          '`~·-·^'´    '`., .·´              `·.,_,.·´  ‚ ';                      ,.´           '`~·- . , . -·'´          
//                                                          '                                                                                '`*^~–––––-·~^'´                                        

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

contract Phraze is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private tokenCounter;
    using Strings for uint256; 
    string private baseURI;
    uint256 public constant MAX_PASSES_PER_WALLET = 1;
    uint256 public maxPasses;
    uint256 public constant PUBLIC_SALE_PRICE = 0.16 ether;
    uint256 public constant COMMUNITY_SALE_PRICE = 0.09 ether;
    bool public isPublicSaleActive;
    bool public isCommunitySaleActive;
    bool public transfersLocked;
    bytes32 public communitySaleMerkleRoot = 0x36153bdef397ee43029e0e85a49064e503f238a04e5ac831f3e73584e6b9ef8d;
    mapping(address => uint256) public communityMintCounts;
    event NewMint(address, uint256);

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier maxPassesPerWallet() {
        require(
            balanceOf(msg.sender) + 1 <= MAX_PASSES_PER_WALLET,
            "Max passes to mint is one"
        );
        _;
    }

    modifier canMintPasses() {
        require(
            tokenCounter.current() + 1 <= maxPasses,
            "Not enough passes remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(
            price * 1 == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
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
    constructor(
        uint256 _maxPasses
    ) ERC721("PhrazeBoard", "PHRAZE") {
        maxPasses = _maxPasses;
        baseURI = "ipfs://QmZWni2oKobMTtBDgw2o1ErbW6PyC2ZMM29K4gkGjWQn33/";
        transfersLocked = false;
        isPublicSaleActive = false;
        isCommunitySaleActive = true;
        communitySaleMerkleRoot = 0x36153bdef397ee43029e0e85a49064e503f238a04e5ac831f3e73584e6b9ef8d;
    }

    function mint()
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        publicSaleActive
        canMintPasses()
        maxPassesPerWallet()
    {
        uint256 tokenId = nextTokenId();
         _safeMint(msg.sender, tokenId);
         emit NewMint(msg.sender, tokenId);
    }

    function mintCommunitySale(
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
        communitySaleActive
        canMintPasses()
        isCorrectPayment(COMMUNITY_SALE_PRICE)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + 1 <= MAX_PASSES_PER_WALLET,
            "Max passes to mint in community sale is one"
        );

        require(
            tokenCounter.current() + 1 <= maxPasses,
            "Not enough passes remaining to mint"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + 1;

        uint256 tokenId = nextTokenId();
         _safeMint(msg.sender, tokenId);
         emit NewMint(msg.sender, tokenId);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setTransfersLocked(bool _transfersLocked)
        external
        onlyOwner
    {
        transfersLocked = _transfersLocked;
    }

    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }


    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============= OVERRIDES ====================

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!transfersLocked, "Cannot transfer - currently locked");
    }

    // transfer back to owner for print burn
    // check if token transfer is owner 
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }
    receive() external payable {}
}