// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INFTMistery.sol";
import "../IToken.sol";

/// @title ManageMint Contract
/// @notice This contract allows the mint of nft, create and open Mistery Box
/// @author Mariano Salazar
contract ManageMint is AccessControl {

    event create(address _owner, uint256 _tokenId, string _uri, string _type);
    event transfer(address _oldOwner, address _newOwner, uint256 _tokenId, uint256 _brun);
    event mint(address _owner, uint256 _tokenId, string _uri, string _type, uint256 _brun);
    event burn(address _owner, uint256 _tokenId, string _uri, string _type, uint256 _brun);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;
    address public feeaddress = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;
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

    function buyBox(uint256 _tokenid,address _collection, address _redeem,string memory _uri) public returns (uint256) {     
        require(!paused, "is paused");
        (address _token, uint256 _price) = INFTMistery(_collection).getPriceToken();
        require(IERC20(_token).transferFrom(_redeem, address(this), _price), "Fail transfer");
        address _owner = INFTMistery(_collection).getAdmin();
        uint256 _profit = calcFee(_price, _token);
        require(IERC20(_token).transfer(_owner, _profit), "Fail transfer");
        uint256 id = INFTMistery(_collection).redeem(_redeem,_tokenid, _uri);
        emit create(_redeem, id, _uri, "Buy Box");
        return id;
    }

    function minting(uint256 _tokenid,address _collection, address _redeem,string memory _uri) public returns (uint256) {
        require(!paused, "is paused");
        address _owner = INFTMistery(_collection).getAdmin();
        require(_owner == msg.sender, "Caller is not the owner");
        require(IERC20(token).transferFrom(_redeem, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        uint256 id = INFTMistery(_collection).redeem(_redeem,_tokenid, _uri);
        emit mint(_redeem, id, _uri, "Mint NFT", amount);
        return id;
    }

    function batchMint(uint256[] calldata _tokenid,address _collection, address _redeem,string[] calldata _uri, 
    uint256 quantity) public returns (uint256[] calldata _ids) {
        require(!paused, "is paused");
        require(_tokenid.length == quantity, "array mismatch");
        address _owner = INFTMistery(_collection).getAdmin();
        require(_owner == msg.sender, "Caller is not the owner");
        uint256 burnAmount = quantity * amount;
        require(IERC20(token).transferFrom(_redeem, address(this), burnAmount), "Fail transfer");
        IToken(token).burn(burnAmount);
        for(uint i = 0; i < quantity;){        
        uint256 id = INFTMistery(_collection).redeem(_redeem,_tokenid[i], _uri[i]);
        emit mint(_redeem, id, _uri[i], "Mint NFT", amount);
            unchecked {
                ++i;
            }
        }
        return _tokenid;
    }

    function openBox(uint256 _tokenid,address _collection, address _redeem,uint256 _idBox, string memory _uri) public returns (uint256) {
        require(!paused, "is paused");
        uint256 id = INFTMistery(_collection).openBox(_redeem, _idBox,_tokenid, _uri);
        emit create(_redeem, id, _uri, "Open Box");
        return id;
    }

    function burning(address _collection, address _burner, uint256 _tokenid) public returns (uint256) {
        require(!paused, "is paused");
        require(IERC20(token).transferFrom(_burner, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        uint256 id = INFTMistery(_collection).burnMyNFT(_burner, _tokenid);
        emit burn(_burner, id,"", "Burn NFT", amount);
        return id;
    }

    ///@dev In this function it is necessary to have the user's approve first in order to send the NFT.
    ///@dev You must use the function approve, to approve only handling that specific NFT to be transferred.
    function transferNFT(address _collection, address _to, address _from, uint256 _tokenid) public {
        require(!paused, "is paused");
        require(IERC20(token).transferFrom(_from, address(this), amount), "Fail transfer");
        IToken(token).burn(amount);
        INFTMistery(_collection).transferFrom(_from,_to,_tokenid);
        emit transfer(_from, _to, _tokenid, amount);
    }

    function calcFee(uint256 _amount, address _token) internal returns (uint256 _profit){
        uint256 minusfee = _getPortionOfBid(_amount, fee);
        IERC20(_token).transfer(feeaddress, minusfee);
        _profit = _amount - minusfee;     
    }

     function _getPortionOfBid(uint256 _totalBid, uint256 _percentage) internal pure returns (uint256) {
        return (_totalBid * (_percentage)) / 10000;
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