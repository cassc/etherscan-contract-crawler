// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VSTONE is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public stoneContract;
    uint256 public maxSupply;
    uint256 public price;
    uint256 public constant SALE_START = 1682938800;
    uint256 public constant SALE_END = SALE_START + 2 days;
    uint256 public constant EXP = 1e18;
    uint256 public constant MAX_BUY = 3e18;
    address private beneficiary;
    mapping(address => uint256) private maxBuy;

    event Claimed(uint256 _amount);

    constructor(
        address _owner,
        uint256 _maxCap,
        uint256 _price,
        address _beneficiary
    ) ERC20("vSTONE", "vSTONE") {
        transferOwnership(_owner);
        maxSupply = _maxCap * EXP;
        price = _price;
        beneficiary = _beneficiary;
    }

    /// @notice admin can set STONE token to be claimed against vSTONE
    /// @param token address of ERC20 token to be claimed
    function setStoneContract(IERC20Metadata token) public onlyOwner {
        stoneContract = token;
    }

    /// @notice can set price for each vSTONE
    /// @param newPrice new price be 1e18
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /// @notice total purchased value in ETH
    /// @param buyer address of the buyer
    function getMaxBuy(address buyer) public view returns (uint256) {
        return maxBuy[buyer];
    }

    /// @notice can only renounce once the stoneContract published
    function renounceOwnership() public override onlyOwner {
        require(
            address(stoneContract) != address(0),
            "STONE_CONTRACT_REQUIRED"
        );
        super.renounceOwnership();
    }

    /// @notice buys vSTONE and charges eth
    /// @dev once SALE_END reaches no more tokens can be minted or purchased
    /// @param amount number of tokens to purchase
    function buy(uint256 amount) public payable {
        require(totalSupply() < maxSupply, "MAX_SUPPLY_SATISFIED");
        require(msg.value <= MAX_BUY, "MAX_BUY_IS_THREE_ETH");
        require(maxBuy[_msgSender()] < MAX_BUY, "MAX_BUY_EXCEEDED");
        require(block.timestamp >= SALE_START, "SALE_NOT_STARTED");
        require(block.timestamp <= SALE_END, "SALE_IS_CLOSED");
        require(msg.value >= (price * amount) / EXP, "PRICE_IS_HIGHER");
        payable(beneficiary).transfer(address(this).balance);
        _mint(_msgSender(), amount);
        maxBuy[_msgSender()] += msg.value;
    }

    /// @notice lets user to claim STONE tokens against vSTONE
    /// @dev in new contract vSTONE must own all of the initial supply to be able to validate the claims
    function claimSTONE() public {
        stoneContract.transfer(_msgSender(), balanceOf(_msgSender()));
        _burn(_msgSender(), balanceOf(_msgSender()));
        emit Claimed(balanceOf(_msgSender()));
    }
}