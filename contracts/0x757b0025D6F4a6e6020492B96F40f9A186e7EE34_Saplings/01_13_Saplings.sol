// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./AccessControlLight.sol";
import "./interfaces/ISaplings.sol";
import "./interfaces/IWETH.sol";

// Sappling placeholder contract to reserve the collection name on OpenSea

contract Saplings is ISaplings, ERC721A, AccessControlLight {

  uint256 private _supplyCap = 10000;
  string private __baseURI = 'https://api.saplings.earth/nft/metadata/';
  mapping(address => uint256) private _userNonces;

  ISwapRouter private constant SWAP_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private currency = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address public charity1 = 0x8aeb83D3d05741CC3Ba89F9B823e9d029d5fD8A6;
  address public charity2 = 0xD173210a16CdA79E691BA3286F4c2891a57f62d6;
  address public charity3 = 0x79Ae3a03C1F7E100113Db2e91C93Cd08aa84910e;

  address public saplingsWallet = 0x072c77409dd951E60caFB455E23Bb497f35480C8;
  uint256 private _charityBalance;

  constructor(address signer) ERC721A("Saplings", "SAP") {
    _grantRole(ROLE_SIGNER, signer);
  }

  receive() external payable {
    emit ReceivedEth(msg.sender, msg.value);
  }

  function mint(
    uint256 value,
    uint256 quantity,
    uint256 blockNumber,
    bytes calldata signature
  ) public payable {
    if (!_checkSignature(value, quantity, blockNumber, signature)) {
      revert InvalidSignature();
    }
    if (value != msg.value) {
      revert WrongAmount();
    }
    if (quantity + totalSupply() > _supplyCap) {
      revert SoldOut();
    }
    if (block.number > blockNumber + 10) {
      revert Timeout();
    }
    _userNonces[msg.sender]++;
    _mint(msg.sender, quantity);
    _charityBalance += msg.value / 2;
  }

  function setSupply(uint256 supplyCap) external onlyRole(ROLE_ADMIN) {
    _supplyCap = supplyCap;
  }

  function setURI(string calldata uri) external onlyRole(ROLE_ADMIN) {
    __baseURI = uri;
  }

  function setCurrency(address token) external onlyRole(ROLE_ADMIN) {
    if (token == currency) {
      revert NothingToDo();
    }
    if (_charityBalance > 0) {
      revert SendToCharityFirst();
    }
    currency = token;
  }

  function setCharity(address _charity1, address _charity2, address _charity3) external onlyRole(ROLE_ADMIN) {
    charity1 = _charity1;
    charity2 = _charity2;
    charity3 = _charity3;
    emit UpdatedCharity(_charity1, _charity2, _charity3);
  }

  function _baseURI() internal view override returns (string memory) {
    return __baseURI;
  }

  function _checkSignature(
    uint256 value,
    uint256 quantity,
    uint256 blockNumber,
    bytes calldata signature
  ) internal view returns(bool) {
    bytes32 message = keccak256(abi.encodePacked(
        msg.sender, _userNonces[msg.sender], value, quantity, blockNumber
      ));
    bytes32 hash = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        message
      )
    );
    address signer = ECDSA.recover(hash, signature);
    return hasRole(ROLE_SIGNER, signer);
  }

  function withdraw(address erc20) external onlyRole(ROLE_ADMIN) {
    if (erc20 == address(0) || erc20 == WETH) {
      _withdrawEth();
    } else {
      _withdrawCurrency(erc20);
    }
  }

  function _withdrawEth() internal {
    uint256 wrappedBalance = IERC20(WETH).balanceOf(address(this));
    if (wrappedBalance > 0) {
      IWETH(WETH).withdraw(wrappedBalance);
    }
    uint256 nativeBalance = address(this).balance;
    uint256 balance = nativeBalance - _charityBalance;
    if (balance == 0) {
      revert NothingToDo();
    }
    (bool success, ) = saplingsWallet.call{ value: balance }("");
    if (!success) {
      revert PaymentFailed();
    }
  }

  function _withdrawCurrency(address erc20) internal {
    uint256 currencyBalance = IERC20(erc20).balanceOf(address(this));
    if (currencyBalance == 0) {
      revert NothingToDo();
    }
    IERC20(erc20).transfer(saplingsWallet, currencyBalance);
  }

  function sendToCharity() external onlyRole(ROLE_ADMIN) {
    uint256 split = _charityBalance * 3333 / 10000;
    (bool sucess1, ) = charity1.call{ value: split }("");
    (bool sucess2, ) = charity2.call{ value: split }("");
    (bool sucess3, ) = charity3.call{ value: split }("");
    if (!sucess1 || !sucess2 || !sucess3) {
      revert PaymentFailed();
    }
    _charityBalance = 0;
  }

  function setSaplingsWallet(address newWallet) external onlyRole(ROLE_ADMIN) {
    if (newWallet == saplingsWallet) {
      revert NothingToDo();
    }
    saplingsWallet = newWallet;
  }

  function swapBalance(uint24 fee, uint256 amountOutMinimum) external onlyRole(ROLE_ADMIN) {
    uint256 ethBalance = address(this).balance - _charityBalance;
    if (ethBalance == 0) {
      revert NothingToDo();
    }
    IWETH(WETH).deposit{value: ethBalance}();
    uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
    (bool success, ) = _swapWeth(wethBalance, fee, amountOutMinimum);
    if (!success) {
      revert SwapFailed();
    }
  }

  function _swapWeth(uint256 amount, uint24 fee, uint256 amountOutMinimum) internal returns(bool, uint256) {
    TransferHelper.safeApprove(WETH, address(SWAP_ROUTER), amount);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: WETH,
      tokenOut: currency,
      fee: fee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amount,
      amountOutMinimum: amountOutMinimum,
      sqrtPriceLimitX96: 0
    });

    try SWAP_ROUTER.exactInputSingle(params) returns (uint256 outAmount) {
      emit SwapSuccess(currency, amount, outAmount);
      return (true, outAmount);
    } catch Error(string memory reason) {
      emit SwapFailure(reason);
      return (false, 0);
    }
  }
}