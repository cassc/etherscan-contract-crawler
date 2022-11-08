// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "ERC721URIStorage.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "Strings.sol";
import "PaymentSplitter.sol";
import "ReleaseTickets0xRichApeWife.sol";

contract RichApeWives is ERC721URIStorage, Ownable, PaymentSplitter {

    uint public constant maxWives = 10000;
    uint256 public RAWPrice;
    bool public isSaleLive = false;
    bool public isCollectionRevealed = false;
    uint256 public wivesCounter;
    uint256 public desiredPrice = 200; //USD
    uint256 public invesmentFunds = 250000; //USD
    uint256 public seedersCashback = 2000; //USD
    uint256 public priorityListFunds = 70000; //USD
    uint16 public constant reservedWifesForPriority = 350; //pieces
    uint16 public claimedPriorityWifes;
    ReleaseTickets0xRichApeWife public releaseTicketsContract;
    uint256 public totalSeeders;
    address[] public seederInvestors;
    address[] public _team;
    uint[] public _teamShares;
    uint public lastMint = 0;
    uint32 public threeDaysInSeconds = 259200;
    address[4] public invesmentFundsWallets;

    AggregatorV3Interface internal priceFeed;
    string private _baseURIExtended;
    bool internal locked;
    address private _marketingWallet;
    address private _team1Wallet;
    address private _team2Wallet;
    address[] private priorityList;
    bool internal releaseActive = false;

    struct Account {
        uint256 mintedNFTs;
        bool isAdmin;
        bool isSeeder;
        uint256 releaseTickets;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PriceUpdate(uint feedPrice, uint newPrice);
    event SeedersFirstAirdropExecuted();
    event SeedersSecondAirdropExecuted();
    event FirstFundRelease();
    event SecondFundRelease();
    event ThirdFundRelease();
    event LastFundRelease();
    event AdminsFirstAirdrop();
    event AdminsSecondAirdrop();
    event AdminsLastAirdrop();
    event PriorityListFundsRelease();
    event EmergencyFundRelease();

    constructor(
        address _dataFeed, 
        string memory _networkBaseURI, 
        address _releaseTickets,
        address[] memory team,
        uint[] memory teamShares,
        address[] memory investmentFunds,
        address marketingWallet, //These wallets are for admin airdrops used to promote the project
        address team1Wallet,
        address team2Wallet 
    ) ERC721("0xRichApeWives", "0xRAW") PaymentSplitter(team, teamShares) {
        wivesCounter = 0;
        RAWPrice = 0;
        claimedPriorityWifes = 0;
        priceFeed = AggregatorV3Interface(_dataFeed);
        releaseTicketsContract = ReleaseTickets0xRichApeWife(_releaseTickets);
        _baseURIExtended = _networkBaseURI;
        accounts[msg.sender] = Account(0, true, false, 0);
        _team = team;
        _teamShares = teamShares;
        totalSeeders = releaseTicketsContract.totalSupply();
        for (uint i = 0; i < totalSeeders; i++) {
            address seeder = releaseTicketsContract.ownerOf(i);
            accounts[seeder] = Account(0, false, true, 0);
            seederInvestors.push(seeder);
        }
        for (uint i = 0; i < _team.length; i++) {
            accounts[_team[i]].isAdmin = true;
        }
        invesmentFundsWallets[0] = investmentFunds[0];
        invesmentFundsWallets[1] = investmentFunds[1];
        invesmentFundsWallets[2] = investmentFunds[2];
        invesmentFundsWallets[3] = investmentFunds[3];
        _marketingWallet = marketingWallet;
        _team1Wallet = team1Wallet;
        _team2Wallet = team2Wallet;
    }

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Only admins can execute this function");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function setAdmin(address _addr) external onlyOwner {
        require(accounts[_addr].isAdmin == false, "This user is already admin");
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function updateBaseURI(string memory _networkBaseURI) external onlyOwner {
        _baseURIExtended = _networkBaseURI;
        for (uint i = 0; i < wivesCounter; i++) {
            _setTokenURI(i, string.concat(_baseURIExtended, Strings.toString(i+1)));
        }
    }

    function updateDataFeed(address _dataFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_dataFeed);
    }

    function makeRevelation(string memory _revelationURI) external onlyOwner {
        this.updateBaseURI(_revelationURI);
        isCollectionRevealed = true;
    }

    function activateSale() external onlyOwner {
        isSaleLive = true;
    }

    function deactivateSale() external onlyOwner {
        isSaleLive = false;
    }

    function totalSupply() public view returns (uint256) {
        return wivesCounter;
    }

    function updatePrice() external onlyAdmin {
        int price = fetchPrice();
        uint256 desired_price = desiredPrice * 10 ** 18;
        uint8 baseDecimals = priceFeed.decimals();
        price = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(price);
        RAWPrice = (desired_price * 10 ** 18) / basePrice;
        emit PriceUpdate(basePrice, RAWPrice);
    }

    function fetchPrice() internal view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        require(price > 0, "Error fetching data from price feed");
        return price;
    }

    function scalePrice(int256 _price, uint8 _baseDecimals) internal pure returns (int256) {
        if (_baseDecimals < uint8(18)) {
            return _price * int256(10 ** uint256(uint8(18) - _baseDecimals));
        } else {
            return _price / int256(10 ** uint256(_baseDecimals - uint8(18)));
        }
    }

    function adminMint(uint _amount) external onlyAdmin {
        require(wivesCounter + 1 <= maxWives, "Wife limit already reached");
        require(_amount > 0, "You must mint at least one NFT and under 10000");
        for (uint i = 0; i < _amount; i++) {
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(msg.sender, wivesCounter);
        }
    }

    function mintWife(uint _amount) external payable noReentrant {
        require(isSaleLive, "Sale must be active to mint");
        require(_amount > 0, "You must mint at least one NFT and under 10000");
        require(wivesCounter + _amount <= maxWives, "Purchase would exceed the max supply of wifes");
        require(msg.value >= (RAWPrice * _amount), "Not enough ether send to buy the desired wifes");
        require(!isContract(msg.sender), "Contracts can't mint");

        for (uint i = 0; i < _amount; i++) {
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            if (wivesCounter < reservedWifesForPriority) {
                priorityList.push(msg.sender);
                claimedPriorityWifes++;
            }
            wivesCounter++;
            emit Mint(msg.sender, wivesCounter);
            lastMint = block.timestamp;
        }
    }

    function getPriorityList() external view returns (address[] memory) {
        return priorityList;
    }

    function seedersFirstAirdrop() external onlyAdmin {
        uint half = uint(seederInvestors.length / 2);
        if (half < 1) half = seederInvestors.length;
        for (uint i = 0; i < half; i++) {
            accounts[seederInvestors[i]].releaseTickets++;
            if (accounts[seederInvestors[i]].mintedNFTs < (accounts[seederInvestors[i]].releaseTickets * 30)) {
                for (uint x = accounts[seederInvestors[i]].mintedNFTs; x < (accounts[seederInvestors[i]].releaseTickets * 30); x++) {
                    accounts[seederInvestors[i]].mintedNFTs++;
                    _safeMint(seederInvestors[i], wivesCounter);
                    _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
                    wivesCounter++;
                    claimedPriorityWifes++;
                    emit Mint(seederInvestors[i], wivesCounter);
                    lastMint = block.timestamp;
                }
            }
        }
        emit SeedersFirstAirdropExecuted();
    }

    function seedersSecondAirdrop() external onlyAdmin {
        uint half = uint(seederInvestors.length / 2);
        for (uint i = half; i < seederInvestors.length; i++) {
            accounts[seederInvestors[i]].releaseTickets++;
            if (accounts[seederInvestors[i]].mintedNFTs < (accounts[seederInvestors[i]].releaseTickets * 30)) {
                for (uint x = accounts[seederInvestors[i]].mintedNFTs; x < (accounts[seederInvestors[i]].releaseTickets * 30); x++) {
                    accounts[seederInvestors[i]].mintedNFTs++;
                    _safeMint(seederInvestors[i], wivesCounter);
                    _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
                    wivesCounter++;
                    claimedPriorityWifes++;
                    emit Mint(seederInvestors[i], wivesCounter);
                    lastMint = block.timestamp;
                }
            }
        }
        emit SeedersSecondAirdropExecuted();
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function firstRelease() external onlyAdmin() {
        require(wivesCounter >= 2500, "Sales have not meet the 25%");
        int price = fetchPrice();
        uint8 baseDecimals = priceFeed.decimals();
        int scaledPrice = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(scaledPrice);
        uint256 desiredCashback = seedersCashback * 10 ** 18;
        uint256 seedersETHCashback = (desiredCashback * 10 ** 18) / basePrice;
        uint256 desiredInvestmentFund = invesmentFunds * 10 ** 18;
        uint256 investmentETH = (desiredInvestmentFund * 10 ** 18) / basePrice;
        for (uint i = 0; i < totalSeeders; i++) {
            Address.sendValue(payable(seederInvestors[i]), seedersETHCashback);
        }
        Address.sendValue(payable(invesmentFundsWallets[0]), investmentETH);
        releaseFunds();
        emit FirstFundRelease();
    }

    function firstAdminAirdrop() external onlyAdmin() {
        require(wivesCounter >= 2500, "Sales have not meet the 25%");
        require(wivesCounter + 1 <= maxWives, "Wife limit already reached");
        for (uint i = 0; i < 65; i++) {
            accounts[_marketingWallet].mintedNFTs++;
            _safeMint(_marketingWallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_marketingWallet, wivesCounter);
        }
        for (uint i = 0; i < 75; i++) {
            accounts[_team1Wallet].mintedNFTs++;
            _safeMint(_team1Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team1Wallet, wivesCounter);
        }
        for (uint i = 0; i < 100; i++) {
            accounts[_team2Wallet].mintedNFTs++;
            _safeMint(_team2Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team2Wallet, wivesCounter);
        }
        emit AdminsFirstAirdrop();
    }

    function secondRelease() external onlyAdmin() {
        require(wivesCounter >= 5000, "Sales have not meet the 50%");
        int price = fetchPrice();
        uint8 baseDecimals = priceFeed.decimals();
        int scaledPrice = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(scaledPrice);
        uint256 desiredCashback = seedersCashback * 10 ** 18;
        uint256 seedersETHCashback = (desiredCashback * 10 ** 18) / basePrice;
        uint256 desiredInvestmentFund = invesmentFunds * 10 ** 18;
        uint256 investmentETH = (desiredInvestmentFund * 10 ** 18) / basePrice;
        for (uint i = 0; i < totalSeeders; i++) {
            Address.sendValue(payable(seederInvestors[i]), seedersETHCashback);
        }
        Address.sendValue(payable(invesmentFundsWallets[1]), investmentETH);
        for (uint i = 0; i < priorityList.length; i++) {
            Address.sendValue(payable(priorityList[i]), RAWPrice);
        }
        releaseFunds();
        emit SecondFundRelease();
    }

    function secondAdminAirdrop() external onlyAdmin() {
        require(wivesCounter >= 5000, "Sales have not meet the 50%");
        require(wivesCounter + 1 <= maxWives, "Wife limit already reached");
        for (uint i = 0; i < 140; i++) {
            accounts[_marketingWallet].mintedNFTs++;
            _safeMint(_marketingWallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_marketingWallet, wivesCounter);
        }
        for (uint i = 0; i < 75; i++) {
            accounts[_team1Wallet].mintedNFTs++;
            _safeMint(_team1Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team1Wallet, wivesCounter);
        }
        for (uint i = 0; i < 100; i++) {
            accounts[_team2Wallet].mintedNFTs++;
            _safeMint(_team2Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team2Wallet, wivesCounter);
        }
        emit AdminsSecondAirdrop();
    }

    function thirdRelease() external onlyAdmin() {
        require(wivesCounter >= 7500, "Sales have not meet the 75%");
        int price = fetchPrice();
        uint8 baseDecimals = priceFeed.decimals();
        int scaledPrice = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(scaledPrice);
        uint256 desiredCashback = seedersCashback * 10 ** 18;
        uint256 seedersETHCashback = (desiredCashback * 10 ** 18) / basePrice;
        uint256 desiredInvestmentFund = invesmentFunds * 10 ** 18;
        uint256 investmentETH = (desiredInvestmentFund * 10 ** 18) / basePrice;
        for (uint i = 0; i < totalSeeders; i++) {
            Address.sendValue(payable(seederInvestors[i]), seedersETHCashback);
        }
        Address.sendValue(payable(invesmentFundsWallets[2]), investmentETH);
        releaseFunds();
        emit ThirdFundRelease();
    }

    function lastAdminAirdrop() external onlyAdmin() {
        require(wivesCounter >= 7500, "Sales have not meet the 75%");
        require(wivesCounter + 1 <= maxWives, "Wife limit already reached");
        for (uint i = 0; i < 145; i++) {
            accounts[_marketingWallet].mintedNFTs++;
            _safeMint(_marketingWallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_marketingWallet, wivesCounter);
        }
        for (uint i = 0; i < 75; i++) {
            accounts[_team1Wallet].mintedNFTs++;
            _safeMint(_team1Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team1Wallet, wivesCounter);
        }
        for (uint i = 0; i < 100; i++) {
            accounts[_team2Wallet].mintedNFTs++;
            _safeMint(_team2Wallet, wivesCounter);
            _setTokenURI(wivesCounter, string.concat(_baseURIExtended, Strings.toString(wivesCounter+1)));
            wivesCounter++;
            emit Mint(_team2Wallet, wivesCounter);
        }
        emit AdminsLastAirdrop();
    }

    function lastRelease() external onlyAdmin() {
        require(wivesCounter >= 10000, "Sales have not meet the 100%");
        int price = fetchPrice();
        uint8 baseDecimals = priceFeed.decimals();
        int scaledPrice = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(scaledPrice);
        uint256 desiredCashback = seedersCashback * 10 ** 18;
        uint256 seedersETHCashback = (desiredCashback * 10 ** 18) / basePrice;
        uint256 desiredInvestmentFund = invesmentFunds * 10 ** 18;
        uint256 investmentETH = (desiredInvestmentFund * 10 ** 18) / basePrice;
        for (uint i = 0; i < totalSeeders; i++) {
            Address.sendValue(payable(seederInvestors[i]), seedersETHCashback);
        }
        Address.sendValue(payable(invesmentFundsWallets[3]), investmentETH);
        releaseFunds();
        emit LastFundRelease();
    }

    //Only authorized to claim the expected earning from the priority list
    function priorityListRelease() external onlyAdmin() {
        int price = fetchPrice();
        uint8 baseDecimals = priceFeed.decimals();
        int scaledPrice = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(scaledPrice);
        uint256 desiredFunds = priorityListFunds * 10 ** 18;
        uint256 priorityListETHFunds = (desiredFunds * 10 ** 18) / basePrice;
        require(totalReleased() < priorityListETHFunds, "Total funds from the priority list already claimed");
        releaseFunds();
        emit PriorityListFundsRelease();
    }

    //Only authorized if  more than 3 days since last mint
    function emergencyRelease() external onlyAdmin() {
        uint nowDate = block.timestamp;
        uint difference = nowDate - lastMint;
        require(difference > threeDaysInSeconds, "Condition not met for a emergency release");
        releaseFunds();
        emit EmergencyFundRelease();
    }

    function releaseFunds() internal {
        releaseActive = true;
        for (uint i = 0; i < _team.length; i++) {
            release(payable(_team[i]));
        }
        releaseActive = false;
    }

    function release(address payable account) public override onlyAdmin() {
        require(releaseActive, "Funds release disabled");
        super.release(account);
    }

    function release(IERC20 /*_token*/, address /*_account*/) public override view onlyAdmin() {
        require(false, "Funds release disabled by this function");
    }

}