// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator) internal view returns (bool) {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return address(registry) != address(0) && address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PPAShuttlepass is ERC1155, Ownable {

  uint public constant GOLD = 0;
  uint public constant SILVER = 1;
  uint public constant BRONZE = 2;

  uint public constant MAX_TOKENS = 9890;
  uint public numMinted = 0;

  uint public goldPriceWei = 0.2 ether;
  uint public silverPriceWei = 0.12 ether;
  uint public bronzePriceWei = 0.07 ether;

  // All members of First Buyer whitelist.
  bytes32 public firstBuyersMerkleRoot;

  // All members of OG/Passengers whitelist.
  bytes32 public ogAndPassengersMerkleRoot;

  mapping (address => uint) public sale1NumMinted;
  mapping (address => uint) public sale2NumMinted;
  mapping (address => uint) public publicNumMinted;

  // Whitelist types (which whitelist is the caller on).
  uint public constant FIRST_BUYERS = 1;
  uint public constant OG_PASSENGERS = 2;

  // Sale state:
  // 0: Closed
  // 1: Open to First Buyer whitelist. Each address can mint 1.
  // 2: Open to First Buyer + OG/Passenger whitelists. Each address can mint 3.
  // 3: Open to Public. Each address can mint 5.
  uint256 public saleState = 0;

  string private _contractUri = "https://assets.jointheppa.com/shuttlepasses/metadata/contract.json";

  string public name = "PPA Shuttlepasses";
  string public symbol = "PPA";

  constructor() public ERC1155("https://assets.jointheppa.com/shuttlepasses/metadata/{id}.json") {}

  function mint(uint passType, uint amount) public payable {
    require(saleState == 3, "Public mint is not open");
    /**
    * Sale 3:
    * Public. 5 per address.
    */
    publicNumMinted[msg.sender] = publicNumMinted[msg.sender] + amount;
    require(publicNumMinted[msg.sender] <= 5, "Cannot mint more than 5 per address in this phase");
    _internalMint(passType, amount);
  }

  function earlyMint(uint passType, uint amount, uint whitelistType, bytes32[] calldata merkleProof) public payable {
    require(saleState > 0, "Sale is not open");
    if (saleState == 1) {
      /**
       * Sale 1: 
       * First Buyers only. 1 per address.
       */
      sale1NumMinted[msg.sender] = sale1NumMinted[msg.sender] + amount;
      require(sale1NumMinted[msg.sender] == 1, "Cannot mint more than 1 per address in this phase.");
      
      require(whitelistType == FIRST_BUYERS, "Must use First Buyers whitelist");
      verifyMerkle(msg.sender, merkleProof, FIRST_BUYERS);

    } else if (saleState == 2) {
      /**
       * Sale 2: 
       * First Buyers or OG/Passengers. 3 per address.
       */
      sale2NumMinted[msg.sender] = sale2NumMinted[msg.sender] + amount;
      require(sale2NumMinted[msg.sender] <= 3, "Cannot mint more than 3 per address in this phase.");

      verifyMerkle(msg.sender, merkleProof, whitelistType);
      
    } else {
      revert("The early sale is over. Use the public mint function instead.");
    }

    _internalMint(passType, amount);
  }

  function _internalMint(uint passType, uint amount) internal {
    incrementNumMinted(amount);
    if (passType == GOLD) {
      checkPayment(goldPriceWei * amount);
    }
    else if (passType == SILVER) {
      checkPayment(silverPriceWei * amount);
    } 
    else if (passType == BRONZE) {
      checkPayment(bronzePriceWei * amount);
    } else {
      revert("Invalid pass type");
    }
    _mint(msg.sender, passType, amount, "");
  }

  function ownerMint(uint passType, uint amount) public onlyOwner {
    incrementNumMinted(amount);
    require(passType == GOLD || passType == SILVER || passType == BRONZE, "Invalid passType");
    _mint(msg.sender, passType, amount, "");
  }

  function incrementNumMinted(uint amount) internal {
    numMinted = numMinted + amount;
    require(numMinted <= MAX_TOKENS, "Minting would exceed max tokens");
  }

  function verifyMerkle(address addr, bytes32[] calldata proof, uint whitelistType) internal view {
    require(isOnWhitelist(addr, proof, whitelistType), "User is not on whitelist");
  }

  function isOnWhitelist(address addr, bytes32[] calldata proof, uint whitelistType) public view returns (bool) {
    bytes32 root;
    if (whitelistType == FIRST_BUYERS) {
      root = firstBuyersMerkleRoot;
    } else if (whitelistType == OG_PASSENGERS) {
      root = ogAndPassengersMerkleRoot;
    } else {
      revert("Invalid whitelistType, must be 1 or 2");
    }
    bytes32 leaf = keccak256(abi.encodePacked(addr));
    return MerkleProof.verify(proof, root, leaf);
  }

  function checkPayment(uint amountRequired) internal {
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function setFirstBuyersMerkleRoot(bytes32 newMerkle) public onlyOwner {
    firstBuyersMerkleRoot = newMerkle;
  }

  function setOgAndPassengersMerkleRoot(bytes32 newMerkle) public onlyOwner {
    ogAndPassengersMerkleRoot = newMerkle;
  }

  function setSaleState(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 3, "Invalid state");
    saleState = newState;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setBaseUri(string calldata newUri) public onlyOwner {
    _setURI(newUri);
  }

  function setContractUri(string calldata newUri) public onlyOwner {
    _contractUri = newUri;
  }

  function setGoldPriceWei(uint newPrice) public onlyOwner {
    goldPriceWei = newPrice;
  }

  function setSilverPriceWei(uint newPrice) public onlyOwner {
    silverPriceWei = newPrice;
  }

  function setBronzePriceWei(uint newPrice) public onlyOwner {
    bronzePriceWei = newPrice;
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    return OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || super.isApprovedForAll(owner, operator);
  }

  function contractURI() public view returns (string memory) {
    return _contractUri;
  }
}