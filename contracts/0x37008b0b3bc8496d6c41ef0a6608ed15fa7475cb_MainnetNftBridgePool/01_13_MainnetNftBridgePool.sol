// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IRainiCard.sol";
import "../tokens/IRainiCustomNFT.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface INftStakingPool {
  function getTokenStaminaTotal(uint256 _tokenId, address _nftContractAddress) external view returns (uint32 stamina);
  function setTokenStaminaTotal(uint32 _stamina, uint256 _tokenId, address _nftContractAddress) external;
}

contract MainnetNftBridgePool is IERC721Receiver, IERC1155Receiver, AccessControl, ReentrancyGuard {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  event CardsDeposited(
    uint256 nftContractId,
    address indexed spender,
    address recipient,
    uint256 amount,
    uint256 requestId,
    uint128 cardId,
    uint32 level,
    uint32 number,
    uint32 stamina,
    bytes1 mintedContractChar,
    bytes state
  );

  event EthWithdrawn(uint256 amount);
  event AutoWithdrawFeeSet(bool autoWithdraw);
  event ConfigSet(address cardToken, address nftV1Token, address nftV2Token);
  event TreasuryAddressSet(address treasuryAddress);
  event FeesSet(uint256 card, uint256 nftV1, uint256 nftV2);
  event ItemFeeSet(uint256 card, uint256 nftV1, uint256 nftV2);

  event CardsWithdrawn(uint256 nftContractId, address indexed owner, uint256 requestId, uint256 cardId, uint256 amount);

  mapping(uint256 => address) public nftContracts;
  mapping(uint256 => bool) public hasSubcontracts;

  // contractId => cardId => bool
  mapping(uint256 => mapping(uint256 => bool)) public cardDisabled;

  // _contractId => _cardId => _cardLevel => _mintedContractChar => uint256 _number
  mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(bytes1 => mapping(uint256 => uint256))))) public heldTokens;

  uint256 public baseFee;
  uint256 public stateUpdateFee;
  uint256 public staminaUpdateFee;
  uint256 public gasPrice;
  mapping(uint256 => uint256) public itemFee;

  uint256 private requestId;
  bool    private autoWithdrawFee;
  address private treasuryAddress;

  address public nftStakingPoolAddress;

  mapping(uint256 => bool) requestWithdrawn;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "MainnetNftBridgePool: caller is not a minter");
    _;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MainnetNftBridgePool: caller is not an owner");
    _;
  }

  function setFees(uint256  _baseFee, uint256 _stateUpdateFee, uint256 _staminaUpdateFee, uint256[] calldata _contractId, uint256[] calldata  _itemFee)
    external onlyOwner {
      baseFee = _baseFee;
      stateUpdateFee = _stateUpdateFee;
      staminaUpdateFee = _staminaUpdateFee;

      for (uint256 i; i < _contractId.length; i++) {
        itemFee[_contractId[i]] = _itemFee[i];
      }
  }

  function setGasPrice(uint256 _gasPrice) 
      external {
        require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'no access');
        gasPrice = _gasPrice;
  }

  function setContracts(uint256[] calldata _contractId, address[] calldata _contractAddress, bool[] calldata _hasSubcontracts)
    external onlyOwner {
      for (uint256 i; i < _contractId.length; i++) {
        nftContracts[_contractId[i]] = _contractAddress[i];
        hasSubcontracts[_contractId[i]] = _hasSubcontracts[i];
      }
  }

  function setDisabledCards(uint256[] calldata _contractId, uint256[] calldata _ids, bool[] calldata _disabled) 
    external onlyOwner {
      for (uint256 i; i < _ids.length; i++) {
        cardDisabled[_contractId[i]][_ids[i]] = _disabled[i];
      }
  }

  function setAutoWithdrawFee(bool _autoWithdrawFee)
    external onlyOwner {
      autoWithdrawFee = _autoWithdrawFee;
      emit AutoWithdrawFeeSet(autoWithdrawFee);
  }

  function setTreasuryAddress(address _treasuryAddress)
    external onlyOwner {
      treasuryAddress = _treasuryAddress;
      emit TreasuryAddressSet(_treasuryAddress);
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function getSubContractTokenState(address _token, uint256 _cardId, uint256 _tokenId) 
    internal view returns(bytes memory) {
      (,,,,,,,address subContract) = IRainiCard(_token).cards(_cardId);
          
      if (subContract != address(0)) {
        return IRainiCustomNFT(subContract).getTokenState(_tokenId);
      }

      return '';
  }

  function handleFeesWithdraw(uint256 _fee, uint256 _refund) internal {
    if (_refund > 0) {
      (bool refundSuccess, ) = _msgSender().call{ value: _refund }("");
      require(refundSuccess, "MainnetNftBridgePool: refund transfer failed");
    }

    if (autoWithdrawFee) {
      (bool withdrawSuccess, ) = treasuryAddress.call{ value: _fee }("");
      require(withdrawSuccess, "MainnetNftBridgePool: withdraw transfer failed");
    }
  }

  function updateSubContractState(address _token, uint256 _cardId, uint256 _tokenId, bytes calldata state) internal {
    if (state.length == 0) return;

    (,,,,,,,address subContract) = IRainiCard(_token).cards(_cardId);
    uint256[] memory ids = new uint256[](1);
    bytes[] memory states = new bytes[](1);
    ids[0] = _tokenId;
    states[0] = state;
    
    if (subContract != address(0)) {
      IRainiCustomNFT(subContract).setTokenStates(ids, states);
    }
  }

  function updateStamina(address _token, uint256 _tokenId, uint32 _stamina) internal {
    if (_stamina == 0 || nftStakingPoolAddress == address(0)) return;

    INftStakingPool(nftStakingPoolAddress).setTokenStaminaTotal(_stamina, _tokenId, _token);
  }

  struct DepositVars {
    uint256 fee;
    uint256 requestId;
  }

  function deposit(address _recipient, uint256[] calldata _contractId, uint256[] calldata _tokenIds, uint256[] calldata _amounts) 
    external payable nonReentrant {
      require(_tokenIds.length == _amounts.length, "MainnetNftBridgePool: input arrays not equal");

      DepositVars memory _locals =  DepositVars(
        baseFee,
        requestId
      );

      for (uint256 i; i < _tokenIds.length; i++) {
        IRainiCard nftContract = IRainiCard(nftContracts[_contractId[i]]);
        IRainiCard.TokenVars memory tokenVars = IRainiCard.TokenVars(0,0,0,0);
        (tokenVars.cardId, tokenVars.level, tokenVars.number, tokenVars.mintedContractChar) = nftContract.tokenVars(_tokenIds[i]);
        require(!cardDisabled[_contractId[i]][tokenVars.cardId], "MainnetNftBridgePool: bridging this card disabled");
        nftContract.safeTransferFrom(_msgSender(), address(this), _tokenIds[i], _amounts[i], "");
        setHeldToken(_tokenIds[i], _contractId[i], tokenVars.cardId, tokenVars.level, tokenVars.mintedContractChar, tokenVars.number);
        _locals.requestId++;

        _locals.fee += itemFee[_contractId[i]];

        bytes memory state = "";
        if (tokenVars.number > 0 && hasSubcontracts[_contractId[i]]) {
          state = getSubContractTokenState(address(nftContract), tokenVars.cardId, _tokenIds[i]);
          if (state.length > 0) {
            _locals.fee += stateUpdateFee;
          }
        }

        uint32 stamina = 0;
        if (nftStakingPoolAddress != address(0)) {
          stamina = INftStakingPool(nftStakingPoolAddress).getTokenStaminaTotal(_tokenIds[i], address(nftContract));
          if (stamina != 0) {
            _locals.fee += staminaUpdateFee;
          }
        }

        emit CardsDeposited(
          _contractId[i],
          _msgSender(),
          _recipient,
          _amounts[i],
          _locals.requestId,
          tokenVars.cardId,
          tokenVars.level,
          tokenVars.number,
          stamina,
          tokenVars.mintedContractChar,
          state
        );
      }

      _locals.fee *= gasPrice;
 
      require(msg.value >= _locals.fee, "MainnetNftBridgePool: not enough funds");
      handleFeesWithdraw(_locals.fee, msg.value - _locals.fee);

      requestId = _locals.requestId;
  }

  function getDepositFee(address _recipient, uint256[] calldata _contractId, uint256[] calldata _tokenIds, uint256[] calldata _amounts) 
    public view returns (uint256 fee) {
      require(_tokenIds.length == _amounts.length, "MainnetNftBridgePool: input arrays not equal");

      DepositVars memory _locals =  DepositVars(
        baseFee,
        requestId
      );

      for (uint256 i; i < _tokenIds.length; i++) {
        IRainiCard nftContract = IRainiCard(nftContracts[_contractId[i]]);
        IRainiCard.TokenVars memory tokenVars = IRainiCard.TokenVars(0,0,0,0);
        (tokenVars.cardId, tokenVars.level, tokenVars.number, tokenVars.mintedContractChar) = nftContract.tokenVars(_tokenIds[i]);
        require(!cardDisabled[_contractId[i]][tokenVars.cardId], "MainnetNftBridgePool: bridging this card disabled");

        _locals.fee += itemFee[_contractId[i]];

        bytes memory state = "";
        if (tokenVars.number > 0 && hasSubcontracts[_contractId[i]]) {
          state = getSubContractTokenState(address(nftContract), tokenVars.cardId, _tokenIds[i]);
          if (state.length > 0) {
            _locals.fee += stateUpdateFee;
          }
        }

        uint32 stamina = 0;
        if (nftStakingPoolAddress != address(0)) {
          INftStakingPool(nftStakingPoolAddress).getTokenStaminaTotal(_tokenIds[i], address(nftContract));
          if (stamina != 0) {
            _locals.fee += staminaUpdateFee;
          }
        }
      }

      _locals.fee *= gasPrice;
      return _locals.fee;
  }

  function setHeldToken(uint256 tokenId, uint256 _contractId, uint256 _cardId, uint256 _cardLevel, bytes1 _mintedContractChar, uint256 _number) internal {
    if (_number == 0) {
      _mintedContractChar = bytes1(0);
    }
    if (heldTokens[_contractId][_cardId][_cardLevel][_mintedContractChar][_number] != tokenId) {
      heldTokens[_contractId][_cardId][_cardLevel][_mintedContractChar][_number] = tokenId;
    }
  }


  function findHeldToken(uint256 _contractId, uint256 _cardId, uint256 _cardLevel, bytes1 _mintedContractChar, uint256 _number) public view returns (uint256) {
    if (_number == 0) {
      _mintedContractChar = bytes1(0);
    }
    return heldTokens[_contractId][_cardId][_cardLevel][_mintedContractChar][_number];
  }

  struct WithdrawNftVars {
    uint256 tokenId;
    uint256 amount;
    uint256 leftAmount;
  }

  function withdrawNft(uint256 _contractId, address _recipient, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256 _requestsId, uint32 _stamina, bytes calldata _state) 
    public onlyMinter {

      if (requestWithdrawn[_requestsId]) {
        return;
      }

      requestWithdrawn[_requestsId] = true;

      WithdrawNftVars memory _locals = WithdrawNftVars(0, 0, 0);

      IRainiCard nftContract = IRainiCard(nftContracts[_contractId]);

      _locals.tokenId = findHeldToken(_contractId, _cardId, _cardLevel, _mintedContractChar, _number);
      _locals.amount = 0;
      if (_locals.tokenId > 0) {
        _locals.amount = nftContract.balanceOf(address(this), _locals.tokenId);
      }
      
      _locals.leftAmount = _amount;

      if (_locals.amount > 0) {
        if (_locals.amount > _amount) {
          _locals.leftAmount = 0;
          nftContract.safeTransferFrom(address(this), _recipient, _locals.tokenId, _amount, bytes(''));
        } else {
          _locals.leftAmount -= _locals.amount;
          nftContract.safeTransferFrom(address(this), _recipient, _locals.tokenId, _locals.amount, bytes(''));
          setHeldToken(0, _contractId, _cardId, _cardLevel, _mintedContractChar, _number);
        }
        
        updateStamina(address(nftContract), _locals.tokenId, _stamina);
        updateSubContractState(address(nftContract), _cardId, _locals.tokenId, _state);
      } 

      if (_locals.leftAmount > 0) {
        if (hasSubcontracts[_contractId]) {
          nftContract.mint(_recipient, _cardId, _cardLevel, _locals.leftAmount, _mintedContractChar, _number, new uint256[](0));
          updateSubContractState(address(nftContract), _cardId, nftContract.maxTokenId(), _state);
        } else {
          nftContract.mint(_recipient, _cardId, _cardLevel, _locals.leftAmount, _mintedContractChar, _number);
        }
        updateStamina(address(nftContract), nftContract.maxTokenId(), _stamina);
      }

      emit CardsWithdrawn(_contractId, _recipient, _requestsId, _cardId, _amount);
  }

  function bulkWithdrawNfts(uint232[] memory _contractId, address[] memory _recipient, uint256[] memory _cardId, uint256[] memory _cardLevel, uint256[] memory _amount, bytes1[] memory _mintedContractChar, uint256[] memory _number, uint256[] memory _requestsId, uint32[] memory _stamina, bytes[] calldata _state) 
    external onlyMinter {
      for (uint256 i; i < _contractId.length; i++) {
        withdrawNft(_contractId[i], _recipient[i], _cardId[i], _cardLevel[i], _amount[i],_mintedContractChar[i], _number[i], _requestsId[i], _stamina[i], _state[i]);
      }
  }

  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "MainnetNftBridgePool: not enough balance");
      
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "MainnetNftBridgePool: transfer failed");

      emit EthWithdrawn(_amount);
  }

  function onERC721Received(address, address, uint256, bytes memory) 
    public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    public virtual override returns (bytes4) {
      return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    public virtual override returns (bytes4) {
      return this.onERC1155BatchReceived.selector;
  }
}