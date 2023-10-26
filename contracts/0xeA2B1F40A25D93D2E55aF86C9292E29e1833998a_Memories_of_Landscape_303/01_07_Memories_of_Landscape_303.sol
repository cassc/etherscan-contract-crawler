// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./BitMaps.sol";

contract Memories_of_Landscape_303 is Ownable, ERC721A  {

    // BitMaps 
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _isConsumed;

    // OnChain memoey for the Season PassCard
    mapping(uint256 => uint256) session;
    mapping(address => mapping (uint256 => uint256)) private mint_limit_count;

    // Total number of Session(season)
    uint256 public total_session = 1;

    // Initial session_id
    uint256 public cur_session_id = 1;
    
    // baseUri mapping
    mapping(uint256 => string) base_uri;

    // Definition of status of the mint progress
    uint256 immutable ADMIN_SWITCH = 1;
    uint256 immutable AIRDROP_SWITCH = 2;
    uint256 immutable WHITELIST_SWITCH = 3;
    uint256 immutable PUBLIC_SWITCH = 4;
    uint256 public cur_switch;

    // Mint Price for public sale and whitelist
    uint256 public whitelist_price = 0.1 ether;
    uint256 public public_sale_price = 0.1 ether;
    
    // Limit of mint token per address in WhiteList & Public
    uint256 public max_whitelist_mint_no = 0;
    uint256 public max_public_mint_no = 10;
  

    // merkle tree for using whitelist address verfication 
    bytes32 public merkle_root;


    // Requirement of modifier in the stage of mint
    modifier onlyAdminSwitchOpen() {
        require(cur_switch == ADMIN_SWITCH, "admin switch closed");
        _;
    }

    modifier onlyAirdroopSwitchOpen() {
        require(cur_switch == AIRDROP_SWITCH, "airdrop switch closed");
        _;
    }


    modifier onlyWhitelistSwitchOpen() {
        require(cur_switch == WHITELIST_SWITCH, "whitelist switch closed");
        _;
    }

    modifier onlyPublicSwitchOpen() {
        require(cur_switch == PUBLIC_SWITCH, "public switch closed");
        _;
    }

    // Setup name & symbol
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {}

    // Setup session(season)-id baseUri 
    function setBaseURI(
        string memory _base_uri,
        uint256 _session_id
    ) external onlyOwner {
        base_uri[_session_id] = _base_uri;
    }

    // AdminMint Stage which ADMIN_SWITCH = 1
    function adminMint(
        address _to,
        uint256 _quantity
    ) external onlyAdminSwitchOpen onlyOwner {
        mint(_to, _quantity);
    }

    // AirDropMint stage which AIRDROP_SWITCH = 2
    function airdropMint(
        address[] calldata _to,
        uint256[] calldata _quantity
    ) external onlyAirdroopSwitchOpen onlyOwner {
        uint256 len = _to.length;
        require(len == _quantity.length);

        for (uint256 i = 0; i < len; ) {
            mint(_to[i], _quantity[i]);
            ++i;
        }
    }

    // WhiteListMint stage which WHITELIST_SWITCH = 3
    function whitelistMint(
        //uint256 session_id,
        uint256 _quantity,
        bytes32[] calldata proof
    ) external payable onlyWhitelistSwitchOpen {
        address _account = msg.sender;

        // Check the mint limit
        require(_quantity <= max_whitelist_mint_no ,"Don't exceed the WhiteList Mint Maximum limit!");

        // When setup leaf from JS, need to packed as [address, cur_session_id] to generate the root
        bytes32 leaf = keccak256(abi.encodePacked(_account, cur_session_id));

        // One address only redeem once at every session of WhiteList Regeristion and mint
        require(!_isConsumed.get(uint256(leaf)), "You have already redeemed the whitelist rights at this season! (consumed)");
        _isConsumed.set(uint256(leaf));

        // Merkle Proof
        require(MerkleProof.verify(proof, merkle_root, leaf), "Invalid proof");

        // Send equivalent Ethereum to contract 
        require(msg.value == _quantity * whitelist_price, "Please enter the enough ethereum to mint! (no enough ether)");
        mint(_account, _quantity);
    }

    // PublicMint stage which PUBLIC_SWITCH = 4
    function publictMint(
        uint256 _quantity
    ) external payable onlyPublicSwitchOpen {
        require(_quantity <= max_public_mint_no ,"Don't exceed the Public Mint Maximum limit!");
        require(_quantity <= allowedMintLimitCount(msg.sender, cur_session_id),"You have reached the max mint limit for each address, Please mint Less!");
        require(msg.value == _quantity * public_sale_price, "Please enter the enough ethereum to mint! (no enough ether)");
        mint(msg.sender, _quantity);
        updateMintLimitCount(msg.sender, _quantity, cur_session_id);
    }

    // Internal calling _safemint function from 1-4 Mint
    function mint(address _to, uint256 _quantity) internal {
        require(totalSupply() + _quantity <= session[cur_session_id], "exceed the maximum supply!");
        _safeMint(_to, _quantity);
    }

    // Read metadata
	function session_baseURI(uint256 session_id) external view virtual returns (string memory) {
		return base_uri[session_id];
    }

    // Read Session supply
	function session_supply(uint256 session_id) external view returns (uint256) {
        return session[session_id];
    }    

    // Read tokenURI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 i = 1;
        for (; i < total_session; ) {
            if (tokenId + 1 > session[i]) {
                ++i;
            } else {
                break;
            }
        }
        string memory baseURI = base_uri[i];

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId),".json"))
                : "";
    }

    // Input Season(Session) root , which constructed from [address, season(session)]
    // Input merkle tree root from a list of address
    function setMerkleRoot(bytes32 _merkle_root) external onlyOwner {
        merkle_root = _merkle_root;
    }

    // Update Public Sale Price
    function setPublicSalePrice(uint256 _public_sale_price) external onlyOwner {
        public_sale_price = _public_sale_price;
    }

    // Update WhiteList Price 
    function setWhiteListPrice(uint256 _whitelist_price) external onlyOwner {
        whitelist_price = _whitelist_price;
    }

    // Setup max number of Public sale limit
    function setPublicMintNo(uint256 _max_public_mint_no)external onlyOwner{
        max_public_mint_no = _max_public_mint_no;
    }

    // Setup max number of Public sale limit
    function setWhiteListMintNo(uint256 _max_whitelist_mint_no)external onlyOwner{
        max_whitelist_mint_no = _max_whitelist_mint_no;
    }


    // Switch of based on what mint stage we are
    function setCurSwitch(uint256 _cur_switch) external onlyOwner {
        cur_switch = _cur_switch;
    }

    // Update the number of remaining limit can mint in public sale
    function allowedMintLimitCount(address minter_address, uint256 _session_id) public view returns(uint256){
        return max_public_mint_no - mint_limit_count[minter_address][_session_id];
    }

    // Update counters for public sale mint Max limit per address
    function updateMintLimitCount(address minter_address, uint256 count, uint256 _session_id)private{
        mint_limit_count[minter_address][_session_id] += count;
    }

    // Set up for the each session(season)[id] have how many tokens
    function setSession(
        uint256 _session_id,
        uint256 _amount
    ) external onlyOwner {
        session[_session_id] = _session_id == 1
            ? _amount
            : session[_session_id - 1] + _amount;
    }

    // Withdrawal function to onlyowner
    receive() external payable {}

    function withdraw(uint _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

}