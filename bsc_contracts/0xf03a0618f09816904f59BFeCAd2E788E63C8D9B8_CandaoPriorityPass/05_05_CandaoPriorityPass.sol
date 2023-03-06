// SPDX-License-Identifier: UNLISTED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CandaoPriorityPass is Ownable, Pausable {

    struct ProrityPass {
        // @dev: package price starting
        uint256 priorityPassPrice;

        // @dev: 
        uint256 blockNumber;

        // @dev: price transfered from user
        uint256 price;

        // @dev: only for validation
        bool valid;
    }

    struct PriorityPassPackageValue {
        // @dev: character count
        uint256 domainLength;

        // @dev: domain price based on package
        uint256 domainPrice;

        // @dev: total price that should be transfered from user
        uint256 totalPrice;

        // @dev: only for validation
        bool valid;
    }

    // @dev: USDC token address
    IERC20 public token;

    uint256 public minimumDeposit = 0;

    bool public depositEnabled = true;

    mapping (address => uint256) private _balances;

    // @dev: available packages with configuration
    mapping (uint256 => PriorityPassPackageValue[]) private _packages;
    uint256[] private _availablePackages;

    mapping (uint256 => uint256) private _domainPricing;

    // @dev: wallet address that holds Candao tokens
    address private wallet;

    // @dev: mapping hosting user PP 
    mapping (address => ProrityPass) private _userInfo;

    // @dev: EVENTS
    event PriorityPassBought(address buyer, string reservationToken, uint256 packageIndex, uint256 price, uint256 domainLength, bool automatic);
    event DomainBought(address buyer, string[] reservationToken, uint256 price, bool automatic);
    event CDOBought(address buyer, uint256 amount, bool automatic);
    event BadgesAddressUpdated(address newAddress);
    event TokenAddressUpdated(address newAddress);
    event Deposit(address wallet, uint256 amount, uint256 blockNumber);
    event Withdraw(address wallet, uint256 amount);

    constructor(address _token, address _wallet) {
        token = IERC20(_token);
        wallet = _wallet;
    }

    function buyPriorityPassAdmin(address _wallet, string memory domain, uint256 packagePrice) external onlyOwner {
        PriorityPassPackageValue[] memory pricingPackages = _packages[packagePrice];
        require(pricingPackages.length != 0, "CandaoCoordinator: pricing not found.");

        uint256 userDeposit = _balances[_wallet];
        require(userDeposit != 0, "CandaoCoordinator: User hasn't any deposit.");
        token.transfer(wallet, userDeposit);

        if (_userInfo[_wallet].valid) {
            emit CDOBought(_wallet, userDeposit, true);
            _balances[_wallet] = 0;
            return;
        }

        uint256 characterCount = bytes(domain).length;
        require(characterCount != 0, "CandaoCoordinator: Incorrect domainLength.");

        if (userDeposit < packagePrice) {
            revert("CandaoCoordinator: deposit not enough to add PP");
        }        

        uint256 depositRest = userDeposit - packagePrice;
        _userInfo[_wallet] = ProrityPass(packagePrice, block.number, packagePrice, true);
        emit PriorityPassBought(_wallet, "", packagePrice, packagePrice, characterCount, true);
        if (depositRest != 0) {
            emit CDOBought(_wallet, depositRest, true);
        }
        _balances[_wallet] = 0;
    }

    function buyPriorityPass(uint256 packagePrice, string memory domain, string memory reservationToken) external {
        require(!_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy priority pass.");
        
        uint256 characterCount = bytes(domain).length;
        require(characterCount != 0, "CandaoCoordinator: Incorrect domainLength.");

        PriorityPassPackageValue[] memory pricingPackages = _packages[packagePrice];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < pricingPackages.length; i++) {
            PriorityPassPackageValue memory packageItem = pricingPackages[i];
            if (packageItem.domainLength == characterCount) {
                totalPrice = packageItem.totalPrice;
            }
        }

        require(totalPrice != 0, "CandaoCoordinator: package totalPrice not found.");        
        _userInfo[msg.sender] = ProrityPass(packagePrice, block.number, totalPrice, true);
        token.transferFrom(msg.sender, wallet, totalPrice);
        emit PriorityPassBought(msg.sender, reservationToken, packagePrice, totalPrice, characterCount, false);
    }

    function addPriorityPass(address _initialBuyer, address _successor) external onlyOwner {
        ProrityPass memory initialBuyerPP = _userInfo[_initialBuyer];
        _userInfo[_successor] = ProrityPass(initialBuyerPP.priorityPassPrice, initialBuyerPP.blockNumber, initialBuyerPP.price, true);
    }

    function buyCDO(uint256 amount) external {
        require(_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy CDO tokens.");

        token.transferFrom(msg.sender, wallet, amount);
        emit CDOBought(msg.sender, amount, false);
    }

    function buyAdditionalDomain(string[] memory domains, string[] memory reservationTokens) external {
        require(_userInfo[msg.sender].valid, "CandaoCoordinator: Address isn't allowed to buy domain.");
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < domains.length; i++) {
            uint256 characterCount = bytes(domains[i]).length;
            require(characterCount != 0, "CandaoCoordinator: Incorrect domainLength.");
            uint256 domainPrice = _domainPricing[characterCount];
            require(domainPrice != 0, "CandaoCoordinator: Domain pricing not set.");
            totalPrice += domainPrice;
        }

        token.transferFrom(msg.sender, wallet, totalPrice);
        emit DomainBought(msg.sender, reservationTokens, totalPrice, false);
    }

    function addDomainPrice(uint256 domainLength, uint256 price) external onlyOwner {
        _domainPricing[domainLength] = price;
    }

    function addPackageOption(uint256 packagePrice, uint256 domainLength, uint256 domainPrice, uint256 totalPrice) external onlyOwner {
        _addPackageOption(packagePrice, domainLength, domainPrice, totalPrice);
    }

    function addPackageOptions(uint256[] memory packagePrice, uint256[] memory domainLength, uint256[] memory domainPrice, uint256[] memory totalPrice) external onlyOwner {
        for (uint i = 0; i < packagePrice.length; i++) {
            _addPackageOption(packagePrice[i], domainLength[i], domainPrice[i], totalPrice[i]);
        }
    }

    function _addPackageOption(uint256 packagePrice, uint256 domainLength, uint256 domainPrice, uint256 totalPrice) private {
        if (_packages[packagePrice].length == 0) {
            _availablePackages.push(packagePrice);
        }

        PriorityPassPackageValue[] memory pricingPackages = _packages[packagePrice];
        for (uint256 i = 0; i < pricingPackages.length; i++) {
            PriorityPassPackageValue memory packageItem = pricingPackages[i];
            if (packageItem.domainLength == domainLength) {
                revert("CandaoCoordinator: Duplicate package option.");
            }
        }

        _packages[packagePrice].push(PriorityPassPackageValue(domainLength, domainPrice, totalPrice, true));
    }

    function removePackage(uint256 packagePrice) external onlyOwner {
        require(_packages[packagePrice].length != 0, "CandaoCoordinator: Missing package");
        delete _packages[packagePrice];

        for (uint i = 0; i < _availablePackages.length; i++) {
            if (_availablePackages[i] == packagePrice) {
                delete _availablePackages[i];
            }
        }
    }

    function deposit(uint256 amount) external {
        require(depositEnabled, "CandaoCoordinator: Deposits disabled.");
        require(amount >= minimumDeposit, "CandaoCoordinator: not enough.");

        token.transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount, block.number);
    }

    function withdraw(address owner) external onlyOwner {
        uint256 balance = _balances[owner];
        token.transfer(owner, balance);
        _balances[owner] = 0;

        emit Withdraw(owner, balance);
    }

    function removePackageDomainLength(uint256 packagePrice, uint256 packageValueIndex) external onlyOwner {
        require(packagePrice != 0, "CandaoCoordinator: Package Index can't be 0.");
        require(packageValueIndex != 0, "CandaoCoordinator: Package Value Index can't be 0.");
        require(_packages[packagePrice].length != 0, "CandaoCoordinator: Missing package");
        require(_packages[packagePrice][packageValueIndex].valid, "CandaoCoordinator: Missing package value");
        delete _packages[packagePrice][packageValueIndex];
    }

    function setTokenAddress(address newAddress) external onlyOwner {
        require(address(token) != newAddress, "CandaoCoordinator: newAddress can't same as prev.");
        token = IERC20(newAddress);
        emit TokenAddressUpdated(newAddress); 
    }

    function setWalletAddress(address newAddress) external onlyOwner {
        wallet = newAddress;
    }

    function setDepositEnbaled(bool enabled) external onlyOwner {
        depositEnabled = enabled;
    }

    function setMinimumDeposit(uint256 minimum) external onlyOwner {
        minimumDeposit = minimum;
    }

    function userInfo(address _wallet) public view returns (ProrityPass memory) {
        return _userInfo[_wallet];
    }

    function showPackage(uint256 selectedPackage) public view returns (PriorityPassPackageValue[] memory) {
        return _packages[selectedPackage];
    }

    function showDomainPricing(uint256 characterCount) public view returns (uint256) {
        return _domainPricing[characterCount];
    }

    function showAvailablePackages() public view returns (uint256[] memory) {
        return _availablePackages;
    }

    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }
}