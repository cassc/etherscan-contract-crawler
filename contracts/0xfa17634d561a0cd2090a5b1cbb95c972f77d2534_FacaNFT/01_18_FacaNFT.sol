// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract FacaNFT is Ownable, ERC721, ERC721Enumerable, VRFConsumerBase, ReentrancyGuard {
    using SafeMath for uint256;
    
    event FacaNFTRandomnessRequest(uint timestamp);
    event FacaNFTRandomnessFulfil(uint timestamp, bytes32 requestId, uint256 seed);
    event FacaNFTChainlinkError(uint timestamp, bytes32 requestId);
    event FacaNFTReveal(uint timestamp);
    event FacaManualSetSeed(uint timestamp);
    event FacaWhitelist(address adress);
    event PermanentURI(string _value, uint256 indexed _id);

    bool _revealed = false;
    bool _requestedVRF = false;

    bytes32 _keyHash;

    uint private _mode = 0;
    uint private _limitPrivateSaleTx = 2;
    uint private _limitPublicSaleTx = 20;
    uint public maxAirdrop;
    uint public maxPrivateSale;
    uint public totalAirdrop;
    uint public totalPrivateSale;
    uint public maxSupply;

    uint256 public seed = 0;
    uint256 private _privateSalePrice = 77000000000000000; //0.077ETH
    uint256 private _publicSalePrice = 88000000000000000; //0.088ETH

    string _tokenBaseURI;
    string _defaultURI;
    
    mapping(address => uint) private _originalOwns;
    mapping(address => uint) private _presaleMinted;
    mapping(address => bool) private _originalOwner;
    mapping(address => bool) private _presaleAllowed;

    /**
     * @param vrfCoordinator address of Chainlink VRF coordinator to use
     * @param linkToken address of LINK token
     * @param keyHash Chainlink VRF keyhash for the coordinator
     * @param tokenName Token name
     * @param tokenSymbol Token symbol
     * @param baseURI token base URI
     * @param defaultURI token default URI aka loot box
     * @param maximumAirdrop max amount for airdrop
     * @param maximumPrivateSale max amount to sale in private sale
     * @param maximumSupply max supply of token
     */
    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        string memory tokenName, 
        string memory tokenSymbol, 
        string memory baseURI,
        string memory defaultURI,
        uint maximumAirdrop,
        uint maximumPrivateSale,
        uint maximumSupply
    ) ERC721(tokenName, tokenSymbol) 
        VRFConsumerBase(vrfCoordinator, linkToken) {
        maxAirdrop = maximumAirdrop;
        maxPrivateSale = maximumPrivateSale;
        maxSupply = maximumSupply;
        _keyHash = keyHash;
        _tokenBaseURI = baseURI;
        _defaultURI = defaultURI;
    }

    /**
     * @dev ensure collector pays for mint token and message sender is directly interact (and not a contract)
     * @param amount number of token to mint
     */
    modifier mintable(uint amount) {
        require( msg.sender == tx.origin , "Apes don't like bots");

        if(_mode == 1) {
            require(amount <= _limitPrivateSaleTx, "Number Token invalid.");
            require(msg.value >= amount.mul(_privateSalePrice), "Payment error.");
        }

        if(_mode == 3) {
            require(amount <= _limitPublicSaleTx, "Number Token invalid.");
            require(msg.value >= amount.mul(_publicSalePrice), "Payment error.");
        }

        _;
    }

    /**
     * @dev add collector to private sale allowlist
     */
    function addAllowlist(address[] memory allowlist) public onlyOwner {
        for(uint i = 0; i < allowlist.length; i+=1) {
            _presaleAllowed[allowlist[i]] = true;
            emit FacaWhitelist(allowlist[i]);
        }
    }

    /**
     * @dev airdrop token for marketing and influencer campaign
     */
    function airdrop(address[] memory _to, uint256 amount) public onlyOwner {
        require(totalAirdrop + (_to.length * amount) <= maxAirdrop, "Exceed airdop allowance limit.");
        for (uint i = 0; i < _to.length; i+=1) {
            mintFaca(_to[i], amount, true); // mint for marketing & influencer
        }
    }

    /**
     * @dev return token base URI to construct metadata URL
     */
    function tokenBaseURI() public view returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @dev get sale mode
     * 0 - offline
     * 1 - presale
     * 2 - before public sale
     * 3 - public sale
     * 4 - close public sale
     * 5 - sold out
     */
    function getSaleMode() public view returns(uint) {
        if (_mode == 1 &&  totalPrivateSale == maxPrivateSale - maxAirdrop) {
            return 2;
        }

        if (totalSupply() - totalAirdrop == maxSupply - maxAirdrop) {
            return 5;
        }

        return _mode;
    }

    /**
     * @dev get sale price base on sale mode
     */
    function getPrice() public view returns(uint256) {
        return (_mode == 1) ? _privateSalePrice : _publicSalePrice; // return public sale price as default
    }

    /**
     * @dev get current amount of minted token by sale mode
     */
    function getMintedBySaleMode() public view returns(uint256) {
        if (_mode == 1) return totalPrivateSale;
        if (_mode == 3) return totalPublicSale();
        return 0;
    }

    /**
     * @dev get current token amount available for sale (by sale mode)
     */
    function getMaxSupplyBySaleMode() public view returns(uint256) {
        if (_mode == 1) return maxPrivateSale  - maxAirdrop;
        if (_mode == 3) return maxSupply - totalPrivateSale - maxAirdrop;
        return 0;
    }

    /**
     * @dev emit event for OpenSea to freeze metadata.
     */
    function freezeMetadata() public onlyOwner {
        for (uint256 i = 1; i <= totalSupply(); i+=1) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    /**
     * @dev ensure collector is under allowlist
     */
    function inAllowlist(address collector) public view returns(bool) {
        return _presaleAllowed[collector];
    }

    /**
     * @dev check if collector is an original minter
     */
    function isOriginalOwner(address collector) public view returns(bool) {
        return _originalOwns[collector] > 0;
    }

    function isRequestedVrf() public view returns(bool) {
        return _requestedVRF;
    }

    function isRevealed() public view returns(bool) {
        return _requestedVRF && _revealed;
    }

    /**
     * @dev shuffle metadata with seed provided by VRF
     */
    function metadataOf(uint256 tokenId) public view returns (string memory) {
        if(_msgSender() != owner()) {
            require(tokenId <= totalSupply(), "Token id invalid");
        }
        
        if(!_revealed) return "default";

        uint256[] memory metaIds = new uint256[](maxSupply+1);
        uint256 ss = seed;

        for (uint256 i = 1; i <= maxSupply; i+=1) {
            metaIds[i] = i;
        }

        // shuffle meta id
        for (uint256 i = 1; i <= maxSupply; i+=1) {
            uint256 j = (uint256(keccak256(abi.encode(ss, i))) % (maxSupply));
            (metaIds[i], metaIds[j]) = (metaIds[j], metaIds[i]);
        }

        return Strings.toString(metaIds[tokenId]);
    }


    /**
     * @dev Mint NFT
     */
    function mintNFT(uint256 amount) public payable nonReentrant mintable(amount) returns (bool) {
        require(_mode == 1 || _mode == 3, "Sale is not available");
        return mintFaca(_msgSender(), amount, false);
    }

    /**
     * @dev get amount of original minted amount.
     */
    function originalMintedBalanceOf(address collector) public view returns(uint){
        return _originalOwns[collector];
    }

    function publicSalePrice() public view returns(uint256) {
        return _publicSalePrice;
    }
    
    function privateSalePrice() public view returns(uint256) {
        return _privateSalePrice;
    }

    /**
     * @dev request Chainlink VRF for a random seed
     */
    function requestChainlinkVRF() public onlyOwner {
        require(!_requestedVRF, "You have already generated a random seed");
        require(LINK.balanceOf(address(this)) >= 2000000000000000000);
        requestRandomness(_keyHash, 2000000000000000000);
        _requestedVRF = true;
        emit FacaNFTRandomnessRequest(block.timestamp);
    }

    /**
     * @dev set token base URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _tokenBaseURI = baseURI;
    }

    /**
     * @dev reveal all lootbox
     */
    function reveal() public onlyOwner {
        require(!_revealed, "You can only reveal once.");
        _revealed = true;
    }

    /**
     * @dev set public sale price in case we have last minutes change on sale price/promotion
     */
    function setPublicSalePrice(uint256 price) public onlyOwner {
        _publicSalePrice = price;
    }

    /**
     * @dev set seed number (only used for automate testing and emergency reveal)
     */
    function setSeed(uint randomNumber) public onlyOwner {
        _requestedVRF = true;
        seed = randomNumber;
        emit FacaManualSetSeed(block.timestamp);
    }

    /**
     * @dev start private sale
     */
    function startPrivateSale() public onlyOwner {
        _mode = 1;
    }

    /**
     * @dev change mode to before public sale
     */
    function startBeforePublicSale() public onlyOwner {
        _mode = 2;
    }

    /**
     * @dev change mode to public sale
     */
    function startPublicSale() public onlyOwner {
        _mode = 3;
    }

    /**
     * @dev close public sale
     */
    function closePublicSale() public onlyOwner {
        _mode = 4;
    }

    function stopAllSale() public onlyOwner {
        _mode = 0;
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev return token metadata based on reveal status
     */
    function tokenURI(uint256 tokenId) public view override (ERC721) returns (string memory) {
        require(tokenId <= totalSupply(), "Token not exist.");
        
        // before we reveal, everyone will get default URI
        return isRevealed() ? string(abi.encodePacked(_tokenBaseURI, metadataOf(tokenId), ".json")) :_defaultURI;        
    }

    /**
     * @dev total public sale amount
     */
     function totalPublicSale() public view returns(uint) {
        return totalSupply() - totalPrivateSale - totalAirdrop;
    }

    /**
     * @dev withdraw ether to owner/admin wallet
     * @notice only owner can call this method
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev ensure original minter is logged and favor for future use.
     */
    function addOriginalOwns(address collector) internal {
        _originalOwns[collector] += 1;
    }

    /**
     * @dev ensure private sale amount will not exceed quota per collector
     */
    function isValidPrivateSaleAmount(address collector,uint amount) internal view returns(bool) {
        return _presaleMinted[collector] + amount <= _limitPrivateSaleTx;
    }

    /**
     * @dev ensure private sale amount will not oversell
     */
    function isOversell(uint amount) internal view returns(bool) {
        return getMintedBySaleMode().add(amount)  <= getMaxSupplyBySaleMode();
    }

    /**
     * @dev Mints amount `amount` of token to collector
     * @param collector The collector to receive the token
     * @param amount The amount of token to be minted
     * @param isAirdrop Flag for use in airdrop (internally)
     */
    function mintFaca( address collector, uint256 amount, bool isAirdrop) internal returns (bool) {
        // private sale
        if(getSaleMode() == 1) {
            require(inAllowlist(collector), "Only whitelist addresses allowed.");
            require(isValidPrivateSaleAmount(collector, amount), "Max presale amount exceeded.");
        }
        if (getSaleMode() > 0 && !isAirdrop) {
            require(isOversell(amount), "Cannot oversell");
        }

        for (uint256 i = 0; i < amount; i+=1) {
            uint256 tokenIndex = totalSupply();
            
            if (tokenIndex < maxSupply) {
                _safeMint(collector, tokenIndex+1);
                addOriginalOwns(collector);
            }
        }

        logTrade(collector, amount, isAirdrop);
        return true;
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        if (randomNumber > 0) {
            seed = randomNumber;
            emit FacaNFTRandomnessFulfil(block.timestamp, requestId, seed);
        }
        else {
            seed = 1;
            emit FacaNFTChainlinkError(block.timestamp, requestId);
        } 
    }

    /**
     * @dev log trade amount for controlling the capacity of tx
     * @param collector collector address
     * @param amount amount of sale
     * @param isAirdrop flag for log airdrop transaction
     */
    function logTrade(address collector,uint amount, bool isAirdrop) internal {
        if (isAirdrop) {
            totalAirdrop += amount;
            return;
        }

        if (_mode == 1) {
            totalPrivateSale += amount;
            _presaleMinted[collector] += amount;
        }
    }
}