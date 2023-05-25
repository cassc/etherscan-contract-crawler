// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract GhostTraderV2 is ERC20, Ownable {
    //init
    bool public __initComplete;
    uint256 public __initMaxTotalSupply;

    //tax
    IERC20 public lpAddress;
    mapping(address => bool) private taxWhitelist;
    mapping(uint8 => uint16) public taxPercents;
    mapping(uint8 => address) public taxAddresses;
    mapping(uint8 => IERC721) public taxBuyWaiverNftAddresses;
    mapping(IERC721 => uint8) public taxBuyWaiverNftPercents;

    //events
    event TransferSummary(uint8 direction, address taxAddress, uint256 taxAmount, uint256 remainingAmount);

    constructor() ERC20("Ghost Trader", "GTR") {
        taxWhitelist[address(this)] = true;

        __initComplete = false;
        __initMaxTotalSupply = 100000000 * (10 ** 18);
    }



    //
    // INIT FUNCTIONS
    //

    function __initSetComplete() external onlyOwner { 
        require(__initComplete == false, "INIT_COMPLETE");
        __initComplete = true; 
    }

    function __initAirdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(__initComplete == false, "INIT_COMPLETE");
        require(addresses.length == amounts.length, "INPUT_MISMATCH");
        uint256 i = 0;

        //calculate total new tokens to mint
        uint256 mintTotal = 0;
        for (i = 0; i < addresses.length; i++) mintTotal += amounts[i];
        require((totalSupply() + mintTotal) <= __initMaxTotalSupply, "INVALID_NEW_SUPPLY");

        //mint tokens
        for (i = 0; i < addresses.length; i++) _mint(addresses[i], amounts[i]);
    }



    //
    // OVERRIDES
    //

    function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20)
    {
        //prevent transfers during initialisation
        require(__initComplete == true || taxWhitelist[from] == true || taxWhitelist[to] == true, "INIT_INCOMPLETE");

        uint256 remainingAmount = amount;
        if (taxWhitelist[from] == false && taxWhitelist[to] == false) {
            //calculate trade direction
            uint8 direction = 3;
            if (address(from) == address(lpAddress)) { direction = 1; }
            else if (address(to) == address(lpAddress)) { direction = 2; }

            //calculate taxes
            address taxAddress = taxAddresses[direction];
            uint16 taxPercent = taxPercents[direction];
            uint256 taxAmount = (taxAddress == address(0) || taxPercent == 0 ? 0 : remainingAmount * taxPercent / 100);

            //apply nft buy fee waiver if wallet is holding an approved NFT
            if (direction == 1 && taxAmount > 0 && taxAddress != address(0)) {
                IERC721 taxBuyWaiverNftAddress;
                for (uint8 i = 0; i < 5; i++) {
                    taxBuyWaiverNftAddress = taxBuyWaiverNftAddresses[i];
                    if (address(taxBuyWaiverNftAddress) != address(0) && taxBuyWaiverNftAddress.balanceOf(to) > 0) {
                        taxAmount = remainingAmount * (taxPercent-taxBuyWaiverNftPercents[taxBuyWaiverNftAddress]) / 100;
                        continue;
                    }
                }
            }

            //execute taxes
            if (taxAmount > 0 && taxAddress != address(0)) {
                remainingAmount -= taxAmount;
                super._transfer(from, taxAddress, taxAmount);
            }

            emit TransferSummary(direction, taxAddress, taxAmount, remainingAmount);
        }

        require(remainingAmount > 0, "TRANSFER_TOO_SMALL"); 
        super._transfer(from, to, remainingAmount);
    }



    //
    // PUBLIC FUNCTIONS
    //

    function getTaxEffectiveRates() external view returns(uint16 buy, uint16 sell, uint16 transfer, uint16 divisor) {
        uint16 buyDiscount = 0;
        IERC721 taxBuyWaiverNftAddress;
        for (uint8 i = 0; i < 5; i++) {
            taxBuyWaiverNftAddress = taxBuyWaiverNftAddresses[i];
            if (address(taxBuyWaiverNftAddress) != address(0) && taxBuyWaiverNftAddress.balanceOf(msg.sender) > 0) {
                buyDiscount = taxBuyWaiverNftPercents[taxBuyWaiverNftAddress];
                continue;
            }
        }

        return (taxPercents[1] - buyDiscount, taxPercents[2], taxPercents[3], 100);
    }


    //
    // ADMIN FUNCTIONS
    //

    function setLpAddress(IERC20 a) external onlyOwner {
        require(address(a) != address(0), "ADDRESS_INVALID");
        lpAddress = a; 
    }

    function getTaxWhitelistStatus(address a) external view onlyOwner returns (bool isWhitelisted) {
        return (taxWhitelist[a]);
    }

    function setTaxWhitelistStatus(address[] calldata addresses, bool[] calldata statuses) external onlyOwner {
        require(addresses.length == statuses.length, "INPUT_MISMATCH");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "ADDRESS_INVALID");
            taxWhitelist[addresses[i]] = statuses[i];
        }
    }

    function setTaxAmounts(uint8 direction, uint8 percent, address a) external onlyOwner {
        require(direction > 0 && direction <= 3, "INVALID_DIRECTION");
        require(percent <= 20, "INVALID_PERCENT");
        taxPercents[direction] = percent;
        taxAddresses[direction] = a;
    }

    function setTaxBuyWaiverNftAmounts(uint8 index, uint8 percent, IERC721 a) external onlyOwner {
        require(index < 5, "INVALID_INDEX");
        taxBuyWaiverNftAddresses[index] = a;
        taxBuyWaiverNftPercents[a] = percent;
    }

    function withdrawToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = to.call{value: (amount == 0 ? address(this).balance : amount)}(new bytes(0)); 
            require(success, "NATIVE_TRANSFER_FAILED");
        } else {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, (amount == 0 ? token.balanceOf(address(this)) : amount))); 
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20_TRANSFER_FAILED");
        }
    }

    receive() external payable {}
}