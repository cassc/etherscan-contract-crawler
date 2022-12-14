// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract JDBMint7DaysAccess is ERC721, Ownable{

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    
    string public baseURI;
    
    uint256 public mintPriceInWeiBNB;
    
    uint256 public nftTypeIdentifier = 3;
    uint256 public _totalSupply;
    // 10% from total of 10000
    uint256 public discount = 1000; 
    uint256 public tokensAmountForDiscount;
    address public revenueShareContract;
    address public JDBToken;


    event LogSetMintPriceInWei(uint256 price);
    event LogChangeBaseURI(string _baseURI);
    event LogWithdraw(address account, uint256 amount);
    event LogWithdrawERC20(address account, uint256 amount, address erc20);
    event LogSetrevenueShareContract(address _revenueshare);
    event LogSetJDBToken(address _JDBToken);
    event LogSetTokensAmountForDiscount(uint256 _amount);
    event LogSetDiscount(uint256 _discount);
   

    constructor(
        string memory name,
        string memory ticker,
        string memory _baseURI,
        address _JDBToken, 
        uint256 _tokensAmountForDiscount,
        address _revenueShareContract, 
        uint256 _mintPriceInWeiBNB) 
        ERC721(name, ticker) {
        require(_JDBToken != address(0), "JDBToken cannot be address 0");
        require(_tokensAmountForDiscount != 0, "TokensAmountForDiscount cannot be 0");
        require(_revenueShareContract != address(0), "RevenueShareContract cannot be address 0");
        require(_mintPriceInWeiBNB != 0, "MintPriceInWeiBNB cannot be 0");
        baseURI = _baseURI;
        JDBToken = _JDBToken;
        tokensAmountForDiscount = _tokensAmountForDiscount;
        revenueShareContract = _revenueShareContract;
        mintPriceInWeiBNB = _mintPriceInWeiBNB;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721)
    {
        require(from == address(0) || to == address(0), "Non transferrable");
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function setMintPriceInWeiBNB(uint256 _mintPriceInWeiBNB) external onlyOwner{
        require(mintPriceInWeiBNB != _mintPriceInWeiBNB, "Already set to this Value");
       
        mintPriceInWeiBNB = _mintPriceInWeiBNB;
        emit LogSetMintPriceInWei(_mintPriceInWeiBNB);
    }

    function setTokensAmountForDiscount(uint256 _tokensAmountForDiscount) external onlyOwner{
        require(tokensAmountForDiscount != _tokensAmountForDiscount, "Already set to this Value");
       
        tokensAmountForDiscount = _tokensAmountForDiscount;
        emit LogSetTokensAmountForDiscount(_tokensAmountForDiscount);
    }

    function setDiscount(uint256 _discount) external onlyOwner{
        require(discount != _discount, "Already set to this Value");
       
        discount = _discount;
        emit LogSetDiscount(_discount);
    }

    function setRevenueShareContract(address _revenueShareContract) external onlyOwner{
        require(revenueShareContract != _revenueShareContract, "Already set to this Value");
       
        revenueShareContract = _revenueShareContract;
        emit LogSetrevenueShareContract(_revenueShareContract);
    }

    function setJDBToken(address _JDBToken) external onlyOwner{
        require(JDBToken != _JDBToken, "Already set to this Value");
       
        JDBToken = _JDBToken;
        emit LogSetJDBToken(_JDBToken);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
        emit LogChangeBaseURI(baseURI_);
    }

    
    function mint() external payable {
        
       if(IERC20(JDBToken).balanceOf(msg.sender) >= tokensAmountForDiscount){
          uint256 _discount = _calculateDiscountFromAmount(mintPriceInWeiBNB);
          uint256 mintPrice = mintPriceInWeiBNB.sub(_discount);
          require(msg.value >= mintPrice, "DiscountMint: Not enough bnb sent");
        }else{
           require(msg.value >= mintPriceInWeiBNB, "Not enough bnb sent");
        }  
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _totalSupply = _totalSupply.add(1);  
        _safeMint(msg.sender, newItemId);  
        safeTransferBNB(revenueShareContract, msg.value);
        
    }


    function _calculateDiscountFromAmount(uint256 _amount)
        public
        view
        returns (uint256)
    {
        require(_amount > 0, "Amount cannot be zero");
        require(discount > 0,"ServiceFee not set");

        return _amount.mul(discount).div(10**4);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        
    }

    function withdraw(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "cannot be address zero " );
        require(amount <= address(this).balance, "Insufficient funds");
        safeTransferBNB(account, amount);
        emit LogWithdraw(account, amount);
    }

    function withdrawERC20(address account, uint256 amount, address tokenErc20) external onlyOwner {
        require(account != address(0), "cannot be address zero " );
        require(tokenErc20 != address(0), "cannot be address zero " );
        require(amount <= IERC20(tokenErc20).balanceOf(address(this)), "Insufficient funds");
        IERC20(tokenErc20).transfer(account, amount);
        emit LogWithdrawERC20(account, amount, tokenErc20);
    }

    function burn(uint256 tokenId) external {
        require(_totalSupply > 0, "Insufficient funds");
        _totalSupply = _totalSupply.sub(1);
        super._burn(tokenId);
    }
    
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Internal function to handle safe transfer
    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }

}