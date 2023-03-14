// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../weth/IWeth9.sol";
import "../niftykit/INiftyKit.sol";
import "./IGlobalKindMinter.sol";

/// @title A minter contract that owns a nifty kit proxy contract and splits mint fees between the
///    NiftyKit and the WETH recipient.
/// @author skymagic
/// @custom:security-contact [email protected]
contract GlobalKindMinter is Ownable, IGlobalKindMinter {

    INiftyKit public niftykit;
    address  public wethRecipient;
    IWETH9 public weth;

    uint128 public basisPointsWeth = 3750; // 37.5%

    constructor(address _niftykit, address _wethRecipient, address payable _weth)  {
        niftykit = INiftyKit(_niftykit);
        wethRecipient = _wethRecipient;
        weth = IWETH9(_weth);
    }

    function setNiftyKit(address _niftykit) external onlyOwner {
        niftykit = INiftyKit(_niftykit);
    }

    function setWethRecipient(address _wethRecipient) external onlyOwner {
        wethRecipient = _wethRecipient;
    }

    function setBasisPointsWeth(uint128 _basisPointsWeth) external onlyOwner {
        require(_basisPointsWeth <= 10000, "Invalid basis points");
        basisPointsWeth = _basisPointsWeth;
    }

    function transferOwnershipProxy(address newOwner) external onlyOwner {
        niftykit.transferOwnership(newOwner);
    }

    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyOwner {
        niftykit.startSale(newMaxAmount, newMaxPerMint, newMaxPerWallet, newPrice, presale);
    }

    function mintTo(address to, uint64 quantity) external payable {
        _mint(to, quantity);
    }

    function mint(uint64 quantity) external payable {
        _mint(msg.sender, quantity);
    }

    function _mint(address to, uint64 quantity) internal {
        payoutWeth(to, quantity);
        address[] memory toArray = new address[](1);
        toArray[0] = to;
        uint64[] memory quantityArray = new uint64[](1);
        quantityArray[0] = quantity;

        niftykit.batchAirdrop(quantityArray, toArray);
    }

    /// @notice Pay out the WETH recipient.
    /// @dev Swap Eth to WETH. Transfer WETH to the user. Then Transfer WETH to the recipient so that the contribution
    ///     appears to come from the msg sender.
    function payoutWeth(address from, uint64 quantity) internal {
        require(quantity > 0, "Quantity too low");
        uint256 price = niftykit.price();
        require(msg.value == price * quantity, "Not enough funds sent");
        uint256 wethCut = msg.value * basisPointsWeth / 10000;

        // swap half of eth to weth, and send back to sender
        weth.deposit{value : wethCut}();
        weth.transfer(from, wethCut);
        // send weth from sender to recipient2
        weth.transferFrom(from, wethRecipient, wethCut);
    }

    function withdraw(address payable _ethRecipient) external onlyOwner {
        require(_ethRecipient != address(0), "Invalid address");
        _ethRecipient.transfer(address(this).balance);
    }
}