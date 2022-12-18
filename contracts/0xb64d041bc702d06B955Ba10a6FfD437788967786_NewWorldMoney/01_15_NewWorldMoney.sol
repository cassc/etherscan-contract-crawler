// SPDX-License-Identifier: MIT

/**
* NEW WORLD MONEY by Val Bochkov
* Old Money Has Let Us Down - It's Time For New World Money
*
* In collaboration with Rarity Garden, renowned US artist Val Bochkov 
* applies the vision of his New World Money idea to a first-of-its-kind 
* NFT collection. Not only New World Money suggests to value money 
* based on people's contributions to society, but also goes the extra 
* mile and preserves value for collectors.
*
* The New World money collection consists of 20 Eras and iconic faces
* for each with a total supply of 3315 NFTs. Each era has its own 
* secured floor, starting with a secured floor of 0.01 ETH for Era #1 
* and 2000 NFTs. Subsequent eras consist of less supply, until a total 
* of 3315 is reached. The floor price may be returned by burning NFTs 
* using this contract's "burnAndReturn" function (do not send to 0x0 directly!).
*
* Additionally, holders of Rarity Garden Unicorns receive $UNIVERSE tokens.
* For Era 1, the additional $UNIVERSE is 500 for each NFT being burned. 500 being 
* added for each subsequent era and NFT.
*
* Art reveal occurs after mint of each era.
*
* Mint & burn page: https://rarity.garden/new-world-money
* Twitter: https://twitter.com/rarity_garden
* Discord: https://discord.gg/Ur8XGaurSd
*/

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./filter/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NewWorldMoney is IERC721A, ERC721A, ERC2981, DefaultOperatorFilterer, Ownable, ReentrancyGuard {

    using Strings for uint256;

    struct Edition {

        uint256 from;
        uint256 to;
    }

    struct Floor {

        uint256 price;
        uint256 edition;
        uint256 extraTokens;
    }

    struct MintData {

        uint256 maxMintsPerWallet;
        uint256 floorPrice;
        uint256 extraTokens;
        uint256 devFee;
        uint256 editionSupply;
        uint256 edition;
        uint256 totalMaxSupply;
        uint256 minted;
        uint256 devFees;
    }

    struct TokenUris {

        string baseTokenUri;
        string defaultURI;
    }

    MintData public _mintData;
    TokenUris public _tokenUris;
    mapping(uint256 => Floor) public _floors;
    mapping(uint256 => Edition) public _editions;
    mapping(uint256 => uint256) public _burned;
    mapping(uint256 => mapping(address => uint256)) public _minters;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory defaultURI,
        address royaltyAddress,
        uint96 royaltyAmount
    ) ERC721A(name, symbol) {

        // initial edition
        _mintData.maxMintsPerWallet = 2;
        _mintData.floorPrice = 10000000000000000;
        _mintData.extraTokens = 500000000000000000000;
        _mintData.devFee = 5000000000000000;
        _mintData.totalMaxSupply = 3315;
        _mintData.editionSupply = 2000;
        _mintData.edition = 1;
        _tokenUris.baseTokenUri = baseTokenURI;
        _tokenUris.defaultURI = defaultURI;

        // setting initial edition data.
        // "to" can change for the current edition if the edition 
        // didn't mint out before a new edition is set.
        _editions[1].from = 0;
        _editions[1].to = 1999;
        
        // initial royalties
        _setDefaultRoyalty(royaltyAddress, royaltyAmount);

        // should make it cheaper for the very first minter
        _floors[_mintData.totalMaxSupply].price = 1;
        _minters[_mintData.totalMaxSupply][_msgSender()] = 1;
    }

    /**
    * Minting
    *
    **/

    function mint(uint256 amount) external payable {

        MintData memory data = _mintData;
        
        require(amount != 0, "mint: amount must be larger than zero.");
        require(data.minted + amount <= data.editionSupply, "mint: max. supply would be reached with the requested amount.");
        require(_minters[data.edition][_msgSender()] + amount <= data.maxMintsPerWallet, "mint: exceeding max. allowed per wallet.");
        uint256 mintPrice = data.floorPrice + data.devFee;
        require(msg.value == amount * mintPrice, "mint: please send the exact amount.");

        uint256 nextTokenId = _nextTokenId();
        
        for(uint256 i = 0; i < amount; i++) {

            _floors[nextTokenId].price = data.floorPrice;
            _floors[nextTokenId].extraTokens = data.extraTokens;
            _floors[nextTokenId].edition = data.edition;
            nextTokenId += 1;
        }

        _mintData.devFees += amount * data.devFee;
        _mintData.minted += amount;
        _minters[data.edition][_msgSender()] += amount;

        _safeMint(_msgSender(), amount, "");
    }

    /**
    * Burn & Return
    *
    * Burns the desired NFTs owned by the caller and returns the guaranteed ETH floors for each.
    * If the returning address owns at least as many unicorns as New World Money tokens to be returned (at that moment),
    * the corresponding extra universe is granted.
    **/

    function burnAndReturn(uint256[] calldata tokenIds) external nonReentrant {

        uint256 refund = 0;
        uint256 universe = 0;
        address unicornAddress = 0x13fD344E39C30187D627e68075d6E9201163DF33;
        address universeAddress = 0xf6f31B8AFBf8E3F7FC8246BEf26093F02838dA98;
        uint256 unicornBalance = IERC721A(unicornAddress).balanceOf(_msgSender());
        
        for(uint256 i = 0; i < tokenIds.length; i++) {

            uint256 token = tokenIds[i];
            Floor memory floor = _floors[token];

            require(ownerOf(token) == _msgSender(), "burnAndReturn: not the owner.");

            if(i < unicornBalance) {
                
                universe += floor.extraTokens;
            }

            refund += floor.price;
            _burned[floor.edition] += 1;
            _burn(token);
        }

        if(universe != 0) {

            if(IERC20(universeAddress).balanceOf(address(this)) >= universe) {

                IERC20(universeAddress).transfer(_msgSender(), universe);
            }
        }

        (bool success,) = payable(_msgSender()).call{value: refund}("");

        if(!success) {

            revert("There has been a problem returning the funds.");
        }
    }

    /**
    * Infos
    *
    **/ 

    function _baseURI() internal view override returns (string memory) {

        return _tokenUris.baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : _tokenUris.defaultURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {

        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
    * Admin
    * 
    **/

    function setupEdition(
        uint256 price,
        uint256 fee,
        uint256 extra,  
        uint256 mintsPerWallet, 
        uint256 edition,
        uint256 supply
    ) external onlyOwner {

        require(supply != 0, "setupEdition: supply must be larger than zero.");
        require(supply + _mintData.minted <= _mintData.totalMaxSupply, "setupEdition: total max reached.");
        require(edition == _mintData.edition + 1, "setupEdition: the next edition number must be an increment of 1.");

        uint256 prevEdition = edition - 1;
        uint256 to = _mintData.minted != 0 ? _mintData.minted - 1 : 0;

        if(to < _editions[prevEdition].from) {
            
            _editions[prevEdition].from = 0;
            _editions[prevEdition].to = 0;

        } else {

            _editions[prevEdition].to = to;
        }

        _editions[edition].from = _mintData.minted;
        _editions[edition].to = _mintData.minted + supply - 1;

        _mintData.floorPrice = price;
        _mintData.extraTokens = extra;
        _mintData.devFee = fee;
        _mintData.maxMintsPerWallet = mintsPerWallet;
        _mintData.edition = edition;
        _mintData.editionSupply = _mintData.minted + supply;
    }

    function setupFees(
        uint256 price, 
        uint256 fee,
        uint256 extra, 
        uint256 mintsPerWallet
    ) external onlyOwner {

        _mintData.floorPrice = price;
        _mintData.extraTokens = extra;
        _mintData.devFee = fee;
        _mintData.maxMintsPerWallet = mintsPerWallet;
    }

    function setBaseUri(string calldata baseTokenURI) external onlyOwner {

        _tokenUris.baseTokenUri = baseTokenURI;
    }

    function setDefaultUri(string calldata defaultURI) external onlyOwner {

        _tokenUris.defaultURI = defaultURI;
    }

    function performErc721Recover(address collection, uint256 token_id) external onlyOwner {

        IERC721A(collection).safeTransferFrom(address(this), _msgSender(), token_id);
    }

    /**
    * The owner may only recover ERC20 tokens that are NOT $UNIVERSE as they are reserved for burn & return.
    *
    */
    function performErc20Recover(address token, uint256 amount) external onlyOwner {

        require(token != 0xf6f31B8AFBf8E3F7FC8246BEf26093F02838dA98, "performErc20Recover: universe tokens only returnable through NWM burning.");

        IERC20(token).transfer(_msgSender(), amount);
    }

    function collectDevFees() external onlyOwner {
        
        uint256 tmp = _mintData.devFees;
        _mintData.devFees = 0;
        
        (bool success,) = payable(_msgSender()).call{value: tmp}("");

        if(!success) {

            revert("There has been a problem collecting the dev fees.");
        }
    }

    /**
    * ERC2981 Royalties
    *
    **/

    function setDefaultRoyalty(address royaltyAddress, uint96 royaltyAmount) external onlyOwner {

        _setDefaultRoyalty(royaltyAddress, royaltyAmount);
    }

    /**
    * Royalty enforcing overrides for OpenSea in order to be eligiible for creator fees on their platform.
    *
    * Since OpenSea basically controls where NFTs are allowed to get transferred to and by whom they may be approved,
    * we added a switch in onlyAllowedOperatorApproval() and onlyAllowedOperator() to turn it off 
    * in case if it will be mis-used by marketplaces.
    *
    * In case we want to allow certain addresses that are banned but the marketplace is not really bad acting,
    * we reserve the right to do so by using an internal allow-list for transfers and approvals.
    **/

    function setInternallyAllowed(address requestor, bool allowed) external onlyOwner {

        internallyAllowed[requestor] = allowed;
    }

    function isInternallyAllowed(address requestor) view external returns(bool) {

        return internallyAllowed[requestor];
    }

    function setOperatorFiltererAllowed(bool allowed) external onlyOwner {

        filterAllowed = allowed;
    }

    function isOperatorFiltererAllowed() view external returns(bool) {

        return filterAllowed;
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {

        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {

        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {

        super.safeTransferFrom(from, to, tokenId, data);
    }
}