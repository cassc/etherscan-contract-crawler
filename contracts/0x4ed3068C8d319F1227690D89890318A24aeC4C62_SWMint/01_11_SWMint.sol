//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ITrunkNFT.sol";
import "./interfaces/IBaleNFT.sol";

contract SWMint is ReentrancyGuard, Ownable {
  using ECDSA for bytes32;

  uint256 public MINT_PRICE = 0.197 ether;
  IERC721 public passes;
  ITrunkNFT public trunkNFT;
  IBaleNFT public baleNFT;
  string public tokenUriBase;
  address public signer;

  mapping(uint256 => bool) public tokensMinted;
  mapping(uint256 => bool) public tokensClaimed;
  mapping(address => bool) public walletsMinted;

  bool public MINT_ENABLED = false;
  bool public CLAIM_ENABLED = false;

  uint256 public TRUNK_MINT_SUPPLY = 1500;
  uint256 public TRUNK_CLAIM_SUPPLY = TRUNK_MINT_SUPPLY + 1600;
  uint256 public BALE_SUPPLY = 100;

  event EtherWithdrawn(address _to, uint256 _amount);

  constructor(
    IERC721 _passes,
    ITrunkNFT _trunkNFT,
    IBaleNFT _baleNFT,
    address _signer
  ) {
    passes = _passes;
    trunkNFT = _trunkNFT;
    baleNFT = _baleNFT;
    signer = _signer;
  }

  modifier noContract() {
    require(msg.sender == tx.origin, "Contract not allowed");
    _;
  }

  function setTrunkNFT(ITrunkNFT _address) external onlyOwner {
    trunkNFT = _address;
  }

  function setBaleNFT(IBaleNFT _adderss) external onlyOwner {
    baleNFT = _adderss;
  }

  function setPassesAddress(IERC721 _address) external onlyOwner {
    passes = _address;
  }

  function setMintPrice(uint256 _price) external onlyOwner {
    MINT_PRICE = _price;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setClaimEnabled(bool _bool) external onlyOwner {
    CLAIM_ENABLED = _bool;
  }

  function setMintEnabled(bool _bool) external onlyOwner {
    MINT_ENABLED = _bool;
  }

  function setTrunkMintSupply(uint256 _supply) external onlyOwner {
    TRUNK_MINT_SUPPLY = _supply;
  }

  function setTrunkClaimSupply(uint256 _supply) external onlyOwner {
    TRUNK_CLAIM_SUPPLY = _supply;
  }

  function setBaleSupply(uint256 _supply) external onlyOwner {
    BALE_SUPPLY = _supply;
  }

  function getSupply() public view returns (uint256, uint256) {
    return (baleNFT.totalSupply(), trunkNFT.totalSupply());
  }

  function _verify(
    bytes memory _encoded,
    bytes memory _signature,
    address _signer
  ) public pure returns (bool) {
    return keccak256(_encoded).toEthSignedMessageHash().recover(_signature) == _signer;
  }

  function mint(bytes memory _encoded, bytes memory _signature) external payable nonReentrant noContract {
    // fail if mint not open
    require(MINT_ENABLED, "mint is not open");
    // get values out of ABI encoded string
    (address wallet, address contractAddress, bool general, uint256[] memory tokens) = abi.decode(
      _encoded,
      (address, address, bool, uint256[])
    );
    // fail if wallet sending tx doesn't match wallet token is for
    require(wallet == msg.sender, "invalid wallet");
    // fail if this contract address doesn't match contract address token is for
    require(contractAddress == address(this), "invalid contract");
    // fail if token cannot be verified as signed by signer
    require(_verify(_encoded, _signature, signer), "invalid signature");
    if (general == true) {
      // fail it sold out
      require(trunkNFT.totalSupply() + 1 <= TRUNK_MINT_SUPPLY, "mint is sold out");
      // fail if wrong eth amount sent
      require(MINT_PRICE == msg.value, "wrong ether amount sent");
      // fail if wallet has already minted
      require(!walletsMinted[msg.sender], "already minted");
      walletsMinted[msg.sender] = true;
      trunkNFT.mint(msg.sender, 1);
      return;
    } else {
      // fail if not enough supply left
      require(trunkNFT.totalSupply() + tokens.length <= TRUNK_MINT_SUPPLY, "mint is sold out");
      // fail if wrong eth amount sent
      require(MINT_PRICE * tokens.length == msg.value, "wrong ether amount sent");
      unchecked {
        for (uint256 i = 0; i < tokens.length; i++) {
          // for each token, fail if token not owned by wallet
          require(passes.ownerOf(tokens[i]) == msg.sender, "you do not own this token");
          // for each token, fail if token has already minted
          require(!tokensMinted[tokens[i]], "token has already minted");
          // set tokens to minted
          tokensMinted[tokens[i]] = true;
        }
      }
      trunkNFT.mint(msg.sender, tokens.length);
      return;
    }
  }

  function claim(bytes memory _encoded, bytes memory _signature) external nonReentrant noContract {
    // fail if claim is not open
    require(CLAIM_ENABLED, "claim is not open");
    (address wallet, address contractAddress, uint256[] memory tokens, uint256 amountBales, uint256 amountTrunks) = abi
      .decode(_encoded, (address, address, uint256[], uint256, uint256));
    // fail if wallet sending tx doesn't match wallet token is for
    require(wallet == msg.sender, "invalid wallet");
    // fail if this contract address doesn't match contract address token is for
    require(contractAddress == address(this), "invalid contract");
    // fail if token cannot be verified as signed by signer
    require(_verify(_encoded, _signature, signer), "invalid signature");
    // fail if sold out of bales
    require(baleNFT.totalSupply() + amountBales <= BALE_SUPPLY, "all bales have been claimed");
    // fail if sold out of trunks
    require(trunkNFT.totalSupply() + amountTrunks <= TRUNK_CLAIM_SUPPLY, "all trunks have been claimed");
    unchecked {
      for (uint256 i = 0; i < tokens.length; i++) {
        // for each token, fail if token not owned by wallet
        require(passes.ownerOf(tokens[i]) == msg.sender, "you do not own this token");
        // for each token, fail if token has already minted
        require(!tokensClaimed[tokens[i]], "token has already claimed");
        // set tokens to minted
        tokensClaimed[tokens[i]] = true;
      }
    }
    if (amountBales > 0) baleNFT.mint(msg.sender, amountBales);
    trunkNFT.mint(msg.sender, amountTrunks);
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAll(address recipient) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(recipient).transfer(balance);
    emit EtherWithdrawn(recipient, balance);
  }

  /* @dev: Allows for withdrawal of Ether
   * @param: The recipient to withdraw to
   */
  function withdrawAllViaCall(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = _to.call{value: balance}("");
    require(sent, "Failed to send Ether");
    emit EtherWithdrawn(_to, balance);
  }
}