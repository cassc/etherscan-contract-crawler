/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface BlackErc20 {
    function getMintedCounts() external view returns (uint256);
    function getAllContractTypes() external view returns (uint256[] memory);
}

contract Berc20Store is Ownable {

    address public authorizedAddress;
    uint256 public maxUrlLength = 50;
    uint256 public maxTextLength = 100;
    string public defaultLogo = "https://s1.ax1x.com/2023/06/18/pC1Sj1A.png";
    string[] private forbiddenNames = ["btc", "eth", "usdt", "bnb", "usdc", "xrp", "steth", "ada", "doge", "sol", "trx", "ltc", "matic", "dot", "dai", "busd", "wbtc", "shiba","avax","uin","link","okb","atom","etc","tusd",""];
    address public devAddress;
    uint256 public payPrice;



    //////////////////////////////////////////////////////////////////////

    struct TokenInfo {
        address tokenAddress;
        string logo;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxMintCount;
        uint256 maxMintPerAddress;
        uint256 mintPrice;
        address creator;
        uint256 progress;
        uint256[4] limits;  // 0 - erc20，1 - erc721，2 - erc1155，3 - white list
    }

    struct TokenMsg {
        string description;
        string logoUrl;
        string bannerUrl;
        string website;
        string twitter;
        string telegram;
        string discord;
        string detailUrl;
    }

    struct Profile {

        uint256 idx;
        TokenMsg msg;
        bytes32 wlRoot;

        mapping(uint256=>uint256) params;
        uint256 paramsCount;

        mapping(uint256=>address) authContracts;
        uint256 authContractsCount;
    }

    struct FoundTokenItem {
        uint128 i;
        uint128 progress;
    }

    //////////////////////////////////////////////////////////////////////

    // tokens
    mapping(uint256 => TokenInfo) public tokens;      // (id=>token), NOTE: begin with 1, or 0 failed 
    uint256 public tokensCount;

    // profile data for uesr
    mapping(address => Profile) public tokenProfiles;
    mapping(string => address) public tokenNames;

    modifier onlyAuthorized() {
        require(msg.sender == authorizedAddress, "Not authorized");
        _;
    }

    receive() external payable {}
    //fallback() external payable {}

    function createTokenInfo(address tokenAddress,
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxMintCount,
            uint256 maxMintPerAddress,
            uint256 mintPrice,
            address creator,
            bytes32 wlRoot,
            uint256[] memory params,
            address[] memory authContracts
        ) external onlyAuthorized {
        require(isNameValid(symbol),"symbol unavailable");
        _addTokenInfo(tokenAddress, name, _toLower(symbol), totalSupply, maxMintCount, maxMintPerAddress, mintPrice, creator, wlRoot, params, authContracts);
         string memory lowerCaseName = _toLower(symbol);
        forbiddenNames.push(lowerCaseName);
    }

    function addTokenInfo(address tokenAddress,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxMintCount,
        uint256 maxMintPerAddress,
        uint256 mintPrice,
        address creator,
        bytes32 wlRoot,
        uint256[] memory params,
        address[] memory authContracts
        ) public onlyOwner {

        _addTokenInfo(tokenAddress, name, _toLower(symbol), totalSupply, maxMintCount, maxMintPerAddress, mintPrice, creator, wlRoot, params, authContracts);
    }

    /* 
        new search tokens
        tokenType_: 
            0 - ALL;
            1 - IN PROGRESS;
            2 - END.
    */
    function getTokensByPage(uint256 pageNo_, uint256 pageSize_, uint256 tokenType_, string memory tokenName_) external view 
        returns (uint256 allItems_, uint256 totalPages_, uint256 cnt_, TokenInfo[] memory recs_) {

        require(pageNo_ > 0, "Invalid pageNo number");
        require(pageSize_ > 0, "Invalid pageNo size");

        // query by specified token name
        //
        if (bytes(tokenName_).length > 0) {
            (cnt_, recs_) = _queryTokenByName(tokenName_);
            allItems_ = cnt_;
            totalPages_ = cnt_;
            return (allItems_, totalPages_, cnt_, recs_);
        }

        // step 1 search ids by conditions...
        //
        FoundTokenItem[] memory idsFound_ = new FoundTokenItem[](tokensCount);
        for (uint i = 0; i < tokensCount; i++) {
            BlackErc20 blackErc20_ = BlackErc20(tokens[i].tokenAddress);
            uint256 mintedCount_ = blackErc20_.getMintedCounts();
            uint256 tokenProgress_ = mintedCount_ * 100 / tokens[i].maxMintCount;
            if (tokenType_ == 0 || tokenType_ == 1 && tokenProgress_ < 100 || tokenType_ == 2 && tokenProgress_ == 100) {
                idsFound_[allItems_++] = FoundTokenItem(uint128(i), uint128(tokenProgress_));
            }
        }

        // step 2 filling data by search result...
        if ( allItems_ == 0 ) {
            return (allItems_, totalPages_, cnt_, recs_);
        }

        // total pages
        totalPages_ = allItems_ / pageSize_;
        if ( allItems_ % pageSize_ != 0 ) totalPages_ += 1;
        if ( totalPages_ == 0 ) totalPages_ = 1;
        if ( pageNo_ > totalPages_ ) {
            pageNo_ = totalPages_;
        }

        // items for specified the pageNo
        if ( pageNo_ < totalPages_ ) {
            cnt_ = pageSize_;
        } else {
            cnt_ = allItems_ % pageSize_;
            if ( cnt_ == 0 ) {
                cnt_ = pageSize_;
            }
        }

        // filling data...
        //
        recs_ = new TokenInfo[](cnt_);
        uint cur_ = pageNo_ > 1 ? (pageNo_-1) * pageSize_ : 0;

        for (uint i = 0; i < cnt_; i++) {

            uint j = idsFound_[cur_].i;
            address addr_ = tokens[j].tokenAddress;
            string memory logo_;
            Profile storage p_ = tokenProfiles[addr_];

            if (keccak256(bytes(p_.msg.logoUrl)) != keccak256("")){
                logo_ = p_.msg.logoUrl;
            } else {
                logo_ = defaultLogo;
            }

            recs_[i].tokenAddress = tokens[j].tokenAddress;
            recs_[i].logo = logo_;
            recs_[i].name = tokens[j].name;
            recs_[i].symbol = tokens[j].symbol;
            recs_[i].totalSupply = tokens[j].totalSupply;
            recs_[i].maxMintCount = tokens[j].maxMintCount;
            recs_[i].maxMintPerAddress = tokens[j].maxMintPerAddress;
            recs_[i].mintPrice = tokens[j].mintPrice;
            recs_[i].creator = tokens[j].creator;
            recs_[i].progress = idsFound_[cur_].progress;

            _setConditionDataByMem(recs_[i], addr_);
            cur_ += 1;
        }
    }

    // query by specified token name
    function _queryTokenByName(string memory tokenName_) private view returns (uint256 cnt_, TokenInfo[] memory recs_) {

        address token_ = tokenNames[tokenName_];

        if (token_ != address(0)) {

            cnt_ = 1;
            recs_ = new TokenInfo[](cnt_);
            
            Profile storage p_ = tokenProfiles[token_];
            if (p_.idx == 0) { // not found
                return (cnt_, recs_);
            }

            uint j = p_.idx - 1;
            BlackErc20 blackErc20_ = BlackErc20(token_);
            uint mintedCount_ = blackErc20_.getMintedCounts();
            recs_[0].progress = mintedCount_ * 100 / tokens[j].maxMintCount;
            
            if (keccak256(bytes(p_.msg.logoUrl)) != keccak256("")) {
                recs_[0].logo = p_.msg.logoUrl;
            } else {
                recs_[0].logo = defaultLogo;
            }

            recs_[0].tokenAddress = tokens[j].tokenAddress;
            recs_[0].name = tokens[j].name;
            recs_[0].symbol = tokens[j].symbol;
            recs_[0].totalSupply = tokens[j].totalSupply;
            recs_[0].maxMintCount = tokens[j].maxMintCount;
            recs_[0].maxMintPerAddress = tokens[j].maxMintPerAddress;
            recs_[0].mintPrice = tokens[j].mintPrice;
            recs_[0].creator = tokens[j].creator;

            _setConditionDataByMem(recs_[0], token_);
        }
    }

    function getTokenBase(address tokenAddress) external view returns (TokenInfo memory tokenInfo,TokenMsg memory tokenMsg) {
        Profile storage p_ = tokenProfiles[tokenAddress];
        uint256 id = p_.idx - 1;
        tokenMsg = p_.msg;
        tokenInfo = tokens[id];
    }

    function getTokenDetail(address tokenAddress) external view returns (TokenMsg memory tokenMsg, address[] memory tokenAuthContract, uint256[] memory tokenParam1) {
        Profile storage p_ = tokenProfiles[tokenAddress];
        tokenMsg = p_.msg;
        if ( p_.authContractsCount > 0 ) {
            tokenAuthContract = new address[](p_.authContractsCount);
            for (uint i = 0; i < p_.authContractsCount; ++i) {
                tokenAuthContract[i] = p_.authContracts[i];
            }
        }
        if ( p_.paramsCount > 0 ) {
            tokenParam1 = new uint256[](p_.paramsCount);
            for (uint i = 0; i < p_.paramsCount; ++i) {
                tokenParam1[i] = p_.params[i];
            }
        }
    }

    function editTokenMsg(   
        address tokenAddress,     
        string memory description,
        string memory logoUrl,
        string memory bannerUrl,
        string memory website,
        string memory twitter,
        string memory telegram,
        string memory discord,
        string memory detailUrl
    ) external payable {
        require(msg.value >= payPrice, "illegal price");
        Profile storage p_ = tokenProfiles[tokenAddress];
        require(p_.idx > 0, "Invalid Token Address");

        TokenInfo storage tokenInfo = tokens[p_.idx-1];
        require(tokenInfo.creator == msg.sender,"not permission");

        require(bytes(description).length <= maxTextLength, "Invalid description length");
        require(bytes(logoUrl).length <= maxUrlLength, "Invalid logoUrl length");
        require(bytes(bannerUrl).length <= maxUrlLength, "Invalid bannerUrl length");
        require(bytes(website).length <= maxUrlLength, "Invalid website length");
        require(bytes(twitter).length <= maxUrlLength, "Invalid twitter length");
        require(bytes(telegram).length <= maxUrlLength, "Invalid telegram length");
        require(bytes(discord).length <= maxUrlLength, "Invalid discord length");
        require(bytes(detailUrl).length <= maxUrlLength, "Invalid detailUrl length");
        

        TokenMsg storage tokenMsg = p_.msg;

        tokenMsg.description = description;
        tokenMsg.logoUrl = logoUrl;
        tokenMsg.bannerUrl = bannerUrl;
        tokenMsg.website = website;
        tokenMsg.twitter = twitter;
        tokenMsg.telegram = telegram;
        tokenMsg.discord = discord;
        tokenMsg.detailUrl = detailUrl;
    }

    function _addTokenInfo(address tokenAddress,
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxMintCount,
            uint256 maxMintPerAddress,
            uint256 mintPrice,
            address creator,
            bytes32 wlRoot,
            uint256[] memory params,
            address[] memory authContracts
        ) private {

        Profile storage p_ = tokenProfiles[tokenAddress];

        tokenNames[symbol] = tokenAddress;

        p_.wlRoot = wlRoot;

        p_.paramsCount = params.length;
        for (uint i = 0; i < params.length; ++i) {
            p_.params[i] = params[i];
        }

        p_.authContractsCount = authContracts.length;
        for (uint i = 0; i < authContracts.length; ++i) {
            p_.authContracts[i] = authContracts[i];
        }

        TokenInfo storage newToken = tokens[tokensCount];

        newToken.tokenAddress = tokenAddress;
        newToken.logo = defaultLogo;
        newToken.name = name;
        newToken.symbol = symbol;
        newToken.totalSupply = totalSupply;
        newToken.maxMintCount = maxMintCount;
        newToken.maxMintPerAddress = maxMintPerAddress;
        newToken.mintPrice = mintPrice;
        newToken.creator = creator;

        _setConditionDataByStorage(newToken, tokenAddress);
        tokensCount += 1;

        p_.idx = tokensCount;
    }

    function isNameValid(string memory name) public view returns (bool) {
        string memory lowerCaseName = _toLower(name);
        bytes memory lowerCaseBytes = bytes(lowerCaseName);
        for (uint256 i = 0; i < lowerCaseBytes.length; i++) {
            if (
                uint8(lowerCaseBytes[i]) >= uint8(bytes1("A")) &&
                uint8(lowerCaseBytes[i]) <= uint8(bytes1("Z"))
            ) {
                return false;
            }
        }
        for (uint256 j = 0; j < forbiddenNames.length; j++) {
            string memory forbiddenName = forbiddenNames[j];
            if (keccak256(bytes(lowerCaseName)) == keccak256(bytes(forbiddenName))) {
                return false;
            }
        }
        return true;
    }

    function _toLower(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            // 将大写字母转换为小写字母
            if (uint8(strBytes[i]) >= uint8(bytes1("A")) && uint8(strBytes[i]) <= uint8(bytes1("Z"))) {
                strBytes[i] = bytes1(uint8(strBytes[i]) + 32);
            }
        }
        return string(strBytes);
    }

    // new set condition data
    function _setConditionDataByStorage(TokenInfo storage token_, address addr_) private {
        Profile storage p_ = tokenProfiles[addr_];
        for ( uint i = 0; i < 3; ++i ) {
            token_.limits[i] = (p_.authContracts[i] != address(0) ? 1 : 0);
        }
        if (p_.paramsCount >= 3) {
            token_.limits[3] = (p_.params[2] > 0 ? 1 : 0);
        } else {
            token_.limits[3] = 0;
        }
    }

    function _setConditionDataByMem(TokenInfo memory token_, address addr_) private view {
        Profile storage p_ = tokenProfiles[addr_];

        // authContracts
        for ( uint i = 0; i < 3; ++i ) {
            token_.limits[i] = (p_.authContracts[i] != address(0) ? 1 : 0);
        }

        // params
        if (p_.paramsCount >= 3) {
            token_.limits[3] = (p_.params[2] > 0 ? 1 : 0);
        } else {
            token_.limits[3] = 0;
        }
    }

    function addForbiddenName(string memory name) private  onlyOwner{
        string memory lowerCaseName = _toLower(name);
        forbiddenNames.push(lowerCaseName);
    }

    function removeForbiddenName(string memory name) public onlyOwner {
        string memory lowerCaseName = _toLower(name);
        for (uint256 i = 0; i < forbiddenNames.length; i++) {
            if (keccak256(bytes(forbiddenNames[i])) == keccak256(bytes(lowerCaseName))) {
                forbiddenNames[i] = forbiddenNames[forbiddenNames.length - 1];
                forbiddenNames.pop();
                break;
            }
        }
    }

    function setUrlLength(uint256 urlLength) external onlyOwner{
        maxUrlLength = urlLength;
    }

    function setTextLength(uint256 textLength) external onlyOwner{
        maxTextLength = textLength;
    }

    function setAuthorizedAddress(address _address) external onlyOwner{
        authorizedAddress = _address;
    }

    function setDefaultLogo(string memory logo) external onlyOwner{
        defaultLogo = logo;
    }

    function setDevAddress(address dev) external onlyOwner {
        devAddress = dev;
    }

    function devAward() external  onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no ETH balance.");
        address payable sender = payable(devAddress);
        sender.transfer(balance);
    }

    function setPayPrice(uint256 _payPrice) external  onlyOwner{
        payPrice = _payPrice;
    }

    
}