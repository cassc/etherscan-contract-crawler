//
//                                         
//
//                                       <AI, The GIRLs>
//                              
//
//
//
//                                              _..  
//                                          .qd$$$$bp.
//                                        .q$$$$$$$$$$m.
//                                       .$$$$$$$$$$$$$$
//                                     .q$$$$$$$$$$$$$$$$
//                                    .$$$$$$$$$$$$P\$$$$;
//                                  .q$$$$$$$$$P^"_.`;$$$$
//                                 q$$$$$$$P;\   ,  /$$$$P
//                               .$$$P^::Y$/`  _  .:.$$$/
//                              .P.:..    \ `._.-:.. \$P
//                              $':.  __.. :   :..    :'
//                             /:_..::.   `. .:.    .'|
//                           _::..          T:..   /  :
//                        .::..             J:..  :  :
//                     .::..          7:..   F:.. :  ;
//                 _.::..             |:..   J:.. `./
//            _..:::..               /J:..    F:.  : 
//          .::::..                .T  \:..   J:.  /
//         /:::...               .' `.  \:..   F_o'
//        .:::...              .'     \  \:..  J ;
//        ::::...           .-'`.    _.`._\:..  \'
//        ':::...         .'  `._7.-'_.-  `\:.   \
//         \:::...   _..-'__.._/_.--' ,:.   b:.   \._ 
//          `::::..-"_.'-"_..--"      :..   /):.   `.\   
//            `-:/"-7.--""            _::.-'P::..    \} 
// _....------""""""            _..--".-'   \::..     `. 
//(::..              _...----"""  _.-'       `---:..    `-.
// \::..      _.-""""   `""""---""                `::...___)
//  `\:._.-"""                             
//

pragma solidity ^0.8.17;


import './erc721a/contracts/ERC721A.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import "@openzeppelin/contracts/utils/Strings.sol";

contract AIGIRLS is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public GIRL_PRICE = 0.008 ether;

    uint256 public MAX_GIRLS = 333;

    uint256 public MAX_GIRLS_PER_TX = 2;

    string public TOKEN_NAME = "AI, The GIRLs";

    string public TOKEN_SYMBOL = "AIGIRL";
  
    string public baseTokenUri;

    bool public paused = true;

    constructor(
    string memory _URI
  ) ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {
    baseTokenUri = (_URI);
  }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= MAX_GIRLS_PER_TX, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= MAX_GIRLS, 'You missed wives');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= GIRL_PRICE * _mintAmount, 'You need enough ETHs to take GIRLS');
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) callerIsUser {
        require(!paused, 'The contract is paused!');
        _safeMint(_msgSender(), _mintAmount);
    }
  
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
            : '';
    }

    function setCost(uint256 _cost) public onlyOwner {
        GIRL_PRICE = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        MAX_GIRLS_PER_TX = _maxMintAmountPerTx;
    }

    function setSaleState(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_GIRLS = _supply;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
        // =============================================================================
    }
}