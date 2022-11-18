// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BulkSender is Ownable {
  // Events
  event WithdrawEther(address indexed account, uint256 amount);
  event WithdrawToken(address indexed token, address indexed account, uint256 amount);

  event RegisterVIP(address indexed account);
  event RemoveFromVIPList(address[] indexed adresses);
  event AddToVipList(address[] indexed adresses);

  event SetReceiverAddress(address indexed Address);

  event SetVipFee(uint256 newVipFee);
  event SetTxFee(uint256 newTransactionFee);

  event SetMaxAdresses(uint maxAddresses);

  event EthSendSameValue(address indexed sender, address payable[] indexed receiver, uint256 value);
  event EthSendDifferentValue(
    address indexed sender,
    address[] indexed receivers,
    uint256[] values
  );
  event ERC20BulksendSameValue(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256 value,
    uint256 sendAmount
  );
  event ERC20BulksendDiffValue(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] values,
    uint256 sendAmount
  );
  event ERC721Bulksend(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] values,
    uint256 sendAmount
  );
  event ERC1155Bulksend(
    address indexed sender,
    address indexed tokenAddress,
    address[] indexed receivers,
    uint256[] tokenId,
    uint256[] amount
  );

  // Variables
  address payable public receiverAddress;
  uint256 public txFee = 0.01 ether;
  uint256 public VIPFee = 1 ether;
  uint public maxAddresses = 255;

  bool internal locked;

  // Modifiers
  modifier noReentrant() {
    require(!locked, "No re-entrancy");
    locked = true;
    _;
    locked = false;
  }

  // Functions

  // VIP List
  mapping(address => bool) public vipList;

  // Withdraw Ether
  function withdrawEth() external onlyOwner noReentrant {
    address _receiverAddress = getReceiverAddress();
    uint256 balance = address(this).balance;
    (bool success, ) = _receiverAddress.call{value: balance}("");
    require(success, "Bulksender: failed to send ETH");
    emit WithdrawEther(_receiverAddress, balance);
  }

  // Withdraw ERC20
  function withdrawToken(address _tokenAddress, address _receiverAddress)
    external
    onlyOwner
    noReentrant
  {
    IERC20 token = IERC20(_tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    token.transfer(_receiverAddress, balance);

    emit WithdrawToken(_tokenAddress, _receiverAddress, balance);
  }

  // Register VIP
  function registerVIP() external payable {
    require(vipList[msg.sender] == false, "Bulksender: already vip");
    require(msg.value >= VIPFee, "Bulksender: invalid vip fee");

    address _receiverAddress = getReceiverAddress();
    (bool success, ) = _receiverAddress.call{value: msg.value}("");
    require(success, "Bulksender: failed to send ETH");

    vipList[msg.sender] = true;

    emit RegisterVIP(msg.sender);
  }

  // VIP list
  function addToVIPList(address[] calldata _vipList) external onlyOwner {
    uint256 len = _vipList.length;

    for (uint256 i = 0; i < len; ) {
      vipList[_vipList[i]] = true;
      unchecked {
        ++i;
      }
    }

    emit AddToVipList(_vipList);
  }

  // Remove address from VIP List by Owner
  function removeFromVIPList(address[] calldata _vipList) external onlyOwner {
    uint256 len = _vipList.length;

    for (uint256 i = 0; i < len; ) {
      vipList[_vipList[i]] = false;
      unchecked {
        ++i;
      }
    }

    emit RemoveFromVIPList(_vipList);
  }

  // Check isVIP
  function isVIP(address _addr) public view returns (bool) {
    return _addr == owner() || vipList[_addr];
  }

  // Set receiver address
  function setReceiverAddress(address payable _addr) external onlyOwner {
    require(_addr != address(0), "Bulksender: zero address");
    receiverAddress = _addr;
    emit SetReceiverAddress(_addr);
  }

  // Get receiver address
  function getReceiverAddress() public view returns (address) {
    if (receiverAddress == address(0)) {
      return owner();
    }

    return receiverAddress;
  }

  // Set vip fee
  function setVIPFee(uint256 _fee) external onlyOwner {
    VIPFee = _fee;
    emit SetVipFee(_fee);
  }

  // Set tx fee
  function setTxFee(uint256 _fee) external onlyOwner {
    txFee = _fee;
    emit SetTxFee(_fee);
  }

  // Set max addresses
  function setMaxAdresses(uint _maxAddresses) external onlyOwner {
    require(_maxAddresses > 0, "Bulksender: zero maxAddresses");
    maxAddresses = _maxAddresses;
    emit SetMaxAdresses(_maxAddresses);
  }

  // Sum total values from an array
  function _sumTotalValues(uint256[] calldata _value) internal pure returns (uint256) {
    uint256 sum = 0;
    uint256 len = _value.length;
    for (uint256 i = 0; i < len; ) {
      sum += _value[i];
      unchecked {
        ++i;
      }
    }

    return sum;
  }

  // Send ETH (same value)
  function bulkSendETHWithSameValue(address payable[] calldata _to, uint256 _value) external payable {
    uint256 sendAmount = (_to.length) * _value;
    uint256 remainingValue = msg.value;

    bool vip = isVIP(msg.sender);

    if (vip) {
      require(remainingValue >= sendAmount, "Bulksender: insufficient ETH");
    } else {
      require(remainingValue >= sendAmount + txFee, "Bulksender: invalid txFee");
    }
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 len = _to.length;

    for (uint256 i = 0; i < len; ) {
      assert(remainingValue >= _value);
      remainingValue -= _value;

      (bool success, ) = _to[i].call{value: _value}("");
      require(success, "Bulksender: failed to send ETH");

      unchecked {
        i++;
      }
    }

    emit EthSendSameValue(msg.sender, _to, _value);
  }

  // Send ETH (different value)
  function bulkSendETHWithDifferentValue(address[] calldata _to, uint256[] calldata _value)
    external payable
  {
    uint256 sendAmount = _sumTotalValues(_value);
    uint256 remainingValue = msg.value;

    bool vip = isVIP(msg.sender);
    if (vip) {
      require(remainingValue >= sendAmount, "Bulksender: invalid eth send");
    } else {
      require(remainingValue >= sendAmount + txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      assert(remainingValue >= _value[i]);
      remainingValue -= _value[i];

      (bool success, ) = _to[i].call{value: _value[i]}("");
      require(success, "Bulksender: failed to send ETH");

      unchecked {
        ++i;
      }
    }
    emit EthSendDifferentValue(msg.sender, _to, _value);
  }

  // Send ERC20 (same value)
  function bulkSendERC20SameValue(
    address _tokenAddress,
    address[] calldata _to,
    uint256 _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);
    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    address from = msg.sender;
    uint256 sendAmount = _to.length * _value;

    IERC20 token = IERC20(_tokenAddress);
    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(from, _to[i], _value);
      unchecked {
        ++i;
      }
    }

    emit ERC20BulksendSameValue(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  // Send ERC20 (diff value)
  function bulkSendERC20DiffValue(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);

    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 sendAmount = _sumTotalValues(_value);
    IERC20 token = IERC20(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(msg.sender, _to[i], _value[i]);
      unchecked {
        ++i;
      }
    }
    emit ERC20BulksendDiffValue(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  //Send ERC721 tokens
  function bulkSendERC721(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _value
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);

    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _value.length, "Bulksender: diff arrays length");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    uint256 sendAmount = _sumTotalValues(_value);
    IERC721 token = IERC721(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.transferFrom(msg.sender, _to[i], _value[i]);
      unchecked {
        ++i;
      }
    }
    emit ERC721Bulksend(msg.sender, _tokenAddress, _to, _value, sendAmount);
  }

  //Send ERC1155 tokens
  function bulkSendERC1155(
    address _tokenAddress,
    address[] calldata _to,
    uint256[] calldata _tokenId,
    uint256[] calldata _amount
  ) external payable {
    uint256 sendValue = msg.value;
    bool vip = isVIP(msg.sender);
    if (!vip) {
      require(sendValue >= txFee, "Bulksender: invalid txFee");
    }

    require(_to.length == _tokenId.length, "Bulksender: different length of inputs");
    require(_to.length <= maxAddresses, "Bulksender: max number of addresses");

    IERC1155 token = IERC1155(_tokenAddress);

    uint256 len = _to.length;
    for (uint256 i = 0; i < len; ) {
      token.safeTransferFrom(msg.sender, _to[i], _tokenId[i], _amount[i], "0x");
      unchecked {
        ++i;
      }
    }

    emit ERC1155Bulksend(msg.sender, _tokenAddress, _to, _tokenId, _amount);
  }
}