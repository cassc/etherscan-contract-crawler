// SPDX-License-Identifier: MIT
                                                                                                                                                       
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                  :-                                                                            
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                            /\                                                                            //
//                                                                           /=*\                                                                           //
//                                                                          -+  -#.\                                                                        //
//                                                                          #.  =#*=\                                                                       //
//                                                                     /\ -+      @ //                                                                      //
//                                                                    /*  .#       *:./.                                                                    //
//                                                                 :# .+==+.       *-=%\                                                                    //
//                                                                 +=  +=+         =*#.//                                                                   //
//                                                                 :#                . +-\                                                                  //
//                                                              :.  %.    ::@@@@@@::    .# \                                                                //
//       [email protected]@@@@@@@@@@@%#.                           ::::        %*-=* :+%@@@@@@@@@@@%+. -**%.          [email protected]@@@@@@@@@@@%*   :::.              @@:              //
//        [email protected]@@@####%@@@@-                          [email protected]@@+       -+ . :#@@@@@@@@@@@@@@@@@#:  -*           [email protected]@@@####%@@@@. [email protected]@@=              @@:              //
//        %@@@=    [email protected]@@%                           %@@@        ==  [email protected]@@@@@@@@@@@@@@@@@@@@*. %.         [email protected]@@@-    #@@@#  @@@%              [email protected]@@.             //
//       [email protected]@@%     :+#@:                          [email protected]@@=        :* *@@@ COOL SKULL CLUB @@@%.*         *@@@#     -+%@. [email protected]@@=               @@@%              //
//       %@@@=           :#######:   .####### :  [email protected]@@@          #[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#%.        [email protected]@@@:          [email protected]@@% :###:   :###: *@@@+####:        //
//      [email protected]@@%          [email protected]@@@@@@@@@# *@@@@@@@@@@+ [email protected]@@-          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@=         *@@@*           *@@@- %@@@   :@@@*[email protected]@@@@@@@@@@:       //
//     [email protected]@@@-         [email protected]@@%[email protected]@@=:@@@*...%@@@:[email protected]@@#            @@@@@%@@@@@@@@@@@@@@@@@@@@%         [email protected]@@@.          [email protected]@@# [email protected]@@=   %@@@.*@@@[email protected]@@%        //
//     [email protected]@@%       := *@@@-   @@@@ %@@@.  :@@@# *@@@:            *@@@@=-----#@@@#-----%@@@@*         #@@@*       :-  *@@@: %@@@   [email protected]@@*[email protected]@@#   *@@@=        //
//    [email protected]@@@:    +#@@*[email protected]@@#   [email protected]@@[email protected]@@+   #@@@:[email protected]@@#             .*@@=      :@@@   \,/  *@@*.       [email protected]@@@.    +#@@+ :@@@# [email protected]@@=   %@@@ *@@@.  :@@@%         //
//    [email protected]@@*    [email protected]@@@:*@@@:  [email protected]@@% %@@@   [email protected]@@* #@@@:               @@+     .*@@@-  /'\  #@@         #@@@+    [email protected]@@@. #@@@: @@@@   [email protected]@@=:@@@*   #@@@:         //
//    @@@@@%%%%@@@@+ @@@@###%@@@:[email protected]@@@###@@@@.:@@@@.              [email protected]@@#**[email protected]@-#[email protected]@%***%@@@=        [email protected]@@@@%%%%@@@@= [email protected]@@@[email protected]@@@%%%@@@@ #@@@%##%@@@+          //
//    -*#########*-  +########*: .*########+. +####*:              *@@@@@@@@. * :@@@@@@@@*          =*#########+:  +####*=*###**%@@%-:########*=.           //
//                                                                  .=+:[email protected]@@@@@%@@@@=-+=.                                                                   //
//                                                                       @@@@@@@@@@@                                                                        //
//                                                                       *@@@@@@@@@*                                                                        //
//                                                                         /SKULL/                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// @title : CoolSkullClub
// @version: 1.0
// @description: Cool Skull Club NFT Project for the Ethereum Ecosystem
// @license: MIT
// @developer: @0xKayaoglu - kayaoglu.eth                                                                                                                                
// @artist: @0xRuhsten - ruhsten.eth


pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CoolSkullClub is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    bytes32 public merkleRoot;

    uint256 public constant WL_MINT_PRICE = 0.0666 ether;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public MAX_SUPPLY = 6666; 
    
    uint256 public constant MAX_PER_WALLET = 10; 

    mapping(address => uint256) public walletMint;

    string private BASE_URI = ''; // Real meta data uri
    string private constant HIDDEN_URI = 'ipfs://QmeoArPda6YBgrDeJaauMYnxKjAxNdiG2sw6BGtfNLdkH2/metadata.json'; // Start of hidden meta data uri
    string private constant URI_SUFFIX = '.json';

    bool public PAUSED = true;
    bool public REVEALED = false;
    
    enum ProjectStatus {
        Before,
        Whitelist,
        Mint,
        SoldOut
    }

    ProjectStatus public pStatus = ProjectStatus.Before;

    constructor() ERC721A("COOL SKULL CLUB", "CSKC") {}

    function _claimToken(uint256 _mintAmount, uint256 _mintPrice, uint256 _amount) internal virtual {
        require(_mintAmount > 0, "COOL SKULL CLUB : Amount cannot be zero!");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "COOL SKULL CLUB : Reached max supply!");
        require(msg.value >= _mintPrice * _amount, "COOL SKULL CLUB : Not enough balance!");
        
        _mint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant {
        require(!PAUSED, "COOL SKULL CLUB : This contract is paused!");
        require(pStatus == ProjectStatus.Mint, "COOL SKULL CLUB : Public Mint not enabled!");
        require(walletMint[msg.sender] + _mintAmount <= MAX_PER_WALLET, "COOL SKULL CLUB: You cannot mint more than 10 tokens!");
    
        _claimToken(_mintAmount, MINT_PRICE, _mintAmount);
        walletMint[msg.sender] += _mintAmount;
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof, uint8 _collabType) public payable nonReentrant {
        require(!PAUSED, "COOL SKULL CLUB : This contract is paused!");
        require(pStatus == ProjectStatus.Whitelist, "COOL SKULL CLUB : Whitelist not enabled!");
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_msgSender()))), "COOL SKULL CLUB : Address is not whitelisted!");
        require(_numberMinted(msg.sender) + _mintAmount <= MAX_PER_WALLET, "COOL SKULL CLUB: You cannot mint more than 10 tokens!");

        uint amount = _collabType == 1 ? _mintAmount - 1 : _mintAmount;
                
        _claimToken(_mintAmount, WL_MINT_PRICE, amount);
    } 

    function reserveNFT(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "COOL SKULL CLUB : Amount cannot be zero!");
        require(totalSupply() + _amount <= MAX_SUPPLY, "COOL SKULL CLUB : Reached the max supply!");
        _mint(_to, _amount);
    }

    function editMaxSupply(uint256 _maxSupply) external onlyOwner {
		require(_maxSupply < MAX_SUPPLY, "COOL SKULL CLUB : Max supply can't exceed initial supply!");
		MAX_SUPPLY = _maxSupply;
	}

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function walletWhitelist(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "COOL SKULL CLUB: URI query for nonexistent token");

        if (REVEALED == false) {
            return HIDDEN_URI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), URI_SUFFIX))
            : '';
    }

    function setRevealed(bool _revealStatus) public onlyOwner {
        REVEALED = _revealStatus;
    }

    function setPaused(bool _pauseStatus) public onlyOwner {
        PAUSED = _pauseStatus;
    }

    function restart() external onlyOwner {
        pStatus = ProjectStatus.Before;
    }

    function setWhitelisted() external onlyOwner {
        pStatus = ProjectStatus.Whitelist;
    }

    function setPublicMint() external onlyOwner {
        pStatus = ProjectStatus.Mint;
    }

    function setSoldOut() external onlyOwner {
        pStatus = ProjectStatus.SoldOut;
    }


}