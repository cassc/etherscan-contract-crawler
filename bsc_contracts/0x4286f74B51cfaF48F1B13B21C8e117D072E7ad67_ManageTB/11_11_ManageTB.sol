// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INFTMistery.sol";
import "../IToken.sol";

/// @title ManageMint Contract
/// @notice This contract allows the mint of nft, create and open Mistery Box
/// @author Mariano Salazar
contract ManageTB is AccessControl, ReentrancyGuard{

    event create(address _owner, address _collection, uint256 _tokenId, string _uri, string _type);
    event transfer(address _oldOwner, address _newOwner, address _collection, uint256 _tokenId, uint256 _brun);
    event burn(address _owner, address _collection, uint256 _tokenId, string _uri, string _type, uint256 _brun);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;
    bool private paused = false;
    address public token;
    uint256 public amount;

    constructor(address _token, uint256 _amount) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        /*only for dev */
        _setupRole(DEFAULT_ADMIN_ROLE,0x30268390218B20226FC101cD5651A51b12C07470);
        /*-------------*/
        token  = _token;
        amount = _amount;  
    }

    function burning(address _collection, address _burner, uint256 _tokenid) public nonReentrant returns (uint256) {
        require(!paused, "is paused");
        require(msg.sender == _burner, "not your NFT");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        uint256 id = INFTMistery(_collection).burnMyNFT(_burner, _tokenid);
        emit burn(_burner, _collection, id,"", "Burn NFT", amount);
        return id;
    }

    ///@dev In this function it is necessary to have the user's approve first in order to send the NFT.
    ///@dev You must use the function approve, to approve only handling that specific NFT to be transferred.
    function transferNFT(address _collection, address _to, address _from, uint256 _tokenid) public nonReentrant {
        require(!paused, "is paused");
        require(msg.sender == _from, "not your NFT");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        INFTMistery(_collection).transferFrom(_from,_to,_tokenid);
        emit transfer(_from, _to, _collection, _tokenid, amount);
    }

    function setPaused(bool _state) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        paused = _state;
    }

    function updateAmount(uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        amount = _amount;
    }

    function withdraw(address _token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(admin, balance);
    }
}