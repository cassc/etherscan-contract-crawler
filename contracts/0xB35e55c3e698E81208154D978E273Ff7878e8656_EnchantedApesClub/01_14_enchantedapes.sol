// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";


interface MainContractInterface is IERC721A{}


contract EnchantedApesClub is ERC721A, ERC721AQueryable, Ownable {

    string private _baseTokenURI;
    bool  public claimingOn= false; 
    mapping (uint256 => bool) private _MainTokenUsed;

    MainContractInterface public MainContract;
   
    constructor(address _mainContractAddress) ERC721A("EnchantedApesClub", "EAC") {        
        setMainContract(_mainContractAddress);        
    }

   function setMainContract(address _mainContractAddress) public onlyOwner {
        MainContract = MainContractInterface(_mainContractAddress);
    }
   
    
    function claim(uint256[] memory _tokensId) public {
        
	    require(claimingOn, "Claiming not active");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            require(canClaim(_tokensId[i]), "Already claimed");
            require(MainContract.ownerOf(_tokensId[i]) == _msgSender(), "Bad owner!");
            _MainTokenUsed[_tokensId[i]] = true;            
        }
        _mint(msg.sender, _tokensId.length);
    }
    function canClaim(uint256 _tokenId) public view returns(bool) {
        return _MainTokenUsed[_tokenId] == false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

   function toggleClaiming() public onlyOwner {
        claimingOn= !claimingOn;
    }
 
    function devMintForHolder (address _holderWalletAddress,uint256[] memory _tokensId) external onlyOwner {         
        for (uint256 i = 0; i < _tokensId.length; i++) {
            require(canClaim(_tokensId[i]), "Already claimed"); 
            require(MainContract.ownerOf(_tokensId[i]) == _holderWalletAddress, "Bad owner!");           
            _MainTokenUsed[_tokensId[i]] = true;            
        }
        _mint(_holderWalletAddress, _tokensId.length);                
    }

}