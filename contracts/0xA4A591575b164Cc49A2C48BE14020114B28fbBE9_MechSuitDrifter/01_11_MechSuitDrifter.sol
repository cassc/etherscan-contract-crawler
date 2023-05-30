//SPDX-License-Identifier: MIT
//Fringe Drifters Lykenrot Contract Created by Swifty.eth
//Legal: https://fringedrifters.com/terms

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address _from) external returns (uint256);
}

//errors
error NotWithdrawAddress();
error FailedToWithdraw();
error NotMinting();
error NotEnoughEth();
error PastBoundsOfBatchLimit();
error PastSupply();
error AlreadyMinted();
error AuthenticationFailed();
error DoesNotExist();

contract MechSuitDrifter is ERC1155, Ownable {
    string public name = "Mech Suit - Fringe Drifters";
    string public symbol = "MSFD";
    address internal _FDContractAddress;

    uint256 public mechPrice = 0.05 ether;
    uint256 public constant totalMechSuits = 250;
    uint256 public currentMechSuits = 0;

    bool public minting = false;

    uint256 public maxBatch = 10;

    address private withdrawAccount =
        0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    mapping(uint256 => uint256) public drifterToMechSuit; //0 means no mech suit.
    mapping(uint256 => bool) public bannedDrifters;

    string internal _baseURI;

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }

    constructor(string memory baseURI, address startingContractAddress)
        ERC1155("")
    {
        _baseURI = baseURI;
        _FDContractAddress = startingContractAddress;
    }

    function gift(uint256 mechId, address[] calldata receivers)
        external
        onlyOwner
    {
        //bulk mints.
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], mechId, 1, "");
        }
    }

    function mint(uint256 qty, uint256 typeMechSuit) external payable {
        if (typeMechSuit == 0) revert DoesNotExist();
        if (!minting) revert NotMinting();
        if (msg.value != (mechPrice * qty)) revert NotEnoughEth();
        if (qty > maxBatch) revert PastBoundsOfBatchLimit();
        if ((currentMechSuits + qty) > totalMechSuits) revert PastSupply();

        _mint(msg.sender, typeMechSuit, qty, "");

        currentMechSuits += qty;
    }

    function transformDrifter(uint256 drifter, uint256 typeMechSuit) external {
        FDContractTrait FDContract = FDContractTrait(_FDContractAddress);
        if (FDContract.ownerOf(drifter) != msg.sender)
            revert AuthenticationFailed();
        if (drifterToMechSuit[drifter] != 0) revert AlreadyMinted();
        if (typeMechSuit == 0) revert DoesNotExist();
        if (bannedDrifters[drifter]) revert DoesNotExist();

        if (balanceOf(msg.sender, typeMechSuit) == 0) revert DoesNotExist();

        _burn(msg.sender, typeMechSuit, 1);

        drifterToMechSuit[drifter] = typeMechSuit;
    }

    function adjustBanned(uint256 drifter, bool banned) external onlyOwner {
        bannedDrifters[drifter] = banned;
    }

    function totalBalance() external view returns (uint256) {
        //gets total balance in account.
        return payable(address(this)).balance;
    }

    function adjustPrice(uint256 newPrice) external onlyOwner {
        mechPrice = newPrice;
    }

    function adjustBatch(uint256 newBatch) external onlyOwner {
        maxBatch = newBatch;
    }

    function toggleMint() external onlyOwner {
        minting = !minting;
    }

    //changes withdraw address if needed.
    function changeWithdrawer(address newAddress)
        external
        withdrawAddressCheck
    {
        withdrawAccount = newAddress;
    }

    //withdraws all eth funds.
    function withdrawFunds() external withdrawAddressCheck {
        (bool success, bytes memory __) = payable(msg.sender).call{
            value: this.totalBalance()
        }("");
        if (!success) revert FailedToWithdraw();
    }

    //withdraws ERC20 tokens.
    function withdrawERC20(IERC20 erc20Token) external withdrawAddressCheck {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    //sets new baseURI
    function setURI(string calldata URI) external onlyOwner {
        _baseURI = URI;
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI,
                    Strings.toString(tokenId),
                    string(".json")
                )
            );
    }
}

abstract contract FDContractTrait {
    function ownerOf(uint256 tokenId) external view virtual returns (address);
}