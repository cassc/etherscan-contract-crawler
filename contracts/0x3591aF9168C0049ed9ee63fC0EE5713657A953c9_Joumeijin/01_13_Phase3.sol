//SPDX-License-Identifier: Unlicense

/*

 __      __  __    __  _______   ________  ______ 
|  \    /  \|  \  |  \|       \ |        \|      \
 \$$\  /  $$| $$  | $$| $$$$$$$\| $$$$$$$$ \$$$$$$
  \$$\/  $$ | $$  | $$| $$__| $$| $$__      | $$  
   \$$  $$  | $$  | $$| $$    $$| $$  \     | $$  
    \$$$$   | $$  | $$| $$$$$$$\| $$$$$     | $$  
    | $$    | $$__/ $$| $$  | $$| $$_____  _| $$_ 
    | $$     \$$    $$| $$  | $$| $$     \|   $$ \
     \$$      \$$$$$$  \$$   \$$ \$$$$$$$$ \$$$$$$
                                                  
                                                  
                                    by: The Croc              

*/
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//error
error NoYureiOwned();
error NotYourPhurbaNerd();
error AlreadyThereSer();
error NotAFriend();
error noFriendFount();
error noOniOwned();
//phurba
abstract contract phurbaContract{

    function DestroyKey(uint256 tokenId) public virtual;
    function setApprovalForAll(address operator, bool approved) public virtual;
    function ownerOf(uint256 tokenId) public virtual returns (address);
}
//yurei
abstract contract YureiContract{

    function balanceOf(address owner) public view virtual returns (uint256);
   
}

contract Joumeijin is ERC721, ERC2981, Ownable {


    //Events
    event Minted(uint256 indexed tokenId);

    //var
    uint256 public MaxSupply = 3333;
    uint256 private _supply;

    uint256 public price = 0.005 ether;
    uint256 public publicPrice = 0.05 ether;
    uint256 public KeyPrice = 0.01 ether; 
    string public URI;
    string private uriSuffix = ".json";

    mapping(uint256 => bool) public isBurned; 
    mapping(address => bool) public PublicList;
    mapping(address => bool) public FriendListCount;
    //mapping(address => bool) public FriendList;
    mapping(address => bool) public OniClaimed;

    address[] public Friends;
    bool public KeyBurn = false;
    bool public YureiKeyBurn = false;
    bool public Onimint = false;

    enum State {
    Closed,
    Private,
    Public
    }

    State public salestatus = State.Closed;

    address public KeycontractAddress = 0xaC07B10340318A47E6396Bbec0B92611c865D8Cd;
    address public YureiAddress = 0x54251bc32A9f389DF7c764AB50BB829ccDcB41bc;
    address public SoulOniAddress = 0xeAcbfd060f4B5aaa0E20fa47c098068CBe23F299;
    //only approved operators
    mapping (address => bool) public ApprovedAddr;

    constructor(address _RoyaltyReceiver, uint96 _royaltyAmount)  ERC721("Joumeijin", "JOUME")  {
        setRoyaltyInfo(_RoyaltyReceiver,_royaltyAmount);
    }

   
    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    modifier OnlyWhitelistedOp(address _ops){
        require(ApprovedAddr[_ops], "Not approved operator");
        _;
    }

    modifier OwnYurei() {
        YureiContract Yurei = YureiContract(YureiAddress);
        if(Yurei.balanceOf(msg.sender)<1) revert NoYureiOwned();
        _;
    }

    modifier OwnOni() {
        YureiContract SoulOni = YureiContract(SoulOniAddress);
        if(SoulOni.balanceOf(msg.sender)<1) revert noOniOwned();
        _;
    }

    modifier OwnAFriend(address _nerd){
        bool found;
        for(uint256 i=0; i< Friends.length; i++){
            YureiContract FriendContract = YureiContract(Friends[i]);
            if(FriendContract.balanceOf(msg.sender)>0) {
                found = true;
                break;
            }

        }
        require(found, "No friend found");
        _;
    }


    function setState(State _saleState) external onlyOwner {
    
    salestatus = _saleState;
    
    }

    //Metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(URI, Strings.toString(tokenId), uriSuffix));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        URI = _newBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    
    //Friends Mint


    function NerdMint() external payable IsUser OwnAFriend(msg.sender) {
        require(salestatus == State.Private, "Private is not open");
        require(!FriendListCount[msg.sender],"Insufficient mints left");
        require(msg.value == publicPrice,"insufficient funds provided");

        FriendListCount[msg.sender] = true;
        mint(msg.sender);
        
    }

    //Public mint
    function mintPublic() external payable IsUser {
        require(salestatus == State.Public, "Public is not open");
        require(!PublicList[msg.sender],"Insufficient mints left");
        require(msg.value == publicPrice,"insufficient funds provided");

        PublicList[msg.sender] = true;
        mint(msg.sender);
    }



    //YureiMint

    function _StartRitual(uint256 Phurba) internal {
        require(!isBurned[Phurba],"This Phurba is used");

        
        phurbaContract key = phurbaContract(KeycontractAddress);
        if(key.ownerOf(Phurba) != msg.sender) revert NotYourPhurbaNerd();
        key.DestroyKey(Phurba);
        isBurned[Phurba]=true;

    }

    //phurba burn mint
    function BurnPhurbaMint(uint256 _key) public payable IsUser {
        require(KeyBurn, "Burn not open");
        require(msg.value == KeyPrice,"insufficient funds provided");

        _StartRitual(_key);
        mint(msg.sender);
    }

    //yurei holders only mint
    function BurnAndMint(uint256 _Phurba) public payable IsUser OwnYurei {
        require(YureiKeyBurn, "hold your hoeses");
        require(msg.value == price,"insufficient funds provided");

        _StartRitual(_Phurba);
        mint(msg.sender);

        
    }

    //soulOni Claim
    function SoulOniMint() external OwnOni {
        require(Onimint, "hold your hoeses");
        require(!OniClaimed[msg.sender],"Insufficient mints left");

        OniClaimed[msg.sender] = true;
        mint(msg.sender);

    }
    //mint function
    function mint(address _who) internal {
        require(totalSupply() < MaxSupply, "max supply reached");
        _supply++;
        _mint(_who, totalSupply());

        emit Minted(totalSupply());

    }
    //owner mint
    function OwnerMint(address to) public onlyOwner {
        mint(to);
        
    }

    ///////////////////////////////Owner//////////////////////////////////////

    //start Burn to mint for yurei holders or phurba only
    function StartTheFire(bool key, bool yurei,bool oni) onlyOwner external{
        KeyBurn=key;
        YureiKeyBurn=yurei;
        Onimint=oni;

    }


    //set contract for SoulOni

     function SetOniContract(address _contr) external onlyOwner {
        SoulOniAddress = _contr;
    }
    
    //set contract for phurba

     function SetKeyContract(address _contr) external onlyOwner {
        KeycontractAddress = _contr;
    }

    //set contract address for yurei
    function SetYureiContract(address _contr) external onlyOwner {
        YureiAddress = _contr;
    }
    //add a friend to the FL
    function AddFriend(address _friend) external onlyOwner {

        Friends.push(_friend);
    }

    //approval modification

    function AddApprover(address Approver) public onlyOwner {
        require(!ApprovedAddr[Approver], "Contract is already in the whitelist");
        ApprovedAddr[Approver] = true;
    }

    function removeApprover(address Approver) public onlyOwner {
        delete ApprovedAddr[Approver];
    }

    //Override functions

    function setApprovalForAll(address operator, bool approved) public virtual OnlyWhitelistedOp(operator) override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public OnlyWhitelistedOp(operator) override {
        super.approve(operator, tokenId);
    }


    //royalty 100 is 1%
    
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
         return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyAmount) public onlyOwner {
        _setDefaultRoyalty(_receiver,_royaltyAmount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}