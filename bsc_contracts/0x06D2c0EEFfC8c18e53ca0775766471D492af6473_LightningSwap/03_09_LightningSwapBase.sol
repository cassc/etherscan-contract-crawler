// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom interface extending IERC20 with the decimals function
interface IERC20WithDecimals is IERC20 {
    function decimals() external pure returns (uint8);
}

contract LightningSwapBase is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant VERSION = "0.1.0";

    mapping(address => EnumerableSet.Bytes32Set) internal depositors;
    mapping(address => EnumerableSet.Bytes32Set) internal withdrawers;

    address public oracle;

    event DepositCreated(bytes32 indexed secretHash, address indexed depositor, address indexed beneficiary, address token, uint256 amount, uint256 deadline, string invoice);
    event Withdrawn(bytes32 indexed secretHash, address indexed withdrawer, address token, uint256 amount);
    event Refunded(bytes32 indexed secretHash, address indexed refundee, address token, uint256 amount);
    event OracleSet(address indexed oracle);

    function sha256Hash(bytes memory secret) public pure returns (bytes32) {
        bytes32 secretHash = sha256(abi.encodePacked(secret));
        return secretHash;
    }

    function getDepositorHashLength(address depositor) external view returns (uint256) {
        return depositors[depositor].length();
    }

    function getDepositorHashs(address depositor) external view returns (bytes32[] memory) {
        return depositors[depositor].values();
    }

    function getDepositorHashByIndex(address depositor, uint256 index) external view returns (bytes32) {
        return depositors[depositor].at(index);
    }

    function getWithdrawerHashLength(address withdrawer) external view returns (uint256) {
        return withdrawers[withdrawer].length();
    }

    function getWithdrawerHashs(address withdrawer) external view returns (bytes32[] memory) {
        return withdrawers[withdrawer].values();
    }

    function getWithdrawerHashByIndex(address withdrawer, uint256 index) external view returns (bytes32) {
        return withdrawers[withdrawer].at(index);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleSet(_oracle);
    }

    function parseInvoice(string memory invoice) public pure returns (string memory network, uint256 amount) {
        bytes memory invoiceBytes = bytes(invoice);
        require(invoiceBytes.length > 4, "Invalid invoice length");

        require(invoiceBytes[0] == 'l' && invoiceBytes[1] == 'n', "Invalid invoice prefix");
        if (invoiceBytes[2] == 'b' && invoiceBytes[3] == 'c') {
            network = "bc";
        } else if (invoiceBytes[2] == 'b' && invoiceBytes[3] == 's') {
            network = "bs";
        } else {
            revert("Invalid network in invoice");
        }

        uint256 index = 4;
        uint256 multiplier = 0;

        while (index < invoiceBytes.length) {
            uint8 charValue = uint8(invoiceBytes[index]);

            if (charValue >= 48 && charValue <= 57) {
                amount *= 10;
                amount += uint256(charValue - 48);
            } else if (charValue == 109 || charValue == 117 || charValue == 110 || charValue == 112) {
                if (charValue == 109) {
                    multiplier = 11;
                } else if (charValue == 117) {
                    multiplier = 8;
                } else if (charValue == 110) {
                    multiplier = 5;
                } else if (charValue == 112) {
                    multiplier = 2;
                }
                break;
            } else {
                revert("Invalid character in amount");
            }

            index++;
        }

        amount *= (10 ** multiplier);
    }


    function calculateBTCtoTokenPrice(
        address tokenAddress,
        uint256 tokenAmount,
        string memory invoice
    ) public pure returns (uint256) {
        IERC20WithDecimals token = IERC20WithDecimals(tokenAddress);
        uint256 tokenDecimals = token.decimals();
        (, uint256 btcAmount) = parseInvoice(invoice);

        // Convert token amount and BTC amount to the same precision (18 decimals)
        uint256 adjustedTokenAmount = tokenAmount * (10 ** (18 - tokenDecimals));
        uint256 adjustedBtcAmount = btcAmount * (10 ** 10);

        // Calculate BTC price relative to the token with 8 decimal precision
        uint256 btcPrice = (adjustedBtcAmount * 10 ** 8) / adjustedTokenAmount;

        return btcPrice;
    }

    function calculateBTCtoNativeCoinPrice(
        uint8 coinDecimals,
        uint256 coinAmount,
        string memory invoice
    ) public pure returns (uint256) {
        (, uint256 btcAmount) = parseInvoice(invoice);

        // Convert coin amount and BTC amount to the same precision (18 decimals)
        uint256 adjustedCoinAmount = coinAmount * (10 ** (18 - coinDecimals));
        uint256 adjustedBtcAmount = btcAmount * (10 ** 10);

        // Calculate BTC price relative to the token with 8 decimal precision
        uint256 btcPrice = (adjustedBtcAmount * 10 ** 8) / adjustedCoinAmount;

        return btcPrice;
    }
}