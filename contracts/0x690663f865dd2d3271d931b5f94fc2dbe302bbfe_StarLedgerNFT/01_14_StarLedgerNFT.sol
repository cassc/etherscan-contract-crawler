// SPDX-License-Identifier: Unlicense

/*
                                  ......                    ......                                  
                             .^~~^:.                            .:^~~^.                             
                        .^!J?!:                                      :!?J!^.                        
                     :!J5J~.                                            .~J5J!:                     
                  :7Y55!.                                                  .!55Y7:                  
               .!JY5Y~                                                        ~Y5YJ!.               
             :7YY55^                                                            ^55YY7:             
           :?YY5P!                                                                !P5YY?:           
         .7YYYPY.                                ..                                .YPYYY7.         
        ~YYJ5G!                                  J?                                  !G5JYY~        
       7YYYPG:                                   #G                                   :GPYYY7       
     .JYYYPG.                                   !&B~                                   .GPYYYJ.     
    .YYYYPG.                                    G&B5                                    .GPYYYY.    
   .JYYYPB^                                    ^&#GB:                                    ^BPYYYJ.   
   JYYYPBJ                                     5&#GBJ                                     JBPYYYJ   
  !YYY5GG.                         .          .&&#GGG.          .                         .GG5YYY!  
 .YYYYGBJ                           :!.       J&&#GGB7       .!:                           JBGYYYY. 
 7YYJ5GB~                            .75~     #&&#GGGP     ~57.                            ~BG5JYY7 
.YYYYGGB:                              .YGJ^ !&&&#GGGB~ ^JGY.                              :BGGYYYY.
~YYYYGGB:                                :PBP#&&&#GGGGPPBP:                                :BGGYYYY~
7YYJ5GGB^                           ..^~7?P##&&&&#GGGGGGGY!~^:..                           ^BGG5JYY7
JYYYPGGB~                ..:~!?YPGB##&&&&&&&&&&&&#BGGGGGGBBBBBGGPP5J?!~^:..                ~BGGPYYYJ
YYYYPGGP            :~?YPB############BBBBBBBBBBBBP55555555555PPPPPPPGGPPP5J?!^.            PGGPYYYY
JYYYPGB^^:                ..:~!7JY5PGGGBBBGGGGGGGGYJJJJJJYYYYYYJJ?7!~^:..                 .^^BGPYYYJ
?YYYPGP~GY                           .:^~!YGGGGGGGYYYYYY57^::..                           JB~PGPYYY?
!YYJPGPPGB^                              :PBPPGGGGYYYYJPBP^                              ^BGPPGPJYY!
.YYY5GGGGGG                            .5GJ: ~BGGGYYYY: :JG5.                            PGGGGG5YYY.
 ?YYYGGGGGP                          .7Y~     PGGGYYYJ     ~Y7.                          PGGGGGYYY? 
 :YYJPGGGG5 !:                      :!.       7BGGYYY~       .~:                      :! 5GGGGPJYY: 
  7YYYGGGGY GG^                    .          .GGGYYY.          .                    ^GG YGGGGYYY7  
   JYJ5GGG5^BGB?                               JBGYY!                               ?BGB~5GGG5JYJ   
   .JYYPGGPYGGGBP                              :BGYY.                              PBGGGYPGGPYYJ.   
    .JYYGGGGGGGGB:                              5GY?                              :BGGGGGGGGYYJ.    
     .JYYGGGGGGGB7 :P~                          ~GY:                          ~P: 7BGGGGGGGYYJ.     
       7YYGGGGGGGP :BBG?.                        PJ                        .?GBB: PGGGGGGGYY7       
        ^YYPGGGGGB!.GGGBG7                       7~                       7GBGGG.~BGGGGGPYY^        
         .7YPGGGGGG:5GGGGBJ                      ..                      JBGGGG5:GGGGGGPY7.         
           :?5GGGGBYJGGGGGB:                                            :BGGGGGJYBGGGG5?:           
             :?PGGGGGGGGGGB~                                            ~BGGGGGGGGGGP?:             
               .7PGGGGGGGGG.                                            .GGGGGGGGGP7.               
                  ~YGBGGGG^                                              ^GGGGBGY~                  
                    .!5GBG7.                                            .7GBG5!.                    
                       .~JPGPJ~.                                    .~JPGPJ~.                       
                           .^7Y55J7^.                          .^7J55Y7^.                           
                                 .^~77!~^:.              .:^~!77~^.                                 
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StarLedgerNFT is ERC721, Ownable, Pausable, ReentrancyGuard {
    /**
     * @dev Emitted when `baseURI` is updated.
     */
    event BaseURIUpdate(string _baseURI);

    /**
     * @dev Emitted when `cost` is updated.
     */
    event CostUpdate(uint256 _cost);

    /**
     * @dev Emitted when `presaleMintEnabled` is updated.
     */
    event PresaleMintEnabledUpdate(bool _enabled);

    /**
     * @dev Emitted when `presaleTokensLimit` is updated.
     */
    event PresaleTokensLimitUpdate(uint256 _limit);

    mapping(address => bool) private _admins;

    string public baseURI;
    uint256 public cost;

    uint256 public totalSupply = 2500;
    uint256 public constant MAX_COUNT = 5000;

    bool public presaleMintEnabled;
    uint256 public presaleTokensLimit;
    mapping(address => uint256) private _presaleClaimedTokens;
    bytes32 private _presaleMerkleTreeRoot;

    constructor() ERC721("StarLedgerNFT", "STRLGR") {
        _admins[owner()] = true;
    }

    /**
     * @dev Adds account to admin list.
     *
     * Requirements:
     *
     * - `account` must be an address.
     */
    function addAdmin(address account) external onlyOwner {
        _admins[account] = true;
    }

    /**
     * @dev Returns whether account is admin.
     *
     * Requirements:
     *
     * - `account` must be an address.
     */
    function isAdmin(address account) external view onlyOwner returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Removes account from admin list.
     *
     * Requirements:
     *
     * - `account` must be an address.
     */
    function removeAdmin(address account) external onlyOwner {
        delete _admins[account];
    }

    /**
     * @dev Overrides _baseURI() to produce proper tokenURI().
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets new base URI.
     *
     * Requirements:
     *
     * - `newBaseURI` must be a string (ie. ipfs://abc/).
     *
     * Emits a {BaseURIUpdate} event.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;

        emit BaseURIUpdate(newBaseURI);
    }

    /**
     * @dev Sets mint cost.
     *
     * Requirements:
     *
     * - `newCost` must be an integer in wei.
     *
     * Emits a {CostUpdate} event.
     */
    function setCost(uint256 newCost) external onlyOwner {
        cost = newCost;

        emit CostUpdate(newCost);
    }

    /**
     * @dev Returns the merkle tree root for presale.
     */
    function presaleMerkleTreeRoot() external view onlyOwner returns (bytes32) {
        return _presaleMerkleTreeRoot;
    }

    /**
     * @dev Sets the merkle tree root for presale.
     *
     * Requirements:
     *
     * - `newMerkleTreeRoot` must be a merkle tree root hash.
     */
    function setPresaleMerkleTreeRoot(bytes32 newMerkleTreeRoot)
        external
        onlyOwner
    {
        _presaleMerkleTreeRoot = newMerkleTreeRoot;
    }

    /**
     * @dev Turns on/off presale.
     *
     * Requirements:
     *
     * - `enabled` must be a boolean.
     *
     * Emits a {PresaleMintEnabledUpdate} event.
     */
    function setPresaleMintEnabled(bool enabled) external onlyOwner {
        presaleMintEnabled = enabled;

        emit PresaleMintEnabledUpdate(enabled);
    }

    /**
     * @dev Sets maximum tokens one can mint during presale.
     *
     * Requirements:
     *
     * - `limit` must be an integer.
     *
     * Emits a {PresaleTokensLimitUpdate} event.
     */
    function setPresaleTokensLimit(uint256 limit) external onlyOwner {
        presaleTokensLimit = limit;

        emit PresaleTokensLimitUpdate(limit);
    }

    /**
     * @dev Internal mint function.
     *
     * Requirements:
     *
     * - `amount` The number of tokens to mint.
     */
    function _callMint(uint256 amount) internal {
        require(amount > 0, "You can't mint 0 tokens");
        require(totalSupply + amount <= MAX_COUNT, "Not enough tokens to mint");
        for (uint256 i = 1; i <= amount; i++) {
            uint256 nextTokenId = totalSupply + i;
            _safeMint(msg.sender, nextTokenId);
        }
        totalSupply = totalSupply + amount;
    }

    /**
     * @dev Mints token(s) as admin (2501-5000).
     *
     * Requirements:
     *
     * - `amount` The number of tokens to mint.
     */
    function adminMint(uint256 amount) external onlyAdmin {
        _callMint(amount);
    }

    /**
     * @dev Mints token(s) as admin (1-2500).
     *
     * Requirements:
     *
     * - `tokenIds` The IDs of the tokens to mint.
     * - Used to sync/bridge NFTs between Layer 1 and Layer 2.
     * - Should be 2500 or less.
     */
    function adminMintTokenIds(uint256[] memory tokenIds) external onlyAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0, "Token ID too low");
            require(tokenIds[i] <= 2500, "Token ID too high");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @dev Mints token(s) (presale).
     *
     * Requirements:
     *
     * - `amount` The number of tokens to mint.
     * - `proof` The merkle tree proof for the presale list.
     */
    function presaleMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
        withEnoughEth(amount)
    {
        require(presaleMintEnabled, "Presale minting disabled");
        require(
            _presaleClaimedTokens[msg.sender] + amount <= presaleTokensLimit,
            "Presale tokens limit reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, _presaleMerkleTreeRoot, leaf),
            "Incorrect proof"
        );

        _presaleClaimedTokens[msg.sender] += amount;
        _callMint(amount);
    }

    /**
     * @dev Mints token(s) (public sale).
     *
     * Requirements:
     *
     * - `amount` The number of tokens to mint.
     */
    function mint(uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        withEnoughEth(amount)
    {
        _callMint(amount);
    }

    /**
     * @dev Pauses public sale.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses public sale.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws funds.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Requires admin role.
     */
    modifier onlyAdmin() {
        require(_admins[msg.sender], "Caller is not an admin");
        _;
    }

    /**
     * @dev Requires a certain amount of ETH.
     */
    modifier withEnoughEth(uint256 amount) {
        require(msg.value >= cost * amount, "Not enough ETH");
        _;
    }
}