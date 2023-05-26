// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./StringUpper.sol";
import "./INameTagV1.sol";
import "./IExternalAllowedContract.sol";


contract NameTag is ERC721Enumerable, Ownable, StringUpper, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => bool) allowList;
    mapping(address => uint256) public allowListPurchasedAmount;
    uint256 public allowListPrice;
    uint256 public allowListLimit;

    event AddedToAllowList(address indexed _address);
    event RemovedFromAllowList(address indexed _address, uint256 _purchasedAmount);


    EnumerableSet.AddressSet private _allowContractList;

    struct AllowContractParams {
        uint256 price;
        uint8 limit;
        uint256 minBalance;
        uint256 purchasedAmount;
        mapping(address => uint8) purchasedAmountByAddress;
    }

    mapping(address => AllowContractParams[]) public allowContractListParams;

    event AddedToAllowContractList(address indexed _address, uint256 indexed _price, uint8 _limit, uint256 _minBalance);
    event RemovedFromAllowContractList(address indexed _address, uint256 _purchasedAmount);
    event PresaleContractPurchase(address indexed _contract, address indexed _address, uint256 _purchasedAmount);

    uint16 public addToAllowListLimit;
    uint16 public removeFromAllowListLimit;


    mapping (string => bool) denyList;

    event AddedDenyList(string _word);
    event RemovedDenyList(string _word);


    bool public presaleActive;
    uint256 public presaleDuration;
    uint256 public presaleStartTime;

    event PresaleStart(uint256 indexed _presaleDuration, uint256 indexed _presaleStartTime);
    event PresalePaused(uint256 indexed _timeElapsed, uint256 indexed _totalSupply);

    bool public saleActive;
    uint8 public saleTransactionLimit;
    uint256 public salePrice;
    uint256 public saleSupply;
    uint256 public saleLimit;

    event SaleStart(uint256 indexed _saleStartTime, uint256 indexed _salePrice, uint8 _saleTransactionLimit);
    event SalePaused(uint256 indexed _salePauseTime, uint256 indexed _totalSupply);
    event SaleLimitUpdated(uint256 indexed _limitStartTime, uint256 indexed _saleLimit);

    modifier whenPresaleActive() {
        require(presaleActive, "NT: Presale is not active");
        _;
    }

    modifier whenPresalePaused() {
        require(!presaleActive, "NT: Presale is not paused");
        _;
    }

    modifier whenSaleActive() {
        require(saleActive, "NT: Sale is not active");
        _;
    }

    modifier whenSalePaused() {
        require(!saleActive, "NT: Sale is not paused");
        _;
    }

    modifier whenAnySaleActive() {
        require(presaleActive || saleActive, "NT: Any sale is terminated");
        _;
    }


    mapping(uint256 => string) tokenNames;
    mapping(string => uint256) names;

    event NameChanged(uint256 indexed tokenId, string from, string to);

    string private _baseTokenURI;

    INameTagV1 immutable _token;
    bool public validateNameTagV1;

    constructor(
        string memory name_, string memory symbol_, string memory baseURI_,
        uint256 allowListPrice_, uint256 allowListLimit_,
        uint16 addToAllowListLimit_, uint16 removeFromAllowListLimit_,
        INameTagV1 token_, bool validateNameTagV1_
    ) ERC721(name_, symbol_)  {
        _baseTokenURI = baseURI_;
        allowListPrice = allowListPrice_;
        allowListLimit = allowListLimit_;

        addToAllowListLimit = addToAllowListLimit_;
        removeFromAllowListLimit = removeFromAllowListLimit_;

        _token = token_;
        validateNameTagV1 = validateNameTagV1_;
    }

    function token() external view returns(address) {
        return address(_token);
    }

    function setValidateNameTagV1(bool validateNameTagV1_) external onlyOwner {
        validateNameTagV1 = validateNameTagV1_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setAddToAllowListLimit(uint16 addToAllowListLimit_) external onlyOwner {
        addToAllowListLimit = addToAllowListLimit_;
    }

    function setRemoveFromAllowListLimit(uint16 removeFromAllowListLimit_) external onlyOwner {
        removeFromAllowListLimit = removeFromAllowListLimit_;
    }

    function setAllowListLimit(uint256 limit_) external onlyOwner {
        allowListLimit = limit_;
    }

    function setAllowListPrice(uint256 price_) external onlyOwner {
        allowListPrice = price_;
    }

    function addToAllowList(address[] memory addresses) external onlyOwner {
        require(addresses.length <= addToAllowListLimit, "NT: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (allowList[addresses[index]]) {
                emit RemovedFromAllowList(addresses[index], allowListPurchasedAmount[addresses[index]]);
                allowListPurchasedAmount[addresses[index]] = 0;
            } else {
                allowList[addresses[index]] = true;
            }
            emit AddedToAllowList(addresses[index]);
        }
    }

    function removeFromAllowList(address[] memory addresses) external onlyOwner {
        require(addresses.length <= removeFromAllowListLimit, "NT: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (allowList[addresses[index]]) {
                allowList[addresses[index]] = false;
                emit RemovedFromAllowList(addresses[index], allowListPurchasedAmount[addresses[index]]);
                delete allowListPurchasedAmount[addresses[index]];
            }
        }
    }

    function inAllowList(address value) public view returns (bool) {
        return allowList[value];
    }

    function checkContract(address _contract) external view returns (bool) {
        return IExternalAllowedContract(_contract).balanceOf(owner()) >= 0;
    }

    function addToAllowContractList(
        address[] memory addresses, uint256[] memory prices, uint8[] memory limits, uint256[] memory balances
    ) external onlyOwner {
        uint256 length = addresses.length;
        require(length <= addToAllowListLimit, "NT: List of addresses is too large");
        require(length == prices.length && length == limits.length && length == balances.length, "NT: All lists should be the same length");
        for(uint index = 0; index < length; index += 1) {
            require(IExternalAllowedContract(addresses[index]).balanceOf(msg.sender) >= 0, "NT: Cannot call balanceOf method on the external contract");

            _allowContractList.add(addresses[index]);

            AllowContractParams storage params = allowContractListParams[addresses[index]].push();
            params.price = prices[index];
            params.limit = limits[index];
            params.minBalance = balances[index];

            emit AddedToAllowContractList(addresses[index], prices[index], limits[index], balances[index]);
        }
    }

    function removeFromAllowContractList(address[] memory addresses) external onlyOwner {
        require(addresses.length <= removeFromAllowListLimit, "NT: List of addresses is too large");
        for(uint index = 0; index < addresses.length; index += 1) {
            if (_allowContractList.remove(addresses[index])) {
                uint version = _contractParamsVersion(addresses[index]) - 1;
                emit RemovedFromAllowContractList(addresses[index], allowContractListParams[addresses[index]][version].purchasedAmount);
            }
        }
    }

    function inAllowContractList(address value) public view returns (bool) {
        return _allowContractList.contains(value);
    }

    function allowContractListLength() external view returns (uint256) {
        return _allowContractList.length();
    }

    function allowContractAddressByIndex(uint256 index) external view returns (address) {
        require(index < _allowContractList.length(), "NT: Index out of bounds");
        return _allowContractList.at(index);
    }

    function _contractParamsVersion(address _contract) internal view returns(uint) {
        return allowContractListParams[_contract].length;
    }

    function contractParamsVersion(address _contract) external view returns(uint) {
        require(inAllowContractList(_contract), "NT: Contract address is not in the allowed list");
        return _contractParamsVersion(_contract);
    }

    function allowContractParams(address _contract) external view returns (uint256, uint8, uint256, uint256) {
        require(inAllowContractList(_contract), "NT: Contract address is not in the allowed list");

        uint version = _contractParamsVersion(_contract) - 1;
        return (
            allowContractListParams[_contract][version].price,
            allowContractListParams[_contract][version].limit,
            allowContractListParams[_contract][version].minBalance,
            allowContractListParams[_contract][version].purchasedAmount
        );
    }

    function contractPurchasedAmountByAddress(address _contract, address owner) external view returns(uint8) {
        require(inAllowContractList(_contract), "NT: Contract address is not in the allowed list");
        return allowContractListParams[_contract][_contractParamsVersion(_contract) - 1].purchasedAmountByAddress[owner];
    }

    function addDenyList(string[] memory _words) external onlyOwner {
        for(uint index = 0; index < _words.length; index+=1) {
            denyList[upper(_words[index])] = true;
            emit AddedDenyList(_words[index]);
        }
    }

    function removeDenyList(string[] memory _words) external onlyOwner {
        for(uint index = 0; index < _words.length; index+=1) {
            denyList[upper(_words[index])] = false;
            emit RemovedDenyList(_words[index]);
        }
    }

    function inDenyList(string memory _word) external view returns (bool) {
        return bool(denyList[upper(_word)]);
    }

    function startPresale(uint256 presaleDuration_) external onlyOwner whenPresalePaused {
        presaleStartTime = block.timestamp;
        presaleDuration = presaleDuration_;
        presaleActive = true;
        emit PresaleStart(presaleDuration, presaleStartTime);
    }

    function pausePresale() external onlyOwner whenPresaleActive {
        presaleActive = false;
        emit PresalePaused(_elapsedPresaleTime(), totalSupply());
    }

    function _setSaleLimit(uint256 saleLimit_) internal {
        saleSupply = 0;
        saleLimit = saleLimit_;
        emit SaleLimitUpdated(block.timestamp, saleLimit);
    }

    function setSaleLimit(uint256 saleLimit_)  external onlyOwner  {
        _setSaleLimit(saleLimit_);
    }

    function startPublicSale(
        uint256 salePrice_, uint8 saleTransactionLimit_, uint256 saleLimit_
    ) external onlyOwner whenSalePaused {
        salePrice = salePrice_;
        saleTransactionLimit = saleTransactionLimit_;

        _setSaleLimit(saleLimit_);

        saleActive = true;
        emit SaleStart(block.timestamp, salePrice, saleTransactionLimit);
    }

    function pausePublicSale() external onlyOwner whenSaleActive {
        saleActive = false;
        emit SalePaused(totalSupply(), block.timestamp);
    }

    function _elapsedPresaleTime() internal view returns (uint256) {
        return presaleStartTime > 0 ? block.timestamp - presaleStartTime : 0;
    }

    function _remainingPresaleTime() internal view returns (uint256) {
        if (presaleStartTime == 0 || _elapsedPresaleTime() >= presaleDuration) {
            return 0;
        }

        return (presaleStartTime + presaleDuration) - block.timestamp;
    }

    function remainingPresaleTime() external view whenPresaleActive returns (uint256) {
        require(presaleStartTime > 0, "NT: Presale hasn't started yet");
        return _remainingPresaleTime();
    }

    function _preValidatePurchase(uint256 tokensAmount) internal view returns(bool) {
        require(msg.sender != address(0));
        require(tokensAmount > 0, "NT: Must mint at least one token");
        if (
            presaleActive && _remainingPresaleTime() > 0 && inAllowList(msg.sender)
            && tokensAmount + allowListPurchasedAmount[msg.sender] <= allowListLimit
        ) {
            require(allowListPrice * tokensAmount <= msg.value, "NT: Presale, insufficient funds");
            return true;
        }

        require(saleActive, "NT: Sale is not active");
        if (saleLimit > 0) {
            // Sale is unlimited if saleLimit == 0
            require(tokensAmount + saleSupply <= saleLimit, "NT: Limited amount of tokens");
        }
        require(tokensAmount <= saleTransactionLimit, "NT: Limited amount of tokens in transaction");
        require(salePrice * tokensAmount <= msg.value, "NT: Insufficient funds");
        return false;
    }

    function _processPurchaseToken(address recipient) internal returns (uint256) {
        uint256 newItemId = totalSupply() + 1;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function _buyTokens(string[] memory _names) internal returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](_names.length);

        for (uint index = 0; index < _names.length; index += 1) {
            tokens[index] = _processPurchaseToken(msg.sender);
            require(_setName(tokens[index], _names[index]), "NT: Name cannot be assigned");
        }

        return tokens;
    }

    function buyTokens(string[] memory _names) external payable whenAnySaleActive nonReentrant returns (uint256[] memory) {
        bool usePresale = _preValidatePurchase(_names.length);

        if (usePresale) {
            allowListPurchasedAmount[msg.sender] += _names.length;
        } else {
            saleSupply += _names.length;
        }

        return _buyTokens(_names);
    }

    function buyTokensByContract(string[] memory _names, address _contract) external payable whenPresaleActive nonReentrant returns (uint256[] memory) {
        require(msg.sender != address(0));
        require(_names.length > 0, "NT: Must mint at least one token");
        require(_remainingPresaleTime() > 0, "NT: Presale time out");
        require(inAllowContractList(_contract), "NT: Contract address is not in the allowed list");

        uint version = _contractParamsVersion(_contract) - 1;
        require(
            IExternalAllowedContract(_contract).balanceOf(msg.sender) >= allowContractListParams[_contract][version].minBalance,
            "NT: Sender balance on the contract less than min balance"
        );

        uint8 purchasedAmount = allowContractListParams[_contract][version].purchasedAmountByAddress[msg.sender];
        require(_names.length + purchasedAmount <= allowContractListParams[_contract][version].limit, "NT: Presale contract limit exceeded");
        require(allowContractListParams[_contract][version].price * _names.length <= msg.value, "NT: Presale, insufficient funds");

        allowContractListParams[_contract][version].purchasedAmountByAddress[msg.sender] += uint8(_names.length);
        allowContractListParams[_contract][version].purchasedAmount += _names.length;

        emit PresaleContractPurchase(_contract, msg.sender, _names.length);

        return _buyTokens(_names);
    }

    function withdraw(address payable wallet, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);
        wallet.transfer(amount);
    }

    function validate(string memory name) internal pure returns (bool, string memory) {
        bytes memory b = bytes(name);
        if (b.length == 0) return (false, '');
        if (b.length > 36) return (false, '');

        bytes memory bUpperName = new bytes(b.length);

        for (uint8 i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            ) {
                return (false, '');
            }
            bUpperName[i] = _upper(char);
        }

        return (true, string(bUpperName));
    }

    function getByName(string memory name) public view virtual returns (uint256) {
        return names[upper(name)];
    }

    function getTokenName(uint256 tokenId) public view virtual returns (string memory) {
        return tokenNames[tokenId];
    }

    function _setName(uint256 tokenId, string memory name_) internal virtual returns(bool){
        bool status;
        string memory upperName;
        (status, upperName) = validate(name_);
        if (status == false || names[upperName] != 0 || denyList[upperName]) {
            return false;
        }
        if (validateNameTagV1) {
            require(_token.getByName(upperName) == 0, "NT: Exist name in version 1");
        }

        string memory oldName = getTokenName(tokenId);
        string memory oldUpperName = upper(oldName);
        names[oldUpperName] = 0;
        tokenNames[tokenId] = name_;
        names[upperName] = tokenId;

        emit NameChanged(tokenId, oldName, name_);
        return true;
    }

    function renounceOwnership() public override onlyOwner {
        revert('NT: Cannot renounce ownership');
    }
}