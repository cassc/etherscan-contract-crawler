// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./F24.sol";
import "./Fiat24PriceList.sol";
import "./interfaces/IF24.sol";
import "./libraries/DigitsOfUint.sol";

contract Fiat24Account is ERC721EnumerableUpgradeable, ERC721PausableUpgradeable, AccessControlUpgradeable {
    using DigitsOfUint for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant LIMITUPDATER_ROLE = keccak256("LIMITUPDATER_ROLE");
    uint256 private constant DEFAULT_MERCHANT_RATE = 55;

    enum Status { Na, SoftBlocked, Tourist, Blocked, Closed, Live }

    struct WalletProvider {
        string walletProvider;
        bool isAvailable;
    }

    uint8 private constant MERCHANTDIGIT = 8;
    uint8 private constant INTERNALDIGIT = 9;

    struct Limit {
        uint256 usedLimit;
        uint256 clientLimit;
        uint256 startLimitDate;
    }

    uint256 public constant LIMITLIVEDEFAULT = 10000000;
    uint256 public limitTourist;

    uint256 public constant THIRTYDAYS = 2592000;

    mapping (address => uint256) public historicOwnership;
    mapping (uint256 => string) public nickNames;
    mapping (uint256 => bool) public isMerchant;
    mapping (uint256 => uint256) public merchantRate;
    mapping (uint256 => Status) public status;
    mapping (uint256 => Limit) public limit;

    uint8 public minDigitForSale;
    uint8 public maxDigitForSale;

    F24 f24;
    Fiat24PriceList fiat24PriceList;
    bool f24IsActive;

    mapping (uint256 => uint256) public walletProvider;
    mapping (uint256 => WalletProvider) public walletProviderMap;

    function initialize() public initializer {
        __Context_init_unchained();
        __ERC721_init_unchained("Fiat24 Account", "Fiat24");
        __AccessControl_init_unchained();
        minDigitForSale = 5;
        maxDigitForSale = 5;
        f24IsActive = false;
        limitTourist = 100000;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function mint(address _to, uint256 _tokenId, bool _isMerchant, uint256 _merchantRate) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        require(_mintAllowed(_to, _tokenId), "Fiat24Account: mint not allowed");
        _mint(_to, _tokenId);
        status[_tokenId] = Status.Tourist;
        initilizeTouristLimit(_tokenId);
        isMerchant[_tokenId] = _isMerchant;
        if(_isMerchant) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", StringsUpgradeable.toString(_tokenId)));
            if(_merchantRate == 0) {
                merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
            } else {
                merchantRate[_tokenId] = _merchantRate;
            }
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", StringsUpgradeable.toString(_tokenId)));
        }
    }

    function mintByClient(uint256 _tokenId, uint256 _walletProvider) external {
        uint256 numDigits = _tokenId.numDigits();
        require(numDigits <= maxDigitForSale, "Fiat24Account: Number of digits of accountId > max. digits");
        require(numDigits >= minDigitForSale, "Fiat24Account: Premium accountId cannot be mint by client");
        require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "Fiat24Account: Internal accountId cannot be mint by client");
        require(_mintAllowed(_msgSender(), _tokenId),
        "Fiat24Account: Not allowed. The target address has an account or once had another account.");
        bool merchantAccountId = _tokenId.hasFirstDigit(MERCHANTDIGIT);
        _mint(_msgSender(), _tokenId);
        status[_tokenId] = Status.Tourist;
        walletProvider[_tokenId] = walletProviderMap[_walletProvider].isAvailable ? _walletProvider : 0;
        initilizeTouristLimit(_tokenId);
        isMerchant[_tokenId] = merchantAccountId;
        if(merchantAccountId) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", StringsUpgradeable.toString(_tokenId)));
            merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", StringsUpgradeable.toString(_tokenId)));
        }
    }

    function mintByClientWithF24(uint256 _tokenId, uint256 _walletProvider) external {
        require(f24IsActive, "Fiat24Account: This function is inactive");
        uint256 numDigits = _tokenId.numDigits();
        require(numDigits <= maxDigitForSale, "Fiat24Account: AccountId not available for sale. Use mintByClient()");
        require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "Fiat24Account: Internal accountId cannot be mint by client");
        require(_mintAllowed(_msgSender(), _tokenId),
        "Fiat24Account: Not allowed. The target address has an account or once had another account.");
        uint256 accountPrice = fiat24PriceList.getPrice(_tokenId);
        require(accountPrice != 0, "Fiat24Account: AccountId not available for sale");
        require(f24.allowance(_msgSender(), address(this)) >= accountPrice, "Fiat24Account: Not enough allowance for mintByClientWithF24");
        bool merchantAccountId = _tokenId.hasFirstDigit(MERCHANTDIGIT);
        f24.burnFrom(_msgSender(), accountPrice);
        _mint(_msgSender(), _tokenId);
        status[_tokenId] = Status.Tourist;
        walletProvider[_tokenId] = walletProviderMap[_walletProvider].isAvailable ? _walletProvider : 0;
        initilizeTouristLimit(_tokenId);
        isMerchant[_tokenId] = merchantAccountId;
        if(merchantAccountId) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", StringsUpgradeable.toString(_tokenId)));
            merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", StringsUpgradeable.toString(_tokenId)));
        }
    }

    function mintByClientWithF24WithPermit(uint256 _tokenId, uint256 _walletProvider, bytes memory sig, uint256 deadline) external {
        require(f24IsActive, "Fiat24Account: This function is inactive");
        uint256 numDigits = _tokenId.numDigits();
        require(numDigits <= maxDigitForSale, "Fiat24Account: AccountId not available for sale. Use mintByClient()");
        require(!_tokenId.hasFirstDigit(INTERNALDIGIT), "Fiat24Account: Internal accountId cannot be mint by client");
        require(_mintAllowed(_msgSender(), _tokenId),
        "Fiat24Account: Not allowed. The target address has an account or once had another account.");
        uint256 accountPrice = fiat24PriceList.getPrice(_tokenId);
        require(accountPrice != 0, "Fiat24Account: AccountId not available for sale");
        bool merchantAccountId = _tokenId.hasFirstDigit(MERCHANTDIGIT);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        f24.permit(msg.sender, address(this), accountPrice, deadline, v, r, s);

        f24.burnFrom(_msgSender(), accountPrice);
        _mint(_msgSender(), _tokenId);
        status[_tokenId] = Status.Tourist;
        walletProvider[_tokenId] = walletProviderMap[_walletProvider].isAvailable ? _walletProvider : 0;
        initilizeTouristLimit(_tokenId);
        isMerchant[_tokenId] = merchantAccountId;
        if(merchantAccountId) {
            nickNames[_tokenId] = string(abi.encodePacked("Merchant ", StringsUpgradeable.toString(_tokenId)));
            merchantRate[_tokenId] = DEFAULT_MERCHANT_RATE;
        } else {
            nickNames[_tokenId] = string(abi.encodePacked("Tourist ", StringsUpgradeable.toString(_tokenId)));
        }
    }

    function burn(uint256 tokenId) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        delete limit[tokenId];
        _burn(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        super.transferFrom(from, to, tokenId);
        if(status[tokenId] != Status.Tourist) {
            historicOwnership[to] = tokenId;
        }
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function removeHistoricOwnership(address owner) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        delete historicOwnership[owner];
    }

    function changeClientStatus(uint256 tokenId, Status _status) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        if(_status == Status.Live && status[tokenId] == Status.Tourist) {
            historicOwnership[this.ownerOf(tokenId)] = tokenId;
            initializeLiveLimit(tokenId);
            if(!this.isMerchant(tokenId)) {
                nickNames[tokenId] = string(abi.encodePacked("Account ", StringsUpgradeable.toString(tokenId)));
            }
        }
        status[tokenId] = _status;
    }

    function setMinDigitForSale(uint8 minDigit) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        minDigitForSale = minDigit;
    }

    function setMaxDigitForSale(uint8 maxDigit) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        maxDigitForSale = maxDigit;
    }

    function setMerchantRate(uint256 tokenId, uint256 _merchantRate) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        merchantRate[tokenId] = _merchantRate;
    }
    
    function initilizeTouristLimit(uint256 tokenId) private {
        Limit storage limit_ = limit[tokenId];
        limit_.usedLimit = 0;
        limit_.startLimitDate = block.timestamp;
    }

    function initializeLiveLimit(uint256 tokenId) private {
        Limit storage limit_ = limit[tokenId];
        limit_.usedLimit = 0;
        limit_.clientLimit = LIMITLIVEDEFAULT;
        limit_.startLimitDate = block.timestamp;
    }

    function setClientLimit(uint256 tokenId, uint256 clientLimit) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        require(_exists(tokenId), "Fiat24Account: Token does not exist");
        require(status[tokenId] != Status.Tourist && status[tokenId] != Status.Na, "Fiat24Account: Not in correct status for limit control");
        Limit storage limit_ = limit[tokenId];
        limit_.clientLimit = clientLimit;
    }

    function resetUsedLimit(uint256 tokenId) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        require(_exists(tokenId), "Fiat24Account: Token does not exist");
        Limit storage limit_ = limit[tokenId];
        limit_.usedLimit = 0;
    }

    function setTouristLimit(uint256 newLimitTourist) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        limitTourist = newLimitTourist;
    }

    function checkLimit(uint256 tokenId, uint256 amount) external view returns(bool) {
        if(_exists(tokenId)) {
            Limit storage limit_ = limit[tokenId];
            uint256 lastLimitPeriodEnd = limit_.startLimitDate + THIRTYDAYS;
            if(status[tokenId] == Status.Tourist) {
                return (lastLimitPeriodEnd < block.timestamp && amount <= limitTourist)
                    || (lastLimitPeriodEnd >= block.timestamp && (limit_.usedLimit + amount) <= limitTourist);
            } else {
                return (lastLimitPeriodEnd < block.timestamp && amount <= limit_.clientLimit)
                    || (lastLimitPeriodEnd >= block.timestamp && (limit_.usedLimit + amount) <= limit_.clientLimit);
            }
        } else {
            return false;
        }
    }

    function updateLimit(uint256 tokenId, uint256 amount) external {
        require(hasRole(LIMITUPDATER_ROLE, msg.sender), "Fiat24Account: Not a limit-updater");
        if(status[tokenId] == Status.Live || status[tokenId] == Status.Tourist) {
            Limit storage limit_ = limit[tokenId];
            uint256 lastLimitPeriodEnd = limit_.startLimitDate + THIRTYDAYS;
            if(lastLimitPeriodEnd < block.timestamp) {
                limit_.startLimitDate = block.timestamp;
                limit_.usedLimit = amount;
            } else {
                limit_.usedLimit += amount;
            }
        }
    }

    function setNickname(uint256 tokenId, string memory nickname) public {
        require(_msgSender() == this.ownerOf(tokenId), "Fiat24Account: Not account owner");
        nickNames[tokenId] = nickname;
    }

    function activateF24(address f24Address, address fiat24PriceListAddress) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        f24 = F24(f24Address);
        fiat24PriceList = Fiat24PriceList(fiat24PriceListAddress);
        f24IsActive = true;
    }

    function addWalletProvider(uint256 number, string memory name) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        walletProviderMap[number].walletProvider = name;
        walletProviderMap[number].isAvailable = true;
    }

    function removeWalletProvider(uint256 number) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Fiat24Account: Not an operator");
        delete walletProviderMap[number];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory uriStatusParam = _uriStatusParam();
        string memory uriWalletParam = _uriWalletParam();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenId), uriStatusParam, StringsUpgradeable.toString(uint256(status[tokenId])), uriWalletParam, StringsUpgradeable.toString(walletProvider[tokenId])))
        : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return 'https://api.defi.saphirstein.com/metadata?tokenid=';
    }

    function _uriStatusParam() internal pure returns (string memory) {
        return '&status=';
    }

    function _uriWalletParam() internal pure returns (string memory) {
        return '&wallet=';
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Fiat24Account: Not an admin");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Fiat24Account: Not an admin");
        _unpause();
    }

    function _mintAllowed(address to, uint256 tokenId) internal view returns(bool){
        return (this.balanceOf(to) < 1 && (historicOwnership[to] == 0 || historicOwnership[to] == tokenId));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        require(!paused(), "Fiat24Account: Account transfers suspended");
        if(AddressUpgradeable.isContract(to) && (from != address(0))) {
            require(this.status(tokenId) == Status.Tourist, "Fiat24Account: Not allowed to transfer account");
        } else {
            if(from != address(0) && to != address(0)) {
                require(balanceOf(to) < 1 && (historicOwnership[to] == 0 || historicOwnership[to] == tokenId),
                "Fiat24Account: Not allowed. The target address has an account or once had another account.");
                require(this.status(tokenId) == Status.Live || this.status(tokenId) == Status.Tourist, "Fiat24Account: Transfer not allowed in this status");
            }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}