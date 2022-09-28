// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// import "erc721a/contracts/ERC721A.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoolVincents is ERC721A, Ownable {
    uint256 constant MAX_MINTS = 2;
    uint256 constant MAX_SUPPLY = 299;
    uint256 public mintPrice = 0 ether;

    // Allowlist (whitelist)
    bytes32 public root;

    // Metadata, Uri
    string public baseURI = "https://coolvincent.nyc3.digitaloceanspaces.com/json/";

    // ERC20 - Pledge
    address public _token20;
    bool private _token20Seted = false;

    // Market
    bool public isPublicSaleActive = true;
    bool public isRevealed = true;


    constructor() ERC721A("CoolVincents", "VNCT$") {}

    

    function mint(uint256 quantity) external payable {
        require(isPublicSaleActive, "Public mint is not active");
        require(quantity <= MAX_MINTS, "Exceeded the personal limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded!");

        if(quantity==5){
            require(msg.value >= 0 ether, "Not enough ether sent");
        }
        else{
            require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        }

        _safeMint(msg.sender, quantity);
    }

  
    function airDrop(address receiver) external {
        require(isPublicSaleActive, "Public mint is not active");
        require( receiver != _msgSender(), "You cannot fill in your own address");
        uint64 _aux = _getAux(_msgSender());
        require(_aux == 0, "You have already mint free give");
        if ( receiver == address(0)){
            require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough left");
        }
        else{
            require(totalSupply() + 2 <= MAX_SUPPLY, "Not enough left");
            _safeMint(receiver, 1);
        }
        _safeMint(msg.sender, 1);

        _setAux(_msgSender(), 1);
    }
    
    /**
     * @dev can get one for free, if fill one other address can give 1 free token as present 
     * if not, need to fill in 0x0000000000000000000000000000000000000000, then only caller can get one for free
    */
   //
   

    function burn(uint256 tokenId) external{
        _burn(tokenId, true); // no approve function, but need to check if owner
    }

  

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return isRevealed
                ?  string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) 
                : string(abi.encodePacked(baseURI));
    }

    /**
    * @dev set the address of erc20 contract interecting with this NFT 
    * 
    * called by once and only
    */
    function setErc20(address myErc20) external onlyOwner {
        require(!_token20Seted, "Token20 has been already set");
        //I trust that there is no one in team will randomly send some wrong contract to this function;
        _token20 = myErc20;
        _token20Seted = true;
    }

    /**
    * @dev set pledge status of NFT without change owner and owner's balance record 
    * 
    * Requirements:
    * - only call by the address of erc20 contract which has set by setErc20() function
    * 
    * who heve token pledged, still can call function setApprovalForAll
    */
    function pledgeTransferFromWithoutOwnerChange(
        address from,
        address to,
        uint256 tokenId,
        uint24 isPledged
    ) external virtual {
        require(_msgSender() == _token20, "You're not our contract");

        TokenOwnership memory prevOwnership = _ownershipAt(tokenId);
        if (isPledged==0){
            require(prevOwnership.extraData == 1, "This NFT hasn't been pledged"); //extraData will be initialized to 1 when mint() & transferFrom() by erc721A
            require(prevOwnership.addr == to, "This NFT does not belong to this address");
        }
        else{
            require(prevOwnership.extraData == 0, "This NFT has already been pledged");  //extradata=0=pledged
            require(prevOwnership.addr == from, "This NFT is not yours");
        }
        
        _setExtraDataAt(tokenId, isPledged);
    }

 
    
    function getPledgeStatus(uint256 tokenId) public view returns(uint24){
        require(_exists(tokenId), "This token does not exist");
        TokenOwnership memory prevOwnership = _ownershipAt(tokenId);
        return prevOwnership.extraData;
    }

    /**
    @dev `transfer` and `send` assume constant gas prices. 
    * onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
    */
    function withdraw() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function devMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded!");
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _seatURI, bool _state) external onlyOwner {
        baseURI = _seatURI;
        isRevealed = _state;
    }

    function setIsPublicSaleActive(bool _newState) external onlyOwner {
        isPublicSaleActive = _newState;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function getNumOfBurned(address ownerAddr) public view returns(uint256){
        return _numberBurned(ownerAddr);
    }

    function getMintStatus() external view returns(uint64){
        return _getAux(_msgSender());
    }

}