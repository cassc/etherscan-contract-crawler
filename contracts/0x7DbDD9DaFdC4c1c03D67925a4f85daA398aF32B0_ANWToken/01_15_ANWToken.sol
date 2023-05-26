pragma solidity ^0.5.0;

import "./Context.sol";
import "./TokenRecover.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20VotingMintable.sol";

contract ANWToken is Context, TokenRecover, ERC20, ERC20Detailed, ERC20Burnable, ERC20VotingMintable, ERC20Pausable{
    
    string private _issuingCountry = "Hongkong";
    string private _issuingCompany = "Huimin World Holdings Limited";
    uint256 private _initialSupply = 1000000000;
    
    constructor () public ERC20Detailed
    ( "Anchor Neural World Token", "ANW", 18 ) 
    { _mint(_msgSender(), _initialSupply * (10 ** uint256(decimals()))); }
    
    function issuingCountry() public view returns ( string memory ){
        return _issuingCountry;
    }
    
    function issuingCompany() public view returns ( string memory ){
        return _issuingCompany;
    }

    function initialSupply() public view returns ( uint256 ){
        return _initialSupply;
    }
    
}