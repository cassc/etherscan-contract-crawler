pragma solidity >=0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GluwaAirdropV2 is OwnableUpgradeable {
    event WithdrawToken(
        IERC20 indexed _token,
        address indexed _to,
        uint256 _amount
    );

    function GluwaAirdrop_init() external initializer {
        __Ownable_init();
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
        emit WithdrawToken(token, msg.sender, amount);
    }

    function multiTransferERC20(
        IERC20 token,
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external {
        uint arrayLength = addresses.length;
        for (uint256 i; i < arrayLength; ) {
            token.transferFrom(msg.sender, addresses[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20TightlyPacked(
        IERC20 token,
        bytes32[] calldata addressesAndAmounts
    ) external {
        uint arrayLength = addressesAndAmounts.length;
        uint256 amount;
        address to;
        for (uint256 i; i < arrayLength; ) {
            to = address(uint160(uint256(addressesAndAmounts[i] >> 96)));
            amount = uint256(uint96(uint256(addressesAndAmounts[i])));
            token.transferFrom(msg.sender, to, amount);
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20FromContract(
        IERC20 token,
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint arrayLength = addresses.length;
        for (uint256 i; i < arrayLength; ) {
            token.transfer(addresses[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20TightlyPackedFromContract(
        IERC20 token,
        bytes32[] calldata addressesAndAmounts
    ) external onlyOwner {
        uint arrayLength = addressesAndAmounts.length;
        uint256 amount;
        address to;
        for (uint256 i; i < arrayLength; ) {
            to = address(uint160(uint256(addressesAndAmounts[i] >> 96)));
            amount = uint256(uint96(uint256(addressesAndAmounts[i])));
            token.transfer(to, amount);
            unchecked {
                ++i;
            }
        }
    }
}