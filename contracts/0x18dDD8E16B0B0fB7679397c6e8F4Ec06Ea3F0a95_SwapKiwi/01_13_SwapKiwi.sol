// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title This is the contract which added erc1155 into the previous swap contract.
*/
contract SwapKiwi is Ownable, ERC721Holder, ERC1155Holder {

  uint64 private _swapsCounter;
  uint96 public etherLocked;
  uint96 public fee;

  address private constant _ZEROADDRESS = address(0);

  mapping (uint64 => Swap) private _swaps;

  struct Swap {
    address payable initiator;
    uint96 initiatorEtherValue;
    address[] initiatorNftAddresses;
    uint256[] initiatorNftIds;
    uint128[] initiatorNftAmounts;
    address payable secondUser;
    uint96 secondUserEtherValue;
    address[] secondUserNftAddresses;
    uint256[] secondUserNftIds;
    uint128[] secondUserNftAmounts;
  }

  event SwapExecuted(address indexed from, address indexed to, uint64 indexed swapId);
  event SwapCanceled(address indexed canceledBy, uint64 indexed swapId);
  event SwapCanceledWithSecondUserRevert(uint64 indexed swapId, bytes reason);
  event SwapCanceledBySecondUser(uint64 indexed swapId);
  event SwapProposed(
    address indexed from,
    address indexed to,
    uint64 indexed swapId,
    uint128 etherValue,
    address[] nftAddresses,
    uint256[] nftIds,
    uint128[] nftAmounts
  );
  event SwapInitiated(
    address indexed from,
    address indexed to,
    uint64 indexed swapId,
    uint128 etherValue,
    address[] nftAddresses,
    uint256[] nftIds,
    uint128[] nftAmounts
  );
  event AppFeeChanged(
    uint96 fee
  );
  event TransferEthToSecondUserFailed(uint64 indexed swapId);

  modifier onlyInitiator(uint64 swapId) {
    require(msg.sender == _swaps[swapId].initiator,
      "SwapKiwi: caller is not swap initiator");
    _;
  }

  modifier onlySecondUser(uint64 swapId) {
    require(msg.sender == _swaps[swapId].secondUser,
      "SwapKiwi: caller is not swap secondUser");
    _;
  }

  modifier onlyThisContractItself() {
    require(msg.sender == address(this), "Invalid caller");
    _;
  }

  modifier requireSameLength(address[] memory nftAddresses, uint256[] memory nftIds, uint128[] memory nftAmounts) {
    require(nftAddresses.length == nftIds.length, "SwapKiwi: NFT and ID arrays have to be same length");
    require(nftAddresses.length == nftAmounts.length, "SwapKiwi: NFT and AMOUNT arrays have to be same length");
    _;
  }

  modifier chargeAppFee() {
    require(msg.value >= fee, "SwapKiwi: Sent ETH amount needs to be more or equal application fee");
    _;
  }

  constructor(uint96 initalAppFee, address contractOwnerAddress) {
    fee = initalAppFee;
    super.transferOwnership(contractOwnerAddress);
  }

  function setAppFee(uint96 newFee) external onlyOwner {
    fee = newFee;
    emit AppFeeChanged(newFee);
  }

  /**
  * @dev First user proposes a swap to the second user with the NFTs that he deposits and wants to trade.
  *      Proposed NFTs are transfered to the SwapKiwi contract and
  *      kept there until the swap is accepted or canceled/rejected.
  *
  * @param secondUser address of the user that the first user wants to trade NFTs with
  * @param nftAddresses array of NFT addressed that want to be traded
  * @param nftIds array of IDs belonging to NFTs that want to be traded
  * @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
  * the token is ERC721 token. Otherwise the token is ERC1155 token.
  */
  function proposeSwap(
    address secondUser,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
    uint64 swapsCounter = _swapsCounter + 1;
    _swapsCounter = swapsCounter;

    Swap storage swap = _swaps[swapsCounter];
    swap.initiator = payable(msg.sender);

    if(nftAddresses.length > 0) {
      for (uint256 i = 0; i < nftIds.length; i++){
        safeTransferFrom(msg.sender, address(this), nftAddresses[i], nftIds[i], nftAmounts[i], "");
      }

      swap.initiatorNftAddresses = nftAddresses;
      swap.initiatorNftIds = nftIds;
      swap.initiatorNftAmounts = nftAmounts;
    }

    uint96 _fee = fee;
    uint96 initiatorEtherValue;

    if (msg.value > _fee) {
      initiatorEtherValue = uint96(msg.value) - _fee;
      swap.initiatorEtherValue = initiatorEtherValue;
      etherLocked += initiatorEtherValue;
    }
    swap.secondUser = payable(secondUser);

    emit SwapProposed(
      msg.sender,
      secondUser,
      swapsCounter,
      initiatorEtherValue,
      nftAddresses,
      nftIds,
      nftAmounts
    );
  }

  /**
  * @dev Second user accepts the swap (with proposed NFTs) from swap initiator and
  *      deposits his NFTs into the SwapKiwi contract.
  *      Callable only by second user that is invited by swap initiator.
  *      Even if the second user didn't provide any NFT and ether value equals to fee, it is considered valid.
  *
  * @param swapId ID of the swap that the second user is invited to participate in
  * @param nftAddresses array of NFT addressed that want to be traded
  * @param nftIds array of IDs belonging to NFTs that want to be traded
  * @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
  * the token is ERC721 token. Otherwise the token is ERC1155 token.
  */
  function initiateSwap(
    uint64 swapId,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
    require(_swaps[swapId].secondUser == msg.sender, "SwapKiwi: caller is not swap participator");
    require(
      _swaps[swapId].secondUserEtherValue == 0 &&
      _swaps[swapId].secondUserNftAddresses.length == 0
      , "SwapKiwi: swap already initiated"
    );

    if (nftAddresses.length > 0) {
      for (uint256 i = 0; i < nftIds.length; i++){
        safeTransferFrom(msg.sender, address(this), nftAddresses[i], nftIds[i], nftAmounts[i], "");
      }

      _swaps[swapId].secondUserNftAddresses = nftAddresses;
      _swaps[swapId].secondUserNftIds = nftIds;
      _swaps[swapId].secondUserNftAmounts = nftAmounts;
    }

    uint96 _fee = fee;
    uint96 secondUserEtherValue;

    if (msg.value > _fee) {
      secondUserEtherValue = uint96(msg.value) - _fee;
      _swaps[swapId].secondUserEtherValue = secondUserEtherValue;
      etherLocked += secondUserEtherValue;
    }

    emit SwapInitiated(
      msg.sender,
      _swaps[swapId].initiator,
      swapId,
      secondUserEtherValue,
      nftAddresses,
      nftIds,
      nftAmounts
    );
  }

  /**
  * @dev Swap initiator accepts the swap (NFTs proposed by the second user).
  *      Executeds the swap - transfers NFTs from SwapKiwi to the participating users.
  *      Callable only by swap initiator.
  *
  * @param swapId ID of the swap that the initator wants to execute
  */
  function acceptSwap(uint64 swapId) external onlyInitiator(swapId) {
    Swap memory swap = _swaps[swapId];
    delete _swaps[swapId];

    require(
      (swap.secondUserNftAddresses.length > 0 || swap.secondUserEtherValue > 0) &&
      (swap.initiatorNftAddresses.length > 0 || swap.initiatorEtherValue > 0),
      "SwapKiwi: Can't accept swap, both participants didn't add NFTs"
    );

    if (swap.secondUserNftAddresses.length > 0) {
      // transfer NFTs from escrow to initiator
      for (uint256 i = 0; i < swap.secondUserNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.initiator,
          swap.secondUserNftAddresses[i],
          swap.secondUserNftIds[i],
          swap.secondUserNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorNftAddresses.length > 0) {
      // transfer NFTs from escrow to second user
      for (uint256 i = 0; i < swap.initiatorNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.secondUser,
          swap.initiatorNftAddresses[i],
          swap.initiatorNftIds[i],
          swap.initiatorNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorEtherValue > 0) {
      etherLocked -= swap.initiatorEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.initiatorEtherValue}("");
      require(success, "Failed to send Ether to the second user");
    }
    if (swap.secondUserEtherValue > 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.initiator.call{value: swap.secondUserEtherValue}("");
      require(success, "Failed to send Ether to the initiator user");
    }

    emit SwapExecuted(swap.initiator, swap.secondUser, swapId);
  }

  /**
  * @dev Returns NFTs from SwapKiwi to swap initator.
  *      Callable only if second user hasn't yet added NFTs.
  *
  * @param swapId ID of the swap that the swap participants want to cancel
  */
  function cancelSwap(uint64 swapId) external returns (bool) {
    Swap memory swap = _swaps[swapId];
    delete _swaps[swapId]; 

    require(
      swap.initiator == msg.sender || swap.secondUser == msg.sender,
      "SwapKiwi: Can't cancel swap, must be swap participant"
    );

    if (swap.initiatorNftAddresses.length > 0) {
      // return initiator NFTs
      for (uint256 i = 0; i < swap.initiatorNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.initiator,
          swap.initiatorNftAddresses[i],
          swap.initiatorNftIds[i],
          swap.initiatorNftAmounts[i],
          ""
        );
      }
    }

    if (swap.initiatorEtherValue != 0) {
      etherLocked -= swap.initiatorEtherValue;
      (bool success,) = swap.initiator.call{value: swap.initiatorEtherValue}("");
      require(success, "Failed to send Ether to the initiator user");
    }

    if(swap.secondUserNftAddresses.length > 0) {
      // return second user NFTs
      try this.safeMultipleTransfersFrom(
        address(this),
        swap.secondUser,
        swap.secondUserNftAddresses,
        swap.secondUserNftIds,
        swap.secondUserNftAmounts
      ) {} catch (bytes memory reason) {
        _swaps[swapId].secondUser = swap.secondUser;
        _swaps[swapId].secondUserNftAddresses = swap.secondUserNftAddresses;
        _swaps[swapId].secondUserNftIds = swap.secondUserNftIds;
        _swaps[swapId].secondUserNftAmounts = swap.secondUserNftAmounts;
        _swaps[swapId].secondUserEtherValue = swap.secondUserEtherValue;
        emit SwapCanceledWithSecondUserRevert(swapId, reason);
        return true;
      }
    }

    if (swap.secondUserEtherValue != 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.secondUserEtherValue}("");
      if (!success) {
        etherLocked += swap.secondUserEtherValue;
        _swaps[swapId].secondUser = swap.secondUser;
        _swaps[swapId].secondUserEtherValue = swap.secondUserEtherValue;
        emit TransferEthToSecondUserFailed(swapId);
        return true;
      }
    }

    emit SwapCanceled(msg.sender, swapId);
    return true;
  }

  function cancelSwapBySecondUser(uint64 swapId) external onlySecondUser(swapId) {
    Swap memory swap = _swaps[swapId];
    delete _swaps[swapId];

    if(swap.secondUserNftAddresses.length > 0) {
      // return second user NFTs
      for (uint256 i = 0; i < swap.secondUserNftIds.length; i++) {
        safeTransferFrom(
          address(this),
          swap.secondUser,
          swap.secondUserNftAddresses[i],
          swap.secondUserNftIds[i],
          swap.secondUserNftAmounts[i],
          ""
        );
      }
    }

    if (swap.secondUserEtherValue != 0) {
      etherLocked -= swap.secondUserEtherValue;
      (bool success,) = swap.secondUser.call{value: swap.secondUserEtherValue}("");
      require(success, "Failed to send Ether to the second user");
    }

    if (swap.initiator != _ZEROADDRESS) {
      _swaps[swapId].initiator = swap.initiator;
      _swaps[swapId].initiatorEtherValue = swap.initiatorEtherValue;
      _swaps[swapId].initiatorNftAddresses = swap.initiatorNftAddresses;
      _swaps[swapId].initiatorNftIds = swap.initiatorNftIds;
      _swaps[swapId].initiatorNftAmounts = swap.initiatorNftAmounts;
    }

    emit SwapCanceledBySecondUser(swapId);
  }

  function safeMultipleTransfersFrom(
    address from,
    address to,
    address[] memory nftAddresses,
    uint256[] memory nftIds,
    uint128[] memory nftAmounts
  ) external onlyThisContractItself {
    for (uint256 i = 0; i < nftIds.length; i++) {
      safeTransferFrom(from, to, nftAddresses[i], nftIds[i], nftAmounts[i], "");
    }
  }

  function safeTransferFrom(
    address from,
    address to,
    address tokenAddress,
    uint256 tokenId,
    uint256 tokenAmount,
    bytes memory _data
  ) internal virtual {
    if (tokenAmount == 0) {
      IERC721(tokenAddress).transferFrom(from, to, tokenId);
    } else {
      IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, tokenAmount, _data);
    }
  }

  function withdrawEther(address payable recipient) external onlyOwner {
    require(recipient != address(0), "SwapKiwi: transfer to the zero address");

    recipient.transfer((address(this).balance - etherLocked));
  }
}