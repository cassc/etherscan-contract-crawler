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

/*
    ERROR REF
    ---------
    E1: Airdrop not start
    E2: Recipient not registered
    E3: Not NFT balance
*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BanksyAirDrop is Ownable, ReentrancyGuard, ERC721Holder {
    
    using SafeERC20 for IERC20;

    
    uint256 public startTime;

    uint256 public balanceOfNFT;

    uint256 public lastNFTAssigned;


    // Whitelist
    mapping(address => bool) public recipients;


    // NFT
    IERC721Enumerable public constant banksyNFT = IERC721Enumerable(0x9C26e24ac6f0EA783fF9CA2bf81543c67cf446d2); 

    event AirdropClaimed(address sender);
    event startTimeChanged(uint256 newStartTime);
    event WithdrawNFT(uint256 totalNFT);

    constructor(uint256 _startTime) {        
        startTime = _startTime;
    }

    function claimBanksyAirdrop() external nonReentrant {
        require(block.timestamp > startTime, "E1");
        require(recipients[msg.sender], "E2");
        
        balanceOfNFT = banksyNFT.balanceOf(address(this));

        require(balanceOfNFT > 0, "E3");

        recipients[msg.sender] = false;
        lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
        banksyNFT.safeTransferFrom(address(this), msg.sender, lastNFTAssigned);
            
                        
        emit AirdropClaimed(msg.sender);
    }

    
    function withdrawNFTAll() external onlyOwner {
        balanceOfNFT = banksyNFT.balanceOf(address(this));

        for(uint256 i=0; i < balanceOfNFT; i++ ){
            lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
            banksyNFT.safeTransferFrom(address(this), msg.sender, lastNFTAssigned);
        }

        emit WithdrawNFT(balanceOfNFT);

    }

    function withdrawNFTByOne() external onlyOwner {
        balanceOfNFT = banksyNFT.balanceOf(address(this));
        lastNFTAssigned = banksyNFT.tokenOfOwnerByIndex(address(this), 0);
        banksyNFT.safeTransferFrom(address(this), msg.sender, lastNFTAssigned);

        emit WithdrawNFT(lastNFTAssigned);
    }

    function withdrawNFTByIndex(uint256 _index) external onlyOwner {
        balanceOfNFT = banksyNFT.balanceOf(address(this));
        banksyNFT.safeTransferFrom(address(this), msg.sender, _index);

        emit WithdrawNFT(_index);
    }

    function setstartTime(uint256 _newstartTime) external onlyOwner {
        startTime = _newstartTime;

        emit startTimeChanged(_newstartTime);
    }

    function addRecipients(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = true;
        }
    }

    function removeRecipients(address[] memory _recipients) external onlyOwner {
        for(uint i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = false;
        }
    }

}