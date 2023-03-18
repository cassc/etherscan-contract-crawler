// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";



contract TreesMint is ERC721, ERC721Enumerable, Ownable{

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    
    string public baseURI;
    
    uint256 public mintPriceInWeiBNB;
    uint256 public mintPriceInWeiRBA;
    uint256 public _totalSupply;

    address public rba;
    address payable public feeAddr;


    mapping(address => bool) public isWL;
    mapping(address => bool) public oneFreeMint;
    

    event LogSetMintPriceInWei(uint256 price);
    event LogSetMintPriceInWeiRBA(uint256 price);
    event LogChangeBaseURI(string _baseURI);
    event LogWithdraw(address account, uint256 amount);
    event LogWithdrawERC20(address account, uint256 amount, address erc20);
    event LogSetrevenueShareContract(address _revenueshare);
    event LogSetJDBToken(address _JDBToken);
    event LogSetTokensAmountForDiscount(uint256 _amount);
    event LogSetDiscount(uint256 _discount);
    event LogSetFeeAddr(address _fee);
    event LogSetRBAAddr(address _rba);
   

    constructor(
        string memory name,
        string memory ticker,
        string memory _baseURI,
        uint256 _mintPriceInWeiBNB,
        uint256 _mintPriceInWeiRBA) 
        ERC721(name, ticker) {
        require(_mintPriceInWeiBNB != 0, "MintPriceInWeiBNB cannot be 0");
        require(_mintPriceInWeiRBA != 0, "MintPriceInWeiBNB cannot be 0");
        baseURI = _baseURI;
        mintPriceInWeiRBA = _mintPriceInWeiRBA;
        mintPriceInWeiBNB = _mintPriceInWeiBNB;
    }

    function setMintPriceInWeiBNB(uint256 _mintPriceInWeiBNB) external onlyOwner{
        require(mintPriceInWeiBNB != _mintPriceInWeiBNB, "Already set to this Value");
        mintPriceInWeiBNB = _mintPriceInWeiBNB;
        emit LogSetMintPriceInWei(_mintPriceInWeiBNB);
    }

    function setFeeAddr(address payable _feeAddr) public onlyOwner {
        require(_feeAddr != address(0), "address zero validation");
        feeAddr = _feeAddr;
        emit LogSetFeeAddr(_feeAddr);
    }

    function setRBAAddr(address  _rba) public onlyOwner {
        require(_rba != address(0), "address zero validation");
        rba = _rba;
        emit LogSetRBAAddr(rba);
    }

    function setMintPriceInWeiRBA(uint256 _mintPriceInWeiRBA) external onlyOwner{
        require(mintPriceInWeiRBA != _mintPriceInWeiRBA, "Already set to this Value");
        mintPriceInWeiRBA = _mintPriceInWeiRBA;
        emit LogSetMintPriceInWeiRBA(_mintPriceInWeiRBA);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
        emit LogChangeBaseURI(baseURI_);
    }

    
    function mint(uint256 num) external payable {
        if(msg.value == 0){
           uint256 mintPriceRBA = num * mintPriceInWeiRBA;
           require(IERC20(rba).balanceOf(msg.sender) >= mintPriceRBA, "Not enough rba sent");
           require(IERC20(rba).allowance(msg.sender, address(this)) >= mintPriceRBA, "Not enough rba sent");
           for(uint256 i=0; i < num; i++){
             _tokenIds.increment();
             uint256 newItemId = _tokenIds.current();
             _totalSupply = _totalSupply.add(1);

             _safeMint(msg.sender, newItemId);
            }
            IERC20(rba).transferFrom(msg.sender, address(this), mintPriceRBA);
        }else{
            uint256 mintPrice = num * mintPriceInWeiBNB;
            require(msg.value >= mintPrice, "Not enough bnb sent");
            for(uint256 i=0; i < num; i++){
             _tokenIds.increment();
             uint256 newItemId = _tokenIds.current();
             _totalSupply = _totalSupply.add(1);

             _safeMint(msg.sender, newItemId);
            }
            feeAddr.transfer(msg.value);
        }
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_totalSupply > 0, "Insufficient funds");
        require(msg.sender == ownerOf(tokenId), "Only tokenId owner");
        _totalSupply = _totalSupply.sub(1);
        super._burn(tokenId);
    }
    
    function totalSupply() public 
       virtual
        override(ERC721Enumerable)view returns(uint256)
    {
        return _totalSupply;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
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