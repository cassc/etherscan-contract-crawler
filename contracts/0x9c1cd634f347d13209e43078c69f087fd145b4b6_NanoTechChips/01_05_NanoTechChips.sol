// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solmate/src/auth/Owned.sol";
import "solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IStardust {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract NanoTechChips is ERC1155, Owned {
  uint256 public constant PRICE = 250 ether;

  address private verifier;
  string public baseURI =
    "ipfs://QmRHwfoqVzWmqWQLjvgtYp9iQYC6c379yPCB1Qq9ANAaWP/?";

  bool public paused = false;

  mapping(address => uint256) public mintedByWallet;

  IStardust private stardustContract;

  constructor(address _stardustContract) Owned(msg.sender) {
    stardustContract = IStardust(_stardustContract);
  }

  function mintWithClaimable(
    uint256 _amount,
    uint256 _count,
    bytes calldata _signature
  ) external {
    require(!paused, "Minting stopped");

    address signer = _recoverWallet(msg.sender, _count, _signature);

    require(signer == verifier, "Unverified transaction");
    require(mintedByWallet[msg.sender] < _count, "Invalid mint count");

    mintedByWallet[msg.sender] = _count;

    _mint(msg.sender, 0, _amount, "");
  }

  function mintWithClaimed(uint256 _amount) external {
    require(!paused, "Minting stopped");

    stardustContract.transferFrom(
      msg.sender,
      address(stardustContract),
      PRICE * _amount
    );

    _mint(msg.sender, 0, _amount, "");
  }

  function burn(address _from, uint256 _amount) external {
    require(
      msg.sender == _from || isApprovedForAll[_from][msg.sender],
      "Not authorized"
    );

    _burn(_from, 0, _amount);
  }

  function mintBatch(address[] calldata _to, uint256[] calldata _amounts)
    external
    onlyOwner
  {
    require(_to.length == _amounts.length, "To and amounts length must match");

    for (uint256 i = 0; i < _to.length; ++i) {
      _mint(_to[i], 0, _amounts[i], "");
    }
  }

  function uri(uint256 _id)
    public
    view
    virtual
    override(ERC1155)
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(_id)));
  }

  function _recoverWallet(
    address _wallet,
    uint256 _amount,
    bytes memory _signature
  ) internal pure returns (address) {
    return
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(_wallet, _amount))
        ),
        _signature
      );
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function setVerifier(address _newVerifier) external onlyOwner {
    verifier = _newVerifier;
  }
}