// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNNXXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl::oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWWMMMMMMMMMMMMWWMMMWXKKKNMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNklcclxXMMMMWXxllcd0WMWN00KNWMMMMMMMMMMMMMWXKKXWMMMMMMMMMMMMMNOxlcllokXWMMk'.;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kc..;dNMXo,..lx0NMMMMMMMMMMWKxdONMMMMMMWKxocckNMMMMMMMMMMW0xo:c:..',c0K:,x00kdolldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKOko;lkc;oxOXWMMWNKKXNMMMXo';xXMMMMMMMMWWNk:'lXMXkdodxKWMXd:o0KkkOdlcllkkc,,'..;;,lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkoc;cccoxlclxxdxk0XWNkoc,:oOXo:dk000KNWNOdoccloxdcoxc;;lxkKNN0l.,0MMWKOxooloc::lkkOKKKXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc;:;,lo:;cllccc:;..,lkXNKOkxoloddl:,;cd0Kkxdlcl:;lo:cox0NMMMWN0oo0NKdc;;llcllcdc,;:dKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKKXXKd:,ld:odcck0kdxc:xKOdoddlcclllx0NNWWMWKoc:col::clc,;xXMMMNXWNd' .okc;dOc.d0kc..,xNMMWWWMMWWMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMWXK0KXWMMMMK:..oKd'lKXl'lXWWNXkc;,dklod:dk:'cOWMMWk;,,l0k,oOcl0kl;lXMMMMWo.;coOl.oN0l.,KN0do;.xWMN0OkO0KWMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMNK0XNWMMMWl.;o0Wk..cONd.,OWMNkd0XKccKk'cXKkcc0MMNddKNWMd.:Kk'lNWX0XMMMMKcckKNx.,0Nx' 'OMMWXOodXMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMNNNNNWWMMXl:kXWMNl.,dKNo..kWWWWMWd'xXo.cNMWN0XMMWWWMMMM0;;0X:.OMMMMWXKK00XWW0, lWNx;.:XMMMMMNXNNNNNNMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMWO:';::ccclco0NMMMNk::xNNc 'kWMMMK,'0XdlKMMMMMMMWX00KXNMMKxKWo.lWMMMWN00XWMMWd..xMXd,:0X0kdlc::;;,'c0MMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMWO;.;ccc:;,,',cd0WMWKKWWO' 'kWMWx.'xxdkK00KNWWWNXKKK0OOOOkkx: ,0WNXXNWMMMMMX: .kMWkll:''',,;;;,..:0MMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMXo''cllldo'.',':dKWMWKk,  ,xko,..........,;;;,,,,'...........;:,,,;:oKMMWk' .xOl;',..;ll::;,.,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMW0;.',:cc::lll;.'oKWO:. .........,,..';;;;;,..,,...,,,,,'.......... .ldOl. .'..:loc;;:;,'..lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMNo..loc:c::lc.  'c,...'..;:ccc'.,..;looool'.,,. 'looool'.,;,..:;;,'..'.     'ol:::::c;.'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMWNKK000KXXx'.cdoc;;c;..  .;cllo,.cooll;..,..cooooo:.',. .:oool,..;;,.'looooolc:'. . .cc,;cll;.;0XK0000KXNWMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMNklc::;;;,..,::' .',;cc;'.....;loooc,:loll'.',..colcloo,.''..;ooo;..',,'.,oooc::cc;......':c:;'...;:;'.',,,;;:cokNMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMM0;..;looooc';lc:'. .,co;..',,..'colooololo:.',.,lol:cooc.....;ool,.'''...coooc,.....,;,..:ol:.. .,:cc,,cc:::;...:0MMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMNOdc;',,;cccc::l,....;;'.',;;'.,llol,'cool,..'cool:clllc'. 'loolcllll'.,ooo:,'....,;;..'::,....:c;::::;''.';cxKWMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMWXko;.,:cc::::,,'......',;,..cool,.colll'.:oooc..clcl;..;lllooooo:.'lllo;..',,,,;'.......',;::;:::;..:d0NMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMW0d:',,,;llc,.......',,..coool;:l:;:,.':;;'...'.........'',,;..,c::l;.';,,;,.........;llc,,,',cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMNKko:....',;:;........',..:c:;;..............'.........................',,,;'........'::;,....'cdkXWMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMWKxc;,.....................''....     ...........'..       ...  .....        .........................,:lkXWMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMW0o:,,;clllll::;;;,.............   ..,;;'.    ..,'.    'cloooddxxl.   .';:clllc:'.  ..........';;;;;:cccc:;,',:dKWMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMNx:,;codddoooooooc;'..        ..  .:dxOO00k,.,ldxOOOd,  .l0OOOOOOOkc..;lxkO0OOOOO0Oo.          ..,:loollllllllc:,''cOWMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMNx;,cddoccooool::,.. ..;clodol:'.   'dOOOOOOx,.lOOOOOOOx, 'xOOOOOOkl,,cxOOOOOOkkkkOOko'.'clodolc;'.  .';cc:clcc:;:cc:'.:OWMMMMMMMMMMMMMMMM
* MMMMMMMMMMMK:..;;;;,',;:,...  .,cdkO0OOOOOOkc.  .oOOOkkOOd'.:xOOOOOOk;,xOOOOOd,'lkOOOOOko:,;dkOx;.,okOOOOOOO0Oxl;.  ....,;;;'',,''...oNMMMMMMMMMMMMMMM
* MMMMMMMMMW0c,:loxOKXXXKx,. .,cxO0OOOkkkkOOOOk:. .lOOOkxkOOx,.'okOOOOOkldOOkkl.;xOOOOOkl'. .:kOd'.ckOOOOOOOOOOOOOOko,.  'oKXXXXX0Oxoc:;oXMMMMMMMMMMMMMM
* MMMMMMMMMWXXWMMMMMMMMNd. .:dO0OOOOkkxddxkOOOOc. .ckOOxoxOOOk: .:xOOOOOOOOkc..:kOOOOOd,. .'okOO:.ckkkkkkkkkkkkkkOOOOOd;. .lXMMMMMMMMMMNXNMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMWd. .d0OOOOOkkd:'.,dOOOOk;  .:kOOklokOOOx, .,dkOOOOOOl..:kOOOOOo'  .ckOOOOl..::::::::ccclodxkkkkOOd'  ;0MMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMX: .:kOOOOOkdc,.. ;kOkkxc.   'okOOlcxOOOOo.  .lkOOOOd',oxOOOOOo' .:xOOkOOkc.  .,;,,..   ...';coxkkOk:. ;KMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMN: .:kOOOkxolokx,'xOkdolcclll;',oOd:dOOOOOc.  .ckOOk;.oOOOOOOd'...,cloolc,. .;dO0OOkd;   ... ..;oxkOO;  cXMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMWo. ,dkkkdldOOOkxkOOkkkO0OOOOOd''dOkOOOOOOx, . 'xOOd';kOOOOOx,..  .;loc.  ..lkOOOOOxc'....   ..;dkOO0x. .kMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMM0' .cxxo'.lkOOOkkkkOkkkkOOOOOOl.:kOOOOOOOOo. .lOOOl.cOOOOOkc.. .:xOOO0o..;xOOOOOxc'    ..,:ldkOOOOOOk; .xMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMWd. .,,.. .oOOOxddddoodkOOOOOOo..oxddxkOOOO:.;kOOO:.oOOOOOd. .'oOOOOOo''lkOOOOkl. ..,:ldkOOOOOOOOOOOk, .xMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMNo.   .   .oOOxc,....lOOOOOOOc..ld,.oOOOOk;'dOOOk:.oOOOOOl..;xOOOOxc.,dOOOOko;,:ldkOOOOOOOOOOOOOOOOo. .kMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMNx'       'dOOOo.  ;kOOOOOOd, .lO;.ckOOOl.cOOOOd'.lOOOOOl.ckOOkd;..ckOOOOxoldOOOOOOOOOOOOOOOOOOOxc.  :XMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMXxolldc. ,xOOk:.;kOOOOOOx;. .dOl.'dOOO:.oOkOk; .:kOOOOkxOOOx:. .okOOOOOkOOOOOOOOOOOOOOOOkxdl:,... .dWMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  ;xOOdokOOOOOkd;.  :kOd..lkOOo.':dkl.. 'dkkOOOOOkl'. .lkOOOOOOOOOOOOOOOkkxdol:;,.......  ;KMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:. .'.:kO00OOOOkxl'.  .;ldl. ,odl;.  .,... .;oxkkOxl,... .okkkkkkkkkkxdolc:;,'.........    .:KMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .:kkodO0OOOkkxo;.      ...   ...      ..   ..':c:'...   .':ccc:;;,,'............       .'ckNMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ,kOOOOOkkkkdl;..    ..              .    ..    ....  ... ................         .';cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMk. 'dkkkkkxdl:'.     .c00dc,...,'....;dOdc:o00;.      .,xk,   ...             ..,:ldk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMNl. ':clc:;'.      .;kWMMMMWXKKNN0O0XWMMMMMMMMNKxc;;:lONMWO,         ...,;cldk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.             .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMNkocclodxkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.         .;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:,'',:lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

/*
 * @title  Half BAYCD ERC-721 Smart Contract
 */

contract HalfBAYCD is ERC721A, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // PUBLIC MINT
    uint256 public tokenPricePublic = 0.069 ether; 
    uint256 public tokenPriceAPE = 20000000000000000000;
    uint256 public constant MAX_PER_TXN_PUBLIC = 10;
    uint256 public constant MAX_TOKENS = 6969;
    bool public mintIsActive = false;

    string private baseURI;
    address public tokenContract = address(0x4d224452801ACEd8B2F0aebE155379bb5D594381);

    // FREE MERKLE MINT
    bool public mintIsActivePresale = false;
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    constructor() ERC721A("Half BAYCD", "HBAYCD") {}

    // @title PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /*
    *  @notice public mint function ETH
    */
    function mintHalfBAYCD(uint256 qty) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");
        require(qty <= MAX_PER_TXN_PUBLIC, "You went over max tokens per transaction");
        require(totalSupply() + qty <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(msg.value >= tokenPricePublic * qty, "You sent the incorrect amount of ETH");

        _safeMint(msg.sender, qty);
    }

    /*
    * @notice public mint for card actions
    */
    function mintHalfBAYCDWithAPECoin(uint256 qty) external nonReentrant {
        require(tx.origin == msg.sender);
        require(mintIsActive, "Public mint is not active");
        
        uint256 apeBalance = IERC20(tokenContract).balanceOf(msg.sender);
        require(tokenPriceAPE * qty <= apeBalance, "Not enough $APE to mint.");
  
        require(
            qty <= MAX_PER_TXN_PUBLIC, 
            "You can't mint that many tokens per transaction."
        );
        require(
            totalSupply() + qty <= MAX_TOKENS, 
            "Tokens are all minted."
        );

        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), tokenPriceAPE * qty);      
        _safeMint(msg.sender, qty);
    }


    // FREE CLAIM MERKLE 

    /*
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /*
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /*
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList, uint256 qty) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    claimed[walletList[i]] = qty;
	    }
    }
   
    /*
    * @notice check if wallet claimed for all potions
    */
    function checkClaimed(address wallet) external view returns (uint256) {
        return claimed[wallet];
    }

    /*
     * @notice free claim merkle mint 
     */
    function claim(uint256 qty, uint256 maxQty, bytes32[] calldata merkleProof) external nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");       
        require(
            claimed[msg.sender] + qty <= maxQty, 
            "Claim: Not allowed to claim given amount"
        );
        require(
            totalSupply() + qty <= MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );

        bytes32 node = keccak256(abi.encodePacked(msg.sender, maxQty));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "You have a bad Merkle Proof."
        );

        claimed[msg.sender] += qty;

        _safeMint(msg.sender, qty);
    }

    // OWNER FUNCTIONS

    /*
     * @notice Withdraw ETH in contract to ownership wallet 
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }
    }

    /*
     * @notice Withdraw $APE in  $APE contract to ownership wallet 
     */
    function withdrawAPE() external onlyOwner {
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        if(balance > 0){
            IERC20(tokenContract).safeTransfer(owner(), balance);
        }
    }

    /*
     * @notice Withdraw $APE in contract to ownership wallet by amount - only use as backup
     */
    function withdrawAPEbyAmount(uint256 amount) external onlyOwner {
        IERC20(tokenContract).safeTransfer(owner(), amount);
    }

    /*
    *  @notice reserve mint n numbers of tokens
    */
    function mintReserveTokens(uint256 qty) public onlyOwner {
        require(totalSupply() + qty <= MAX_TOKENS, "Not enough tokens left to mint that many");
        _safeMint(msg.sender, qty);
    }

    /*
    *  @notice mint n tokens to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 qty) public onlyOwner {
         require(totalSupply() + qty <= MAX_TOKENS, "Not enough tokens left to mint that many");
         _safeMint(toWallet, qty);
    }

    /*
    *  @notice get base URI of tokens
    */
   	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(baseURI, _tokenId.toString()));
	}
 
    /* 
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /*
     * @notice sets Merkle Root for presale
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /*
    *  @notice set token price of public sale - tokenPricePublic
    */
    function setTokenPricePublic(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPricePublic = tokenPrice;
    }

    /*
    *  @notice set token price of $APE public sale - tokenPriceAPE
    */
    function setTokenPriceAPE(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPriceAPE = tokenPrice;
    }

    /*
    *  @notice set token token contract - tokenContract
    */
    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }
}