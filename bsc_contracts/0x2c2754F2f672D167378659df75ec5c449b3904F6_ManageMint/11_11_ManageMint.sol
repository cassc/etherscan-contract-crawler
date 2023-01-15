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
contract ManageMint is AccessControl, ReentrancyGuard{

    event create(address _owner, address _collection, uint256 _tokenId, string _uri, string _type);
    event mint(address _owner, address _collection, uint256 _tokenId, string _uri, string _type, uint256 _brun);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;
    bool private paused = false;
    address public token;
    uint256 public amount;
    uint256 public fee = 250; //Equal 2.5%

    constructor(address _token, uint256 _amount) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        /*only for dev */
        _setupRole(DEFAULT_ADMIN_ROLE,0x30268390218B20226FC101cD5651A51b12C07470);
        /*-------------*/
        token  = _token;
        amount = _amount;  
    }

    function minting(uint256 _tokenid,address _collection, address _redeem,string memory _uri) public nonReentrant returns (uint256) {
        require(!paused, "is paused");
        address _owner = INFTMistery(_collection).getAdmin();
        require(_owner == msg.sender, "Caller is not the owner");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        uint256 id = INFTMistery(_collection).redeem(_redeem,_tokenid, _uri);
        emit mint(_redeem, _collection, id, _uri, "Mint NFT", amount);
        return id;
    }

    function batchMint(uint256[] calldata _tokenid,address _collection, address _redeem,string[] calldata _uri, 
    uint256 quantity) public nonReentrant returns (uint256[] calldata _ids) {
        require(!paused, "is paused");
        require(_tokenid.length == quantity, "array mismatch");
        address _owner = INFTMistery(_collection).getAdmin();
        require(_owner == msg.sender, "Caller is not the owner");
        uint256 burnAmount = quantity * amount;
        require(IERC20(token).transferFrom(msg.sender, address(this), burnAmount), "Fail transfer");
        IToken(token).burn(burnAmount);
        for(uint i = 0; i < quantity;){        
        uint256 id = INFTMistery(_collection).redeem(_redeem,_tokenid[i], _uri[i]);
        emit mint(_redeem, _collection, id, _uri[i], "Mint NFT", amount);
            unchecked {
                ++i;
            }
        }
        return _tokenid;
    }

    function openBox(uint256 _tokenid,address _collection, address _redeem,uint256 _idBox, string memory _uri) public nonReentrant returns (uint256) {
        require(!paused, "is paused");
        require(msg.sender == _redeem, "not your box");
        uint256 id = INFTMistery(_collection).openBox(_redeem, _idBox,_tokenid, _uri);
        emit create(_redeem, _collection, id, _uri, "Open Box");
        return id;
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