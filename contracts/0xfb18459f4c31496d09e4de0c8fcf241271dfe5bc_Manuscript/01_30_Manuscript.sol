// SPDX-License-Identifier: MIT

// Developed by Thanic® Tech Labs


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../KahiruMK.sol";
import "./KahiruStaking.sol";
import "./AbstractERC1155Factory.sol";

contract Manuscript is AbstractERC1155Factory{

    NFTStaking staking;
    KahiruF NFT;

    uint256 constant MAX_SUPPLY = 7222;

    uint8 maxPerWallet = 1;
    uint8 maxPerTx = 1;

    mapping(address => bool) wlcontrollers;
    mapping(address => bool) controllers;
    mapping(address => uint256) public purchaseTxs;

    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        KahiruF _nft,
        NFTStaking _staking
    ) ERC1155(_uri){
        name_ = _name;
        symbol_ = _symbol;
        staking = _staking;
        NFT = _nft;
    }


    function purchase(uint256 tokenId) external payable whenNotPaused {
        require(purchaseTxs[msg.sender] < maxPerWallet , "max wallet amount exceeded");
        address owner1 = NFT.ownerDetails(tokenId).addr;
        uint64 timeHold = NFT.ownerDetails(tokenId).startTimestamp;
        (, uint48 timeStake , , address owner2, ) = staking.vault(tokenId);
        require(owner1 == msg.sender || owner2 == msg.sender, "You are not the owner");
        uint256 dif1 = block.timestamp - timeHold;
        uint256 dif2 = block.timestamp - timeStake;

        if(timeStake != 0){
          if (dif1 > 2592000 || dif2 > 2592000){
            _purchase(1);
          }
          else{
            uint256 restante = 0;
            if(dif1 > dif2){
              restante = 2592000 - dif1;
              revert("You dont hold or stake for more than 30 days");
            }
            else{
              restante = 2592000 - dif2;
              revert("You dont hold or stake for more than 30 days");
            }
          }
        }
        if(timeStake == 0){
          if(timeHold != 0){
            if (dif1 > 2592000){
              _purchase(1);
            }
            else{
              uint256 restante = 0;
              restante = 2592000 - dif1;
              revert("You dont hold or stake for more than 30 days");
            }
          }
          else{
            uint256 restante = 0;
            if(dif1 > dif2){
              restante = 2592000 - dif1;
              revert("You dont hold or stake for more than 30 days");
            }
            else{
              restante = 2592000 - dif2;
              revert("You dont hold or stake for more than 30 days");
            }
          }
        }
    }

    function purchaseController(uint256 _ammount) external payable whenNotPaused {
      require(controllers[msg.sender], "Only controllers can call this function");
      _purchase(_ammount);
    }

    function purchaseExcepts() external payable whenNotPaused {
      require(wlcontrollers[msg.sender], "Only controllers can call this function");
      _purchase(1);
      wlcontrollers[msg.sender] = false;
    }

    function earningInfo(uint256 tokenId) external view returns (uint256 total, bool permission) {
        address owner1 = NFT.ownerDetails(tokenId).addr;
        uint64 timeHold = NFT.ownerDetails(tokenId).startTimestamp;
        (, uint48 timeStake , , address owner2, ) = staking.vault(tokenId);
        uint256 dif1 = block.timestamp - timeHold;
        uint256 dif2 = block.timestamp - timeStake;
        if(timeStake != 0){
          if (dif1 > 2592000 || dif2 > 2592000){
            return(0, true);
          }
          else{
            uint256 restante = 0;
            if(dif1 > dif2){
              restante = 2592000 - dif1;
              return(restante, false);
            }
            else{
              restante = 2592000 - dif2;
              return(restante, false);
            }
          }
        }
        if(timeStake == 0){
          if(timeHold != 0){
            if (dif1 > 2592000){
              return(0, true);
            }
            else{
              uint256 restante = 0;
              restante = 2592000 - dif1;
              return(restante, false);
            }
          }
          else{
            uint256 restante = 0;
            if(dif1 > dif2){
              restante = 2592000 - dif1;
              return(restante, false);
            }
            else{
              restante = 2592000 - dif2;
              return(restante, false);
            }
          }
        }
    }

    function Stakedinfo(uint256 tokenId) external view returns (uint256 total1, uint256 total2,  bool permission) {
        address owner1 = NFT.ownerDetails(tokenId).addr;
        uint64 timeHold = NFT.ownerDetails(tokenId).startTimestamp;
        (, uint48 timeStake , , address owner2, ) = staking.vault(tokenId);
        uint256 dif1 = block.timestamp - timeHold;
        uint256 dif2 = block.timestamp - timeStake;
        return(dif1, dif2, true);
    }


    function _purchase(uint256 amount) private {
        require(totalSupply(0) + amount <= MAX_SUPPLY, "Purchase: Max supply reached");
        purchaseTxs[msg.sender] += 1;

        _mint(msg.sender, 0, amount, "");
        emit Purchased(0, msg.sender, amount);
    }


    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function addController(address controller) external onlyOwner {
      controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
      controllers[controller] = false;
    }

    function addWlController(address controller) external onlyOwner {
      wlcontrollers[controller] = true;
    }

    function removeWlController(address controller) external onlyOwner {
      wlcontrollers[controller] = false;
    }

    // ROYALTIES //

    function royaltyInfo(uint256, uint256 salePrice) external view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 650) / 10000);
  }

}