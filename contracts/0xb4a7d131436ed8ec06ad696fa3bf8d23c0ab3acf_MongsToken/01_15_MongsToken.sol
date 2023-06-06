// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MongsToken is
    Context,
    Ownable,
    ERC721Burnable,
    ERC721Pausable
{
    using Strings for uint256;
    event Blend(address indexed operator, uint256 indexed tokenId, uint256 indexed burnTokenId);

    struct WhitelistSettings {
        uint256[] startTime;
        uint256[] limitPerAddress;        
        uint256[] whitelistIds;
    }

    uint24 private constant PROJECT_SCALE = 1e6;
    uint24 private constant MAX_MINT_ID = 999999;

    string private _baseTokenURI;
    string private _contractURI;
    address private _proxyRegistryAddress;

    address private _payoutAddress;
    uint256 private _projectFee;
    uint256 private _supplyTracker;

    // Mapping from address to balance
    mapping(address => uint256) private _balances;

    // Mapping from project id to current mint number
    mapping(uint256 => uint256) private _projectMints;

    // Mapping from project id to project upgrades
    mapping(uint256 => string) private _projectURIs;

    // Mapping from project id to address or token
    mapping(uint256 => mapping(address => uint256)) private _addressClaims;
    mapping(uint256 => mapping(uint256 => uint256)) private _tokenClaims;

    // Mapping to nonce used
    mapping(uint256 => mapping(uint256 => bool)) private _nonces;

    // Mapping from project id to project settings
    mapping(uint256 => address) public _projectOwner;
    
    // Mapping from project id to project settings
    mapping(uint256 => uint256) private _projectSettings;

    // Mapping from project id to project upgrades
    mapping(uint256 => uint256) private _projectUpgrades;

    // Mapping from project id to project blends
    mapping(uint256 => uint256) private _projectBlends;

    // Mapping from project id to project perks
    mapping(uint256 => mapping(uint256 => uint256)) private _projectPerks;

    // Mapping from whitelist id to address approved
    mapping(uint256 => mapping(address => bool)) private _whitelist;

    // Mapping from project id whitelist array
    mapping(uint256 => WhitelistSettings) private _projectWhitelist;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory initContractURI,
        address payoutAddress,
        address proxyAddress
    ) ERC721(name, symbol) {
        _proxyRegistryAddress = proxyAddress;
        _baseTokenURI = baseTokenURI;
        _contractURI = initContractURI;
        _payoutAddress = payoutAddress;
        _projectFee = 100;        
    }

    //view functions
    function balance(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function totalSupply() public view returns (uint256) {
        return _supplyTracker;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function projectSupply(uint256 projectId) public view returns (uint256) {
        return _projectMints[projectId];
    }

    function addressClaims(address owner, uint256 projectId) public view returns(uint256) {
        return _addressClaims[projectId][owner];
    }

    function tokenClaims(uint256 tokenId, uint256 projectId) public view returns(uint256) {
        return _tokenClaims[projectId][tokenId];
    }

    function projectSettings(uint256 projectId) public view returns (
        uint256 maxSupply,
        uint256 costEach,
        uint256 startTime, 
        uint256 limitPerTx, 
        uint256 limitPerAddress
    ) {
        uint256 settings = _projectSettings[projectId];
        maxSupply = uint256(uint64(settings));
        costEach = uint256(uint64(settings>>64));
        startTime = uint256(uint64(settings>>128));
        limitPerTx = uint256(uint32(settings>>192));
        limitPerAddress = uint256(uint32(settings>>224));
    }

    function projectPerks(uint256 projectId, uint256 perkProjectId) public view returns (        
        uint256 costEach,
        uint256 startTime, 
        uint256 limitPerTx, 
        uint256 limitPerAddress,
        uint256 limitPerToken
    ) {
        uint256 settings = _projectPerks[projectId][perkProjectId];
        costEach = uint256(uint64(settings));
        startTime = uint256(uint64(settings>>64));
        limitPerTx = uint256(uint64(settings>>128));
        limitPerAddress = uint256(uint32(settings>>192));
        limitPerToken = uint256(uint32(settings>>224));
    }

    function projectUpgrades(uint256 projectId) public view returns (        
        uint256 outputProjectId,
        uint256 inputQuantity
    ) {
        uint256 settings = _projectUpgrades[projectId];
        outputProjectId = uint256(uint128(settings));
        inputQuantity = uint256(uint128(settings>>128));
    }

    function projectBlends(uint256 projectId) public view returns (        
        uint256 burnProjectId
    ) {
        burnProjectId = _projectBlends[projectId];
    }

    function checkSignature(
        uint256 projectId, 
        uint256 nonce, 
        bytes memory signature
    ) public view returns (
        uint256 maxSupply
    ) {
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(projectId,nonce))), signature);
        require(signer == _projectOwner[projectId], "BADSIG");
        (maxSupply, , , , ) = projectSettings(projectId); 
    }

    function checkWhitelist(address owner, uint256 whitelistId) public view returns (
        bool approved
    ) {
        approved = _whitelist[whitelistId][owner];
    }

    function checkProjectWhitelist(uint256 projectId) public view returns (
        uint256[] memory startTime,
        uint256[] memory limitPerAddress,        
        uint256[] memory whitelistIds
    ) {
        startTime = _projectWhitelist[projectId].startTime;
        limitPerAddress = _projectWhitelist[projectId].limitPerAddress;
        whitelistIds = _projectWhitelist[projectId].whitelistIds;
    }

    //admin functions 

    function setProxy(address proxyRegistryAddress) public onlyOwner {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function setProjectFee(uint256 projectFee) public onlyOwner {
        _projectFee = projectFee;
    } 
    
    function setPayoutAddress(address payoutAddress) public onlyOwner {
        _payoutAddress = payoutAddress;
    }   

    function setContractURI(string memory initContractURI) public onlyOwner {
        _contractURI = initContractURI;
    } 

    function setProjectURI(uint256 projectId, string memory projectURI) public onlyOwner {
        _projectURIs[projectId] = projectURI;
    } 

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function addProject(address owner, uint256 projectId) public onlyOwner {
        _projectOwner[projectId] = owner;
    }

    function transferProject(address newOwner, uint256 projectId) public {
        require(_projectOwner[projectId] == _msgSender(), "NOTOWNER");
        _projectOwner[projectId] = newOwner;
    }

    function configProject(
        uint256 projectId,
        uint256 maxSupply,
        uint256 costEach,
        uint256 startTime, 
        uint256 limitPerTx, 
        uint256 limitPerAddress
    ) public {
        require(_projectOwner[projectId] == _msgSender(), "NOTOWNER");        
        require(maxSupply > 0 && maxSupply <= MAX_MINT_ID, "SUPPLY");
        require(costEach <= 18 ether, "COST");
        require(startTime < 2e64 && limitPerTx < 2e32 && limitPerAddress < 2e32, "OOB");

        uint256 settings = maxSupply;
        settings |= costEach<<64;
        settings |= startTime<<128;
        settings |= limitPerTx<<192;
        settings |= limitPerAddress<<224;
        _projectSettings[projectId] = settings;
    }

    function configPerk(
        uint256 projectId,
        uint256 perkProjectId,
        uint256 costEach,
        uint256 startTime,
        uint256 limitPerTx,
        uint256 limitPerAddress,
        uint256 limitPerToken       
    ) public {
        require(_projectOwner[projectId] == _msgSender(), "NOTOWNER");
        require(_projectOwner[perkProjectId] != address(0), "NOPERK");
        require(costEach <= 18 ether, "COST");
        require(startTime < 2e64 && limitPerTx < 2e32 && limitPerAddress < 2e32 && limitPerToken < 2e32, "OOB");

        uint256 settings = costEach;
        settings |= startTime<<64;
        settings |= limitPerTx<<128;
        settings |= limitPerAddress<<192;
        settings |= limitPerToken<<224;
        _projectPerks[projectId][perkProjectId] = settings;  
    }

    function configUpgrade(
        uint256 projectId,
        uint256 outputProjectId,
        uint256 quantity       
    ) public {
        require(_projectOwner[projectId] == _msgSender(), "NOTOWNER");
        require(_projectOwner[outputProjectId] == _msgSender(), "NOTOWNER");

        uint256 settings = outputProjectId;
        settings |= quantity<<128;
        _projectUpgrades[projectId] = settings;  
    }

    function configBlend(
        uint256 projectId,
        uint256 burnProjectId      
    ) public {
        require(_projectOwner[projectId] == _msgSender(), "NOTOWNER");
        _projectBlends[projectId] = burnProjectId;  
    }

    function pushWhitelist(uint256 whitelistId, address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            _whitelist[whitelistId][addresses[i]] = true;
        }
    }

    function popWhitelist(uint256 whitelistId, address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            delete _whitelist[whitelistId][addresses[i]];
        }
    }

    function configWhitelist(uint256 projectId, uint256[] memory startTime, uint256[] memory limitPerAddress, uint256[] memory whitelistIds) public onlyOwner {
        require(startTime.length == limitPerAddress.length, "LENGTH");
        require(limitPerAddress.length == whitelistIds.length, "LENGTH");
        _projectWhitelist[projectId] = WhitelistSettings(startTime, limitPerAddress, whitelistIds);
    }

    //user functions

    function withdraw(address payable account) public {
        require(account == _msgSender(), "AUTH");
        uint256 payment = _balances[account]; 
        require(payment > 0, "NOFUNDS"); 
        _balances[account] = 0;
        Address.sendValue(account, payment);
    }

    function mint(address to, uint256 projectId, uint256 quantity) public payable {
        address owner;
        uint256 maxSupply;
        uint256 totalCost;
        uint256 limitPerAddress;
        (owner, maxSupply, totalCost, limitPerAddress) = _checkProject(_msgSender(), projectId, quantity);
        _internalMint(owner,to,projectId,maxSupply,totalCost,quantity,limitPerAddress);
    }

    function mintWhitelist(address to, uint256 projectId, uint256 quantity) external {
        uint256 maxSupply;
        uint256 mints = _projectMints[projectId];
        (maxSupply, , , , ) = projectSettings(projectId);

        bool eligible = false;
        for (uint256 i = 0; i < _projectWhitelist[projectId].whitelistIds.length; ++i) {
            if(_whitelist[_projectWhitelist[projectId].whitelistIds[i]][_msgSender()]) {
                eligible = true;

                if(_projectWhitelist[projectId].limitPerAddress[i] > 0) {
                    require(_addressClaims[projectId][_msgSender()] + quantity <= _projectWhitelist[projectId].limitPerAddress[i], "ADDRESS LIMIT");
                    _addressClaims[projectId][_msgSender()] += quantity;
                }

                if(_projectWhitelist[projectId].startTime[i] > 0) {
                    require(_projectWhitelist[projectId].startTime[i] <= block.timestamp, "TOO EARLY");
                }

                break;
            }
        }
        
        require(eligible, "NOTWHITELISTED");
        require(mints + quantity <= maxSupply, "COMPLETE");

        _projectMints[projectId] += quantity;
        _supplyTracker += quantity;

        for (uint256 i = 0; i < quantity; ++i) {
            _safeMint(to, (projectId * PROJECT_SCALE) + mints + i + 1);
        }    
    }

    function promo(address to, uint256 projectId, uint256 claimId, bytes memory signature) external {
        require(_nonces[projectId][claimId] == false, "CLAIMED");
        uint256 maxSupply = checkSignature(projectId, claimId, signature);
        uint256 mintNumber = _projectMints[projectId] + 1;
        require(mintNumber <= maxSupply, "COMPLETE");
        _projectMints[projectId] += 1;
        _supplyTracker += 1;
        _nonces[projectId][claimId] = true;
        _safeMint(to, (projectId * PROJECT_SCALE) + mintNumber);
    }

    function claim(address to, uint256 projectId, uint256 quantity, uint256 tokenId) public payable {
        address owner;
        uint256 maxSupply;
        uint256 totalCost;
        uint256 limitPerAddress;
        uint256 limitPerToken;
        uint256 perkProjectId = tokenId / PROJECT_SCALE;

        require(ERC721.ownerOf(tokenId) == _msgSender(), "TOKENID");

        (owner, maxSupply, totalCost, limitPerAddress, limitPerToken) = _checkPerk(projectId, perkProjectId, quantity);
        
        if(limitPerToken > 0) {
            require(_tokenClaims[projectId][tokenId] + quantity <= limitPerToken, "TOKEN LIMIT");
            _tokenClaims[projectId][tokenId] += quantity;
        }

        _internalMint(owner,to,projectId,maxSupply,totalCost,quantity,limitPerAddress);
    }

    function upgrade(address to, uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "NOTOKENS");
        uint256 maxSupply;
        uint256 outputProjectId;
        uint256 projectId = tokenIds[0] / PROJECT_SCALE;
        (maxSupply, outputProjectId) = _checkUpgrade(projectId, tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require((tokenIds[i] / PROJECT_SCALE) == projectId, "NOTMATCH");
            burn(tokenIds[i]);
        }

        uint256 mintNumber = _projectMints[outputProjectId] + 1;
        require(mintNumber <= maxSupply, "COMPLETE");
        _projectMints[outputProjectId] += 1;
        _supplyTracker += 1;
        _safeMint(to, (outputProjectId * PROJECT_SCALE) + mintNumber);
    }

    function blend(uint256 tokenId, uint256 burnTokenId) public {
        uint256 projectId = tokenId / PROJECT_SCALE;
        uint256 burnProjectId = burnTokenId / PROJECT_SCALE;
        uint256 compareProjectId = _projectBlends[projectId];
        require(burnProjectId == compareProjectId, "INVALID");
        require(ERC721.ownerOf(tokenId) == _msgSender(), "TOKENID");
        burn(burnTokenId);
        emit Blend(_msgSender(), tokenId, burnTokenId);
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "NOTOKEN");
        uint256 projectId = tokenId / PROJECT_SCALE;        
        string memory _projectURI = _projectURIs[projectId];

        if (bytes(_projectURI).length > 0) {
            return string(abi.encodePacked(_projectURI, tokenId.toString()));
        }

        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if(_proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    //internal functions

    function _internalMint(
        address projectOwner,
        address destination,
        uint256 projectId,
        uint256 maxSupply,
        uint256 totalCost,
        uint256 quantity,
        uint256 limitPerAddress
    ) internal {
        if(projectOwner != _msgSender()) {
            require(totalCost == msg.value, "FUNDS");        

            if(limitPerAddress > 0) {
                require(_addressClaims[projectId][_msgSender()] + quantity <= limitPerAddress, "ADDRESS LIMIT");
                _addressClaims[projectId][_msgSender()] += quantity;
            }

            uint256 projectFee = (msg.value * _projectFee) / 1000;
            uint256 projectPayout = msg.value - projectFee;

            _balances[_payoutAddress] += projectFee;        
            _balances[projectOwner] += projectPayout;
        }        

        uint256 mints = _projectMints[projectId];
        require(mints + quantity <= maxSupply, "COMPLETE");

        _projectMints[projectId] += quantity;
        _supplyTracker += quantity;

        for (uint256 i = 0; i < quantity; ++i) {
            _safeMint(destination, (projectId * PROJECT_SCALE) + mints + i + 1);
        }    
    }

    function _checkProject(address operator, uint256 projectId, uint256 quantity) internal view returns (
        address owner,
        uint256 maxSupply,
        uint256 totalCost,
        uint256 limitPerAddress
    ) {        
        uint256 costEach;
        uint256 startTime;
        uint256 limitPerTx;
        (maxSupply, costEach, startTime, limitPerTx, limitPerAddress) = projectSettings(projectId);
        owner = _projectOwner[projectId];

        if(operator != owner) {
            require(startTime > 0, "DISABLED");
            require(startTime <= block.timestamp, "TOO EARLY");
            require(quantity <= limitPerTx, "TX LIMIT");
        }
        
        totalCost = quantity * costEach;        
    }

    function _checkPerk(uint256 projectId, uint256 perkProjectId, uint256 quantity) internal view returns (
        address owner,
        uint256 maxSupply,
        uint256 totalCost,
        uint256 limitPerAddress,
        uint256 limitPerToken
    ) {        
        uint256 costEach;
        uint256 startTime;
        uint256 limitPerTx;
        (maxSupply, , , , ) = projectSettings(projectId);
        (costEach, startTime, limitPerTx, limitPerAddress, limitPerToken) = projectPerks(projectId, perkProjectId);
        require(startTime > 0, "DISABLED");
        require(startTime <= block.timestamp, "TOO EARLY");
        require(quantity <= limitPerTx, "TX LIMIT");
        totalCost = quantity * costEach;
        owner = _projectOwner[projectId];
    }

    function _checkUpgrade(uint256 projectId, uint256 quantity) internal view returns (
        uint256 maxSupply,
        uint256 outputProjectId
    ) {        
        uint256 inputQuantity;
        (outputProjectId, inputQuantity) = projectUpgrades(projectId);
        (maxSupply, , , , ) = projectSettings(outputProjectId);  
        require(inputQuantity > 0, "DISABLED");      
        require(quantity == inputQuantity, "QUANTITY");
    }

    

}