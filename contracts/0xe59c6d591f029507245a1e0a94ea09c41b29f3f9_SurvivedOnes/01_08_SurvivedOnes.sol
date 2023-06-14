// SPDX-License-Identifier: MIT

//     ▄▀▀▀▀▄  ▄▀▀▄ ▄▀▀▄  ▄▀▀▄▀▀▀▄  ▄▀▀▄ ▄▀▀▄  ▄▀▀█▀▄   ▄▀▀▄ ▄▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀█▄▄
//    █ █   ▐ █   █    █ █   █   █ █   █    █ █   █  █ █   █    █ ▐  ▄▀   ▐ █ ▄▀   █
//       ▀▄   ▐  █    █  ▐  █▀▀█▀  ▐  █    █  ▐   █  ▐ ▐  █    █    █▄▄▄▄▄  ▐ █    █
//    ▀▄   █    █    █    ▄▀    █     █   ▄▀      █       █   ▄▀    █    ▌    █    █
//     █▀▀▀      ▀▄▄▄▄▀  █     █       ▀▄▀     ▄▀▀▀▀▀▄     ▀▄▀     ▄▀▄▄▄▄    ▄▀▄▄▄▄▀
//     ▐                 ▐     ▐              █       █            █    ▐   █     ▐
//                                            ▐       ▐            ▐        ▐
//     ▄▀▀▀▀▄   ▄▀▀▄ ▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▀▀▄
//    █      █ █  █ █ █ ▐  ▄▀   ▐ █ █   ▐
//    █      █ ▐  █  ▀█   █▄▄▄▄▄     ▀▄
//    ▀▄    ▄▀   █   █    █    ▌  ▀▄   █
//      ▀▀▀▀   ▄▀   █    ▄▀▄▄▄▄    █▀▀▀
//             █    ▐    █    ▐    ▐
//             ▐         ▐

pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error PriceError(string message);
error LogicError(string message);
error InvalidSignature(string message);
error ReceiverMismatch(string message);

contract SurvivedOnes is ERC721A, Ownable {
  using StringsUpgradeable for uint256;
  using ECDSA for bytes32;

  mapping(address => bool) private FREE_MINT_USAGE_MAP;

  uint256 public constant MAX_SUPPLY = 400;
  uint256 public constant TEAM_SUPPLY = 20;
  uint256 public constant MAX_TOTAL_SUPPLY = MAX_SUPPLY + TEAM_SUPPLY;
  uint256 public constant FREE_MINT_PER_ALLOWED_WALLET = 5;
  uint256 public DOSE_PRICE = 0.005 ether;

  uint256 public SURVIVE_CHANCE = 10;
  uint256 public FREE_SURVIVE_CHANCE = 4;
  uint256 public USED_TEAM_SUPPLY = 0;
  uint256 public DEAD_COUNT = 0;
  int256 public MINT_STAGE = -1;

  string public TOKEN_BASE_URL = "ipfs://tba";
  string public TOKEN_URL_SUFFIX = ".json";
  string public NOT_REVEALED_URL =
    "ipfs://QmRsreuj89gTnbK3AnQEy7rjTg93LVQKngEXTAYpJKvR1W";

  address public WITHDRAW_ADDRESS = 0xdf058F9915ADf447695eE01cb6F0A896D4C0b7a6; // @TODO: change withdraw wallet
  address public DEAD_CONTRACT;
  bool public IS_REVEALED = false;

  address private _signerAddress;

  constructor(address signerAddress_) ERC721A("SurvivedOnes", "SONE") {
    _signerAddress = signerAddress_;
  }

  function gangBang(uint256 _count) external onlyOwner {
    if (USED_TEAM_SUPPLY + _count > TEAM_SUPPLY) {
      revert LogicError("team_supply_exceeded");
    }
    USED_TEAM_SUPPLY += _count;
    _safeMint(msg.sender, _count);
  }

  function isUsedFreeMint(address _receiverAddress) public view returns (bool) {
    return FREE_MINT_USAGE_MAP[_receiverAddress];
  }

  modifier overCumProtection() {
    uint256 REMAINING_TEAM_SUPPLY = TEAM_SUPPLY - USED_TEAM_SUPPLY;
    uint256 remainingSupply = MAX_TOTAL_SUPPLY -
      REMAINING_TEAM_SUPPLY -
      totalSupply();

    if (remainingSupply == 0) {
      revert LogicError("sold_out");
    }
    _;
  }

  function cum(
    uint256 dose,
    uint256 randSeed,
    bool freeMintAllowed,
    bytes calldata signature
  ) external payable overCumProtection returns (uint256) {
    require(msg.sender == tx.origin, "no_bots");
    if (MINT_STAGE < 1) {
      revert LogicError("please_foreplay_first");
    }
    if (dose < 1 || dose > 100) {
      revert LogicError("wrong_dose");
    }
    if (
      verifySignature(msg.sender, randSeed, freeMintAllowed, signature) != true
    ) {
      revert InvalidSignature("wrong_signature");
    }

    uint256 freeMintCount = 0;

    if (freeMintAllowed == true) {
      if (FREE_MINT_USAGE_MAP[msg.sender] != true) {
        freeMintCount = FREE_MINT_PER_ALLOWED_WALLET;
        FREE_MINT_USAGE_MAP[msg.sender] = true;
      }
    }

    if (msg.value < (dose - freeMintCount) * DOSE_PRICE) {
      revert PriceError("not_enough_money");
    }

    uint256 totalDeath = 0;
    uint256 totalSurvived = 0;

    for (uint256 i = 0; i < dose; i += 1) {
      uint256 rand = random(signature, randSeed + i, 100);
      if (totalSupply() + (TEAM_SUPPLY - USED_TEAM_SUPPLY) > MAX_TOTAL_SUPPLY) {
        break;
      }
      uint256 tempSurviveChange = i < freeMintCount
        ? FREE_SURVIVE_CHANCE
        : SURVIVE_CHANCE;
      if (rand < tempSurviveChange) {
        totalSurvived += 1;
      } else {
        totalDeath += 1;
      }
    }

    DeadProxy proxy = DeadProxy(DEAD_CONTRACT);

    if (totalDeath > 0) {
      proxy.killSperm(msg.sender, totalDeath);
      DEAD_COUNT += totalDeath;
    }
    if (totalSurvived < 1) {
      return 0;
    }

    if (
      totalSupply() + (TEAM_SUPPLY - USED_TEAM_SUPPLY) + totalSurvived >
      MAX_TOTAL_SUPPLY
    ) {
      uint256 tempRemainingSupply = MAX_TOTAL_SUPPLY -
        (TEAM_SUPPLY - USED_TEAM_SUPPLY) -
        totalSupply();
      _safeMint(msg.sender, tempRemainingSupply);
      proxy.killSperm(msg.sender, totalSurvived - tempRemainingSupply);
      DEAD_COUNT += totalSurvived - tempRemainingSupply;
      return tempRemainingSupply;
    }
    _safeMint(msg.sender, totalSurvived);
    return totalSurvived;
  }

  // - internal logic

  function random(
    bytes memory signatureSeed,
    uint256 randSeed,
    uint8 max
  ) private view returns (uint8) {
    return
      uint8(
        uint256(
          keccak256(
            abi.encodePacked(
              block.timestamp,
              block.difficulty,
              signatureSeed,
              randSeed,
              _nextTokenId()
            )
          )
        ) % max
      );
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return TOKEN_BASE_URL;
  }

  function _suffix() internal view virtual returns (string memory) {
    return TOKEN_URL_SUFFIX;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if (!IS_REVEALED) {
      return NOT_REVEALED_URL;
    }
    string memory baseURI = _baseURI();
    string memory suffix = _suffix();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), suffix))
        : "";
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    private
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    private
    pure
    returns (
      bytes32 r,
      bytes32 s,
      uint8 v
    )
  {
    if (sig.length != 65) {
      revert InvalidSignature("Signature length is not 65 bytes");
    }
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }

  // - management only functions
  function setDeadContract(address _deadContract) external onlyOwner {
    DEAD_CONTRACT = _deadContract;
  }

  function setSurviveChance(uint8 _surviveChance) external onlyOwner {
    SURVIVE_CHANCE = _surviveChance;
  }

  function setFreeSurviveChance(uint8 _surviveChance) external onlyOwner {
    FREE_SURVIVE_CHANCE = _surviveChance;
  }

  function setDosePrice(uint256 _dosePrice) external onlyOwner {
    DOSE_PRICE = _dosePrice;
  }

  function setMintStage(int256 _mintStage) external onlyOwner {
    require(_mintStage < 3, "Unsupported mint stage");
    MINT_STAGE = _mintStage;
  }

  function setTokenBaseUrl(string memory _tokenBaseUrl) public onlyOwner {
    TOKEN_BASE_URL = _tokenBaseUrl;
  }

  function setTokenSuffix(string memory _tokenUrlSuffix) public onlyOwner {
    TOKEN_URL_SUFFIX = _tokenUrlSuffix;
  }

  function setIsRevealed(bool status) public onlyOwner {
    IS_REVEALED = status;
  }

  function setNotRevealedUrl(string memory _notRevealedUrl) public onlyOwner {
    NOT_REVEALED_URL = _notRevealedUrl;
  }

  function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
    WITHDRAW_ADDRESS = _withdrawAddress;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    _withdraw(WITHDRAW_ADDRESS, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  function getMessageHash(
    address _receiverAddress,
    uint256 _randSeed,
    bool _freeMintAllowed
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(_receiverAddress, _randSeed, _freeMintAllowed)
      );
  }

  function verifySignature(
    address _receiverAddress,
    uint256 _randSeed,
    bool _freeMintAllowed,
    bytes memory signature
  ) private view returns (bool) {
    bytes32 messageHash = getMessageHash(
      _receiverAddress,
      _randSeed,
      _freeMintAllowed
    );
    if (_receiverAddress != msg.sender) {
      revert InvalidSignature("receiver_mismatch_wrong_signature");
    }
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    return recoverSigner(ethSignedMessageHash, signature) == _signerAddress;
  }

  function getEthSignedMessageHash(bytes32 _messageHash)
    private
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
  }
}

// for calling erc721 contracts
abstract contract DeadProxy {
  function killSperm(address to, uint256 count) public virtual;
}