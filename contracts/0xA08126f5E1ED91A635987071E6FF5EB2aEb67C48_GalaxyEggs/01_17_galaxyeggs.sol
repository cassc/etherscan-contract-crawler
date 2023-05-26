// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GalaxyEggs is ERC721Enumerable, Ownable, AccessControl {

    using Strings for uint256;

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant PRICE = 0.085 ether;
    uint256 public constant TOTAL_NUMBER_OF_GALAXY_EGGS = 9999;

    uint256 public giveaway_reserved = 280;
    uint256 public pre_mint_reserved = 2000;

    mapping(address => bool) private _pre_sale_minters;

    bool public paused_mint = true;
    bool public paused_pre_mint = true;
    string private _baseTokenURI = "";


    // withdraw addresses
    address lolabs_splitter;

    // initial team
    address mrbob = 0xDfa857c95608000B46315cdf54Fe1efcF842ab89;
    address giligilik = 0xA52B727d7BA9919074f35a6EB5bf61Bbde841139;
    address lolabs = 0x99095E8123283D9335bcd986f1aE7713dB0f0150;

    modifier whenMintNotPaused() {
        require(!paused_mint, "GalaxyEggs: mint is paused");
        _;
    }

    modifier whenPreMintNotPaused() {
        require(!paused_pre_mint, "GalaxyEggs: pre mint is paused");
        _;
    }

    modifier preMintAllowedAccount(address account) {
        require(is_pre_mint_allowed(account), "GalaxyEggs: account is not allowed to pre mint");
        _;
    }

    event MintPaused(address account);

    event MintUnpaused(address account);

    event PreMintPaused(address account);

    event PreMintUnpaused(address account);

    event setPreMintRole(address account);

    event redeemedPreMint(address account);

    constructor(
        string memory _name,
        string memory _symbol,
        address _lolabs_splitter
    )
        ERC721(_name, _symbol)
    {
        lolabs_splitter = _lolabs_splitter;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, mrbob);
        _setupRole(DEFAULT_ADMIN_ROLE, giligilik);
        _setupRole(DEFAULT_ADMIN_ROLE, lolabs);

        _setupRole(WHITE_LIST_ROLE, msg.sender);
        _setupRole(WHITE_LIST_ROLE, mrbob);
        _setupRole(WHITE_LIST_ROLE, giligilik);
        _setupRole(WHITE_LIST_ROLE, lolabs);
    }

    fallback() external payable { }

    receive() external payable { }

    function mint(uint256 num) public payable whenMintNotPaused(){
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require( num <= 12,                                                             "GalaxyEggs: You can mint a maximum of 12 Galaxy Eggs" );
        require( tokenCount + num <= 13,                                                "GalaxyEggs: You can mint a maximum of 13 Galaxy Eggs per wallet" );
        require( supply + num <= TOTAL_NUMBER_OF_GALAXY_EGGS - giveaway_reserved,       "GalaxyEggs: Exceeds maximum Galaxy Eggs supply" );
        require( msg.value >= PRICE * num,                                              "GalaxyEggs: Ether sent is less than PRICE * num" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function pre_mint() public payable whenPreMintNotPaused() preMintAllowedAccount(msg.sender){
        require( pre_mint_reserved > 0,         "GalaxyEggs: Exceeds pre mint reserved Galaxy Eggs supply" );
        require( msg.value >= PRICE,            "GalaxyEggs: Ether sent is less than PRICE" );
        _pre_sale_minters[msg.sender] = false;
        pre_mint_reserved -= 1;
        uint256 supply = totalSupply();
        _safeMint( msg.sender, supply);
        emit redeemedPreMint(msg.sender);
    }

    function giveAway(address _to) external onlyRole(WHITE_LIST_ROLE) {
        require(giveaway_reserved > 0, "GalaxyEggs: Exceeds giveaway reserved Galaxy Eggs supply" );
        giveaway_reserved -= 1;
        uint256 supply = totalSupply();
        _safeMint( _to, supply);
    }

    function pauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

    function pausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_pre_mint = true;
        emit PreMintPaused(msg.sender);
    }

    function unpausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_pre_mint = false;
        emit PreMintUnpaused(msg.sender);
    }

    function updateLolaSplitterAddress(address _lolabs_splitter) public onlyRole(WHITE_LIST_ROLE) {
        lolabs_splitter = _lolabs_splitter;
    }

    function setPreMintRoleBatch(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
        for(uint256 i; i < _addresses.length; i++){
            _pre_sale_minters[_addresses[i]] = true;
            emit setPreMintRole(_addresses[i]);
        }
    }

    function setBaseURI(string memory baseURI) public onlyRole(WHITE_LIST_ROLE) {
        _baseTokenURI = baseURI;
    }

    function withdrawAmountToSplitter(uint256 amount) public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "GalaxyEggs: withdraw amount call without balance");
        require(_balance-amount >= 0, "GalaxyEggs: withdraw amount call with more than the balance");
        require(payable(lolabs_splitter).send(amount), "GalaxyEggs: FAILED withdraw amount call");
    }

    function withdrawAllToSplitter() public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "GalaxyEggs: withdraw all call without balance");
        require(payable(lolabs_splitter).send(_balance), "GalaxyEggs: FAILED withdraw all call");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "GalaxyEggs: URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
            : '';
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getLolabsSplitter() public view onlyRole(WHITE_LIST_ROLE) returns(address splitter) {
        return lolabs_splitter;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function is_pre_mint_allowed(address account) public view  returns (bool) {
        return _pre_sale_minters[account];
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}