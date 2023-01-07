// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ERC2981.sol";

/// @title Lazymint witn Mistery Box Contract
/// @notice This contract allows the mint of nft when the user decides and the creator doesn't need to pay the gas for the minting
/// @author Mariano Salazar
contract LazyNFT is AccessControl, ERC721URIStorage, ERC2981 {

    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 internal maxsupply; //Enter here the max supply that you want the NFT collection to have.
    uint256 internal supply;
    uint256 internal boxSupply; //The box supply must start with the value of maxsupply
    uint256 internal maxBoxSupply; //The max box supply must be twice the maxsupply
    address internal token;
    uint256 internal amount;
    uint256 internal date;
    //Here you place the wallet to which the administrator role would be given,
    //this for future changes in the roles of the contract.
    address internal admin;

    bool public paused = false;
    bool public mintBox;
    bool private royaties = false;

    constructor(
        address _manager,
        address _market,
        uint256 _maxsupply,
        string memory name_,
        string memory symbol_,
        address _token,
        uint256 _amount,
        bool _mintBox,
        uint256 _date,
        address _admin
    ) ERC721(name_, symbol_) {
        //This function (_setupRole) helps to assign an administrator role that can then assign new roles.
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(MINTER_ROLE, _market);
        _setupRole(MINTER_ROLE, _manager);
        maxsupply = _maxsupply;
        maxBoxSupply = (_maxsupply * 2); //The max supply of the boxes is twice the maxsupply of the collection.
        boxSupply = _maxsupply; // Box ID starts where maxsupply ends 
        token  = _token;
        amount = _amount;
        mintBox = _mintBox;
        date = _date;
    }

    function getTotalSupply() public view returns (uint256) {
        return supply;
    }

    function getStartBoxSupply() public view returns (uint256) {
        return boxSupply;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxsupply;
    }

     function getMaxBoxSupply() public view returns (uint256) {
        return maxBoxSupply - maxsupply;
    }

    function getPriceToken() public view returns (address _token,uint256 _price) {
        return(token, amount);
    }

    function getOpenDate() public view returns(uint256){
        return date;
    }
    function getAdmin() public view returns(address){
        return admin;
    }

    function redeem(address _redeem,uint256 _tokenid, string memory _uri) public returns (uint256) {
    require(!paused, "is paused");
    require(hasRole(MINTER_ROLE, msg.sender), "caller is not a minter");
    if (_tokenid == 0) {
            revert ("can not be zero");
    }
    
    if(mintBox){
        require((boxSupply <= maxBoxSupply),"max supply exceeded");
        require((_redeem != address(0)),"zero address");
        _safeMint(_redeem, _tokenid);
        _setTokenURI(_tokenid, _uri);
        ++boxSupply;
        return _tokenid;
    }else{
        require((supply <= maxsupply),"max supply exceeded");
        require((_redeem != address(0)),"zero address");
        _safeMint(_redeem, _tokenid);
        _setTokenURI(_tokenid, _uri);
        ++supply;
        return _tokenid;
    }
    }

    function openBox(address _redeem,uint256 _idBox, uint256 _tokenid, string memory _uri) public returns(uint256){
        require(!paused, "is paused");
        require(hasRole(MINTER_ROLE, msg.sender), "caller is not a minter");
        require(ownerOf(_idBox) == _redeem, "not your box");
        require((supply <= maxsupply),"max supply exceeded");
        require(date != 0, "date not set");
        require(block.timestamp >= date, "still wait");
        _burn(_idBox);
        _safeMint(_redeem, _tokenid);
        _setTokenURI(_tokenid, _uri);
         ++supply;
        return _tokenid;
    }

    function burnMyNFT(address _burner, uint256 _tokenid) public returns(uint256) {
        require(!paused, "is paused");
        require(hasRole(MINTER_ROLE, msg.sender), "caller is not a minter");
        require(ownerOf(_tokenid) == _burner, "not your NFT");
        _burn(_tokenid);
        _resetTokenRoyalty(_tokenid);
        return _tokenid;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxsupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        require(!royaties, "royalties already defined");
        super._setDefaultRoyalty(receiver,feeNumerator);
        royaties = true;
    } 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    //If you need the option to pause the contract, activate this function and the ADMIN role.
    function setPaused(bool _state) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        paused = _state;
    }

    function closeBox(bool _state) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        mintBox = _state;
    }

    function updateDate(uint256 _date) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        date = _date;
    }
}