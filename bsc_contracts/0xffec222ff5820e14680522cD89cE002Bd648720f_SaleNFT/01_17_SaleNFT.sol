/*
     ,-""""-.
   ,'      _ `.
  /       )_)  \
 :              :
 \              /
  \            /
   `.        ,'
     `.    ,'
       `.,'
        /\`.   ,-._
            `-'         BanksyDao.finance

 */

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*
    ERROR REF
    ---------
    E0: start block must be greater than current start block
    E1: Sale hasn't started yet
    E2: Nft amount must be greater than 0 
    E3: Can't buy more than the limit allowed per user
    E4: There is not enough nft
    E5: USD amount must be greater than 0 
    E6: There is not enough USD
    
*/

contract SaleNFT is ReentrancyGuard, Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    address public constant ADMIN_ADDRESS = 0xf9E78C3a76BefaD33F25F1f55936234BeE318f5B;
    
    address public constant SALE_ADDRESS = 0xA94aa23F43E9f00CE154F3C1c7f971ECb5318bE8;
    
    IERC20 public constant USD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    IERC721Enumerable public constant banksyNFT = IERC721Enumerable(0x9C26e24ac6f0EA783fF9CA2bf81543c67cf446d2); 

    uint256 public nftCardPerAccountMaxTotal = 3; // 3 cards
    
    uint256 public salePrice = 75 * (10 ** 17); // 7.5 usd

    uint256 public lastNFTAssigned;

    uint256 public startTime;
    
    mapping(address => uint256) public userNftCardTotally;

    event SetStartBlock(uint256 newStartBlock);
    event BuyNftCard(address sender, uint256 usdSpent, uint256 nftCardReceived);
    event SendUnclaimedNftCard(uint256 amountNftCard);
    event SetSalePrice(uint256 newSalePrice);
    event SetUpdateLimitByUser(uint256 newLimitUser);

    constructor(uint256 _startTime) {
        require(block.timestamp < _startTime, "E0");
        
        startTime  = _startTime;
    }
    

    function buyNftCard(uint256 _amountNFT) external nonReentrant {
        require(block.timestamp >= startTime, "E1");
        require(_amountNFT > 0, "E2");
        require(_amountNFT <= nftCardPerAccountMaxTotal, "E3");
        require(userNftCardTotally[msg.sender] < nftCardPerAccountMaxTotal, "E3");        

        uint256 _balanceOfNFT = banksyNFT.balanceOf(address(this));

        require(_balanceOfNFT > 0, "E4");
        
        if ((userNftCardTotally[msg.sender] + _amountNFT) > nftCardPerAccountMaxTotal)
            _amountNFT = nftCardPerAccountMaxTotal - userNftCardTotally[msg.sender];

        // if we dont have enough left, give them the rest.
        if (_amountNFT > _balanceOfNFT)
            _amountNFT = _balanceOfNFT;


        uint256 _usdSpend = (_amountNFT * salePrice);

        require(_usdSpend > 0, "E5");
        require(_usdSpend <= USD.balanceOf(msg.sender), "E6");
  
        if (_balanceOfNFT > 0) {
              for(uint256 i=0; i < _amountNFT; i++){
                lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
                banksyNFT.safeTransferFrom(address(this), msg.sender, lastNFTAssigned);
              }


              userNftCardTotally[msg.sender] = userNftCardTotally[msg.sender] + _amountNFT;
              // send usd to sale address
              USD.safeTransferFrom(msg.sender, SALE_ADDRESS, _usdSpend);
        }
        
        emit BuyNftCard(msg.sender, _amountNFT, _usdSpend);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(_newStartBlock > 0);

        startTime = _newStartBlock;

        emit SetStartBlock(_newStartBlock);
    }


    function setPriceSale(uint256 _newSalePrice) external onlyOwner {
        require(_newSalePrice > 0);

        salePrice = _newSalePrice;

        emit SetSalePrice(salePrice);
    }

    function setUpdateLimitByUser(uint256 _newLimitUser) external onlyOwner {
        require(_newLimitUser > 0);

        nftCardPerAccountMaxTotal = _newLimitUser;

        emit SetUpdateLimitByUser(salePrice);
    }


    function sendUnclaimedNftCardToAdminAddressAll() external onlyOwner {
        uint256 _balanceOfNFT = banksyNFT.balanceOf(address(this));

        if (_balanceOfNFT > 0){
            uint256 _lastNFTAssigned;
            for(uint256 i=0; i < _balanceOfNFT; i++ ){
                _lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
                banksyNFT.safeTransferFrom(address(this), ADMIN_ADDRESS, _lastNFTAssigned);
            }
        }

        emit SendUnclaimedNftCard(_balanceOfNFT);
    }

    function sendUnclaimedNftCardToAdminAddressByOne() external onlyOwner {
        uint256 _balanceOfNFT = banksyNFT.balanceOf(address(this));

        if (_balanceOfNFT > 0){
            uint256 _lastNFTAssigned;
            _lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
            banksyNFT.safeTransferFrom(address(this), ADMIN_ADDRESS, _lastNFTAssigned);
        }

        emit SendUnclaimedNftCard(_balanceOfNFT);
    }

    function sendUnclaimedNftCardToAdminAddressByIndex(uint256 _index) external onlyOwner {
        uint256 _balanceOfNFT = banksyNFT.balanceOf(address(this));

        if (_balanceOfNFT > 0)
            banksyNFT.safeTransferFrom(address(this), ADMIN_ADDRESS, _index);

        emit SendUnclaimedNftCard(_balanceOfNFT);
    }

}