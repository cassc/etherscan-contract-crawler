// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Contract of Rpcp NFTs collection
/// @author Johnleouf21
import "./ERC721A.sol";
import "./Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Rpcp is ERC721A, PaymentSplitter, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint private constant LIMIT_SUPPLY_RATON = 1000;
    uint private constant LIMIT_SUPPLY_CARCAJOU = 2000;
    uint private constant LIMIT_SUPPLY_RENARD = 3000;
    uint private constant LIMIT_SUPPLY_LOUP = 4000;
    uint private constant LIMIT_SUPPLY_OURS = 5000;
    uint256 private constant COMMISSION_RATE = 5;
    uint256 private constant COMMISSION_CYCLE = 30 * 24 * 60 * 60;
    uint public max_mint_allowed = 5000;
    uint public priceRaton = 500000000; //500 with 6 decimals
    uint public priceCarcajou = 1500000000;
    uint public priceRenard = 5000000000;
    uint public priceLoup = 10000000000;
    uint public priceOurs = 20000000000;
    string private baseURI;
    string public baseExtension = ".json";
    address private  tokenAddress;
    enum Steps {
        Before,
        SaleRaton,
        SaleCarcajou,
        SaleRenard,
        SaleLoup,
        SaleOurs,
        SoldOut,
        Reveal
    }
    Steps public sellingStep;
  event CommissionWithdraw(address indexed buyer, uint256 indexed amount);
  struct SaleLog {uint256 unitPrice; uint256 qty; uint256 startTokenId; uint256 lastWithdraw;}
  mapping(address => SaleLog[]) saleLogs;
    address private _owner;
    uint numberNftSold = totalSupply();
    uint256 private _currentIndex;
    mapping(address => uint) nftsPerWallet;
    uint private teamLength;
    address[] private _team = [
        0x45520e8A18deE37d34BacF78Ab98E1a123b484DC,
        0x538Abb8fF8057AF5Ebb0062e7902AC171a3370f9,
        0x7EEAaD9C49c5422Ea6B65665146187A66F22c48E,
        0x08db6be654bA391e80e80358112EDE75717dcfAb,
        0xA9DD0A95849B61743c3a4b66167BaF22FF6E9986,
        0x5Fd1e5d91187D1f206AB144C9a3f098060C1D6D7,
        0x3193F74Dc03575e7b5b15957B4dB32F989117896
    ];
    uint[] private _teamShares = [
        85, 
        10,
        1,
        1,
        1,
        1,
        1
    ];
    constructor(string memory _theBaseURI, address _tokenAddress) ERC721A("Rpcp", "RPCP") PaymentSplitter(_team, _teamShares) {
        transferOwnership(msg.sender);
        sellingStep = Steps.Before;
        baseURI = _theBaseURI;
        teamLength = _team.length;
        tokenAddress = _tokenAddress;
        _mint(msg.sender, 10);
    }
    function changePriceRaton(uint _priceRaton) external onlyOwner {
        priceRaton = _priceRaton;
    }
    function changePriceCarcajou(uint _priceCarcajou) external onlyOwner {
        priceCarcajou = _priceCarcajou;
    }
    function changePriceRenard(uint _priceRenard) external onlyOwner {
        priceRenard = _priceRenard;
    }
    function changePriceLoup(uint _priceLoup) external onlyOwner {
        priceLoup = _priceLoup;
    }
    function changePriceOurs(uint _priceOurs) external onlyOwner {
        priceOurs = _priceOurs;
    }
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setStep(uint _step) external onlyOwner {
        sellingStep = Steps(_step);
    }
    function addSaleLog( address _buyer, uint256 price, uint256 qty) internal {
        saleLogs[_buyer].push(SaleLog(price, qty, _currentIndex + 1, block.timestamp));
    }
    function getBillableCommissionCycle(uint256 lastWithdraw, uint256 currentTime) internal pure returns (uint256) {
        uint256 duration = currentTime - lastWithdraw;
        return duration / COMMISSION_CYCLE;
    }
    function calculateCommission(address _buyer, uint256 currentTime) internal view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        SaleLog memory saleLog = saleLogs[_buyer][i];
        uint256 billableCycle = getBillableCommissionCycle(
            saleLog.lastWithdraw,
            currentTime
        );
        uint256 billableAmount = (billableCycle *
            saleLog.unitPrice * saleLog.qty *
            COMMISSION_RATE) / 100;
        amount += billableAmount;
        }
        return amount;
    }
    function afterWithdrawCommission(address _buyer, uint256 currentTime) internal {
        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        uint256 billableCycle = getBillableCommissionCycle(
            saleLogs[_buyer][i].lastWithdraw,
            currentTime
        );
        uint256 billableDuration = billableCycle * COMMISSION_CYCLE;
        saleLogs[_buyer][i].lastWithdraw += billableDuration;
        }
    }
    function withdrawCommission() external nonReentrant {
        address buyer =  msg.sender;
        uint256 currentTime = block.timestamp;
        require(saleLogs[buyer].length > 0);
        uint256 amount = calculateCommission(buyer, currentTime);
        require(amount > 0);
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);
		require(IERC20(tokenAddress).transfer(buyer,amount));
        afterWithdrawCommission(buyer, currentTime);
        emit CommissionWithdraw(buyer, amount);
    }
    function deposit(uint amount) public  onlyOwner {
     require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount));
    }
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
      if (saleLogs[from].length > 0) {
          for (uint256 i = 0; i < saleLogs[from].length; i++) {
            SaleLog memory log = saleLogs[from][i];
            bool isInTokenRange = log.startTokenId <= startTokenId && log.startTokenId + log.qty >= startTokenId + quantity && quantity <= log.qty;
            if (isInTokenRange) {
                uint256 headLogQty =  startTokenId - log.startTokenId;
                uint256 tailLogQty = log.qty - quantity - headLogQty;
                delete saleLogs[from][i];
                if (headLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, headLogQty, log.startTokenId, log.lastWithdraw));
                }
                if (tailLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, tailLogQty, startTokenId + quantity, log.lastWithdraw));
                }             
                saleLogs[to].push(SaleLog(log.unitPrice, quantity, startTokenId, log.lastWithdraw));
            }
        }
      }
    }
    function saleRaton(uint256 _quantity) external nonReentrant {
        uint price = priceRaton;
        require(sellingStep == Steps.SaleRaton);
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed);
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity));
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_RATON);
        nftsPerWallet[msg.sender] += _quantity;
        if(numberNftSold + _quantity == LIMIT_SUPPLY_RATON) {
             sellingStep = Steps.SaleCarcajou;   
        }
        addSaleLog(msg.sender, price, _quantity);
        _safeMint(msg.sender, _quantity);
    }
    function saleCarcajou(uint256 _quantity) external nonReentrant {
        uint price = priceCarcajou;
        require(sellingStep == Steps.SaleCarcajou);
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity));
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed);
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_CARCAJOU);
        nftsPerWallet[msg.sender] += _quantity;
        if(numberNftSold + _quantity == LIMIT_SUPPLY_CARCAJOU) {
            sellingStep = Steps.SaleRenard;   
        }
        addSaleLog(msg.sender, price, _quantity);
        _safeMint(msg.sender, _quantity);
    }
    function saleRenard(uint256 _quantity) external nonReentrant {
        uint price = priceRenard;
        require(sellingStep == Steps.SaleRenard);
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity));
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed);
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_RENARD);
        nftsPerWallet[msg.sender] += _quantity;
        if(numberNftSold + _quantity == LIMIT_SUPPLY_RENARD) {
            sellingStep = Steps.SaleLoup;   
        }
        addSaleLog(msg.sender, price, _quantity);
        _safeMint(msg.sender, _quantity);
    }
    function saleLoup(uint256 _quantity) external nonReentrant {
        uint price = priceLoup;
        require(sellingStep == Steps.SaleLoup);
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity));
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed);
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_LOUP);
        nftsPerWallet[msg.sender] += _quantity;
        if(numberNftSold + _quantity == LIMIT_SUPPLY_LOUP) {
            sellingStep = Steps.SaleOurs;   
        }
        addSaleLog(msg.sender, price, _quantity);
        _safeMint(msg.sender, _quantity);
    }
    function saleOurs(uint256 _quantity) external nonReentrant {
        uint price = priceOurs;
        require(sellingStep == Steps.SaleOurs);
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity));
        require(nftsPerWallet[msg.sender] + _quantity <= max_mint_allowed);
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_OURS);
        nftsPerWallet[msg.sender] += _quantity;
        if(numberNftSold + _quantity == LIMIT_SUPPLY_OURS) {
            sellingStep = Steps.SoldOut;   
        }
        addSaleLog(msg.sender, price, _quantity);
        _safeMint(msg.sender, _quantity);
    }
    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId));
    string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }   
}