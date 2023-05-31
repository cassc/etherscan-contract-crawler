pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./FoundersTokensV2.sol";
//import "./CollabFaker.sol";
import "./StakingContract.sol";

contract StarFallVillage is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;

    uint256 private MAX_TOKENS;

    uint256 private MAX_GENESIS = 3333;

    uint256 private SALE_PRICE = 0.08 ether;

    uint256 private WL_LIMIT = 1111;

    uint256 private AL_AMOUNT = 10;

    uint256 private FP_AMOUNT = 2;

    uint256 private balance = 0;

    uint256 private _wlStartDateTime;

    uint256 private _wlEndDateTime;

    uint256 private _alStartDateTime;

    uint256 private _alEndDateTime;

    uint256 private _publicSaleTime;

    bool private publicSaleActive = true;

    bool private isGenesis = true;

    string private baseURI = "https://sfvpfp.s3.amazonaws.com/preview/";

    mapping (address => uint256) private _mappingWhiteList;

    mapping (address => uint256) private _mappingAllowList;

    mapping (address => uint256) private _mappingFPSpots;

    mapping (address => bool) private _mappingPartnerChecked;

    address fp_address;

    mapping(string => uint256) discountNum;
    
    //mapping(string => uint256) discountDen;

    uint256 wlSaleCount = 0;

    uint256 public offsetGenesis = 0;

    uint256 public offsetNext = 0;

    bool public genesisOffsetSet = false;

    bool public nextOffsetSet = false;

    address[10] partner_tokens_721 = [0xf36446105fF682999a442b003f2224BcB3D82067, 
    0xb072114151f32D85223aE7B00Ac0528d1F56aa6E, 0xf36446105fF682999a442b003f2224BcB3D82067, 0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42, 
    0x9690b63Eb85467BE5267A3603f770589Ab12Dc95, 0xe26F2c3547123B5FDaE0bfD52419D71BdFb0c4EF, 0x67421C8622F8E38Fe9868b4636b8dC855347d570, 
    0x8c3FB10693B228E8b976FF33cE88f97Ce2EA9563, 0x364C828eE171616a39897688A831c2499aD972ec, 0x8Cd8155e1af6AD31dd9Eec2cEd37e04145aCFCb3];

    //address[2] partner_tokens_721 = [0x6a033F4680069BB66D99Dab5Bf97C6D2c663d4A7, 0x0C296728a1B309a8f7043F22349c1874e63cF37f];  // for dev

    address[2] staking_partners = [0x0C565d28364a2C073AF3E270444476C19e8b986c, 0x682F6Fa7dBf3ea6CAd1533E4acd9B5E6f67372C9];

    //address[2] staking_partners = [0xBf8a4dF45F98386852b1Ae1aDb7F5e1fFa8d9200, 0xBf8a4dF45F98386852b1Ae1aDb7F5e1fFa8d9200]; // for dev

    address[2] partner_tokens_1155 = [0x495f947276749Ce646f68AC8c248420045cb7b5e, 0x495f947276749Ce646f68AC8c248420045cb7b5e];

    uint256[2] start_token_ids = [108510973921457929967077298367545831468135648058682555520544970183838078599169,
    108510973921457929967077298367545831468135648058682555520544981071202216837121];

    uint256[2] token_deltas = [1099511627776, 1099511627776];

    constructor(address _fp, uint256 supply) ERC721("StarFall Village PFP", "SVPFP") public {
        _owner = msg.sender;

        MAX_TOKENS = supply;

        fp_address = _fp;

        _tokenIds.increment();

        discountNum["Paper"] = 90;
        discountNum["Bronze"] = 85;
        discountNum["Silver"] = 80;
        discountNum["Gold"] = 75;
        discountNum["Ghostly"] = 50;

        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        uint256 total = fp.itemsMinted();
        for (uint256 i=1; i <= total; i++) {
            _mappingFPSpots[fp.ownerOf(i)] += FP_AMOUNT;
        }

    }



    /** Sale helper functions */

    function hasPartnerTokenStaked(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < staking_partners.length; i ++) {
            StakingContract sc = StakingContract(staking_partners[i]);
            if (sc.depositsOf(owner).length > 0) {
                return true;
            }
        }

        return false;
    }

    function hasPartnerToken(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < partner_tokens_721.length; i ++) {
            ERC721 token = ERC721(partner_tokens_721[i]);
            if (token.balanceOf(owner) > 0) {
                return true;
            }
        }

        return false;
    }

    function hasSemiPartnerToken(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < partner_tokens_1155.length; i ++) {
            ERC1155 token = ERC1155(partner_tokens_1155[i]);
            uint256 token_id = start_token_ids[i];
            for (uint i= 0; i < 9900; i++) {
                if (token.balanceOf(owner, token_id) > 0) {
                    return true;
                }
                token_id += token_deltas[i];
            }
        }

        return false;
    }

    function getWLPrice(uint256 numberOfMints, address wallet) 
    public 
    view 
    returns (uint256) {
        uint256 price = 0;
        if (numberOfMints > _mappingFPSpots[wallet]) {
            price = (numberOfMints - _mappingFPSpots[wallet]) * SALE_PRICE;
        }
        return price;
    }

    function getDiscountPrice(uint256 numberOfMints, uint256 fpTokenId) 
    public 
    view 
    returns (uint256) {
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        //require(wallet == fp.ownerOf(fpTokenId), "not owner");
        (, string memory trait) = fp.getTraits(fpTokenId);
        uint256 discountPrice = (SALE_PRICE * numberOfMints * discountNum[trait]) / 100;
        return discountPrice;
    }

    function getDiscountPriceWL(uint256 numberOfMints, uint256 fpTokenId, address wallet)
    public 
    view 
    returns (uint256) {
        uint256 discountPrice = 0;
        if (numberOfMints > _mappingFPSpots[wallet]) {
            FoundersTokensV2 fp = FoundersTokensV2(fp_address);
            (, string memory trait) = fp.getTraits(fpTokenId);
            discountPrice = ((numberOfMints - _mappingFPSpots[wallet]) * SALE_PRICE * discountNum[trait]) / 100;
        }
        return discountPrice;
    }

    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        //string memory _tokenURI = _tokenURIs[tokenId];
        //string(abi.encodePacked("ipfs://"));
        if (tokenId <= MAX_GENESIS) {
            uint256 tokenIdGenesis = tokenId + offsetGenesis;
            if (tokenIdGenesis > MAX_GENESIS) {
                tokenIdGenesis = tokenIdGenesis - MAX_GENESIS;
            }
            return string(abi.encodePacked("https://sfvpfp.s3.amazonaws.com/preview/", Strings.toString(tokenIdGenesis), ".json"));
        }
        uint256 tokenIdNext = tokenId + offsetNext;
        if (tokenIdNext > MAX_TOKENS) {
            tokenIdNext = tokenIdNext - MAX_TOKENS + MAX_GENESIS;
        }
        return string(abi.encodePacked(baseURI, Strings.toString(tokenIdNext), ".json"));
    }



    /** Owner methods */

    function createMintEvent(uint256 wlStartTime, uint256 wlEndTime, uint256 alStartTime, uint256 alEndTime, uint256 publicStartTime) 
    external 
    onlyOwner {
        _wlStartDateTime = wlStartTime;
        _wlEndDateTime = wlEndTime; //wlStartTime + WL_SALE_LENGTH;
        _alStartDateTime = alStartTime;
        _alEndDateTime = alEndTime; //alStartTime + AL_SALE_LENGTH;
        _publicSaleTime = publicStartTime;
    }

    function setWhiteList(address[] calldata whiteListAddress, uint256[] calldata amount) 
    external 
    onlyOwner {
        for (uint256 i = 0; i < whiteListAddress.length; i++) {
            _mappingWhiteList[whiteListAddress[i]] = amount[i];
        }
    }

    function setAllowList(address[] calldata allowListAddress) 
    external 
    onlyOwner {
        for (uint256 i = 0; i < allowListAddress.length; i++) {
            _mappingAllowList[allowListAddress[i]] = AL_AMOUNT;
        }
    }

    function setFPList() 
    external 
    onlyOwner {
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        uint256 total = fp.itemsMinted();
        for (uint256 i=1; i <= total; i++) {
            _mappingFPSpots[fp.ownerOf(i)] += FP_AMOUNT;
        }
    }

    function setBaseURI(string memory _uri) 
    external 
    onlyOwner {
        baseURI = _uri;
    }

    function changePrice(uint256 _salePrice) 
    external 
    onlyOwner {
        SALE_PRICE = _salePrice;
    }

    function changeWLLimit(uint256 limit) 
    external 
    onlyOwner {
        WL_LIMIT = limit;
    }

    function changeALAmount(uint256 amount) 
    external 
    onlyOwner {
        AL_AMOUNT = amount;
    }

    function changeFPAmount(uint256 amount) 
    external 
    onlyOwner {
        FP_AMOUNT = amount;
    }

    function setPublicSaleActive(bool active) 
    external 
    onlyOwner {
        publicSaleActive = active;
    }

    function setGenisis(bool genesis) 
    external 
    onlyOwner {
        isGenesis = genesis;
    }

    function getRandom(uint256 limit) 
    private 
    view 
    returns(uint16) {
        uint256 totalMinted = itemsMinted();
        address owner1 = ownerOf(totalMinted/5);
        address owner2 = ownerOf(totalMinted*2/5);
        address owner3 = ownerOf(totalMinted*3/5);
        address owner4 = ownerOf(totalMinted*4/5);
        address owner5 = ownerOf(totalMinted - 1);
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), owner1, owner2, owner3, owner4, owner5)));
        return uint16(uint16(pseudoRandom >> 1) % limit);
    }

    function revealGenesis() 
    external 
    onlyOwner { 
        require(
            !genesisOffsetSet, 
            "already revealed"
        );
        offsetGenesis = uint256(getRandom(MAX_GENESIS));
        genesisOffsetSet = true;
    }

    function revealNext() 
    external 
    onlyOwner { 
        require(
            !nextOffsetSet, 
            "already revealed"
        );
        offsetNext = uint256(getRandom(MAX_TOKENS - MAX_GENESIS));
        nextOffsetSet = true;
    }



    /** Minting methods */

    function mintWhiteList(uint256 numberOfMints) 
    public 
    payable {
        uint256 reserved = _mappingWhiteList[msg.sender] + _mappingFPSpots[msg.sender];
        require(
            isWhiteListSale(), 
            "No presale active"
        );
        require(
            reserved > 0 || 
            msg.sender == _owner, 
            "This address is not authorized for presale"
        );
        require(
            numberOfMints <= reserved 
            || msg.sender == _owner, 
            "Exceeded allowed amount"
        );
        require(
            wlSaleCount + numberOfMints <= WL_LIMIT, 
            "This would exceed the max number of allowed for wl sale"
        );
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            getWLPrice(numberOfMints, msg.sender) <= msg.value 
            || msg.sender == _owner, 
            "Amount of ether is not enough"
        );

        uint256 usedSpots = 0;

        if (numberOfMints >= _mappingFPSpots[msg.sender]) {
            usedSpots = _mappingFPSpots[msg.sender];
            _mappingFPSpots[msg.sender] = 0;
        } else {
            _mappingFPSpots[msg.sender] = _mappingFPSpots[msg.sender] - numberOfMints;
        }
        if ((numberOfMints > usedSpots) && _mappingFPSpots[msg.sender] == 0) {
            _mappingWhiteList[msg.sender] = _mappingWhiteList[msg.sender] - (numberOfMints - usedSpots);
        }

        wlSaleCount = wlSaleCount + numberOfMints;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintWhiteListWithDiscount(uint256 numberOfMints, uint256 fpTokenId) 
    public 
    payable {
        uint256 reserved = _mappingWhiteList[msg.sender] + _mappingFPSpots[msg.sender];
        require(
            isWhiteListSale(), 
            "No presale active"
        );
        require(
            reserved > 0 
            || msg.sender == _owner, 
            "This address is not authorized for presale"
        );
        require(
            numberOfMints <= reserved 
            || msg.sender == _owner, 
            "Exceeded allowed amount"
        );
        require(
            wlSaleCount + numberOfMints <= WL_LIMIT, 
            "This would exceed the max number of allowed for wl sale"
        );
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        uint256 discountPrice = getDiscountPriceWL(numberOfMints, fpTokenId, msg.sender);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        uint256 usedSpots = 0;

        if (numberOfMints >= _mappingFPSpots[msg.sender]) {
            usedSpots = _mappingFPSpots[msg.sender];
            _mappingFPSpots[msg.sender] = 0;
        } else {
            _mappingFPSpots[msg.sender] = _mappingFPSpots[msg.sender] - numberOfMints;
        }
        if ((numberOfMints > usedSpots) && _mappingFPSpots[msg.sender] == 0) {
            _mappingWhiteList[msg.sender] = _mappingWhiteList[msg.sender] - (numberOfMints - usedSpots);
        }

        wlSaleCount = wlSaleCount + numberOfMints;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintAllowList(uint256 numberOfMints) public payable {
        uint256 reserved = _mappingAllowList[msg.sender];
        require(
            isAllowListSale(), 
            "No presale active"
        );
        //require(hasPartnerToken(msg.sender), "No partner token");
        require(
            reserved > 0 
            || hasPartnerToken(msg.sender) 
            || hasPartnerTokenStaked(msg.sender)
            || hasSemiPartnerToken(msg.sender),
            "This address is not authorized for presale"
        );
        if (reserved == 0 && (hasPartnerToken(msg.sender) || hasPartnerTokenStaked(msg.sender) || hasSemiPartnerToken(msg.sender))) {
            if (!_mappingPartnerChecked[msg.sender]) {
                _mappingAllowList[msg.sender] = AL_AMOUNT;
                _mappingPartnerChecked[msg.sender] = true;
            }
            reserved = _mappingAllowList[msg.sender];
            require(
                reserved > 0, 
                "This address is not authorized for presale"
            );
        }
        require(
            numberOfMints <= reserved, 
            "Exceeded allowed amount"
        );
        //require(alSaleCount < AL_LIMIT, "This would exceed the max number of allowed for allow sale");
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            numberOfMints * SALE_PRICE <= msg.value, 
            "Amount of ether is not enough"
        );

        _mappingAllowList[msg.sender] = reserved - numberOfMints;

        _mappingPartnerChecked[msg.sender] = true;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintAllowListWithDiscount(uint256 numberOfMints, uint256 fpTokenId) public payable {
        uint256 reserved = _mappingAllowList[msg.sender];
        require(
            isAllowListSale(), 
            "No presale active"
        );
        //require(hasPartnerToken(msg.sender), "No partner token");
        require(
            reserved > 0 
            || hasPartnerToken(msg.sender) 
            || hasPartnerTokenStaked(msg.sender)
            || hasSemiPartnerToken(msg.sender), 
            "This address is not authorized for presale"
        );
        if (reserved == 0 && (hasPartnerTokenStaked(msg.sender)  || hasPartnerToken(msg.sender) || hasSemiPartnerToken(msg.sender))) {
            if (!_mappingPartnerChecked[msg.sender]) {
                _mappingAllowList[msg.sender] = AL_AMOUNT;
                _mappingPartnerChecked[msg.sender] = true;
            }
            reserved = _mappingAllowList[msg.sender];
            require(
                reserved > 0, 
                "This address is not authorized for presale"
            );
        }
        require(
            numberOfMints <= reserved, 
            "Exceeded allowed amount"
        );
        //require(alSaleCount < AL_LIMIT, "This would exceed the max number of allowed for allow sale");
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        require(
            msg.sender == fp.ownerOf(fpTokenId), 
            "not owner"
        );
        uint256 discountPrice = getDiscountPrice(numberOfMints, fpTokenId);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        _mappingAllowList[msg.sender] = reserved - numberOfMints;

        _mappingPartnerChecked[msg.sender] = true;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function createItem(uint256 numberOfTokens) public payable returns (uint256) {
        require(
            (
                (block.timestamp >= _publicSaleTime && publicSaleActive) 
                || msg.sender == _owner
            ), 
            "sale not active"
        );
        require(
            msg.value >= (SALE_PRICE * numberOfTokens) 
            || msg.sender == _owner, 
            "not enough money"
        );

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(
            (newItemId - 1 + numberOfTokens) <= MAX_TOKENS, 
            "collection fully minted"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfTokens <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        for (uint256 i=0; i < numberOfTokens; i++) {

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }

    function createItemWithDiscount(uint256 numberOfTokens, uint256 fpTokenId) public payable returns (uint256) {
        require(
            (
                (block.timestamp >= _publicSaleTime && publicSaleActive) 
                || msg.sender == _owner
            ), 
            "sale not active"
        );
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        require(
            msg.sender == fp.ownerOf(fpTokenId), 
            "not owner"
        );
        uint256 discountPrice = getDiscountPrice(numberOfTokens, fpTokenId);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(
            (newItemId - 1 + numberOfTokens) <= MAX_TOKENS, 
            "collection fully minted"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfTokens <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        for (uint256 i=0; i < numberOfTokens; i++) {

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }


    /** Public View methods */

    function withdraw() onlyOwner public {
        require(
            address(this).balance > 0, 
            "0 balance"
        );
        payable(_owner).transfer(address(this).balance);
    }

    function getRemainingWLSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingWhiteList[wl];
    }

    function getRemainingFPSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingFPSpots[wl];
    }

    function getRemainingAllowListSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingAllowList[wl];
    }

    function getParterChecked(address wl) 
    public 
    view 
    returns (bool) {
        return _mappingPartnerChecked[wl];
    }

    function getCurrentPrice() 
    public 
    view 
    returns (uint256) {
        return SALE_PRICE;
    }

    function getWLSaleCount() 
    public 
    view 
    returns (uint256) {
        return wlSaleCount;
    }

    function itemsMinted() 
    public 
    view 
    returns(uint) {
        return _tokenIds.current() - 1;
    }

    function ownerBalance() 
    public 
    view 
    returns(uint256) {
        return address(this).balance;
    }

    function isWhiteListSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _wlStartDateTime && block.timestamp <= _wlEndDateTime);
    }

    function isAllowListSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _alStartDateTime && block.timestamp <= _alEndDateTime);
    }

    function isPublicSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _publicSaleTime);
    }

}