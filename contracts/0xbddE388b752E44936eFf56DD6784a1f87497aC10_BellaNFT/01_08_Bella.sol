// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721A } from "./ERC721A.sol";
import { Ownable } from "./Ownable.sol";

pragma solidity >=0.8.17 <0.9.0;

error IsNotTokenOwnerNorApproved();
error AlreadyClaim();
error CallerIsContract();
error CannotMintFromContract();
error InsufficientFunds();
error InvalidMintAmount();
error InvalidMintPriceChange();
error InvalidAllowAddress();
error InvalidWithdrawalAmount();
error MintAmountExceedsSupply();
error MintAmountFreeExceedsSupply();
error WithdrawalFailed();
error InvalidMerkleProof();
error MintAmountExceedsUserAllowance();
error InvalidSignature();
error InvalidSignerAddress();
error InvalidNumber();
error AllowMintInsufficient();
error PublicMintInsufficient();

contract BellaNFT is ERC721A, Ownable {
    event SetPublicPrice(
        uint indexed Price
    );
    event SetWlPrice(
        uint  indexed Price
    );

     event SetURI(
        string indexed uri
    );
    event MintedCounters(
        address indexed wallet,
        uint48 indexed amount,
        uint indexed channel
    );
    event SetAllowAddress(
        address indexed allowAddress
    );

    event SalesPhaseChanged(
        uint8 indexed newPhase
    );
    event Burn(
        uint256 indexed tokenId
    );
    event Withdraw(
        uint256 indexed amount,
        address indexed to
    );
    event SetApprovalTime(
        uint indexed time
    );
    event SetMerkleRoot(
        bytes32 indexed root
    );
    event SetSignerAddress(
        address indexed signer
    );

    event SetAllowSupply(
        uint256 indexed max
    );
    event SetPublicSupply(
        uint256 indexed max
    );

    uint256 public constant MAX_SUPPLY = 1800;
    uint public constant PUBLIC_CHANNEL =0;
    uint public constant ALLOW_CHANNEL =1;
    uint256 public MAX_ALLOW_SUPPLY = 1700;
    uint256 public MAX_PUBLIC_SUPPLY =100;
    uint256 public  PUBLIC_PRICE = 0.0002 ether;
    uint256 public  ALLOW_LIST_PRICE = 0.0001 ether;
    uint48 public SUPPLY = 0;
    uint48 public ALLOW_SUPPLYED =0;
    uint48 public PUBLIC_SUPPLYED =0;
    uint48 public constant SECTION_BITMASK = 15;
    uint48 public DEV_LIMIT =1700;
    uint48 public PUBLIC_LIMIT =2;
    string public METADATA_URL;
    uint8 public ALLOW_LIMIT =2;
    uint public SELL_END_TIME;
    uint public SELL_START_TIME;
    address private SIGNER;
    constructor(uint _sellEndTime,//sell end time 
    uint _approveStartTime, // approve start time 
    uint _sellStartTime,//sell start time
    address _signer, //signer
    string memory _uri //metadatauri
    ) ERC721A("Belladonna of Sadness", "Bella"){
        SELL_END_TIME = _sellEndTime;
        SIGNER = _signer;
        SELL_START_TIME =_sellStartTime;
        _setApprovedStartTime(_approveStartTime);
        METADATA_URL = _uri;
    }

    //modifiers
    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContract();
        _;
    }
    modifier mintPublic(uint48 _mintAmount) {
        require(
            SUPPLY + _mintAmount <= MAX_SUPPLY,
            "Max supply exceeded!"
        );
        _;
    }
    function whitelistMint(uint48 _mintAmount, bytes memory signature)
        external
        payable
        callerIsUser
        mintPublic(_mintAmount)
    {   
        require((getDate()<SELL_END_TIME),"timeout");
        require(_mintAmount!=0,"zero mint");
        require((ALLOW_SUPPLYED +_mintAmount <= MAX_ALLOW_SUPPLY),"MAX_ALLOW_SUPPLY");

        bytes32 x = keccak256(abi.encodePacked(msg.sender));
        require((ECDSA.recover(x, signature) == SIGNER),"error sign"); 

        uint64 userAux = _getAux(msg.sender);
        uint64 allowlistMinted = (userAux >> 4) & SECTION_BITMASK;
        require((allowlistMinted + _mintAmount <= ALLOW_LIMIT),"MintAmountExceedsUserAllowance");
        require((msg.value >= _mintAmount * ALLOW_LIST_PRICE),"InsufficientFunds");

        uint64 updatedAux = userAux + (_mintAmount << 4);
        _setAux(msg.sender, updatedAux);
        SUPPLY += _mintAmount;
        allowlistMinted+=_mintAmount;
        _mint(msg.sender, _mintAmount);

        emit MintedCounters(msg.sender,_mintAmount,ALLOW_CHANNEL);
    }


    function publicMint(uint48 _mintAmount)
        external
        payable
        callerIsUser
        mintPublic(_mintAmount)
    {
        require((getDate()>SELL_START_TIME),"not start");
        require(_mintAmount!=0,"zero mint");
        require((_mintAmount <= PUBLIC_LIMIT),"limit mint");
        if (getDate()<SELL_END_TIME){
            require((PUBLIC_SUPPLYED +_mintAmount <= MAX_PUBLIC_SUPPLY),"PublicMintInsufficient");
        }
        require((msg.value >= _mintAmount * PUBLIC_PRICE),"InsufficientFunds");
        SUPPLY += _mintAmount;
        PUBLIC_SUPPLYED+= _mintAmount;
        _mint(msg.sender, _mintAmount);
        emit MintedCounters(msg.sender,_mintAmount,PUBLIC_CHANNEL);
    }

    // onlyOwner functions

    function devMint(address _to, uint48 _numberOfTokens)
        external 
        onlyOwner 
    {   
        if (_numberOfTokens > DEV_LIMIT) revert MintAmountExceedsSupply();
        if (SUPPLY + _numberOfTokens > MAX_SUPPLY) revert MintAmountExceedsSupply();
        _mint(_to, _numberOfTokens);
        SUPPLY += _numberOfTokens;
    }
    function setSigner(address _signer)
        external
        onlyOwner
    {
            if (_signer == address(0)) revert InvalidSignerAddress();
            SIGNER = _signer;
            emit SetSignerAddress(_signer);
    }

   
    function setMaxAllowSupply(uint256 _max)
    external
    onlyOwner{
        if (_max==0) revert InvalidNumber();
        if (_max>ALLOW_SUPPLYED) revert InvalidNumber();
        MAX_ALLOW_SUPPLY = _max;
        emit SetAllowSupply(_max);
    }

    
    function setMaxPublicSupply(uint256 _max)
    external
    onlyOwner{
        if (_max==0) revert InvalidNumber();
        if (_max>PUBLIC_SUPPLYED) revert InvalidNumber();
        MAX_PUBLIC_SUPPLY = _max;
        emit SetPublicSupply(_max);
    }

    function setURI(string calldata _uri) 
        external 
        onlyOwner 
    {
        METADATA_URL = _uri;
        emit SetURI(_uri);
    }


    function setPublicMintPrice(uint _mintPrice) 
        external 
        onlyOwner 
    {
        if (_mintPrice < 0.0001 ether) revert InvalidMintPriceChange();
        PUBLIC_PRICE = _mintPrice;
        emit SetPublicPrice(_mintPrice);
    }
  
    function setWlMintPrice(uint _mintPrice) 
        external 
        onlyOwner 
    {
        if (_mintPrice < 0.0001 ether) revert InvalidMintPriceChange();
        ALLOW_LIST_PRICE = _mintPrice;
        emit SetWlPrice(_mintPrice);
    }
    function setStartTime(uint _time) 
        external 
        onlyOwner 
    {
        SELL_START_TIME = _time;
    }
    function setEndTime(uint _time) 
        external 
        onlyOwner 
    {
        SELL_END_TIME = _time;
    }
 
    //
    function withdraw(uint256 _amount, address _to) 
        external 
        onlyOwner 
    {
        uint256 contractBalance = address(this).balance;
        if (contractBalance < _amount) revert InvalidWithdrawalAmount();

        (bool success,) = payable(_to).call{value: _amount}("");
        emit Withdraw(_amount,_to);
        if (!success) revert WithdrawalFailed();
    }
    //publice function

    function burn(uint256 _tokenId) 
        external   
    {
        if(!_isApprovedOrOwner(_msgSender(), _tokenId)) revert IsNotTokenOwnerNorApproved();
        _burn(_tokenId, true);
        emit Burn(_tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721A.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function getApprovedStartTime()
        public
        view
    returns(uint){
        return _getApprovedStartTime();
    }
    function numberMinted(address owner) 
        public 
        view 
        returns (uint256) 
    {
        return _numberMinted(owner);
    }
    function numberMintedWhiteList(address owner) 
        public 
        view 
        returns (uint64) 
    {
        return (_getAux(owner) >> 4) & SECTION_BITMASK;
    }
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return METADATA_URL;
    }
}