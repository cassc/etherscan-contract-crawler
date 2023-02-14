// SPDX-License-Identifier: MIT

/**  
G̷̭̑ L̷͉̕ I̴̜̘̅ T̴̳̗̽ C̴̤̽ H̸̘͑  ̴̠́ D̶͙͑̓͜ Ḝ̶͕̈ C̵̥͝ K̵̞͖͋  Animated Generative Glitch Art
.------..------..------..------..------..------.             
|G.--.♦||L.--.♠||I.--.♥||T.--.♠||C.--.♦||H.--.♠|             
| :/\: || :/\: || (\/) || :/\: || :/\: || :/\: |             
| :\/: || (__) || :\/: || (__) || :\/: || (__) |             
|♦'--'G||♠'--'L||♥'--'I||♠'--'T||♦'--'C||♠'--'H|             
`------'`------'`------'`------'`------'`------'             
.------..------..------..------.     .------..------..------.
|D.--.♠||E.--.♥||C.--.♦||K.--.♦|.-.  |N.--.♣||F.--.♣||T.--.♠|
| :/\: || (\/) || :/\: || :/\: ((X)) | :(): || :(): || :/\: |
| (__) || :\/: || :\/: || :\/: |'-.-.| ()() || ()() || (__) |
|♠'--'D||♥'--'E||♦'--'C||♦'--'K| ((V))♣'--'N||♣'--'F||♠'--'T|
`------'`------'`------'`------'  '-'`------'`------'`------'
GLITCH DECK NFT is a pioneering glitch-art project by Jim Dee of GenerativeNFTs.io (@SwiggaJuice). It consists of 8,100 playing-card-themed ANIMATED glitch-art NFTs with regular and dynamic traits (meaning, even when two NFTs have the same trait, they often appear differently on each NFT, bestowing even more uniqueness to each token than normal generative sets). As of today (Feb. 13, 2023), the artwork is generating. I expect the final total size of the drop to surpass 90GB(!) and require a full week to render. Reveal is scheduled for Feb. 21, 2023, depending on final rendering / uploading time.

Of the 8,100 tokens: up to 2,699 are available to the Deck of Degeneracy (DoD) NFT community as follows: 

1̴̩̩̉    FIVE free mints per holder (512 holders * 5 == 2560 mints) via exclulsive open allow-list for one week. All DoD holder wallets (as of a snapshot taken at 9:51pm PST on Feb. 11, 2023) have been allow-listed for the claim period. The free-claim allow-list itself will remain open until full set mint-out, but mints will not be guaranteed after the first week, as the public could mint the set out anytime thereafter after.

2̵͔͒͑    43 contract claims allotted to DoD top-five holders. Claims will be available for two weeks. After that, this allotment will be returned to the public supply pool.

3̷̟̋    96 special editions will be airdropped, *post-mint-out*, to those who held 6+ DoD NFTs as of my snapshot on Feb. 11, 2023.

Public sale opens one week after allow-list launch. 

Marketing Partner bonus for DoD holders:  40% of the primary mint proceeds will be stored in this wallet: 0xa7CfE42834468cedbD986D58950700E84AEE59A0. The funds that accrue there, provided they meet levels and timeline discussed at GlitchDeck.xyz, will be sent out equally among all holders of DoD as of snapshot date (above). Detailed info on how that works is available on the web site, but the goal is to sell out this (awesome) set, get cool glitch-art collectibles into DoD hands, and possibly distribute approximately $100k in ETH (current value) equally among the 512 current holders in the snapshot. 

Will we realize this crazy goal? I have no idea. But we can try. :-)  

For info see GlitchDeck.xyz. Thanks & good luck! ♠ ♣ ♥ ♦ 

    J̴̙̺͂i̷̗͎̍̍̀̕m̵̛͈͗͒̓̿
  ♠ ♣ ♥ ♦ 
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol"; 
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract GLITCHDECK is Ownable, ERC721A, PaymentSplitter, DefaultOperatorFilterer {

    uint public maxSupply  = 8100;        // Hard-coded ceiling in setMaxSupply() also.
    uint public mintPrice  = 0.042 ether; // Initial street price (subject to change)
    uint public degenPrice  = 0 ether;    // Allowlist price for DoD holders
    uint public promoPrice = 0.037 ether; // Initial promo price if offered via affiliates:
    bool public presaleIsLive = false;    // (Affiliates earn ~0.0055 / mint, if engaged)
    string public provenanceHash;         // TB calc'd / set post-launch, as 90GB+ still generating!
    uint public reservedNFTs;
    bool public saleIsLive = false;
    uint public walletLimit = 100;          
    string private contractURIval;
    string private metadataURI;
    bool private mintLock;
    bool private provenanceLock = false;
    uint id = totalSupply();

    bytes32 public merkleRoot;
    mapping(address => bool) public allowlistClaimed;

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        uint isAdmin;
    }
    mapping(address => Account) public accounts;

    struct AffiliateAccount {
    	uint affiliateFee;
    	uint affiliateUnpaidSales;
    	uint affiliateTotalSales;
    	uint affiliateAmountPaid;
        address affiliateReceiver;
        bool affiliateIsActive;
    }
    mapping(string => AffiliateAccount) public affiliateAccounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    string[] private affiliateDistro;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim, bytes32 _merkleRoot)
        ERC721A("Glitch Deck NFT", "GLITCH") 
        PaymentSplitter(distro, distro_shares)
    {
        metadataURI = "https://api.generativenfts.io/glitchdeck-prereveal/"; // Prereveal

        accounts[msg.sender] = Account( 0, 0, 0 );

        // ♠ ♣ ♥ ♦ Accounts ♠ ♣ ♥ ♦
        accounts[teamclaim[0]] = Account( 50, 0, 3); //  GlitchDeck deployer
        accounts[teamclaim[1]] = Account( 25, 0, 1); //  JD wallet
        accounts[teamclaim[2]] = Account( 25, 0, 1); //  WD wallet
        accounts[teamclaim[3]] = Account(  2, 0, 1); //  60-DoD holder -- claim by 2-28-23
        accounts[teamclaim[4]] = Account(  5, 0, 1); //  65-DoD holder -- claim by 2-28-23
        accounts[teamclaim[5]] = Account(  5, 0, 1); //  65-DoD holder -- claim by 2-28-23
        accounts[teamclaim[6]] = Account(  6, 0, 1); //  98-DoD holder -- claim by 2-28-23
        accounts[teamclaim[7]] = Account( 10, 0, 1); // 103-DoD holder -- claim by 2-28-23
        accounts[teamclaim[8]] = Account( 15, 0, 1); // 109-DoD holder -- claim by 2-28-23
        accounts[teamclaim[9]] = Account( 96, 0, 1); //  6+-DoD holder special editions
                                                     //    t/b airdropped post-mint-out
        reservedNFTs = 239;  

        _distro = distro;
        _distro_shares = distro_shares;

        // Merkle tree:
        merkleRoot = _merkleRoot;

    }

    // ♠ ♣ ♥ ♦ Modifiers ♠ ♣ ♥ ♦ 

    modifier minAdmin1() {
        require(accounts[msg.sender].isAdmin > 0 , "Error: Level 1(+) admin clearance required.");
        _;
    }

    modifier minAdmin2() {
        require(accounts[msg.sender].isAdmin > 1, "Error: Level 2(+) admin clearance required.");
        _;
    }

    modifier minAdmin3() {
        require(accounts[msg.sender].isAdmin > 2, "Error: Level 3(+) admin clearance required.");
        _;
    }

    modifier noReentrant() {
        require(!mintLock, "Error: No re-entrancy.");
        mintLock = true;
        _;
        mintLock = false;
    } 

    // ♠ ♣ ♥ ♦  Overrides ♠ ♣ ♥ ♦ 

    // ERC721A: Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

    // ERC721A: Xfer functions for OS Operator Filter Registry
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    // ERC721A: Xfer functions for OS Operator Filter Registry
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    // ERC721A: Xfer functions for OS Operator Filter Registry
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // OZ Payment Splitter, make release() restricted to minAdmin3
    // (I do this to prevent strangeness if/when we sell via affiliates / influencers.)
    function release(address payable account) public override minAdmin3 {
        super.release(account);
    }

    // OZ Payment Splitter, make release() restricted to minAdmin3
    function release(IERC20 token, address account) public override minAdmin3 {
        super.release(token, account);
    }

    // ♠ ♣ ♥ ♦  Setters ♠ ♣ ♥ ♦  

    function adminLevelRaise(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin ++; 
    }

    function adminLevelLower(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin --; 
    }

    // basic mint function for anyone desiring to mint from the contract
    function contractMint(uint _amount) external payable noReentrant {

        require(saleIsLive, "Error: Sale is not active. Via contractMint().");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply. Via contractMint().");
        require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Error: You would exceed the wallet limit. Via contractMint().");
        require(!isContract(msg.sender), "Error: Contracts cannot mint. Via contractMint().");
        require(msg.value >= (mintPrice * _amount), "Error: Not enough ether sent. Via contractMint().");
	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    }

    function provenanceHashLock() external onlyOwner {
        provenanceLock = true;
    }
    
    function provenanceSet(string memory _provenanceHash) external onlyOwner {
        require(provenanceLock == false);
        provenanceHash = _provenanceHash;
    }  

    function reservesDecrease(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(reservedNFTs - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        reservedNFTs -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
    }

    function reservesIncrease(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(reservedNFTs + totalSupply() + _increaseReservedBy <= maxSupply, "Error: This would exceed the max supply.");
        reservedNFTs += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        if ( accounts[_addr].isAdmin == 0 ) { accounts[_addr].isAdmin ++; }
    }

    function salePresaleActivate() external minAdmin2 {
        presaleIsLive = true;
    }

    function salePresaleDeactivate() external minAdmin2 {
        presaleIsLive = false;
    } 

    function salePublicActivate() external minAdmin2 {
        saleIsLive = true;
    }

    function salePublicDeactivate() external minAdmin2 {
        saleIsLive = false;
    } 

    function setBaseURI(string memory _newURI) external minAdmin2 {
        metadataURI = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        contractURIval = _newURI;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply <= 8100, 'Error: New max supply cannot exceed original max.');        
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setPromoPrice(uint _newPrice) external onlyOwner {
        promoPrice = _newPrice;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        walletLimit = _newLimit;
    }

    // ♠ ♣ ♥ ♦  Getters ♠ ♣ ♥ ♦ 

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return contractURIval;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURI;
    }  
    

    // ♠ ♣ ♥ ♦  Main NFT Drop Mgmt. Functions ♠ ♣ ♥ ♦ 

    function airDropNFT(address[] memory _addr) external minAdmin2 {

        require(totalSupply() + _addr.length <= (maxSupply - reservedNFTs), "Error: You would exceed the airdrop limit.");

        for (uint i = 0; i < _addr.length; i++) {
             _safeMint(_addr[i], 1);
             emit Mint(msg.sender, totalSupply());
        }

    }

    function claimReserved(uint _amount) external minAdmin1 {

        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= maxSupply, "Error: You would exceed the max supply limit.");

        accounts[msg.sender].nftsReserved -= _amount;
        reservedNFTs -= _amount;

        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
        
    }

    function mint(uint _amount, bool isAffiliate, string memory affiliateRef) external payable noReentrant {

        require(saleIsLive, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");

        if(isAffiliate) {

            require(msg.value >= (promoPrice * _amount), "Error: Not enough ether sent.");
        	bool isActive = affiliateAccounts[affiliateRef].affiliateIsActive;
        	require(isActive, "Error: Affiliate account invalid or disabled.");
       		affiliateAccounts[affiliateRef].affiliateUnpaidSales += _amount;
       		affiliateAccounts[affiliateRef].affiliateTotalSales += _amount;

        } else {

            require(msg.value >= (mintPrice * _amount), "Error: Not enough ether sent.");

        }

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    }

    function burn(uint _id) external returns (bool, uint) {

        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);

    }

    // Below is functionality for our Affiliate Marketing program.
    // ♠ ♣ ♥ ♦ See: tinyurl.com/NFTaffiliateProgram for deets.
    // Payout Function 1 --> Distribute Shares to Affiliates *and* Payees (DSAP)
    // In addition to including this function, we also modified the PaymentSplitter
    // release() function to make it minAdmin3, offering further assurance to
    // affiliates that affiliate funds will be paid out prior to defined shares.
    function distributeSharesAffilsAndPayees() external minAdmin2 noReentrant {

        // A. Payout affiliates:
        for (uint i = 0; i < affiliateDistro.length; i++) {

            // The ref name -- eg. jim, etc.
		    string memory affiliateRef = affiliateDistro[i];

            // The wallet addr to be paid for this affiliate:
		    address DSAP_receiver_wallet = affiliateAccounts[affiliateRef].affiliateReceiver;

            // The fee due per sale for this affiliate:
		    uint DSAP_fee = affiliateAccounts[affiliateRef].affiliateFee;

            // The # of mints they are credited with:
		    uint DSAP_mintedNFTs = affiliateAccounts[affiliateRef].affiliateUnpaidSales;

            // Payout calc:
            uint DSAP_payout = DSAP_fee * DSAP_mintedNFTs;
            if ( DSAP_payout == 0 ) { continue; }
 
            // Require that the contract balance is enough to send out ETH:
		    require(address(this).balance >= DSAP_payout, "Error: Insufficient balance");

            // Send payout to the affiliate:
	       	(bool sent, bytes memory data) = payable(DSAP_receiver_wallet).call{value: DSAP_payout}("");
		    require(sent, "Error: Failed to send ETH to receiver");	

            // Update total amt earned for this person:
		    affiliateAccounts[affiliateRef].affiliateAmountPaid += DSAP_payout;

            // Set their affiliateUnpaidSales back to 0:
		    affiliateAccounts[affiliateRef].affiliateUnpaidSales = 0;

        }

        // B. Then pay defined shareholders:
        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }

    }    

    // Payout Function 2 --> Standard distribute per OZ payment splitter
    // (present as a backup distrubute mechanism only, and/or a normal one if no affiliates).
    function distributeSharesPayeesOnly() external onlyOwner {

        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }

    }


    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    


    // (^_^) GenNFTs Affiliate Program functions (^_^) 
    // New functionality created by GenerativeNFTs.io to aid in influencer trust and transparency.
    
    function genNftsAffiliateAdd(address _addr, string memory affiliateRef, uint fee) external onlyOwner { 

        // REMINDER: Submit fee in WEI!
        require(fee > 0, "Error: Fee must be > 0 (and s/b in WEI).");

        // FORMAT: lowercase alpha-numeric; will enforce in affiliateValidateName().
        require(validateAffiliateName(affiliateRef), "Error: Affiliate Reference code used doesn't pass validations.");

        // ORDER: fee, minted NFTs, ttl minted, ttl amt earned, wallet, active:
        affiliateAccounts[affiliateRef] = AffiliateAccount(fee, 0, 0, 0, _addr, true);
        affiliateDistro.push(affiliateRef);

    }

    function genNftsAffiliateDisable(string memory affiliateRef) external onlyOwner {
       	require(affiliateAccounts[affiliateRef].affiliateFee > 0 , "Error: Affiliate reference likely wrong.");
        affiliateAccounts[affiliateRef].affiliateIsActive = false;
    }

    function genNftsAffiliateEnable(string memory affiliateRef) external onlyOwner { 
       	require(affiliateAccounts[affiliateRef].affiliateFee > 0 , "Error: Affiliate reference likely wrong.");
        affiliateAccounts[affiliateRef].affiliateIsActive = true;
    }

    function genNftsLookupAffilRef(address _addr) public view returns (string memory) { 

        for (uint i = 0; i < affiliateDistro.length; i++) {
   		    string memory affiliateRef = affiliateDistro[i];
            address thisWallet = affiliateAccounts[affiliateRef].affiliateReceiver;
            if ( thisWallet==_addr ) { return affiliateRef; }
        }

    }

    function validateAffiliateName(string memory str) public pure returns (bool){

        bytes memory b = bytes(str);
        if ( b.length < 3  ) return false;
        if ( b.length > 15 ) return false;  // Can't be > 15 chars
        if ( b[0] == 0x20  ) return false;  // No leading space
        if ( b[b.length - 1] == 0x20 ) return false; // No trailing space

        bytes1 lastChar = b[0];

        for( uint i; i < b.length; i++ ){

            bytes1 char = b[i];

            if (char == 0x20) return false; // Can't contain spaces

            //   We want all lowercase alpha-numeric here.
            //   But to include UC as well, add:
            //   !(char >= 0x41 && char <= 0x5A) && // A-Z
            if ( !(char >= 0x30 && char <= 0x39) && // 9-0
                 !(char >= 0x61 && char <= 0x7A)    // a-z 
               ) return false;

            lastChar = char;
        }

        return true;
    }  
    
    function allowlistMint(bytes32[] calldata _merkleProof, uint _amount) external payable noReentrant {
        require(presaleIsLive, "Error: Allowlist Sale is not active.");
        require(totalSupply() + _amount <= (maxSupply - reservedNFTs), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= 5, "Error: You would exceed the allow list limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");
        require(msg.value >= (degenPrice * _amount), "Error: Not enough ether sent.");
        require(!allowlistClaimed[msg.sender], "Error: You have already claimed all of your NFTs.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Error: You are not allowlisted.");

        if ( ( _amount + accounts[msg.sender].mintedNFTs ) == 5 ) {
            allowlistClaimed[msg.sender] = true;
        }

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    } 

    function allowlistNewMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    } 

    // ♠ ♣ ♥ ♦  THE END, FRENS! ♠ ♣ ♥ ♦ 
    // LFG!  @SwiggaJuice -- [email protected]
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}