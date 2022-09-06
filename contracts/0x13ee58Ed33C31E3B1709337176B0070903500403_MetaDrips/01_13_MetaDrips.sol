// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
contract MetaDrips is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;

    bool public paused = true;
    bool public onlyWhitelisted = true;
    mapping(address => bool) public whitelistedAddresses;
    uint256[] public prices = [0.5 ether, 1 ether, 3 ether];
    uint[] public limits = [100, 75,50];
    mapping(uint => uint) public nftTier;
    mapping(uint => uint) public nftMinted;


    address private __vault = 0x42DF924Ded4006d5ED24a642b695046E35cf9718; 

    event WithdrawAll(uint256 _amt, address _to);
    event TierLimit(uint _tier, uint _limit);
    event SetURI(string _uri);
    event SetPrice(uint _tier, uint256 _newPrice);
    event Mint(uint _tier, address _address);
    event WhitelistStatus(bool _state);
    event WhitelistUsers(address[] _wallets, bool _state);


    constructor(string memory baseURI) ERC721("MetaDrips", "MD")  {
        setBaseURI(baseURI);
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(nftTier[_tokenId]), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function getURI() external view returns (string memory){
        return _baseTokenURI;
    }

    function mint(uint _tier) public payable {
        uint256 supply = totalSupply();
        require(!paused,                                 "Sale paused" );
        require(nftMinted[_tier] + 1 <= limits[_tier],   "Exceeds maximum NFT supply" );

        require(msg.value == prices[_tier],              "Ether sent is not correct" );

        if(onlyWhitelisted) {
            require(whitelistedAddresses[msg.sender],    "Wallet is not whitelisted");
        }

        nftTier[supply+1] = _tier;
        nftMinted[_tier]++;
        _safeMint(msg.sender, supply + 1 );
        emit Mint(_tier, msg.sender);
        (bool success, ) = payable(__vault).call{value: msg.value}("");
        require(success,                                 "Can't transfer" );
    }


    function giveAway(address _to, uint256 _amount, uint _tier) external onlyOwner() {
        uint256 supply = totalSupply()+1;
        for(uint256 i; i < _amount; i++){
            nftTier[supply+i] = _tier;
            nftMinted[_tier]++;
            _safeMint( _to, supply + i );
        }
    }
    function withdrawAll() external onlyOwner() { 
        (bool success, ) = payable(__vault).call{value: address(this).balance}("");
        require(success, "Can't transfer" );
        emit WithdrawAll(address(this).balance, __vault);
    }
    function whitelistUsers(address[] calldata _wallets, bool _state) external onlyOwner() { 
        for(uint256 i; i < _wallets.length; i++){
            whitelistedAddresses[_wallets[i]] = _state;
        }
        emit WhitelistUsers(_wallets, _state);
    }

    function setBaseURI(string memory baseURI) public onlyOwner() { 
        _baseTokenURI = baseURI;
        emit SetURI(baseURI);
    }
    function setOnlyWhitelisted(bool _state) external onlyOwner() {
        onlyWhitelisted = _state;
        emit WhitelistStatus(_state);
    }
    function setVaultAddress(address _newAddress) external onlyOwner() { 
        require( _newAddress != address(0), "Vault can not be set to the zero address" );
        __vault = _newAddress;
    }
    function setTierLimit(uint _tier, uint _limit) external onlyOwner() { 
        limits[_tier] = _limit;
        emit TierLimit(_tier, _limit);
    }
    function setPrice(uint _tier, uint256 _newPrice) external onlyOwner() { 
        prices[_tier] = _newPrice;
        emit SetPrice(_tier, _newPrice);
    }
    function addTier(uint256 _newPrice, uint _limit) external onlyOwner() { 
        prices.push(_newPrice);
        limits.push(_limit);
    }
    function setPause(bool _newState) external onlyOwner() { 
        paused = _newState;
    }
}