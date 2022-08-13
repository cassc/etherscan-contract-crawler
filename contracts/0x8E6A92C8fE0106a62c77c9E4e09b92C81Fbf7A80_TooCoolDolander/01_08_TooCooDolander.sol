// SPDX-License-Identifier: MIT

// ,---------.    ,-----.        ,-----.        _______      ,-----.        ,-----.      .---.           _░▒███████
// \          \ .'  .-,  '.    .'  .-,  '.     /   __  \   .'  .-,  '.    .'  .-,  '.    | ,_|           ░██▓▒░░▒▓██
//  `--.  ,---'/ ,-.|  \ _ \  / ,-.|  \ _ \   | ,_/  \__) / ,-.|  \ _ \  / ,-.|  \ _ \ ,-./  )          ██▓▒░__░▒▓██___██████
//     |   \  ;  \  '_ /  | :;  \  '_ /  | :,-./  )      ;  \  '_ /  | :;  \  '_ /  | :\  '_ '`)        ██▓▒░___░▓██▓_____░▒▓██
//     :_ _:  |  _`,/ \ _/  ||  _`,/ \ _/  |\  '_ '`)    |  _`,/ \ _/  ||  _`,/ \ _/  | > (_)  )        ██▓▒░_______________░▒▓██
//     (_I_)  : (  '\_/ \   ;: (  '\_/ \   ; > (_)  )  __: (  '\_/ \   ;: (  '\_/ \   ;(  .  .-'        _██▓▒░______________░▒▓██
//    (_(=)_)  \ `"/  \  ) /  \ `"/  \  ) / (  .  .-'_/  )\ `"/  \  ) /  \ `"/  \  ) /  `-'`-'|___      __██▓▒░____________░▒▓██
//     (_I_)    '. \_/``".'    '. \_/``".'   `-'`-'     /  '. \_/``".'    '. \_/``".'    |        \     ___██▓▒░__________░▒▓██
//     '---'      '-----'        '-----'       `._____.'     '-----'        '-----'      `--------`     ____██▓▒░________░▒▓██
//                                                                                                      _____██▓▒░_____░▒▓██
//    ______         ,-----.      .---.       ____   ,---.   .--.______         .-''-.  .-------.       ______██▓▒░__░▒▓██
//   |    _ `''.   .'  .-,  '.    | ,_|     .'  __ `.|    \  |  |    _ `''.   .'_ _   \ |  _ _   \      _______█▓▒░░▒▓██
//   | _ | ) _  \ / ,-.|  \ _ \ ,-./  )    /   '  \  \  ,  \ |  | _ | ) _  \ / ( ` )   '| ( ' )  |      _________░▒▓██
//   |( ''_'  ) |;  \  '_ /  | :\  '_ '`)  |___|  /  |  |\_ \|  |( ''_'  ) |. (_ o _)  ||(_ o _) /      _______░▒▓██
//   | . (_) `. ||  _`,/ \ _/  | > (_)  )     _.-`   |  _( )_\  | . (_) `. ||  (_,_)___|| (_,_).' __    _____░▒▓██
//   |(_    ._) ': (  '\_/ \   ;(  .  .-'  .'   _    | (_ o _)  |(_    ._) ''  \   .---.|  |\ \  |  | 
//   |  (_.\.' /  \ `"/  \  ) /  `-'`-'|___|  _( )_  |  (_,_)\  |  (_.\.' /  \  `-'    /|  | \ `'   / 
//   |       .'    '. \_/``".'    |        \ (_ o _) /  |    |  |       .'    \       / |  |  \    /  
//   '-----'`        '-----'      `--------`'.(_,_).''--'    '--'-----'`       `'-..-'  ''-'   `'-'                                                                                         

// ✨The most fashionable cat in WEB3✨ 
//  Made with Beauty and Love;



pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TooCoolDolander is ERC721A, Ownable, ReentrancyGuard{
    
    using Strings for uint256;
    
    bytes32 public merkleRoot;
    mapping(address => bool) public fashionlistClaimed;

    string selfie;
    string public hiddenMessage;

    uint256 public immutable maxBeauty = 3333; 
    uint256 public maxTOOCOOLPerTx = 1;

    bool public _paused = false;
    bool public isValid = false;
    bool public catWalkStarted = false;
    bool public catWalkEnded = false;
    bool public revealed = false;
    bool public champagneFinished = false;

    constructor(
    string memory selfieURI,
    string memory hiddenMessageURL
      ) ERC721A("TooCoolDolander", "TOOCOOL") {
    selfie = selfieURI;
    hiddenMessage = hiddenMessageURL;
  }

    modifier onlyWhenNotPaused {
            require(!_paused, "CONTRACT PAUSED");
            _;
        }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 merkleRoot){
      require(
        MerkleProof.verify(
          merkleProof,
          merkleRoot,
          keccak256(abi.encodePacked(msg.sender))
        ),
        "NOT ON FASHIION LIST"
      );
      _;
    }

    modifier passBeautyCheck {
      require(balanceOf(msg.sender) == 0, "ONE TOOCOOL PER WALLET");
      require(totalSupply() + maxTOOCOOLPerTx <= maxBeauty, "EXCEED MAX BEAUTY");
      _;
    }

  function fashionlistMint(bytes32[] calldata merkleProof)
        external
        onlyWhenNotPaused
        nonReentrant
        passBeautyCheck
        isValidMerkleProof(merkleProof, merkleRoot){

        require(catWalkStarted&&!catWalkEnded, "NOT RIGHT TIME");
        fashionlistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
  }

  function beTooCool() external onlyWhenNotPaused nonReentrant passBeautyCheck{
        require(catWalkEnded, "NOT RIGHT TIME");
        require(balanceOf(msg.sender) == 0, "ONE TOOCOOL PER WALLET");
        require(totalSupply() + maxTOOCOOLPerTx <= maxBeauty, "EXCEED MAX BEAUTY");

        _safeMint(msg.sender, 1);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
     return selfie;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "NONEXISTENT TOOCOOL");
    if(revealed == false){
      return hiddenMessage;
    }
    else{
    string memory selfieURI = _baseURI();

    return bytes(selfieURI).length > 0 ? string(abi.encodePacked(selfieURI, tokenId.toString(), ".json")) : "";
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

//    ___       __             __          ____       __    
//   / _ \___  / /__ ____  ___/ /__ ____  / __ \___  / /_ __
//  / // / _ \/ / _ `/ _ \/ _  / -_) __/ / /_/ / _ \/ / // /
// /____/\___/_/\_,_/_//_/\_,_/\__/_/    \____/_//_/_/\_, / 
//                                                   /___/  

    function setPaused(bool _state) external onlyOwner {
    _paused = _state;
  }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
    function setcatWalkStarted(bool _state) external onlyOwner {
    catWalkStarted = _state;
  }
    function setcatWalkEnded(bool _state) external onlyOwner {
    catWalkEnded = _state;
  }
    function reveal () external onlyOwner(){
    revealed = true;
  }

   function champagneBeforeParty(address Dolander, uint256 reserveBeauty) external onlyOwner {
        require(!champagneFinished, "RESERVE MINT COMPLETED");

        uint256 totalToocool = totalSupply();
	      require(totalToocool + reserveBeauty <= maxBeauty,"EXCEED MAX BEAUTY");
        _safeMint(Dolander, reserveBeauty);

        champagneFinished = true;
    }

  function toocoolTreats(address _lover, uint256 _kiss) external onlyOwner {
    require(totalSupply() + _kiss <= maxBeauty, "EXCEED MAX BEAUTY");
    _safeMint(_lover, _kiss);
  }

  function withdraw() external payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, "SEND ETHER FAILED");
  }

}