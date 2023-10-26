// SPDX-License-Identifier: MIT        
//
//
//                                                                                                                                         
//                                                                                    -d`              
//                                                                       `-/o+    :  :NMd`             
//                                                                `-/+. .dMMMMd. sM:+MMMMy             
//                                                         ``    `dMMMm. `oMMMMNyMMNMMMMMM.            
//                                                      :hmNd`   yMMMMMN-  +MMMMMMMMNMMMMm             
//                                           `.:+o:`   .NMMMMd. +MMMyMMMN: sMMMNMMMNsMMMMy             
//                                     `:+oymNNMMMMmo.`dMMNMMMm-+MMo +MMMd dMMMyoMM/sMMMM+             
//                               `/oyd` /NMMMMMmNMMMm.yMMN-oMMMN`/y` :MMMo`MMMM/`mo dMMMM.             
//                      `.://    :MMMm ` mMMM:.-NMMN-+MMM/  NMMN  `  yMMM-:MMMM` -  NMMMN          .:` 
//                 ./y. hNNMo    oMMMy mhMMMm `hMMM/-NMMs  -MMMy h+-`NMMN sMMMd    -MMMMh      `:ohNN  
//             .:sdNMN `MMMM:..  hMMM+-MMMMMm-sMMMo.mMMN:  oMMM/:MMNmMMMy mMMMs    +MMMM+  `-+hmNMMMd  
//         `:ohmMMMMMy :MMMMmNs:+NMMM.+MMMMMMNMMMy :dNMMNdomMMM``ohNMMMN/`yo/-`    oNMMN-`ymNMMMMNds-  
//        .mMMMMMmho-` sMMMMMMMMMMMMN hMMMydNMMMMms:.-+hNMMMMMd    .//::-  :yho:-` `.-:. /MMMMds:.`    
//        /MMMNh+-`    ss+MMMMMmNMMMh NMMM``-+hNMMMMmy/--+hdhs:  .-/oydmd  hMMMMNmh`     sMMMMmhso/:-.`
//        yMMMMNNmdhyo+: -MMMh-.hMMM+.MMMd     ./ymmdhs:``.:/:`-yNMMMMMMy  NMMMMMMMdhs+` ymmNMMMMMMMNNd
//        /oyhdmNNMMMMMN +MMMo  NMMM-+MMMs        -::/oydmmd+:yNMMMdNMMM/ -MMMo/ohdMMMN   `.--/+syMMMMh
//            `..-/NMMMy hMMM- .MMMN smhs-  `-/oyhmNMMMMMd/:yNMMMNo`NMMM. +MMM-   .MMMh      `.-:oMMMM+
//    `.-/oy+.-/oydMMMM+ NMMN  /MMMh ``-oyh sMMMMMMNmdhs:.yNMMMMMMmdMMMN  yMMN   .sMMM+ .:+shdmMMMMMMM-
// .shdNMMMMNNMMMMMMMMN-`dyo:  yMMMo   yMMh mmmhs+:-.`   yMMMN/sdNMMMMMh  mMMh .omMMNs.+mMMMMMMMMNmdhs 
// sMMNNmNMMMMMNNmdyo/-        mMMM:   NMMo -.```.:+sy`  NMMMNs: -/mMMM+ .MMMyomMMMd:-hMMMNmmhs+:-`    
// oo/-.`ymdyo/:.`            `MMMM`  -MMM-   -dmMMMMd  -MMMMMM-   hMMM- /MMMNMMMm+`odhs+:-.           
//       .`                   :MMMd.:+hMMN    oMMNNmh/  /yoMMMN    NMMN` sMMNNmho. `.                  
//                            sMMMMMMMMMMh    oo/-.   ``` .MMMh   .MMNh  ++/-`                         
//                            dMMMMMNNMMMo     ``.:+shdNs +MMM+   -o/-`                                
//                           `MMMM/-.:MMM:`-/sydNMMMMMMM: +yo/`                                        
//                           -MMMm   oMMM.`dMMMMMNNdyo/-                                               
//                           oMMMs   dMMMd.`yyo/:.                                                     
//                           hMMM/  `dyo/-`                                                            
//                           mdyo`              
//
//
//                                                                                                                                                                                                        

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ShroomHeads is EIP712, AccessControl, ReentrancyGuard, ERC1155Supply
{
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    // roles
    bytes32 public constant TEAM = keccak256("TEAM"); // 0x9b82d2f38fbdf13006bfa741767f793d917e063392737837b580c1c2b1e0bab3
    address[] public payees;
    mapping(address => uint256) private shares;
    uint256 private totalShares;
    address private signerAddress;

    // Opensea come on. It's for OS only
    address public owner;

    // NFT
    struct NFTStruct {
        bytes1 traits;
        uint256 price;
        uint8 editions;
        uint8 saleType; // 0 - public; 1 - private; 2 - auction; 3 - extras not for sale
    }
    NFTStruct[] private Nfts;

    // variables
    uint256 public state;
    address public WETH; // made varible for more convenient testing
    mapping (uint256 => mapping(address => uint256)) public wlBalance;

    // events
    event Mint(address minter, uint256 tokenId, uint256 amount);
    event AuctionWin(address minter, uint256 tokenId, uint256 amount);
    event CraftNFT(uint256 tokenId, bytes1 traits, uint256 price, uint8 editions, uint8 saleType);

    constructor(address _owner, string memory uri_, address[] memory _team, uint256[] memory _shares, address wETH, address _signerAddress) ERC1155(uri_) EIP712("ShroomHeads", "1") {
        // roles
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(TEAM, _owner);
        owner = _owner;

        // wETH
        WETH = wETH;

        // payment splitter
        require(_team.length == _shares.length, "Payees and shares length mismatch");
        require(_team.length > 0, "No payees");
        for (uint256 i = 0; i < _team.length; i++) {
            addPayee(_team[i], _shares[i]);
        }

        // signer
        _setSignerAddress(_signerAddress);
    }

    /**
     * @dev Override supportsInterface from AccessControl
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId);
    }

    /**
     * @dev Private
     */
    function _setSignerAddress(address addr) private {
        signerAddress = addr;
    }

    /**
     * @dev Changes signer address for raffles. In case of emergency
     */
    function setSignerAddress(address addr) external onlyRole(TEAM) {
        _setSignerAddress(addr);
    }

    /**
    * @dev 0 - paused, 2 - sale
    */
    function setState(uint256 val) external onlyRole(TEAM) {
       state = val;
    }

    /**
     * @dev Craft new NFTs
     */
    function craftNewNfts(bytes1[] calldata _traitsHex,
                          uint256[] calldata _prices,
                          uint8[] calldata _editions,
                          uint8[] calldata _saleType) external onlyRole(TEAM) 
        {
        require(_traitsHex.length == _prices.length && 
                _prices.length == _editions.length &&
                _editions.length == _saleType.length, "All args should have same length");
        require(Nfts.length+_traitsHex.length <= 130, "The total amount of NFTs can be > 100 characters + ~30 of different perks");

        for (uint256 i = 0; i < _traitsHex.length; i++) {
            uint256 tokenId = Nfts.length;
            
            require(_editions[i] > 0 && _editions[i] <= 7, "Number of editions should be > 0 and <= 7");
            require(_prices[i] != 0, "Price should be > 0");
            require(_saleType[i] <= 3, "Unknown sale type");

            NFTStruct memory tmpNft = NFTStruct({traits:_traitsHex[i],
                                                 price:_prices[i],
                                                 editions:_editions[i],
                                                 saleType: _saleType[i]});
            Nfts.push(tmpNft);

            // emit event
            emit CraftNFT(tokenId, tmpNft.traits, tmpNft.price, tmpNft.editions, tmpNft.saleType);
        }
    }

    /**
     * @dev ONLY IN EMERGENCY case Update NFT info
     */
    function correctExistingNftTraits(uint256 tokenId, bytes1 _traits) external onlyRole(TEAM) {
        require(tokenId< Nfts.length, "NFT doesn't exist");
        Nfts[tokenId].traits = _traits;
    }

    /**
     * @dev ONLY IN EMERGENCY case Update NFT info
     */
    function correctExistingNftPrice(uint256 tokenId, uint256 _price) external onlyRole(TEAM) {
        require(tokenId< Nfts.length, "NFT doesn't exist");
        require(_price > 0, "Price should be > 0");
        Nfts[tokenId].price = _price;
    }

    /**
     * @dev ONLY IN EMERGENCY case Update NFT info
     */
    function correctExistingNftEdition(uint256 tokenId, uint8 _editions) external onlyRole(TEAM) {
        require(tokenId< Nfts.length, "NFT doesn't exist");
        require(_editions> 0 && _editions<= 7, "Number of editions should be > 0 and <= 7");
        Nfts[tokenId].editions = _editions;
    }

    /**
     * @dev ONLY IN EMERGENCY case Update NFT info
     */
    function correctExistingNftSaleType(uint256 tokenId, uint8 _saleType) external onlyRole(TEAM) {
        require(tokenId< Nfts.length, "NFT doesn't exist");
        require(_saleType <= 3, "Unknown sale type");
        Nfts[tokenId].saleType = _saleType;
    }

    /**
    * @dev Mint
    */
    function mint(uint256 tokenId, uint256 amount) external nonReentrant payable {
        require(amount > 0, "Amount should be > 0");
        require(state == 2, "Sale is paused");
        require(msg.value == Nfts[tokenId].price.mul(amount), "Wrong ETH amount");
        require(Nfts[tokenId].saleType == 0, "This NFT is not put on public sale");

        // mint
        _mintBase(_msgSender(), tokenId, amount);

        // emit
        emit Mint(_msgSender(), tokenId, amount);
    }

    /**
    * @dev Mint for private sales
    */
    function privateMint(uint256 tokenId, bytes memory _signature) external nonReentrant payable {
        require(state == 2, "Sale is paused");
        require(msg.value == Nfts[tokenId].price, "Wrong ETH amount");
        require(Nfts[tokenId].saleType == 1, "This NFT is not put on private sale");
       
        //check signature
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Raffle(uint256 nft_id,address minter)"),
            tokenId,
            _msgSender()
        )));
        require(signerAddress == ECDSA.recover(digest, _signature), "Not authorized. You need to be whitelisted on Discord");
        
        require(wlBalance[tokenId][_msgSender()] == 0, "Only 1 edition per account is allowed for private sale");
        
        // increase wl balance
        wlBalance[tokenId][_msgSender()] = wlBalance[tokenId][_msgSender()].add(1);

        // mint
        _mintBase(_msgSender(), tokenId, 1);

        // emit
        emit Mint(_msgSender(), tokenId, 1);
    }

    /**
    * @dev Mints for auction
    */
    function auctionMint(uint256 tokenId, address winningBidder, uint256 winningBid, uint256 ts, bytes memory _signature) external nonReentrant onlyRole(TEAM) {
        // check signature
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Bid(string action,uint256 nft_id,address bidder,uint256 amount,uint256 timestamp)"),
            keccak256(bytes("place_bid")),
            tokenId,
            winningBidder,
            winningBid,
            ts
        )));
        require(winningBidder == ECDSA.recover(digest, _signature), "Bad signature");
        
        // other checks
        require(totalSupply(tokenId) == 0, "Could only be charged once");
        require(Nfts[tokenId].saleType == 2, "This NFT is not on auction");
        require(IERC20(WETH).allowance(winningBidder, address(this)) >= winningBid, "The bidder doesn't have enough allowance");
        
        // charge WETH
        require(IERC20(WETH).transferFrom(winningBidder, address(this), winningBid));
        
        // mint
        _mintBase(winningBidder, tokenId, 1);
        
        // emit
        emit AuctionWin(winningBidder, tokenId, winningBid);
    }

    /**
    * @dev Mints for giveaways
    */
    function airdrop(address to, uint256 tokenId, uint256 amount) external onlyRole(TEAM) {
        require(to != address(0), "Cant drop to Null address");
        require(tokenId < Nfts.length, "No such NFT");
        require(amount > 0, "Amount should be >0");

        // mint
        _mintBase(to, tokenId, amount);
    }

    /**
    * @dev base mint
    */
    function _mintBase(address to, uint256 tokenId, uint256 amount) private {
        // check if token has enough editions
        require(totalSupply(tokenId).add(amount) <= uint256(Nfts[tokenId].editions), "This NFT id has not enough left editions");

        // mint
        _mint(to, tokenId, amount, "");
    }
    
    /** 
    * @dev List NFTs owned by address. As total amount of NFTs is low - ok to iterate thru all of them
    */
    function listNFTs(address _owner) external view returns(uint256[] memory) {
        uint256[] memory balances = new uint256[](Nfts.length);
        for (uint256 i = 0; i < Nfts.length; i++) {
            balances[i] = balanceOf(_owner, i);
        }
        return balances;
    }

    /**
     * @dev Set url. Later to migrate all NFTs to IPFS
     */
    function setURI(string memory newuri) external onlyRole(TEAM) {
        _setURI(newuri);
    }

    /**
     * @dev Overwrite ERC1155 uri method
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev Read NFTs info
     */
    function getNftsInfo(uint256 tokenId) external view returns (bytes1, uint256, uint8, uint8, uint256) {
        require(tokenId < Nfts.length, "Such NFT doesn't exist");
        return (Nfts[tokenId].traits, Nfts[tokenId].price, Nfts[tokenId].editions, Nfts[tokenId].saleType, totalSupply(tokenId));
    }

    /**
    * @dev Withdraw ether
    */
    function withdraw() external {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            Address.sendValue(payable(payees[i]), balance.div(totalShares).mul(shares[payees[i]]));
        }
    }

    /**
     * @dev Withdraw ERC20
    */
    function withdrawERC20(address tokenAddress) external {
        require(shares[_msgSender()] > 0, "Only team members are allowed");
        // get balance 
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(payees[i], balance.div(totalShares).mul(shares[payees[i]]));
        }
    }

    /**
    * @dev Add Payee
    */
    function addPayee(address account, uint256 shares_) private {
        require(account != address(0), "Account is the zero address");
        require(shares_ > 0, "Shares are 0");
        require(shares[account] == 0, "Account already has shares");

        payees.push(account);
        shares[account] = shares_;
        totalShares = totalShares.add(shares_);
    }

    /**
    * @dev total count of nfts
     */
    function getNftsCount() external view returns(uint256){
        return Nfts.length;
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
    }
}