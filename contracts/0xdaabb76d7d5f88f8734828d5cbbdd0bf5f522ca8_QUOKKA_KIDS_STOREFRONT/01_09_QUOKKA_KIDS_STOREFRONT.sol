// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

interface IERC1155Burnable {
    function burn(
        address from,
        uint256 id,
        uint256 amount) external;
}


interface IERC721 {
    function mint(address to, uint amount) external;
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
}

interface IER721ParentTracker is IERC721 {
    function genesisParents(uint256 index) external returns (bool);
    function legendParents(uint256 index) external returns (bool);

    function parentMint(address to, uint amount) external;
    function setGenesisParentUsed(uint256 index, bool used) external;
    function setLegendParentUsed(uint256 index, bool used) external;
}

// Version 2 of Storefront
contract QUOKKA_KIDS_STOREFRONT is Ownable {
  uint256 public constant DOUBLE_TICKET = 2;
  uint256 public constant TRIPLE_TICKET = 3;

  using Address for address;
  using BytesLib for bytes;
  using ECDSA for bytes32;
  using Strings for uint256;

  address public preorderContract;
  address public mintingContract;
  address public genesisContract;
  address public legendsContract;

  uint public preSaleStart = 1663646400;    
  uint public publicSaleStart = 1663970400;

  uint256 public tokenPrice     = 300000000000000000;
  uint256 public doubleDiscount = 200000000000000000;
  uint256 public tripleDiscount = 300000000000000000;

  address payable public payout = payable(0x6A4813082c2F6598b01698B222c5b1414Fe77eF6);

  address public parentingSigner = 0x3dF6f92097B349f30d31315a7453821f14998f3E;
  address public freemintSigner = 0x3dF6f92097B349f30d31315a7453821f14998f3E;

  mapping(address => uint256) public claimed;

  uint256 public nextId = 1;

  //Declare an Event
  event ParentMint(uint256 id, bool parentsfur);
  event ManyMint(uint256 id, uint256 count);
  event Mint(uint256 id, bool parentsfur);

  function setNextId(uint256 nextId_) public onlyOwner {
    nextId = nextId_;
  }

  function setMintingContract(address mintingContract_) public onlyOwner{
    mintingContract = mintingContract_;
  }

  // exchange preorder tokens
  function setPreorderContract(address preorderContract_) public onlyOwner {
      preorderContract = preorderContract_;
  }

  function setGenesisLegendsContract(address genesis_, address legends_) public onlyOwner {
    genesisContract = genesis_;
    legendsContract = legends_;
  }

  function setSignerAddress(address parentingSigner_, address freemintSigner_) public onlyOwner {
      parentingSigner = parentingSigner_;
      freemintSigner = freemintSigner_;
  }

  function setPrice(uint tokenPrice_) public onlyOwner {
      tokenPrice = tokenPrice_;
  }

  function setPayout(address addr) public onlyOwner {
    payout = payable(addr);
  }

  function release(uint amount) public {
    uint ourBalance = address(this).balance;
    require(ourBalance >= amount, "Must have enough balance to send");
    payout.transfer(amount);
  }

  function setSaleStart(uint preSaleStartTime, uint publicSaleStartTime) public onlyOwner {
      preSaleStart = preSaleStartTime;
      publicSaleStart = publicSaleStartTime;
  }

  function airdrop(address recipient, uint totalMint) public onlyOwner {

    IERC721(mintingContract).mint(recipient, uint256(totalMint));

    for (uint i = 0; i < totalMint; i++) {
      //Emit an event
      emit Mint(nextId, false);
      nextId += 1;
    }
  }

  function whitelistMint(uint index, uint claimAmmt, uint claimTotal, bytes memory signature) payable public {
    require(block.timestamp >= preSaleStart, "Presale has not begun");
    require(claimed[msg.sender] + claimAmmt <= claimTotal, "Already claimed.");
    claimed[msg.sender] += claimAmmt;

    bytes memory encoded = abi.encodePacked(
            index,
            claimTotal, 
            msg.sender);
    
    bytes32 digestreal = keccak256(encoded);

    address claimSigner = digestreal.toEthSignedMessageHash().recover(signature);

    require(claimSigner == freemintSigner, "Invalid Message Signer.");

    IERC721(mintingContract).mint(msg.sender, uint256(claimAmmt));

    for (uint i = 0; i < claimAmmt; i++) {
      //Emit an event
      emit Mint(nextId, false);
      nextId += 1;
    }
  }

  function publicSale(uint totalMint) payable public {
      require(block.timestamp >= publicSaleStart, "Sale has not begun");
      require( msg.value >= totalMint * tokenPrice, "Not enough ETH sent");

      IERC721(mintingContract).mint(msg.sender, uint256(totalMint));

      for (uint i = 0; i < totalMint; i++) {
        //Emit an event
        emit Mint(nextId, false);
        nextId += 1;
      }
  }

  function preorderMint(uint doublePreorders, uint triplePreorders) payable public {
    
    require(block.timestamp >= preSaleStart, "Presale has not begun");

    uint totalMint = doublePreorders + triplePreorders;
    IERC1155 POContract = IERC1155(preorderContract);
    IERC1155Burnable POBurn = IERC1155Burnable(preorderContract);

    uint priceRequired = tokenPrice * totalMint - (doubleDiscount * doublePreorders) -(tripleDiscount * triplePreorders);

    require(msg.value >= priceRequired, "Not enough ETH sent");
    // burn double preorders equal to #
    // check holdingsdoublePreorders);

    if (doublePreorders > 0) {
      require(POContract.balanceOf(_msgSender(), DOUBLE_TICKET) >= doublePreorders, "Need as many preorder tickets as being requested to mint");
      POBurn.burn(_msgSender(), DOUBLE_TICKET, doublePreorders);
    }

    if (triplePreorders > 0) {
      require(POContract.balanceOf(_msgSender(), TRIPLE_TICKET) >= triplePreorders, "Need as many preorder tickets as being requested to mint");
      POBurn.burn(_msgSender(), TRIPLE_TICKET, triplePreorders);
    }

    for (uint i = 0; i < totalMint; i++) {
      //Emit an event
      emit Mint(nextId, false);
      nextId += 1;
    }

    IERC721(mintingContract).mint(_msgSender(), totalMint);
  }

  function parent(bool[] memory tokentypes, uint256[] memory parents, address[] memory owners, bool[] memory parentsfur, bytes memory signature) public {
    // require(mintAllowed, "Minting period has ended");

    bytes memory encoded = abi.encodePacked(msg.sender, tokentypes, owners, parents);
    
    bytes32 digestreal = keccak256(encoded);

    address claimSigner = digestreal.toEthSignedMessageHash().recover(signature);
    require(claimSigner == parentingSigner, "Invalid Message Signer.");
    require(block.timestamp >= preSaleStart, "Presale has not begun");

    require(parents.length == tokentypes.length, "Length of parents and tokentypes must be the same");
    require(parents.length == owners.length, "Length of parents and owners must be the same");

    uint pairs = parents.length / 2;
    require(parentsfur.length == pairs, "Must have a fur choice for each pair");

    // first, verify tokens and mark them as used
    for (uint i = 0; i < parents.length; i++) {
      if (tokentypes[i]) {

        require(IERC721(genesisContract).ownerOf(parents[i]) == owners[i], "Must own genesis token");
        require(IER721ParentTracker(mintingContract).genesisParents(parents[i]) == false, "Token must not already be a parent");
        IER721ParentTracker(mintingContract).setGenesisParentUsed(parents[i], true);

      } else {
        // require(IERC721(legendsContract));
        require(IERC721(legendsContract).ownerOf(parents[i]) == owners[i], "Must own legend token");
        require(IER721ParentTracker(mintingContract).legendParents(parents[i]) == false, "Token must not already be a parent");
        IER721ParentTracker(mintingContract).setLegendParentUsed(parents[i], true);

      }
    }


    // let's mint!
    for (uint i = 0; i < pairs; i++) {
      //Emit an event
      emit Mint(nextId, parentsfur[i]);
      nextId += 1;
    }

    IER721ParentTracker(mintingContract).parentMint(msg.sender, pairs);
  }

}